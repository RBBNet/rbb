#!/usr/bin/env bash
# Publica (ou atualiza) a entrada da organização em RBBNet/participantes/<rede>/nodes.json
# por meio de um pull request (passo 6 do roteiro). Requer 'gh' com acesso ao repositório.
#
# Uso: ./scripts/rbb-publish-nodes.sh <testnet|mainnet> [--dry-run]
#   Lê tofu/envs/<env>/network/our-nodes.json (gerado por rbb-node-info.sh), mescla com o
#   nodes.json atual (substitui a entrada da organização, se existir), cria a branch
#   <org>-nodes-<rede>-<data> e abre o PR. Com --dry-run só grava network/nodes.merged.json.
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

# Mantém a ordem; substitui a entrada da organização ou acrescenta ao final
jq --slurpfile o "${ours}" '
  if (map(.organization) | index($o[0].organization)) != null
  then map(if .organization == $o[0].organization then $o[0] else . end)
  else . + $o end' "${netdir}/nodes.current.json" | jq --indent 3 . > "${netdir}/nodes.merged.json"

echo "== diff ${rede}/nodes.json"
diff -u "${netdir}/nodes.current.json" "${netdir}/nodes.merged.json" || true
if ${dry}; then echo "(dry-run) resultado em ${netdir}/nodes.merged.json"; exit 0; fi

base="$(gh api "repos/${repo}" --jq .default_branch)"
base_sha="$(gh api "repos/${repo}/git/ref/heads/${base}" --jq .object.sha)"
branch="$(tr '[:upper:]' '[:lower:]' <<<"${org}")-nodes-${rede}-$(date +%Y%m%d)"
gh api -X POST "repos/${repo}/git/refs" -f ref="refs/heads/${branch}" -f sha="${base_sha}" >/dev/null 2>&1 || echo "branch ${branch} já existe; reutilizando"
gh api -X PUT "repos/${repo}/contents/${rede}/nodes.json" \
  -f message="Adiciona/atualiza nós da ${org} na rede ${rede}" \
  -f branch="${branch}" -f sha="${sha}" \
  -f content="$(base64 < "${netdir}/nodes.merged.json" | tr -d '\n')" >/dev/null
pr_url="$(gh pr create --repo "${repo}" --base "${base}" --head "${branch}" \
  --title "Nós da ${org} na rede ${rede}" \
  --body "Documentação dos nós da ${org} conforme o passo 6 do roteiro de adição de nós (gerado por rbb-node-info.sh / rbb-publish-nodes.sh)." 2>&1 | tail -1)"
echo "PR: ${pr_url}"
echo "Depois: anuncie a inclusão no Comitê Técnico (passo 7) e solicite o permissionamento (passo 8)."
