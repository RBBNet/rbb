# ---------------------------------------------------------------------------
# Trilha de auditoria imutável: CloudTrail -> S3 com Object Lock (GOVERNANCE),
# validação de integridade dos arquivos de log e retenção configurável.
# Registra todo uso da chave (kms:Sign, quem, quando, de onde) e mudanças de
# permissão, atendendo à exigência de trilha completa e inalterável.
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "audit" {
  count               = var.create_trail ? 1 : 0
  bucket              = local.bucket_name
  object_lock_enabled = true
  tags                = local.tags

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "audit" {
  count  = var.create_trail ? 1 : 0
  bucket = aws_s3_bucket.audit[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "audit" {
  count  = var.create_trail ? 1 : 0
  bucket = aws_s3_bucket.audit[0].id
  rule {
    default_retention {
      mode  = "GOVERNANCE"
      years = var.audit_retention_years
    }
  }
  depends_on = [aws_s3_bucket_versioning.audit]
}

resource "aws_s3_bucket_public_access_block" "audit" {
  count                   = var.create_trail ? 1 : 0
  bucket                  = aws_s3_bucket.audit[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit" {
  count  = var.create_trail ? 1 : 0
  bucket = aws_s3_bucket.audit[0].id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "audit_bucket" {
  count = var.create_trail ? 1 : 0
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.audit[0].arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${local.account_id}:trail/${var.name}-audit"]
    }
  }
  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.audit[0].arn}/AWSLogs/${local.account_id}/*"]
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.region}:${local.account_id}:trail/${var.name}-audit"]
    }
  }
}

resource "aws_s3_bucket_policy" "audit" {
  count  = var.create_trail ? 1 : 0
  bucket = aws_s3_bucket.audit[0].id
  policy = data.aws_iam_policy_document.audit_bucket[0].json
}

resource "aws_cloudtrail" "audit" {
  count                         = var.create_trail ? 1 : 0
  name                          = "${var.name}-audit"
  s3_bucket_name                = aws_s3_bucket.audit[0].id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  tags                          = local.tags

  depends_on = [aws_s3_bucket_policy.audit, aws_s3_bucket_object_lock_configuration.audit]
}
