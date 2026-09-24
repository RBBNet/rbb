mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_region" {
    defaults = { region = "sa-east-1" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
}

variables {
  name                     = "org-rbb-lab-admin"
  admin_principal_arns     = ["arn:aws:iam::123456789012:user/admin1", "arn:aws:iam::123456789012:user/admin2"]
  signer_role_trusted_arns = ["arn:aws:iam::123456789012:user/operador"]
}

run "chave_nao_exportavel_com_papel_e_trilha" {
  command = plan

  assert {
    condition     = aws_kms_key.this.key_usage == "SIGN_VERIFY" && aws_kms_key.this.customer_master_key_spec == "ECC_SECG_P256K1"
    error_message = "A chave deve ser secp256k1 somente para assinatura."
  }
  assert {
    condition     = length(aws_iam_role.signer) == 1 && aws_iam_role.signer[0].name == "org-rbb-lab-admin-signer"
    error_message = "Papel de assinatura deve ser criado quando há principais confiáveis."
  }
  assert {
    condition     = length(aws_s3_bucket.audit) == 1 && aws_s3_bucket.audit[0].object_lock_enabled == true
    error_message = "Bucket de auditoria com Object Lock."
  }
  assert {
    condition     = aws_s3_bucket_object_lock_configuration.audit[0].rule[0].default_retention[0].years == 5
    error_message = "Retenção padrão de 5 anos."
  }
  assert {
    condition     = aws_cloudtrail.audit[0].enable_log_file_validation == true && aws_cloudtrail.audit[0].is_multi_region_trail == true
    error_message = "Trilha com validação de integridade e multi-região."
  }
  assert {
    condition     = contains(data.aws_iam_policy_document.signer_permissions[0].statement[0].actions, "kms:Sign") && !contains(data.aws_iam_policy_document.signer_permissions[0].statement[0].actions, "kms:ScheduleKeyDeletion")
    error_message = "Papel de assinatura só pode assinar."
  }
  assert {
    condition     = !contains(flatten([for st in data.aws_iam_policy_document.key.statement : st.actions if st.sid == "AdminByOwner"]), "kms:Sign")
    error_message = "Administradores da organização não assinam por padrão."
  }
}

run "sem_papel_quando_nao_ha_operador" {
  command = plan
  variables {
    signer_role_trusted_arns = []
    create_trail             = false
  }
  assert {
    condition     = length(aws_iam_role.signer) == 0 && length(aws_cloudtrail.audit) == 0
    error_message = "Sem operador e sem trilha quando desativados."
  }
}
