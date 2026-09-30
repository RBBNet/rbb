#!/usr/bin/env bash
# Gera tofu/envs/<env>/network/rbb-status.json para a CLI rbb-status (tools/rbb-status), a partir
# dos outputs do OpenTofu (IPs dos nós), de network/contracts.json (NodeRulesV2Impl) e de
# network/our-nodes.json (chaves públicas dos nossos nós, geradas por rbb-node-info.sh).
# Uso: ./scripts/rbb-status-config.sh <testnet|mainnet>
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_env "${1:-}"
env="$1"; netdir="$(env_dir "${env}")/network"
nodes="$(nodes_json "${env}")"; bastion="$(bastion_ip "${env}")"
org="$(jq -r '.organization // empty' "${netdir}/our-nodes.json" 2>/dev/null)"
[[ -n "${org}" ]] || org="$(grep -E '^\s*organization_name\s*=' "$(env_dir "${env}")/terraform.tfvars" | sed -E 's/.*=\s*"([^"]+)".*/\1/' | head -1)"
[[ -n "${org}" ]] || { echo "não foi possível determinar a organização (gere network/our-nodes.json com rbb-node-info.sh)" >&2; exit 1; }
node_rules="$(jq -r '.NodeRulesV2Impl // empty' "${netdir}/contracts.json" 2>/dev/null)"
jq -n --arg org "${org}" --arg nodes_json "${netdir}/nodes.json" --arg rules "${node_rules}" --arg user "${SSH_USER}" --arg bastion "${bastion}" \
  --argjson nodes "${nodes}" --slurpfile ours "${netdir}/our-nodes.json" '
  { org: $org, nodes_json: $nodes_json, node_rules_v2: $rules,
    hosts: ($nodes | to_entries | map(select(.value.type == "validator" or .value.type == "boot" or .value.type == "prometheus")
             | { key: .key, value: ({ role: .value.type }
                 + (if .value.public_ip != null then { ssh: ($user + "@" + .value.public_ip) }
                    else { ssh: ($user + "@" + .value.private_ip), jump: ($user + "@" + $bastion) } end)) }) | from_entries),
    our_nodes: ($ours[0].nodes // []) }' > "${netdir}/rbb-status.json"
echo "gerado: ${netdir}/rbb-status.json (org ${org}, $(jq '.hosts|length' "${netdir}/rbb-status.json") hosts, NodeRulesV2=${node_rules:-?})"
