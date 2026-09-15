locals {
  genesis_path = var.genesis_file == null ? null : (startswith(var.genesis_file, "/") ? var.genesis_file : "${path.module}/${var.genesis_file}")
  genesis_json = local.genesis_path != null && fileexists(local.genesis_path) ? file(local.genesis_path) : null
}

module "rbb" {
  source = "../../modules/mgc-rbb-stack"

  organization      = var.organization
  rbb_network       = "piloto"
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
  rpc_cidrs         = var.rpc_cidrs

  genesis_json          = local.genesis_json
  start_network_version = var.start_network_version
  besu_image            = var.besu_image
  nat_gateway           = var.nat_gateway

  prometheus_federation_targets = var.prometheus_federation_targets
}
