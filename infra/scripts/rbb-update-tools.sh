#!/usr/bin/env bash
# Envia as versões atuais de rbb-node-setup e rbb-node (modules/rbb-node-config/files) para todos
# os nós de um ambiente e, opcionalmente, reexecuta o bootstrap (idempotente).
# Uso: ./scripts/rbb-update-tools.sh <env> [--rerun-setup] [nó ...]
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_env "${1:-}"
env="$1"; shift; rerun=false; [[ "${1:-}" == "--rerun-setup" ]] && { rerun=true; shift; }
files="${INFRA_DIR}/tofu/modules/rbb-node-config/files"
nodes=("$@"); [[ ${#nodes[@]} -gt 0 ]] || mapfile -t nodes < <(nodes_json "${env}" | jq -r 'keys[]')
for node in "${nodes[@]}"; do
  echo "== ${node}"
  node_ssh "${env}" "${node}" 'cat > /tmp/rbb-node-setup && sudo install -m 0755 /tmp/rbb-node-setup /usr/local/sbin/rbb-node-setup' < "${files}/rbb-node-setup.sh"
  node_ssh "${env}" "${node}" 'cat > /tmp/rbb-node && sudo install -m 0755 /tmp/rbb-node /usr/local/bin/rbb-node' < "${files}/rbb-node"
  if [[ -f "${files}/prometheus-setup.sh" ]]; then
    node_ssh "${env}" "${node}" 'cat > /tmp/rbb-prometheus-setup && sudo install -m 0755 /tmp/rbb-prometheus-setup /usr/local/sbin/rbb-prometheus-setup' < "${files}/prometheus-setup.sh"
  fi
  if ${rerun}; then
    echo "   reexecutando bootstrap (log em /var/log/rbb-node-setup.log)"
    node_ssh "${env}" "${node}" 'sudo bash -c "/usr/local/sbin/rbb-node-setup >> /var/log/rbb-node-setup.log 2>&1"; sudo tail -n 3 /var/log/rbb-node-setup.log'
  fi
done
