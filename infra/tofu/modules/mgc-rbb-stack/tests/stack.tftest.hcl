# Testes sem credenciais: o provider mgc é simulado (mock_provider).
# Executar: tofu test  (dentro de modules/mgc-rbb-stack)

mock_provider "mgc" {
  mock_resource "mgc_network_public_ips" {
    defaults = {
      public_ip = "200.1.2.3"
    }
  }
}

variables {
  organization         = "exemplo"
  rbb_network          = "lab"
  availability_zone    = "br-se1-a"
  default_machine_type = "BV2-4-20"
  ssh_public_key       = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITESTKEYTESTKEYTESTKEYTESTKEYTESTKEYTESTKEY teste"
  admin_ssh_cidrs      = ["203.0.113.0/24"]
  genesis_json         = "{\"config\":{\"chainId\":648629}}"
  nodes = {
    boot01          = { type = "boot" }
    validator01     = { type = "validator" }
    writer01        = { type = "writer" }
    observer-boot01 = { type = "observer-boot", rpc_public = true }
    prometheus01    = { type = "prometheus", data_volume_size = 0 }
  }
}

run "topologia_associado" {
  command = plan

  assert {
    condition     = length(mgc_virtual_machine_instances.node) == 5
    error_message = "Deveriam existir 5 VMs."
  }
  assert {
    condition     = length(mgc_block_storage_volumes.data) == 4 && length(mgc_block_storage_volumes.data_protected) == 0
    error_message = "Prometheus não deve ter volume de dados; os 4 nós Besu devem (sem proteção em lab)."
  }
  assert {
    condition     = length(mgc_network_public_ips.this) == 5
    error_message = "Todos os nós têm IP público por padrão."
  }
  assert {
    condition     = length(mgc_network_nat_gateway.this) == 0
    error_message = "Sem nós privados, não deve haver NAT gateway."
  }
  assert {
    condition     = output.nodes["writer01"].p2p_public == false && output.nodes["writer01"].p2p_address == "10.120.1.14:30303"
    error_message = "Writer de associado anuncia o IP interno."
  }
  assert {
    condition     = output.nodes["validator01"].p2p_public == true && output.nodes["validator01"].p2p_address == "200.1.2.3:30303"
    error_message = "Validator anuncia o IP público."
  }
  assert {
    condition     = output.nodes["boot01"].private_ip == "10.120.1.10"
    error_message = "IPs privados devem ser sequenciais a partir do offset (ordem alfabética das chaves)."
  }
  # Firewall: writer sem P2P público; observer-boot com P2P e RPC públicos; prometheus com 443
  assert {
    condition     = !contains([for r in module.node_config["writer01"].firewall_rules : r.cidr if r.protocol == "tcp" && r.port_min == 30303], "0.0.0.0/0")
    error_message = "Writer não pode expor P2P para a internet."
  }
  assert {
    condition     = contains([for r in module.node_config["observer-boot01"].firewall_rules : r.cidr if r.port_min == 8545], "0.0.0.0/0")
    error_message = "observer-boot com rpc_public deve liberar RPC público."
  }
  assert {
    condition     = contains([for r in module.node_config["prometheus01"].firewall_rules : r.port_min], 443)
    error_message = "Prometheus deve liberar 443 (mTLS)."
  }
  assert {
    condition     = alltrue([for k in keys(var.nodes) : module.node_config[k].user_data_size < 65000])
    error_message = "cloud-init acima do limite."
  }
  assert {
    condition     = alltrue([for k in keys(var.nodes) : startswith(module.node_config[k].user_data, "#cloud-config")])
    error_message = "user_data deve ser cloud-config."
  }
  assert {
    condition     = length(output.prometheus_targets) == 4
    error_message = "Prometheus deve coletar os 4 nós Besu."
  }
}

run "piloto_protege_volumes" {
  command = plan

  variables {
    rbb_network = "piloto"
  }

  assert {
    condition     = length(mgc_block_storage_volumes.data_protected) == 4 && length(mgc_block_storage_volumes.data) == 0
    error_message = "Em piloto os volumes devem usar prevent_destroy."
  }
  assert {
    condition     = length(mgc_block_storage_volume_attachment.data) == 4
    error_message = "Todos os volumes devem ser anexados."
  }
}

run "writer_privado_cria_nat" {
  command = plan

  variables {
    nodes = {
      boot01   = { type = "boot" }
      writer01 = { type = "writer", public_ip = false }
    }
  }

  assert {
    condition     = length(mgc_network_nat_gateway.this) == 1
    error_message = "Nó sem IP público exige NAT gateway."
  }
  assert {
    condition     = length(mgc_network_public_ips.this) == 1
    error_message = "Somente o boot deve ter IP público."
  }
}
