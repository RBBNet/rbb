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
  ssh_authorized_keys  = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINSTITUCIONALINSTITUCIONALINSTITUCIONAL admin@org"]
  admin_ssh_cidrs      = ["203.0.113.0/24"]
  genesis_json         = "{\"config\":{\"chainId\":648629}}"
  nodes = {
    boot01          = { type = "boot" }
    validator01     = { type = "validator" }
    writer01        = { type = "writer" }
    observer-boot01 = { type = "observer-boot", rpc_public = true }
    observer01      = { type = "observer", archive = true }
    prometheus01    = { type = "prometheus", data_volume_size = 0 }
  }
}

run "topologia_associado" {
  command = plan

  assert {
    condition     = length(mgc_virtual_machine_instances.node) == 6
    error_message = "Deveriam existir 6 VMs."
  }
  assert {
    condition     = length(mgc_block_storage_volumes.data) == 5 && length(mgc_block_storage_volumes.data_protected) == 0
    error_message = "Prometheus não deve ter volume de dados; os 5 nós Besu devem (sem proteção em lab)."
  }
  assert {
    condition     = length(mgc_network_public_ips.this) == 6
    error_message = "Todos os nós têm IP público por padrão."
  }
  assert {
    condition     = length(mgc_network_nat_gateway.this) == 0
    error_message = "Sem nós privados, não deve haver NAT gateway."
  }
  assert {
    condition     = output.nodes["writer01"].p2p_public == false && output.nodes["writer01"].p2p_address == "10.120.1.15:30303"
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
    condition     = contains([for r in module.node_config["prometheus01"].firewall_rules : r.port_min], 8443) && contains([for r in module.node_config["prometheus01"].firewall_rules : r.port_min], 443)
    error_message = "Prometheus deve liberar 8443 (mTLS federado) e 443 (UI)."
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
    condition     = alltrue([for k in keys(var.nodes) : strcontains(module.node_config[k].user_data, "ssh_authorized_keys:")])
    error_message = "Chaves SSH adicionais devem entrar no cloud-init de todos os nós."
  }
  assert {
    condition     = length(output.prometheus_targets) == 5
    error_message = "Prometheus deve coletar os 5 nós Besu (incluindo o observer)."
  }
  assert {
    condition     = output.nodes["observer01"].p2p_public == false && tolist([for r in module.node_config["observer01"].firewall_rules : r.cidr if r.port_min == 30303]) == tolist(["10.120.0.0/16", "10.120.0.0/16"])
    error_message = "Observer interno: P2P só na VPC (tcp+udp)."
  }
  assert {
    condition     = module.node_config["observer01"].archive_env["BESU_DATA_STORAGE_FORMAT"] == "FOREST" && module.node_config["observer01"].archive_env["BESU_SYNC_MODE"] == "FULL"
    error_message = "archive = true deve configurar Forest + sync FULL."
  }
}

run "piloto_protege_volumes" {
  command = plan

  variables {
    rbb_network = "piloto"
  }

  assert {
    condition     = length(mgc_block_storage_volumes.data_protected) == 5 && length(mgc_block_storage_volumes.data) == 0
    error_message = "Em piloto os volumes devem usar prevent_destroy."
  }
  assert {
    condition     = length(mgc_block_storage_volume_attachment.data) == 5
    error_message = "Todos os volumes devem ser anexados."
  }
}

run "firewall_por_papel" {
  command = plan

  variables {
    peer_cidrs = {
      validators = ["198.51.100.1/32", "198.51.100.2/32"]
      boots      = ["198.51.100.3/32"]
      prometheus = ["198.51.100.4/32"]
    }
    dns_domain = "exemplo.org.br"
  }

  assert {
    condition     = tolist(sort([for r in module.node_config["validator01"].firewall_rules : r.cidr if r.port_min == 30303 && r.protocol == "tcp"])) == tolist(["198.51.100.1/32", "198.51.100.2/32"])
    error_message = "P2P do validator deve aceitar apenas validators das outras organizações."
  }
  assert {
    condition     = tolist([for r in module.node_config["boot01"].firewall_rules : r.cidr if r.port_min == 30303 && r.protocol == "udp"]) == tolist(["198.51.100.3/32"])
    error_message = "P2P (UDP) do boot deve aceitar apenas boots/writers parceiros/observer-boots."
  }
  assert {
    condition     = tolist([for r in module.node_config["observer-boot01"].firewall_rules : r.cidr if r.port_min == 30303 && r.protocol == "tcp"]) == tolist(["0.0.0.0/0"])
    error_message = "observer-boot continua público."
  }
  assert {
    condition     = tolist([for r in module.node_config["prometheus01"].firewall_rules : r.cidr if r.port_min == 8443]) == tolist(["198.51.100.4/32"])
    error_message = "8443 só para Prometheus das outras organizações."
  }
  assert {
    condition     = tolist([for r in module.node_config["prometheus01"].firewall_rules : r.cidr if r.port_min == 443]) == tolist(["203.0.113.0/24"])
    error_message = "UI 443 só para administradores."
  }
  assert {
    condition     = module.node_config["validator01"].hostname_public == "rbb-validator01.exemplo.org.br"
    error_message = "dns_domain deve gerar hostName público por nó."
  }
}

run "writer_nao_pode_ter_rpc_publico" {
  command = plan

  variables {
    nodes = {
      writer01 = { type = "writer", rpc_public = true }
    }
  }

  expect_failures = [var.nodes]
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
