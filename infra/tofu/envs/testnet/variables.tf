# Ambiente: testnet (rede RBB "lab")

variable "mgc_api_key" {
  description = "API key da Magalu Cloud. Prefira exportar TF_VAR_mgc_api_key."
  type        = string
  sensitive   = true
}

variable "mgc_region" {
  description = "Região da Magalu Cloud (br-se1 ou br-ne1)."
  type        = string
  default     = "br-se1"
}

variable "availability_zone" {
  type    = string
  default = "br-se1-a"
}

variable "organization" {
  description = "Nome curto da organização (minúsculas). Ex.: exemplo"
  type        = string
}

variable "ssh_public_key" {
  description = "Chave pública SSH dos administradores."
  type        = string
  default     = null
}

variable "existing_ssh_key_name" {
  type    = string
  default = null
}

variable "admin_ssh_cidrs" {
  description = "CIDRs com acesso SSH. Não use 0.0.0.0/0."
  type        = list(string)
}

variable "participant_cidrs" {
  description = "CIDRs dos demais partícipes (P2P e Prometheus). Padrão: qualquer origem."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "rpc_cidrs" {
  description = "CIDRs adicionais com acesso à porta RPC (aplicações da organização)."
  type        = list(string)
  default     = []
}

variable "vpc_cidr" {
  type    = string
  default = "10.120.0.0/16"
}

variable "subnet_cidr" {
  type    = string
  default = "10.120.1.0/24"
}

variable "default_machine_type" {
  description = "Tipo de máquina padrão (BV<vcpu>-<ram>-<disco>)."
  type        = string
  default     = "BV2-4-20"
}

variable "default_data_volume_size" {
  description = "Volume de dados (GB) por nó Besu. Referência RBB: 400 GB."
  type        = number
  default     = 400
}

variable "data_volume_type" {
  type    = string
  default = "cloud_nvme1k"
}

variable "container_cpus" {
  type    = number
  default = 2
}

variable "container_memory" {
  type    = string
  default = "3G"
}

variable "nodes" {
  description = "Nós da organização nesta rede. Padrão: topologia de partícipe associado."
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
    extra_env         = optional(map(string), {})
    container_cpus    = optional(number)
    container_memory  = optional(string)
    private_ip_offset = optional(number)
  }))
  default = {
    boot01          = { type = "boot" }
    validator01     = { type = "validator" }
    writer01        = { type = "writer" }
    observer-boot01 = { type = "observer-boot" }
    prometheus01    = { type = "prometheus", data_volume_size = 0 }
  }
}

variable "genesis_file" {
  description = "Caminho do genesis.json da rede lab (RBBNet/participantes/lab/genesis.json). Nulo = não iniciar o Besu."
  type        = string
  default     = "network/genesis.json"
}

variable "start_network_version" {
  type    = string
  default = "v1.2.0"
}

variable "besu_image" {
  description = "Besu <= 25.5.0 (exigência da RBB)."
  type        = string
  default     = "hyperledger/besu:25.5.0"
}

variable "protect_data_volumes" {
  description = "prevent_destroy nos volumes de dados. Nulo = padrão do módulo (true em piloto, false em lab)."
  type        = bool
  default     = null
}

variable "nat_gateway" {
  type    = string
  default = "auto"
}

variable "prometheus_federation_targets" {
  type = list(object({
    organization = string
    target       = string
  }))
  default = []
}
