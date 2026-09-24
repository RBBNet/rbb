#!/usr/bin/env bash
# Publica (ou atualiza) a entrada da organização em RBBNet/participantes/<rede>/nodes.json
# por meio de um pull request (passo 6 do roteiro). Requer 'gh' com acesso ao repositório.
#
# Uso: ./scripts/rbb-publish-nodes.sh <testnet|mainnet> [--dry-run]
#   Lê tofu/envs/<env>/network/our-nodes.json (gerado por rbb-node-info.sh), mescla com o
#   nodes.json atual (substitui a entrada da organização, se existir), cria a branch
#   <org>-nodes-<rede>-<data> e abre o PR. Inclui no mesmo PR o certificado de cada
#   Prometheus com IP público (<rede>/certificados/<org>-<no>.pem, lido da VM), para o mTLS
#   dos demais partícipes. Com --dry-run só grava network/nodes.merged.json e os .pem.
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_env "${1:-}"
env="$1"; dry=false; [[ "${2:-}" == "--dry-run" ]] && dry=true
case "${env}" in testnet) rede=lab ;; mainnet) rede=piloto ;; esac
netdir="$(env_dir "${env}")/network"
ours="${netdir}/our-nodes.json"
[[ -f "${ours}" ]] || { echo "gere ${ours} com ./scripts/rbb-node-info.sh ${env}" >&2; exit 1; }
org="$(jq -r .organization "${ours}")"

repo=RBBNet/participantes
cur="$(gh api "repos/${repo}/contents/${rede}/nodes.json")"
sha="$(jq -r .sha <<<"${cur}")"
jq -r .content <<<"${cur}" | base64 -d > "${netdir}/nodes.current.json"

# Insere/substitui a entrada da organização preservando a formatação original do arquivo,
# para que o PR mostre apenas a nossa alteração.
python3 "${INFRA_DIR}/scripts/merge-nodes.py" "${netdir}/nodes.current.json" "${ours}" "${netdir}/nodes.merged.json"

echo "== diff ${rede}/nodes.json"
diff -u "${netdir}/nodes.current.json" "${netdir}/nodes.merged.json" || true

# Certificados dos Prometheus com IP público (roteiro_prometheus_nginx.md: publicar em <rede>/certificados)
orglc="$(tr '[:upper:]' '[:lower:]' <<<"${org}")"
certs=()
for prom in $(jq -r '.nodes[] | select(.nodeType == "prometheus") | .name' "${ours}"); do
  out="${netdir}/${orglc}-${prom}.pem"
  if node_ssh "${env}" "${prom}" 'sudo cat /srv/rbb/prometheus/certs/certificado.pem' > "${out}" 2>/dev/null && grep -q 'BEGIN CERTIFICATE' "${out}"; then
    certs+=("${out}"); echo "== certificado de ${prom}: ${rede}/certificados/${orglc}-${prom}.pem ($(openssl x509 -noout -subject -enddate -in "${out}" | tr '\n' ' '))"
  else
    rm -f "${out}"; echo "AVISO: não foi possível ler o certificado de ${prom}" >&2
  fi
done
if ${dry}; then echo "(dry-run) resultado em ${netdir}/nodes.merged.json"; exit 0; fi

base="$(gh api "repos/${repo}" --jq .default_branch)"
base_sha="$(gh api "repos/${repo}/git/ref/heads/${base}" --jq .object.sha)"
branch="$(tr '[:upper:]' '[:lower:]' <<<"${org}")-nodes-${rede}-$(date +%Y%m%d)"
gh api -X POST "repos/${repo}/git/refs" -f ref="refs/heads/${branch}" -f sha="${base_sha}" >/dev/null 2>&1 || echo "branch ${branch} já existe; reutilizando"
gh api -X PUT "repos/${repo}/contents/${rede}/nodes.json" \
  -f message="Adiciona/atualiza nós da ${org} na rede ${rede}" \
  -f branch="${branch}" -f sha="${sha}" \
  -f content="$(base64 < "${netdir}/nodes.merged.json" | tr -d '\n')" >/dev/null
for c in ${certs[@]+"${certs[@]}"}; do
  name="$(basename "${c}")"
  existing="$(gh api "repos/${repo}/contents/${rede}/certificados/${name}?ref=${branch}" --jq .sha 2>/dev/null || true)"
  gh api -X PUT "repos/${repo}/contents/${rede}/certificados/${name}" \
    -f message="Certificado do Prometheus ${name%.pem} da ${org} (rede ${rede})" \
    -f branch="${branch}" ${existing:+-f sha="${existing}"} \
    -f content="$(base64 < "${c}" | tr -d '\n')" >/dev/null
done
pr_url="$(gh pr create --repo "${repo}" --base "${base}" --head "${branch}" \
  --title "Nós da ${org} na rede ${rede}" \
  --body "Documentação dos nós da ${org} conforme o passo 6 do roteiro de adição de nós${certs:+, e certificado do Prometheus para o mTLS da monitoração federada (passo 5.4)}." 2>&1 | tail -1)"
echo "PR: ${pr_url}"
echo "Depois: anuncie a inclusão no Comitê Técnico (passo 7) e solicite o permissionamento (passo 8)."
