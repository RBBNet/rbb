#!/usr/bin/env bash
# Coleta 'rbb-node info' de todos os nós Besu e gera:
#   - a entrada da organização para participantes/<rede>/nodes.json (passo 6 do roteiro), em
#     tofu/envs/<env>/network/our-nodes.json (validada contra o esquema quando disponível)
#   - os parâmetros de permissionamento gen02 (passo 8) e do voto QBFT (passo 13)
# Uso: ./scripts/rbb-node-info.sh <testnet|mainnet> [provisioned|deployed] [active|inactive]
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_env "${1:-}"
env="$1"; deploy="${2:-provisioned}"; oper="${3:-active}"
netdir="$(env_dir "${env}")/network"; mkdir -p "${netdir}"

infos=()
# observer interno não entra no nodes.json (fora do núcleo da RBB)
for node in $(nodes_json "${env}" | jq -r 'to_entries[] | select(.value.type != "prometheus" and .value.type != "observer") | .key'); do
  info="$(node_ssh "${env}" "${node}" sudo rbb-node info 2>/dev/null || true)"
  [[ -n "${info}" && "$(jq -r .pubKey <<<"${info}")" != "" ]] || { echo "AVISO: ${node} ainda sem chave (bootstrap em andamento?)" >&2; continue; }
  infos+=("${info}")
done
[[ ${#infos[@]} -gt 0 ]] || { echo "nenhum nó respondeu" >&2; exit 1; }

# Prometheus: entra no nodes.json com IP público e porta 8443 (mTLS), sem pubKey.
# Sem IP público ele não é alcançável pelos demais partícipes e fica de fora até ter um.
prom_entries="$(nodes_json "${env}" | jq -c '[to_entries[] | select(.value.type == "prometheus" and .value.public_ip != null) | {name: .key, nodeType: "prometheus", ipAddresses: [.value.public_ip], port: 8443}]')"
if nodes_json "${env}" | jq -e 'to_entries[] | select(.value.type == "prometheus" and .value.public_ip == null)' >/dev/null; then
  echo "AVISO: prometheus sem IP público não entra no nodes.json (os demais partícipes não conseguiriam coletar)." >&2
fi

printf '%s\n' ${infos[@]+"${infos[@]}"} | jq -s --arg d "${deploy}" --arg o "${oper}" --argjson prom "${prom_entries}" '
  { organization: .[0].organization,
    nodes: ((map({ name, nodeType, pubKey, hostNames, ipAddresses, port, id })
             | map(if .nodeType != "validator" or .id == "" then del(.id) else . end)
             | map(if (.hostNames | length) == 0 then del(.hostNames) else . end))
            + $prom)
           | map(. + { deploymentStatus: $d, operationalStatus: $o }) }' > "${netdir}/our-nodes.json"

echo "== entrada para participantes/$( [[ "${env}" == testnet ]] && echo lab || echo piloto)/nodes.json (${netdir}/our-nodes.json)"
jq . "${netdir}/our-nodes.json"
if command -v check-jsonschema >/dev/null 2>&1 && gh api repos/RBBNet/participantes/contents/nodes.schema.json --jq .content 2>/dev/null | base64 -d > "${netdir}/nodes.schema.json"; then
  jq '[.]' "${netdir}/our-nodes.json" > "${netdir}/.our-nodes-array.json"
  check-jsonschema --schemafile "${netdir}/nodes.schema.json" "${netdir}/.our-nodes-array.json" && echo "   esquema OK"
  rm -f "${netdir}/.our-nodes-array.json"
fi

echo
echo "== permissionamento gen02 (passo 8) e voto QBFT (passo 13)"
for node in $(printf '%s\n' ${infos[@]+"${infos[@]}"} | jq -r .name); do
  echo "--- ${node}"; node_ssh "${env}" "${node}" sudo rbb-node perm-args
done
echo
echo "Publique com: ./scripts/rbb-publish-nodes.sh ${env}"
