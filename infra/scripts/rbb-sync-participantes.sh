#!/usr/bin/env bash
# Sincroniza os dados da rede a partir do repositório privado RBBNet/participantes
# (requer 'gh' autenticado com uma conta membro da org RBBNet) e gera, em
# tofu/envs/<env>/network/:
#   genesis.json            <- participantes/<rede>/genesis.json
#   nodes.json              <- participantes/<rede>/nodes.json
#   docker-compose.yml.hbs  <- participantes/<rede>/docker-compose.yml.hbs (se existir)
#   boots.txt               <- enodes dos boots ATIVOS das OUTRAS organizações
#   validators.txt          <- enodes dos validators ATIVOS das OUTRAS organizações
#   federation.json         <- Prometheus (porta 8443, mTLS) ATIVOS das OUTRAS organizações
#   clients.pem             <- certificados concatenados de participantes/<rede>/certificados
#
# Uso: ./scripts/rbb-sync-participantes.sh <testnet|mainnet> [NOME-DA-ORGANIZACAO]
#   NOME-DA-ORGANIZACAO: como consta em nodes.json (ex.: BNDES). Padrão: variável
#   organization_name/organization do terraform.tfvars do ambiente, em maiúsculas.
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_env "${1:-}"
env="$1"
case "${env}" in testnet) rede=lab ;; mainnet) rede=piloto ;; esac
netdir="${RBB_NETWORK_DIR:-$(env_dir "${env}")/network}"
mkdir -p "${netdir}"

org="${2:-}"
if [[ -z "${org}" ]]; then
  tfvars="$(env_dir "${env}")/terraform.tfvars"
  if [[ -f "${tfvars}" ]]; then
    org="$(grep -E '^\s*organization_name\s*=' "${tfvars}" | sed -E 's/.*=\s*"([^"]+)".*/\1/' | head -1)"
    [[ -n "${org}" ]] || org="$(grep -E '^\s*organization\s*=' "${tfvars}" | sed -E 's/.*=\s*"([^"]+)".*/\1/' | head -1 | tr '[:lower:]' '[:upper:]')"
  fi
fi
[[ -n "${org}" ]] || { echo "informe o nome da organização (como em nodes.json) como 2º argumento" >&2; exit 1; }

gh auth status >/dev/null 2>&1 || { echo "gh não autenticado (gh auth login)" >&2; exit 1; }
fetch() { gh api "repos/RBBNet/participantes/contents/${rede}/$1" --jq .content | base64 -d; }

echo "== ${env} (rede ${rede}), organização própria: ${org}"
fetch genesis.json > "${netdir}/genesis.json"; echo "   genesis.json (chainId $(jq .config.chainId "${netdir}/genesis.json"))"
fetch nodes.json   > "${netdir}/nodes.json";   echo "   nodes.json ($(jq length "${netdir}/nodes.json") organizações)"
if fetch docker-compose.yml.hbs > "${netdir}/docker-compose.yml.hbs" 2>/dev/null && [[ -s "${netdir}/docker-compose.yml.hbs" ]]; then
  echo "   docker-compose.yml.hbs (template específico da rede)"
else
  rm -f "${netdir}/docker-compose.yml.hbs"
fi

if ! jq -e --arg o "${org}" 'map(.organization) | index($o)' "${netdir}/nodes.json" >/dev/null; then
  echo "   AVISO: '${org}' ainda não consta em nodes.json (normal antes do passo 6 do roteiro). Organizações: $(jq -r 'map(.organization) | join(", ")' "${netdir}/nodes.json")"
fi

# Nós ativos das outras organizações. Usa o primeiro IP documentado.
active='.deploymentStatus == "deployed" and .operationalStatus == "active"'
jq -r --arg o "${org}" ".[] | select(.organization != \$o) | .nodes[] | select(${active} and .nodeType == \"boot\" and .pubKey) | \"enode://\(.pubKey[2:])@\(.ipAddresses[0]):\(.port)\"" \
  "${netdir}/nodes.json" > "${netdir}/boots.txt"
jq -r --arg o "${org}" ".[] | select(.organization != \$o) | .nodes[] | select(${active} and .nodeType == \"validator\" and .pubKey) | \"enode://\(.pubKey[2:])@\(.ipAddresses[0]):\(.port)\"" \
  "${netdir}/nodes.json" > "${netdir}/validators.txt"
jq --arg o "${org}" "[.[] | select(.organization != \$o) | .organization as \$org | .nodes[] | select(${active} and .nodeType == \"prometheus\" and .port == 8443) | {organization: \$org, target: \"\(.ipAddresses[0]):\(.port)\"}]" \
  "${netdir}/nodes.json" > "${netdir}/federation.json"
echo "   boots.txt ($(wc -l < "${netdir}/boots.txt" | tr -d ' ')), validators.txt ($(wc -l < "${netdir}/validators.txt" | tr -d ' ')), federation.json ($(jq length "${netdir}/federation.json"))"

# Certificados dos Prometheus dos partícipes (bundle para o mTLS do NGINX)
: > "${netdir}/clients.pem"
n=0
for c in $(gh api "repos/RBBNet/participantes/contents/${rede}/certificados" --jq '.[] | select(.name | endswith(".pem")) | .name'); do
  fetch "certificados/${c}" >> "${netdir}/clients.pem"; printf '\n' >> "${netdir}/clients.pem"; n=$((n+1))
done
echo "   clients.pem (${n} certificados)"
echo "concluído: ${netdir}"
