resource "mgc_network_vpcs" "this" {
  name        = "${local.prefix}-vpc"
  description = "Rede Blockchain Brasil ${var.rbb_network} - ${var.organization}"
}

resource "mgc_network_subnetpools" "this" {
  name        = "${local.prefix}-pool"
  description = "Subnet pool dos nos RBB ${var.rbb_network}"
  cidr        = var.vpc_cidr
}

resource "mgc_network_vpcs_subnets" "nodes" {
  name            = "${local.prefix}-nodes"
  description     = "Sub-rede dos nos RBB ${var.rbb_network}"
  vpc_id          = mgc_network_vpcs.this.id
  subnetpool_id   = mgc_network_subnetpools.this.id
  cidr_block      = var.subnet_cidr
  ip_version      = "IPv4"
  dns_nameservers = var.dns_nameservers
}

# Uma interface por nó, com IP privado fixo (permite configurar Prometheus e
# endereços internos de forma determinística).
resource "mgc_network_vpcs_interfaces" "node" {
  for_each = var.nodes

  name              = "${local.prefix}-${each.key}"
  vpc_id            = mgc_network_vpcs.this.id
  subnet_ids        = [mgc_network_vpcs_subnets.nodes.id]
  ip_address        = local.private_ips[each.key]
  availability_zone = var.availability_zone

  depends_on = [mgc_network_vpcs_subnets.nodes]
}

resource "mgc_network_public_ips" "this" {
  for_each = local.public_nodes

  description = "${local.prefix}-${each.key}"
  vpc_id      = mgc_network_vpcs.this.id
}

resource "mgc_network_public_ips_attach" "this" {
  for_each = local.public_nodes

  public_ip_id = mgc_network_public_ips.this[each.key].id
  interface_id = mgc_network_vpcs_interfaces.node[each.key].id
}

resource "mgc_network_nat_gateway" "this" {
  count = local.needs_nat ? 1 : 0

  name              = "${local.prefix}-nat"
  description       = "Saida para internet dos nos sem IP publico"
  vpc_id            = mgc_network_vpcs.this.id
  availability_zone = var.availability_zone
}
