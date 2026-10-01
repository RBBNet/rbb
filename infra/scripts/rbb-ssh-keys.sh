#!/usr/bin/env bash
# Gerencia as chaves SSH autorizadas no usuário administrador de TODOS os nós de um ambiente,
# sem recriar VMs. Permite rotação e revogação rápida de acesso de operadores.
#
# Uso:
#   ./scripts/rbb-ssh-keys.sh <env> show                 lista as chaves autorizadas em cada nó
#   ./scripts/rbb-ssh-keys.sh <env> set <arquivo.pub>    substitui authorized_keys pelo conteúdo do arquivo (uma chave por linha)
#   ./scripts/rbb-ssh-keys.sh <env> add <arquivo.pub>    acrescenta chaves
#   ./scripts/rbb-ssh-keys.sh <env> remove <trecho>      remove linhas que contenham o trecho (ex.: e-mail/comentário da chave)
#
# ATENÇÃO: 'set' e 'remove' podem revogar a chave usada por este próprio script. Garanta que
# a chave com a qual você continua acessando esteja no arquivo antes de executar.
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_env "${1:-}"
env="$1"; cmd="${2:-show}"; arg="${3:-}"

for node in $(nodes_json "${env}" | jq -r 'keys[]'); do
  echo "== ${node}"
  case "${cmd}" in
    show)   node_ssh "${env}" "${node}" 'cat ~/.ssh/authorized_keys' | awk '{print "   " $1 " " substr($2,1,20) "... " $3}' ;;
    set)    [[ -s "${arg}" ]] || { echo "arquivo de chaves vazio" >&2; exit 1; }
            grep -qE '^ssh-(ed25519|rsa|ecdsa)' "${arg}" || { echo "arquivo não contém chaves válidas" >&2; exit 1; }
            node_ssh "${env}" "${node}" 'cat > ~/.ssh/authorized_keys.new && chmod 600 ~/.ssh/authorized_keys.new && mv ~/.ssh/authorized_keys.new ~/.ssh/authorized_keys && wc -l < ~/.ssh/authorized_keys' < "${arg}" ;;
    add)    [[ -s "${arg}" ]] || { echo "arquivo de chaves vazio" >&2; exit 1; }
            node_ssh "${env}" "${node}" 'cat >> ~/.ssh/authorized_keys && sort -u -o ~/.ssh/authorized_keys ~/.ssh/authorized_keys && wc -l < ~/.ssh/authorized_keys' < "${arg}" ;;
    remove) [[ -n "${arg}" ]] || { echo "informe o trecho a remover" >&2; exit 1; }
            node_ssh "${env}" "${node}" "grep -vF -- '${arg}' ~/.ssh/authorized_keys > ~/.ssh/authorized_keys.new; [ -s ~/.ssh/authorized_keys.new ] && mv ~/.ssh/authorized_keys.new ~/.ssh/authorized_keys && wc -l < ~/.ssh/authorized_keys || { rm -f ~/.ssh/authorized_keys.new; echo 'recusado: ficaria sem nenhuma chave'; }" ;;
    *) echo "comando inválido" >&2; exit 1 ;;
  esac
done
