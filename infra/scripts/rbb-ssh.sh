#!/usr/bin/env bash
# Abre SSH em um nó: ./scripts/rbb-ssh.sh testnet validator01 [comando]
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_env "${1:-}"
[[ -n "${2:-}" ]] || { echo "uso: $0 <env> <nó> [comando]" >&2; nodes_json "$1" | jq -r 'keys[]'; exit 1; }
env="$1"; node="$2"; shift 2
# shellcheck disable=SC2046
exec ssh "${SSH_OPTS[@]}" $(node_jump_opts "${env}" "${node}") -t "${SSH_USER}@$(node_host "${env}" "${node}")" "$@"
