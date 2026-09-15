#!/usr/bin/env bash
# Aplica a topologia do roteiro_adicao_nos.md (passo 3) entre os nós da organização:
#   - validator: static-nodes = validators das OUTRAS organizações (network/validators.txt) + boots PRÓPRIOS (IP interno)
#   - writer / observer-boot (partícipe associado): static-nodes = boots PRÓPRIOS (IP interno)
#   - boot: discovery.bootnodes = boots das OUTRAS organizações (network/boots.txt)
#   - prometheus: instala network/clients.pem (mTLS) se existir
# Depois reinicia os nós alterados. Idempotente.
#
# Uso: ./scripts/rbb-link-nodes.sh <testnet|mainnet> [--no-restart]
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_env "${1:-}"
env="$1"; restart=true; [[ "${2:-}" == "--no-restart" ]] && restart=false
netdir="$(env_dir "${env}")/network"

read_list() { [[ -f "$1" ]] && grep -E '^enode://' "$1" || true; }
mapfile -t ext_boots < <(read_list "${netdir}/boots.txt")
mapfile -t ext_validators < <(read_list "${netdir}/validators.txt")

echo "== enodes internos dos boots próprios"
own_boots=()
for b in $(nodes_of_type "${env}" boot); do
  e="$(node_ssh "${env}" "${b}" sudo rbb-node enode --internal)"
  echo "   ${b}: ${e}"; own_boots+=("${e}")
done
[[ ${#own_boots[@]} -gt 0 ]] || echo "AVISO: nenhum boot próprio; validators/writers dependerão apenas de peers externos."

changed=()
for node in $(nodes_json "${env}" | jq -r 'keys[]'); do
  type="$(nodes_json "${env}" | jq -r --arg n "${node}" '.[$n].type')"
  case "${type}" in
    validator)
      peers=("${ext_validators[@]}" "${own_boots[@]}")
      echo "== ${node}: static-nodes (${#peers[@]} peers)"
      node_ssh "${env}" "${node}" sudo rbb-node peers set "${peers[@]}"; changed+=("${node}") ;;
    writer|observer-boot)
      echo "== ${node}: static-nodes (${#own_boots[@]} boots próprios)"
      node_ssh "${env}" "${node}" sudo rbb-node peers set "${own_boots[@]}"; changed+=("${node}") ;;
    boot)
      if [[ ${#ext_boots[@]} -gt 0 ]]; then
        echo "== ${node}: bootnodes (${#ext_boots[@]} boots externos)"
        node_ssh "${env}" "${node}" sudo rbb-node bootnodes set "${ext_boots[@]}"; changed+=("${node}")
      else
        echo "== ${node}: network/boots.txt ausente; discovery do genesis mantido"
      fi ;;
    prometheus)
      if [[ -f "${netdir}/clients.pem" ]]; then
        echo "== ${node}: instalando clients.pem"
        node_ssh "${env}" "${node}" 'cat > /tmp/clients.pem && sudo rbb-node prometheus clients /tmp/clients.pem' < "${netdir}/clients.pem"
      fi ;;
  esac
done

if ${restart}; then
  for node in "${changed[@]}"; do echo "== reiniciando ${node}"; node_ssh "${env}" "${node}" sudo rbb-node restart >/dev/null; done
fi
echo "concluído. Verifique com: ./scripts/rbb-ssh.sh ${env} <nó> sudo rbb-node status"
