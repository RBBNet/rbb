data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  bucket_name = coalesce(var.audit_bucket_name, "${var.name}-audit-${local.account_id}")
  role_name   = coalesce(var.signer_role_name, "${var.name}-signer")
  create_role = length(var.signer_role_trusted_arns) > 0
  tags        = merge({ "rbb:purpose" = "governance-key", "rbb:key" = var.name }, var.tags)
}

# ---------------------------------------------------------------------------
# Chave: secp256k1 (curva do Ethereum), somente assinatura, não exportável
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "key" {
  # Administração pela organização titular (sem direito de assinar)
  statement {
    sid    = "AdminByOwner"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = var.admin_principal_arns
    }
    actions = [
      "kms:Create*", "kms:Describe*", "kms:Enable*", "kms:List*", "kms:Put*", "kms:Update*",
      "kms:Revoke*", "kms:Disable*", "kms:Get*", "kms:TagResource", "kms:UntagResource",
      "kms:ScheduleKeyDeletion", "kms:CancelKeyDeletion",
    ]
    resources = ["*"]
  }
  # A raiz da conta mantém a capacidade de recuperar a administração (padrão AWS)
  statement {
    sid    = "RootRecovery"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${local.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }
  # Negação explícita: NINGUÉM assina fora dos principais autorizados, nem administradores
  # com AdministratorAccess (a Deny na política da chave prevalece sobre políticas IAM).
  dynamic "statement" {
    for_each = (local.create_role || length(var.signer_principal_arns) > 0) ? [1] : []
    content {
      sid    = "DenySignExceptAuthorized"
      effect = "Deny"
      principals {
        type        = "AWS"
        identifiers = ["*"]
      }
      actions   = ["kms:Sign"]
      resources = ["*"]
      condition {
        test     = "ArnNotEquals"
        variable = "aws:PrincipalArn"
        values = concat(
          var.signer_principal_arns,
          local.create_role ? ["arn:${data.aws_partition.current.partition}:iam::${local.account_id}:role/${local.role_name}"] : [],
        )
      }
    }
  }
  # Assinatura: papel de operação e/ou principais explícitos
  dynamic "statement" {
    for_each = (local.create_role || length(var.signer_principal_arns) > 0) ? [1] : []
    content {
      sid    = "SignOnly"
      effect = "Allow"
      principals {
        type = "AWS"
        identifiers = concat(
          var.signer_principal_arns,
          local.create_role ? ["arn:${data.aws_partition.current.partition}:iam::${local.account_id}:role/${local.role_name}"] : [],
        )
      }
      actions   = ["kms:Sign", "kms:GetPublicKey", "kms:DescribeKey"]
      resources = ["*"]
    }
  }
}

resource "aws_kms_key" "this" {
  description              = var.description
  key_usage                = "SIGN_VERIFY"
  customer_master_key_spec = "ECC_SECG_P256K1"
  deletion_window_in_days  = 30
  enable_key_rotation      = false # rotação automática não se aplica a chaves assimétricas
  policy                   = data.aws_iam_policy_document.key.json
  tags                     = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.this.key_id
}

# ---------------------------------------------------------------------------
# Papel de assinatura (operação técnica): só kms:Sign nesta chave, assumível
# apenas pelos principais indicados. Revogar = remover o principal da lista.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "signer_trust" {
  count = local.create_role ? 1 : 0
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = var.signer_role_trusted_arns
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "signer" {
  count                = local.create_role ? 1 : 0
  name                 = local.role_name
  description          = "Assina transacoes de governanca da RBB com a chave ${var.name} (kms:Sign apenas)"
  assume_role_policy   = data.aws_iam_policy_document.signer_trust[0].json
  max_session_duration = 3600
  tags                 = local.tags
}

data "aws_iam_policy_document" "signer_permissions" {
  count = local.create_role ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = ["kms:Sign", "kms:GetPublicKey", "kms:DescribeKey"]
    resources = [aws_kms_key.this.arn]
  }
}

resource "aws_iam_role_policy" "signer" {
  count  = local.create_role ? 1 : 0
  name   = "${local.role_name}-kms-sign"
  role   = aws_iam_role.signer[0].id
  policy = data.aws_iam_policy_document.signer_permissions[0].json
}
