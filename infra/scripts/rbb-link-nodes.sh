#!/usr/bin/env bash
# Aplica a topologia do roteiro_adicao_nos.md (passo 3) entre os nós da organização:
#   - validator: static-nodes = validators das OUTRAS organizações (network/validators.txt) + boots PRÓPRIOS (IP interno)
#   - writer / observer-boot (partícipe associado): static-nodes = boots PRÓPRIOS (IP interno)
#   - observer (interno/archive): static-nodes = observer-boots PRÓPRIOS (IP interno)
#   - boot: discovery.bootnodes = boots das OUTRAS organizações (network/boots.txt)
#   - prometheus: instala network/clients.pem (mTLS) e network/federation.json (alvos federados), se existirem
# Depois reinicia os nós alterados. Idempotente.
#
# Uso: ./scripts/rbb-link-nodes.sh <testnet|mainnet> [--no-restart]
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_env "${1:-}"
env="$1"; restart=true; [[ "${2:-}" == "--no-restart" ]] && restart=false
netdir="$(env_dir "${env}")/network"

read_list() { [[ -f "$1" ]] && grep -E '^enode://' "$1" || true; }
# (compatível com o bash 3.2 do macOS)
ext_boots=(); while IFS= read -r l; do [[ -n "${l}" ]] && ext_boots+=("${l}"); done < <(read_list "${netdir}/boots.txt")
ext_validators=(); while IFS= read -r l; do [[ -n "${l}" ]] && ext_validators+=("${l}"); done < <(read_list "${netdir}/validators.txt")

echo "== enodes internos dos boots próprios"
own_boots=()
for b in $(nodes_of_type "${env}" boot); do
  e="$(node_ssh "${env}" "${b}" sudo rbb-node enode --internal)"
  echo "   ${b}: ${e}"; own_boots+=("${e}")
done
[[ ${#own_boots[@]} -gt 0 ]] || echo "AVISO: nenhum boot próprio; validators/writers dependerão apenas de peers externos."
own_obs_boots=()
for b in $(nodes_of_type "${env}" observer-boot); do
  e="$(node_ssh "${env}" "${b}" sudo rbb-node enode --internal)"; own_obs_boots+=("${e}")
done

changed=()
for node in $(nodes_json "${env}" | jq -r 'keys[]'); do
  type="$(nodes_json "${env}" | jq -r --arg n "${node}" '.[$n].type')"
  case "${type}" in
    validator)
      peers=(${ext_validators[@]+"${ext_validators[@]}"} ${own_boots[@]+"${own_boots[@]}"})
      echo "== ${node}: static-nodes (${#peers[@]} peers)"
      node_ssh "${env}" "${node}" sudo rbb-node peers set ${peers[@]+"${peers[@]}"}; changed+=("${node}") ;;
    writer|observer-boot)
      echo "== ${node}: static-nodes (${#own_boots[@]} boots próprios)"
      node_ssh "${env}" "${node}" sudo rbb-node peers set ${own_boots[@]+"${own_boots[@]}"}; changed+=("${node}") ;;
    observer)
      [[ ${#own_obs_boots[@]} -gt 0 ]] || { echo "== ${node}: sem observer-boot próprio; observer fica sem peers" ; continue; }
      echo "== ${node}: static-nodes (${#own_obs_boots[@]} observer-boots próprios)"
      node_ssh "${env}" "${node}" sudo rbb-node peers set ${own_obs_boots[@]+"${own_obs_boots[@]}"}; changed+=("${node}") ;;
    boot)
      if [[ ${#ext_boots[@]} -gt 0 ]]; then
        echo "== ${node}: bootnodes (${#ext_boots[@]} boots externos)"
        node_ssh "${env}" "${node}" sudo rbb-node bootnodes set ${ext_boots[@]+"${ext_boots[@]}"}; changed+=("${node}")
      else
        echo "== ${node}: network/boots.txt ausente; discovery do genesis mantido"
      fi ;;
    prometheus)
      if [[ -f "${netdir}/clients.pem" ]]; then
        echo "== ${node}: instalando clients.pem"
        node_ssh "${env}" "${node}" 'cat > /tmp/clients.pem && sudo rbb-node prometheus clients /tmp/clients.pem' < "${netdir}/clients.pem"
      fi
      if [[ -f "${netdir}/federation.json" ]]; then
        echo "== ${node}: atualizando alvos federados ($(jq length "${netdir}/federation.json"))"
        jq '[.[] | {targets: [.target], labels: {organization: .organization}}]' "${netdir}/federation.json" \
          | node_ssh "${env}" "${node}" 'cat > /tmp/federation.json && sudo rbb-node prometheus federation /tmp/federation.json'
      fi ;;
  esac
done

if ${restart}; then
  for node in ${changed[@]+"${changed[@]}"}; do echo "== reiniciando ${node}"; node_ssh "${env}" "${node}" sudo rbb-node restart >/dev/null; done
fi
echo "concluído. Verifique com: ./scripts/rbb-ssh.sh ${env} <nó> sudo rbb-node status"
