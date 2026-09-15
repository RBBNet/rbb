# Módulo AGNÓSTICO de provedor de nuvem.
# Recebe a descrição de um nó RBB e produz (a) o cloud-init que configura o nó
# seguindo o roteiro de adição de nós da RBB e (b) a lista de regras de
# firewall que o provedor deve aplicar. Nenhum recurso de nuvem é criado aqui.

variable "organization" {
  description = "Nome curto da organização (minúsculas, sem espaços). Usado em nomes de hosts e rótulos de monitoração."
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,30}$", var.organization))
    error_message = "organization deve ter apenas letras minúsculas, números e hífens."
  }
}

variable "rbb_network" {
  description = "Rede RBB à qual o nó pertence: 'lab' (testnet) ou 'piloto' (mainnet)."
  type        = string
  validation {
    condition     = contains(["lab", "piloto"], var.rbb_network)
    error_message = "rbb_network deve ser 'lab' ou 'piloto'."
  }
}

variable "node" {
  description = "Descrição do nó, conforme o padrão de nomes da RBB (<tipo><sequencial>, ex.: validator01)."
  type = object({
    name         = string
    type         = string # boot | validator | writer | observer-boot | prometheus
    p2p_port     = optional(number, 30303)
    rpc_port     = optional(number, 8545)
    metrics_port = optional(number, 9545)
    # true: o endereço P2P anunciado é o IP público e a porta P2P fica aberta
    #       para os demais partícipes (boot, validator, observer-boot).
    # false: o endereço P2P anunciado é o IP privado e a porta P2P só é
    #        alcançável de dentro da VPC (writer de partícipe associado).
    p2p_public = optional(bool)
    # Expor a porta RPC publicamente (somente faz sentido para observer-boot,
    # que já bloqueia transações por permissionamento local de contas).
    rpc_public = optional(bool, false)
    # Variáveis de ambiente extras do Besu (BESU_*), aplicadas via rbb-cli.
    extra_env = optional(map(string), {})
  })
  validation {
    condition     = contains(["boot", "validator", "writer", "observer-boot", "prometheus"], var.node.type)
    error_message = "node.type deve ser boot, validator, writer, observer-boot ou prometheus."
  }
  validation {
    condition     = can(regex("^(boot|validator|writer|observer-boot|prometheus)[0-9]{2}$", var.node.name))
    error_message = "node.name deve seguir o padrão <tipo><sequencial> com dois dígitos (ex.: boot01, observer-boot01)."
  }
  validation {
    condition     = startswith(var.node.name, var.node.type)
    error_message = "node.name deve começar com node.type."
  }
}

variable "private_ip" {
  description = "IP privado (interno à VPC) do nó."
  type        = string
}

variable "public_ip" {
  description = "IP público do nó, se houver. Obrigatório quando p2p_public = true."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR da rede interna. Usado para liberar RPC/métricas/P2P interno apenas entre os nós da própria organização."
  type        = string
}

variable "admin_ssh_cidrs" {
  description = "CIDRs com permissão de SSH (porta 22) nos nós."
  type        = list(string)
}

variable "participant_cidrs" {
  description = "CIDRs dos demais partícipes com acesso à porta P2P dos nós núcleo e ao Prometheus (443). Use ['0.0.0.0/0'] para qualquer origem."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "rpc_cidrs" {
  description = "CIDRs com acesso à porta RPC (além da VPC). Ex.: rede das aplicações da organização."
  type        = list(string)
  default     = []
}

variable "genesis_json" {
  description = "Conteúdo do genesis.json da rede (obtido em RBBNet/participantes/<rede>/genesis.json). Se nulo, o nó é preparado mas o Besu não é iniciado."
  type        = string
  default     = null
  sensitive   = false
}

variable "start_network_version" {
  description = "Tag do repositório RBBNet/start-network (rbb-cli) a ser usada."
  type        = string
  default     = "v1.2.0"
}

variable "besu_image" {
  description = "Imagem do Besu. A RBB exige <= 25.5.0 (permissionamento on chain nativo)."
  type        = string
  default     = "hyperledger/besu:25.5.0"
}

variable "rbb_cli_image" {
  description = "Imagem docker do rbb-cli."
  type        = string
  default     = "bndes/rbb:latest"
}

variable "container_cpus" {
  description = "Limite de CPUs do contêiner Besu (CPUS_LIMIT_BESU_CONTAINER)."
  type        = number
  default     = 2
}

variable "container_memory" {
  description = "Limite de memória do contêiner Besu (MEMORY_LIMIT_BESU_CONTAINER), ex.: 6G."
  type        = string
  default     = "6G"
}

variable "data_mount" {
  description = "Ponto de montagem do volume de dados (onde ficam start-network/ e volumes/)."
  type        = string
  default     = "/srv/rbb"
}

variable "data_volume" {
  description = "Se true, o bootstrap procura um disco extra não formatado, formata (ext4) e monta em data_mount."
  type        = bool
  default     = true
}

variable "timezone" {
  type    = string
  default = "America/Sao_Paulo"
}

variable "prometheus_targets" {
  description = "Somente para nós prometheus: alvos locais a coletar (nós Besu da organização)."
  type = list(object({
    name = string
    ip   = string
    port = number
  }))
  default = []
}

variable "prometheus_federation_targets" {
  description = "Somente para nós prometheus: Prometheus de outras organizações (host:porta) e nome da organização."
  type = list(object({
    organization = string
    target       = string
  }))
  default = []
}

variable "ssh_user" {
  description = "Usuário padrão da imagem (usado apenas em mensagens de ajuda)."
  type        = string
  default     = "ubuntu"
}
