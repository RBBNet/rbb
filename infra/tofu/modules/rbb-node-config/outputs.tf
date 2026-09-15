output "user_data" {
  description = "cloud-init (#cloud-config) em texto puro. O módulo de provedor deve codificar em base64 se necessário."
  value       = local.user_data
}

output "firewall_rules" {
  description = "Regras de firewall a aplicar ao nó (lista agnóstica de provedor)."
  value       = local.firewall_rules
}

output "hostname" {
  value = local.hostname
}

output "p2p_address" {
  description = "Endereço host:porta anunciado para P2P (nulo para prometheus)."
  value       = local.p2p_address
}

output "p2p_public" {
  value = local.p2p_public
}

output "user_data_size" {
  description = "Tamanho do cloud-init em caracteres (limite típico dos provedores: ~64 KB)."
  value       = length(local.user_data)
}

output "hostname_public" {
  description = "Nome DNS público do nó, se configurado (entra em hostNames do nodes.json)."
  value       = var.hostname_public
}
