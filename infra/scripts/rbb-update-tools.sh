#!/usr/bin/env bash
# Envia as versões atuais de rbb-node-setup e rbb-node (modules/rbb-node-config/files) para todos
# os nós de um ambiente e, opcionalmente, reexecuta o bootstrap (idempotente).
# Uso: ./scripts/rbb-update-tools.sh <env> [--rerun-setup] [nó ...]
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_env "${1:-}"
env="$1"; shift; rerun=false; [[ "${1:-}" == "--rerun-setup" ]] && { rerun=true; shift; }
files="${INFRA_DIR}/tofu/modules/rbb-node-config/files"
nodes=("$@")
if [[ ${#nodes[@]} -eq 0 ]]; then
  while IFS= read -r l; do nodes+=("${l}"); done < <(nodes_json "${env}" | jq -r 'keys[]')
fi
for node in ${nodes[@]+"${nodes[@]}"}; do
  echo "== ${node}"
  node_ssh "${env}" "${node}" 'cat > /tmp/rbb-node-setup && sudo install -m 0755 /tmp/rbb-node-setup /usr/local/sbin/rbb-node-setup' < "${files}/rbb-node-setup.sh"
  node_ssh "${env}" "${node}" 'cat > /tmp/rbb-node && sudo install -m 0755 /tmp/rbb-node /usr/local/bin/rbb-node' < "${files}/rbb-node"
  if [[ -f "${files}/prometheus-setup.sh" ]]; then
    node_ssh "${env}" "${node}" 'cat > /tmp/rbb-prometheus-setup && sudo install -m 0755 /tmp/rbb-prometheus-setup /usr/local/sbin/rbb-prometheus-setup' < "${files}/prometheus-setup.sh"
  fi
  # Nós prometheus: também os modelos de compose, nginx e regras (o bootstrap copia de /etc/rbb/prometheus)
  if [[ "$(nodes_json "${env}" | jq -r --arg n "${node}" '.[$n].type')" == "prometheus" ]]; then
    node_ssh "${env}" "${node}" 'sudo mkdir -p /etc/rbb/prometheus && cat > /tmp/pc && sudo install -m 0644 /tmp/pc /etc/rbb/prometheus/docker-compose.yml' < "${files}/prometheus-compose.yml"
    node_ssh "${env}" "${node}" 'cat > /tmp/pn && sudo install -m 0644 /tmp/pn /etc/rbb/prometheus/nginx.conf' < "${files}/prometheus-nginx.conf"
    node_ssh "${env}" "${node}" 'cat > /tmp/pr && sudo install -m 0644 /tmp/pr /etc/rbb/prometheus/rules.yml' < "${files}/prometheus-rules.yml"
  fi
  if ${rerun}; then
    echo "   reexecutando bootstrap (log em /var/log/rbb-node-setup.log)"
    node_ssh "${env}" "${node}" 'sudo bash -c "/usr/local/sbin/rbb-node-setup >> /var/log/rbb-node-setup.log 2>&1"; sudo tail -n 3 /var/log/rbb-node-setup.log'
  fi
done
