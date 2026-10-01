# Um security group por nó, sem as regras padrão da Magalu (que liberam toda
# entrada). As regras vêm do módulo agnóstico (rbb-node-config).
resource "mgc_network_security_groups" "node" {
  for_each = var.nodes

  name                  = "${local.prefix}-${each.key}"
  description           = "RBB ${var.rbb_network} ${each.key} ${each.value.type}"
  disable_default_rules = true
}

locals {
  sg_rules = merge([
    for k in local.node_keys : {
      for r in module.node_config[k].firewall_rules : "${k}/${r.key}" => merge(r, { node = k })
    }
  ]...)
}

resource "mgc_network_security_groups_rules" "node" {
  for_each = local.sg_rules

  security_group_id = mgc_network_security_groups.node[each.value.node].id
  description       = replace(each.value.description, "/[^A-Za-z0-9 -]/", "")
  direction         = each.value.direction
  ethertype         = "IPv4"
  protocol          = each.value.protocol
  port_range_min    = each.value.port_min
  port_range_max    = each.value.port_max
  remote_ip_prefix  = each.value.cidr
}

resource "mgc_network_security_groups_rules" "egress_ipv6" {
  for_each = var.nodes

  security_group_id = mgc_network_security_groups.node[each.key].id
  description       = "Saida irrestrita IPv6"
  direction         = "egress"
  ethertype         = "IPv6"
  remote_ip_prefix  = "::/0"
}

resource "mgc_network_security_groups_attach" "node" {
  for_each = var.nodes

  security_group_id = mgc_network_security_groups.node[each.key].id
  interface_id      = mgc_virtual_machine_instances.node[each.key].network_interface_id
}
