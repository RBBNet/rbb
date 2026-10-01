output "key_arn" {
  value = module.admin_key.key_arn
}

output "alias" {
  value = module.admin_key.alias
}

output "signer_role_arn" {
  value = module.admin_key.signer_role_arn
}

output "audit_bucket" {
  value = module.admin_key.audit_bucket
}

output "next_step" {
  value = "Endereço Ethereum: (cd infra/tools/kms-signer && npm ci && npm run address -- ${module.admin_key.alias})"
}
