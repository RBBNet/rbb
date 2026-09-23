output "rbb_network" {
  value = "lab"
}

output "nodes" {
  description = "Nós provisionados (IPs, tipo, acesso SSH)."
  value       = module.rbb.nodes
}

output "genesis_loaded" {
  description = "Se o genesis.json foi encontrado e embutido no bootstrap."
  value       = local.genesis_json != null
}

output "compose_template_loaded" {
  description = "Se um docker-compose.yml.hbs específico da rede foi embutido."
  value       = local.compose_template != null
}

output "federation_targets" {
  description = "Prometheus de outras organizações configurados para federação."
  value       = local.prometheus_federation_targets
}

output "firewall_peer_cidrs" {
  description = "IPs das outras organizações usados nas regras de firewall (nulo = participant_cidrs)."
  value       = local.peer_cidrs
}

output "bastion_ip" {
  description = "IP público de salto SSH para os nós privados."
  value       = module.rbb.bastion_ip
}

output "vpc_id" {
  value = module.rbb.vpc_id
}
