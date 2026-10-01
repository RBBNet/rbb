locals {
  arn_prefix = "arn:aws:iam::${var.aws_account_id}"
}

module "admin_key" {
  source = "../../modules/aws-governance-key"

  name        = "${var.organization}-rbb-lab-admin"
  description = "Administrador Global da ${upper(var.organization)} na rede lab da RBB (nao exportavel)"

  admin_principal_arns     = [for u in var.admin_iam_users : "${local.arn_prefix}:user/${u}"]
  signer_role_trusted_arns = [for u in var.signer_iam_users : "${local.arn_prefix}:user/${u}"]

  audit_retention_years = var.audit_retention_years
}
