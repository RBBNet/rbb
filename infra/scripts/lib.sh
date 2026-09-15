#!/usr/bin/env bash
# Funções comuns dos scripts locais da infra RBB.
set -euo pipefail

INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SSH_USER="${RBB_SSH_USER:-ubuntu}"
SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ConnectTimeout=15 -o BatchMode=yes)

env_dir() { echo "${INFRA_DIR}/tofu/envs/$1"; }

require_env() {
  local env="${1:-}"
  [[ "${env}" == "testnet" || "${env}" == "mainnet" ]] || { echo "uso: $0 <testnet|mainnet> ..." >&2; exit 1; }
  [[ -d "$(env_dir "${env}")" ]] || { echo "ambiente ${env} não encontrado" >&2; exit 1; }
}

_NODES_CACHE=""
nodes_json() {
  # Cacheia 'tofu output' (lento) durante a execução do script
  if [[ -z "${_NODES_CACHE}" ]]; then
    _NODES_CACHE="$(cd "$(env_dir "$1")" && tofu output -json nodes)"
    [[ "${_NODES_CACHE}" != "{}" && -n "${_NODES_CACHE}" ]] || { echo "sem nós no estado de $1 (execute tofu apply)" >&2; exit 1; }
  fi
  printf '%s' "${_NODES_CACHE}"
}

node_host() {
  # IP de acesso SSH (público; se ausente, privado — requer bastion/VPN)
  nodes_json "$1" | jq -r --arg n "$2" '.[$n] | (.public_ip // .private_ip)'
}

node_ssh() {
  local env="$1" node="$2"; shift 2
  local host; host="$(node_host "${env}" "${node}")"
  ssh "${SSH_OPTS[@]}" "${SSH_USER}@${host}" "$@"
}

nodes_of_type() { nodes_json "$1" | jq -r --arg t "$2" 'to_entries[] | select(.value.type == $t) | .key'; }
