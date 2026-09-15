locals {
  is_besu = var.node.type != "prometheus"

  organization_name = coalesce(var.organization_name, upper(var.organization))

  # Regra do roteiro: boot, validator e observer-boot são alcançáveis
  # externamente; writer de partícipe associado é interno.
  p2p_public = coalesce(var.node.p2p_public, contains(["boot", "validator", "observer-boot"], var.node.type))

  p2p_host    = local.p2p_public ? var.public_ip : var.private_ip
  p2p_address = local.is_besu ? "${local.p2p_host}:${var.node.p2p_port}" : null

  hostname = "${var.organization}-${var.rbb_network}-${var.node.name}"

  # Passo 9 do roteiro: validators aceitam validators; boots aceitam boots, writers de parceiros e
  # observer-boots; observer-boot é público para qualquer observer; writer de associado só na VPC.
  peer_cidrs = {
    validator = coalesce(var.peer_cidrs.validators, var.participant_cidrs)
    boot      = coalesce(var.peer_cidrs.boots, var.participant_cidrs)
    prom      = coalesce(var.peer_cidrs.prometheus, var.participant_cidrs)
  }
  p2p_cidrs = (
    var.node.type == "observer-boot" ? ["0.0.0.0/0"] :
    !local.p2p_public ? [var.vpc_cidr] :
    var.node.type == "validator" ? local.peer_cidrs.validator :
    var.node.type == "boot" ? local.peer_cidrs.boot :
    var.participant_cidrs # writer de parceiro (p2p_public = true): boots das outras organizações
  )

  rpc_cidrs = distinct(concat([var.vpc_cidr], var.rpc_cidrs, var.node.rpc_public ? ["0.0.0.0/0"] : []))

  ssh_rules = [
    for cidr in var.admin_ssh_cidrs : {
      key         = "ssh-${cidr}"
      description = "SSH administrativo"
      direction   = "ingress"
      protocol    = "tcp"
      port_min    = 22
      port_max    = 22
      cidr        = cidr
    }
  ]

  besu_rules = local.is_besu ? concat(
    flatten([
      for cidr in local.p2p_cidrs : [
        {
          key         = "p2p-tcp-${cidr}"
          description = "Besu P2P (RLPx) TCP"
          direction   = "ingress"
          protocol    = "tcp"
          port_min    = var.node.p2p_port
          port_max    = var.node.p2p_port
          cidr        = cidr
        },
        {
          key         = "p2p-udp-${cidr}"
          description = "Besu P2P (discovery) UDP"
          direction   = "ingress"
          protocol    = "udp"
          port_min    = var.node.p2p_port
          port_max    = var.node.p2p_port
          cidr        = cidr
        },
      ]
    ]),
    [
      for cidr in local.rpc_cidrs : {
        key         = "rpc-${cidr}"
        description = "Besu JSON-RPC HTTP"
        direction   = "ingress"
        protocol    = "tcp"
        port_min    = var.node.rpc_port
        port_max    = var.node.rpc_port
        cidr        = cidr
      }
    ],
    [
      {
        key         = "metrics-vpc"
        description = "Métricas Besu para o Prometheus da organização"
        direction   = "ingress"
        protocol    = "tcp"
        port_min    = var.node.metrics_port
        port_max    = var.node.metrics_port
        cidr        = var.vpc_cidr
      }
    ]
  ) : []

  prometheus_rules = var.node.type == "prometheus" ? concat(
    [
      for cidr in local.peer_cidrs.prom : {
        key         = "prom-mtls-${cidr}"
        description = "Prometheus federado /federate (NGINX mTLS)"
        direction   = "ingress"
        protocol    = "tcp"
        port_min    = 8443
        port_max    = 8443
        cidr        = cidr
      }
    ],
    [
      for cidr in var.admin_ssh_cidrs : {
        key         = "prom-ui-${cidr}"
        description = "Interface web do Prometheus (TLS + senha)"
        direction   = "ingress"
        protocol    = "tcp"
        port_min    = 443
        port_max    = 443
        cidr        = cidr
      }
    ],
    [
      {
        key         = "prom-vpc"
        description = "Prometheus interno"
        direction   = "ingress"
        protocol    = "tcp"
        port_min    = 9090
        port_max    = 9090
        cidr        = var.vpc_cidr
      }
    ]
  ) : []

  egress_rules = [
    {
      key         = "egress-all"
      description = "Saída irrestrita"
      direction   = "egress"
      protocol    = null
      port_min    = null
      port_max    = null
      cidr        = "0.0.0.0/0"
    }
  ]

  firewall_rules = concat(local.ssh_rules, local.besu_rules, local.prometheus_rules, local.egress_rules)

  node_env = {
    NODE_NAME             = var.node.name
    NODE_TYPE             = var.node.type
    ORGANIZATION          = var.organization
    ORGANIZATION_NAME     = local.organization_name
    RBB_NETWORK           = var.rbb_network
    HOSTNAME_FQDN         = local.hostname
    HOSTNAME_PUBLIC       = var.hostname_public == null ? "" : var.hostname_public
    P2P_PORT              = var.node.p2p_port
    RPC_PORT              = var.node.rpc_port
    METRICS_PORT          = var.node.metrics_port
    P2P_ADDRESS           = local.p2p_address == null ? "" : local.p2p_address
    P2P_PUBLIC            = local.p2p_public
    PRIVATE_IP            = var.private_ip
    PUBLIC_IP             = var.public_ip == null ? "" : var.public_ip
    START_NETWORK_VERSION = var.start_network_version
    BESU_IMAGE            = var.besu_image
    RBB_CLI_IMAGE         = var.rbb_cli_image
    CONTAINER_CPUS        = var.container_cpus
    CONTAINER_MEMORY      = var.container_memory
    DATA_MOUNT            = var.data_mount
    DATA_VOLUME           = var.data_volume
    HAS_GENESIS           = var.genesis_json != null
  }

  node_env_file = join("\n", concat(
    [for k, v in local.node_env : "${k}=${jsonencode(tostring(v))}"],
    ["EXTRA_ENV=${jsonencode(join(" ", [for k, v in var.node.extra_env : "${k}=${v}"]))}"]
  ))

  prometheus_config = templatefile("${path.module}/templates/prometheus.yml.tftpl", {})

  # Alvos em formato file_sd do Prometheus
  prometheus_local_targets = jsonencode([
    for t in var.prometheus_targets : {
      targets = ["${t.ip}:${t.port}"]
      labels  = { node = t.name, organization = local.organization_name, network = "rbb${var.rbb_network == "lab" ? "-lab" : ""}" }
    }
  ])
  prometheus_federation_targets = jsonencode([
    for f in var.prometheus_federation_targets : {
      targets = [f.target]
      labels  = { organization = f.organization }
    }
  ])

  user_data = templatefile("${path.module}/templates/cloud-init.yaml.tftpl", {
    hostname                      = local.hostname
    timezone                      = var.timezone
    node_env_b64                  = base64gzip(local.node_env_file)
    setup_b64                     = base64gzip(file("${path.module}/files/rbb-node-setup.sh"))
    cli_b64                       = base64gzip(file("${path.module}/files/rbb-node"))
    genesis_b64                   = var.genesis_json == null ? null : base64gzip(var.genesis_json)
    compose_template_b64          = var.compose_template == null ? null : base64gzip(var.compose_template)
    is_prometheus                 = var.node.type == "prometheus"
    prometheus_b64                = base64gzip(local.prometheus_config)
    prometheus_rules              = base64gzip(file("${path.module}/files/prometheus-rules.yml"))
    prometheus_local_targets      = base64gzip(local.prometheus_local_targets)
    prometheus_federation_targets = base64gzip(local.prometheus_federation_targets)
    prometheus_nginx              = base64gzip(file("${path.module}/files/prometheus-nginx.conf"))
    prometheus_setup              = base64gzip(file("${path.module}/files/prometheus-setup.sh"))
    prometheus_docker             = base64gzip(file("${path.module}/files/prometheus-compose.yml"))
  })
}
