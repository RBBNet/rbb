#!/usr/bin/env bash
# Coleta 'rbb-node info' de todos os nós Besu e imprime o trecho de nodes.json
# (RBBNet/participantes/<rede>/nodes.json) e os parâmetros para addEnode().
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_env "${1:-}"
env="$1"

infos=()
for node in $(nodes_json "${env}" | jq -r 'to_entries[] | select(.value.type != "prometheus") | .key'); do
  info="$(node_ssh "${env}" "${node}" sudo rbb-node info 2>/dev/null || true)"
  [[ -n "${info}" ]] || { echo "AVISO: ${node} ainda sem informações (bootstrap em andamento?)" >&2; continue; }
  infos+=("${info}")
done
[[ ${#infos[@]} -gt 0 ]] || exit 1

printf '%s\n' "${infos[@]}" | jq -s '
  { organization: .[0].organization,
    nodes: map({ name, nodeType, pubKey, hostNames: [], ipAddresses, port,
                 id: "", deploymentStatus: "deployed", operationalStatus: "active" }) }'

echo
echo "# Permissionamento on chain (addEnode): enodeHigh / enodeLow / nodeType / geoHash 0x000000000000 / name / organization"
printf '%s\n' "${infos[@]}" | jq -r '"\(.name): high=0x\(.pubKey[2:66]) low=0x\(.pubKey[66:130]) type=\(.nodeType)"'
