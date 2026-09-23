output "vpc_id" {
  value = mgc_network_vpcs.this.id
}

output "subnet_id" {
  value = mgc_network_vpcs_subnets.nodes.id
}

locals {
  bastion_key = try([for k in local.node_keys : k if var.nodes[k].public_ip][0], null)
  bastion_ip  = local.bastion_key == null ? null : mgc_network_public_ips.this[local.bastion_key].public_ip
}

output "bastion_ip" {
  description = "IP público usado como salto SSH para os nós sem IP público (primeiro nó público em ordem alfabética)."
  value       = local.bastion_ip
}

output "nodes" {
  description = "Nós provisionados: endereços, tipo e comando de acesso."
  value = {
    for k, n in var.nodes : k => {
      name        = k
      type        = n.type
      hostname    = module.node_config[k].hostname
      instance_id = mgc_virtual_machine_instances.node[k].id
      private_ip  = local.private_ips[k]
      public_ip   = n.public_ip ? mgc_network_public_ips.this[k].public_ip : null
      p2p_address = module.node_config[k].p2p_address
      p2p_public  = module.node_config[k].p2p_public
      ssh         = n.public_ip ? "ssh ubuntu@${mgc_network_public_ips.this[k].public_ip}" : "ssh -J ubuntu@${coalesce(local.bastion_ip, "<bastion>")} ubuntu@${local.private_ips[k]}"
    }
  }
}

output "nat_gateway_id" {
  value = local.needs_nat ? mgc_network_nat_gateway.this[0].id : null
}

output "prometheus_targets" {
  value = local.prometheus_targets
}
