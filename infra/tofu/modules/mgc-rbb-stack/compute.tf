resource "mgc_virtual_machine_instances" "node" {
  for_each = var.nodes

  name                 = "${local.prefix}-${each.key}"
  machine_type         = coalesce(each.value.machine_type, var.default_machine_type)
  image                = var.image
  ssh_key_name         = local.ssh_key_name
  availability_zone    = var.availability_zone
  network_interface_id = mgc_network_vpcs_interfaces.node[each.key].id
  user_data            = base64encode(module.node_config[each.key].user_data)

  # O IP público (recurso) já existe antes da VM e entra no cloud-init (endereço P2P anunciado).
  # A anexação do IP e do security group acontece DEPOIS da VM (ver network.tf/security.tf): na
  # Magalu, apagar a VM apaga a porta, então os anexos precisam ser destruídos antes da VM.
  # A saída para internet durante o bootstrap vem do NAT gateway (nat_gateway = "true").

  lifecycle {
    # Alterações no cloud-init não recriam a VM em produção; use 'rbb-node' para ajustes.
    ignore_changes = [user_data]
    precondition {
      condition     = local.ssh_key_name != null
      error_message = "Informe ssh_public_key ou existing_ssh_key_name."
    }
    precondition {
      condition     = module.node_config[each.key].user_data_size < 65000
      error_message = "cloud-init do nó ${each.key} excede 65000 caracteres (limite da Magalu Cloud)."
    }
  }
}

# Volumes de dados. Em produção (piloto) ficam protegidos contra destruição
# acidental (prevent_destroy); em laboratório podem ser destruídos livremente.
resource "mgc_block_storage_volumes" "data" {
  for_each = local.protect_data_volumes ? {} : local.volume_nodes

  name              = "${local.prefix}-${each.key}-data"
  availability_zone = var.availability_zone
  size              = coalesce(each.value.data_volume_size, var.default_data_volume_size)
  type              = var.data_volume_type
  encrypted         = var.data_volume_encrypted
}

resource "mgc_block_storage_volumes" "data_protected" {
  for_each = local.protect_data_volumes ? local.volume_nodes : {}

  name              = "${local.prefix}-${each.key}-data"
  availability_zone = var.availability_zone
  size              = coalesce(each.value.data_volume_size, var.default_data_volume_size)
  type              = var.data_volume_type
  encrypted         = var.data_volume_encrypted

  lifecycle {
    prevent_destroy = true
  }
}

locals {
  data_volume_ids = merge(
    { for k, v in mgc_block_storage_volumes.data : k => v.id },
    { for k, v in mgc_block_storage_volumes.data_protected : k => v.id },
  )
}

resource "mgc_block_storage_volume_attachment" "data" {
  for_each = local.volume_nodes

  block_storage_id   = local.data_volume_ids[each.key]
  virtual_machine_id = mgc_virtual_machine_instances.node[each.key].id
}
