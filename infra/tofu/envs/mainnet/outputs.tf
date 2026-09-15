output "rbb_network" {
  value = "piloto"
}

output "nodes" {
  description = "Nós provisionados (IPs, tipo, acesso SSH)."
  value       = module.rbb.nodes
}

output "genesis_loaded" {
  description = "Se o genesis.json foi encontrado e embutido no bootstrap."
  value       = local.genesis_json != null
}

output "vpc_id" {
  value = module.rbb.vpc_id
}
