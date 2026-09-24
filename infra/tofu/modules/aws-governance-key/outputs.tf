output "key_id" {
  value = aws_kms_key.this.key_id
}

output "key_arn" {
  value = aws_kms_key.this.arn
}

output "alias" {
  value = aws_kms_alias.this.name
}

output "signer_role_arn" {
  description = "Papel a assumir para assinar (operação técnica). Nulo se não criado."
  value       = local.create_role ? aws_iam_role.signer[0].arn : null
}

output "audit_bucket" {
  value = var.create_trail ? aws_s3_bucket.audit[0].id : null
}

output "audit_trail_arn" {
  value = var.create_trail ? aws_cloudtrail.audit[0].arn : null
}

output "ethereum_address_hint" {
  description = "O endereço Ethereum deriva da chave pública (keccak256); obtenha com: tools/kms-signer address <alias>."
  value       = "tools/kms-signer address ${aws_kms_alias.this.name}"
}
