# Módulo ESPECÍFICO da Magalu Cloud (provider magalucloud/mgc).
# Cria a rede, os grupos de segurança, as VMs, os volumes e os IPs públicos de
# um conjunto de nós RBB, usando o módulo agnóstico rbb-node-config para gerar o
# cloud-init e as regras de firewall de cada nó.
#
# Para portar para outro provedor, reimplemente este módulo mantendo o mesmo
# contrato de entrada (var.nodes etc.) e as mesmas saídas (output "nodes").

variable "organization" {
  description = "Nome curto da organização (minúsculas). Ex.: exemplo"
  type        = string
}

variable "organization_name" {
  description = "Nome do partícipe como consta em participantes/<rede>/nodes.json. Padrão: organization em maiúsculas."
  type        = string
  default     = null
}

variable "rbb_network" {
  description = "'lab' (testnet) ou 'piloto' (mainnet)."
  type        = string
}

variable "availability_zone" {
  description = "Zona de disponibilidade para VMs e volumes (devem coincidir). Ex.: br-se1-a"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR do subnet pool / rede interna."
  type        = string
  default     = "10.120.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR da sub-rede dos nós (dentro de vpc_cidr)."
  type        = string
  default     = "10.120.1.0/24"
}

variable "dns_nameservers" {
  type    = list(string)
  default = ["8.8.8.8", "1.1.1.1"]
}

variable "private_ip_offset" {
  description = "Primeiro host da sub-rede a ser usado pelos nós (evita gateway/DHCP)."
  type        = number
  default     = 10
}

variable "ssh_public_key" {
  description = "Chave pública SSH a cadastrar na Magalu Cloud (ex.: conteúdo de ~/.ssh/id_ed25519.pub). Se nulo, usa existing_ssh_key_name."
  type        = string
  default     = null
}

variable "ssh_authorized_keys" {
  description = "Chaves públicas SSH adicionais autorizadas em todas as VMs (ex.: chave institucional da organização). A chave principal (ssh_public_key) continua cadastrada na nuvem."
  type        = list(string)
  default     = []
}

variable "existing_ssh_key_name" {
  description = "Nome de uma chave SSH já cadastrada na Magalu Cloud (alternativa a ssh_public_key)."
  type        = string
  default     = null
}

variable "image" {
  description = "Imagem das VMs. O bootstrap assume Ubuntu (apt)."
  type        = string
  default     = "cloud-ubuntu-24.04 LTS"
}

variable "default_machine_type" {
  description = "Tipo de máquina padrão dos nós (BV<vcpu>-<ram>-<disco>). Lab: >= 2 vCPU/4 GB; Piloto: >= 8 vCPU/8 GB."
  type        = string
}

variable "default_data_volume_size" {
  description = "Tamanho (GB) do volume de dados dos nós Besu. Referência RBB: 400 GB."
  type        = number
  default     = 400
}

variable "data_volume_type" {
  description = "Tipo do volume de dados (ex.: cloud_nvme1k, cloud_nvme5k, cloud_nvme10k, cloud_nvme20k)."
  type        = string
  default     = "cloud_nvme1k"
}

variable "data_volume_encrypted" {
  type    = bool
  default = true
}

variable "protect_data_volumes" {
  description = "Impede a destruição dos volumes de dados (prevent_destroy). Se nulo: true para 'piloto', false para 'lab'."
  type        = bool
  default     = null
}

variable "nodes" {
  description = <<-EOT
    Nós a provisionar, indexados pelo nome no padrão da RBB (boot01, validator01, writer01, observer-boot01, prometheus01).
    Tipos: boot, validator, writer, observer-boot, prometheus e observer (nó interno de leitura, opcionalmente archive = true: Forest + FULL).
    Campos opcionais por nó: machine_type, data_volume_size (0 = sem volume extra), public_ip (padrão true),
    p2p_public (padrão: true para boot/validator/observer-boot, false para writer), rpc_public, p2p_port, rpc_port,
    metrics_port, extra_env (BESU_*), container_cpus, container_memory, private_ip_offset.
  EOT
  type = map(object({
    type              = string
    machine_type      = optional(string)
    data_volume_size  = optional(number)
    public_ip         = optional(bool, true)
    p2p_public        = optional(bool)
    rpc_public        = optional(bool, false)
    p2p_port          = optional(number, 30303)
    rpc_port          = optional(number, 8545)
    metrics_port      = optional(number, 9545)
    archive           = optional(bool, false)
    extra_env         = optional(map(string), {})
    container_cpus    = optional(number)
    container_memory  = optional(string)
    private_ip_offset = optional(number)
  }))
  validation {
    condition     = alltrue([for n in var.nodes : !coalesce(n.p2p_public, contains(["boot", "validator", "observer-boot"], n.type)) || n.public_ip])
    error_message = "Nós com p2p_public = true precisam de public_ip = true."
  }
  validation {
    condition     = alltrue([for n in var.nodes : !n.rpc_public || n.type == "observer-boot"])
    error_message = "rpc_public = true só é permitido em observer-boot: a porta RPC de boot, validator, writer e observer nunca deve ser exposta à internet."
  }
}

variable "admin_ssh_cidrs" {
  description = "CIDRs com acesso SSH aos nós. Evite 0.0.0.0/0."
  type        = list(string)
}

variable "participant_cidrs" {
  description = "CIDRs dos demais partícipes (P2P dos nós núcleo e Prometheus/443). Padrão: qualquer origem."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "peer_cidrs" {
  description = "CIDRs por papel (validators, boots, prometheus) conforme o passo 9 do roteiro; nulos usam participant_cidrs. Ver network/participants.json."
  type = object({
    validators = optional(list(string))
    boots      = optional(list(string))
    prometheus = optional(list(string))
  })
  default = {}
}

variable "dns_domain" {
  description = "Domínio DNS público da organização (opcional). Se definido, cada nó público recebe hostName rbb-<nó>.<domínio> no nodes.json (o registro DNS é responsabilidade da organização)."
  type        = string
  default     = null
}

variable "rpc_cidrs" {
  description = "CIDRs adicionais com acesso RPC (ex.: rede das aplicações)."
  type        = list(string)
  default     = []
}

variable "genesis_json" {
  description = "Conteúdo do genesis.json da rede. Nulo = nós preparados sem iniciar o Besu."
  type        = string
  default     = null
}

variable "compose_template" {
  description = "Conteúdo de docker-compose.yml.hbs específico da rede (participantes/<rede>/docker-compose.yml.hbs), se houver."
  type        = string
  default     = null
}

variable "start_network_version" {
  type    = string
  default = "v1.2.0"
}

variable "besu_image" {
  type    = string
  default = "hyperledger/besu:25.5.0"
}

variable "container_cpus" {
  description = "Limite de CPUs padrão do contêiner Besu."
  type        = number
  default     = 2
}

variable "container_memory" {
  description = "Limite de memória padrão do contêiner Besu (ex.: 3G, 6G)."
  type        = string
  default     = "6G"
}

variable "nat_gateway" {
  description = "Cria NAT Gateway para nós sem IP público (saída para internet). 'auto' = somente se houver nó com public_ip=false."
  type        = string
  default     = "auto"
  validation {
    condition     = contains(["auto", "true", "false"], var.nat_gateway)
    error_message = "nat_gateway deve ser 'auto', 'true' ou 'false'."
  }
}

variable "prometheus_federation_targets" {
  description = "Prometheus de outras organizações a federar (host:porta)."
  type = list(object({
    organization = string
    target       = string
  }))
  default = []
}
