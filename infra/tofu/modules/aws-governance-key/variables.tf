# Cofre de chaves para a conta de Administrador Global de uma organização na RBB.
# A chave é criada dentro do AWS KMS (curva secp256k1, uso SIGN_VERIFY) e nunca pode ser
# exportada. Quem assina recebe apenas a permissão kms:Sign, revogável a qualquer momento.
# Todo uso fica registrado no CloudTrail, em bucket com Object Lock (imutável).

variable "name" {
  description = "Nome lógico da chave (alias). Ex.: exemplo-rbb-lab-admin"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name))
    error_message = "Use apenas letras minúsculas, números e hífens."
  }
}

variable "description" {
  type    = string
  default = "Chave de Administrador Global na Rede Blockchain Brasil (nao exportavel)"
}

variable "admin_principal_arns" {
  description = "Principais IAM (usuários/papéis) da organização titular que administram a chave e a trilha (nunca assinam por padrão)."
  type        = list(string)
}

variable "signer_principal_arns" {
  description = "Principais IAM autorizados a assinar (kms:Sign) diretamente. Normalmente vazio: a assinatura é feita pelo papel criado por este módulo."
  type        = list(string)
  default     = []
}

variable "signer_role_trusted_arns" {
  description = "Principais autorizados a assumir o papel de assinatura (operação técnica). Vazio = papel não é criado."
  type        = list(string)
  default     = []
}

variable "signer_role_name" {
  type    = string
  default = null
}

variable "audit_bucket_name" {
  description = "Nome do bucket do CloudTrail (global e único). Nulo = <name>-audit-<account_id>."
  type        = string
  default     = null
}

variable "audit_retention_years" {
  description = "Retenção com Object Lock (modo GOVERNANCE) dos logs de auditoria, em anos."
  type        = number
  default     = 5
}

variable "create_trail" {
  description = "Cria a trilha do CloudTrail (uma por conta basta; use false se já existir e informe existing_trail_name apenas para documentação)."
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
