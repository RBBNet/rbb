locals {
  abspath = { for k, v in { genesis = var.genesis_file, compose = var.compose_template_file, federation = var.federation_file, participants = var.participants_file } :
    k => v == null ? null : (startswith(v, "/") ? v : "${path.module}/${v}")
  }
  genesis_json         = local.abspath.genesis != null && fileexists(local.abspath.genesis) ? file(local.abspath.genesis) : null
  compose_template     = local.abspath.compose != null && fileexists(local.abspath.compose) ? file(local.abspath.compose) : null
  federation_from_file = local.abspath.federation != null && fileexists(local.abspath.federation) ? jsondecode(file(local.abspath.federation)) : []
  participants         = var.firewall_from_participants && local.abspath.participants != null && fileexists(local.abspath.participants) ? jsondecode(file(local.abspath.participants)) : null
  # Listas vazias (ex.: rede sem validators de outras orgs) caem no fallback participant_cidrs
  peer_cidrs = local.participants == null ? {} : {
    validators = length(local.participants.validators) > 0 ? local.participants.validators : null
    boots      = length(local.participants.boots) > 0 ? local.participants.boots : null
    prometheus = length(local.participants.prometheus) > 0 ? local.participants.prometheus : null
  }
  prometheus_federation_targets = concat(
    [for f in local.federation_from_file : { organization = f.organization, target = f.target }],
    var.prometheus_federation_targets,
  )
}

module "rbb" {
  source = "../../modules/mgc-rbb-stack"

  organization      = var.organization
  organization_name = var.organization_name
  rbb_network       = "lab"
  availability_zone = var.availability_zone

  vpc_cidr    = var.vpc_cidr
  subnet_cidr = var.subnet_cidr

  ssh_public_key        = var.ssh_public_key
  existing_ssh_key_name = var.existing_ssh_key_name

  default_machine_type     = var.default_machine_type
  default_data_volume_size = var.default_data_volume_size
  data_volume_type         = var.data_volume_type
  protect_data_volumes     = var.protect_data_volumes
  container_cpus           = var.container_cpus
  container_memory         = var.container_memory

  nodes = var.nodes

  admin_ssh_cidrs   = var.admin_ssh_cidrs
  participant_cidrs = var.participant_cidrs
  peer_cidrs        = local.peer_cidrs
  rpc_cidrs         = var.rpc_cidrs
  dns_domain        = var.dns_domain

  genesis_json          = local.genesis_json
  compose_template      = local.compose_template
  start_network_version = var.start_network_version
  besu_image            = var.besu_image
  nat_gateway           = var.nat_gateway

  prometheus_federation_targets = local.prometheus_federation_targets
}
