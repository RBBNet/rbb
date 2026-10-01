# Bucket de estado remoto do OpenTofu (todos os ambientes desta organização), na conta AWS
# da organização titular. Estado próprio deste diretório fica local: é um único bucket, e
# ele precisa existir antes dos demais. Aplicar uma vez por organização.
terraform {
  required_version = ">= 1.11"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "sa-east-1"
}

variable "organization" {
  type = string
}

provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.aws_account_id]
  default_tags {
    tags = { "rbb:organization" = var.organization, "managed-by" = "opentofu" }
  }
}

resource "aws_s3_bucket" "state" {
  bucket = "${var.organization}-rbb-tofu-state-${var.aws_account_id}"
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Mantém 90 dias de versões antigas do estado (recuperação de erros), depois expira.
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {}
    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

output "bucket" {
  value = aws_s3_bucket.state.id
}

output "backend_config" {
  description = "Cole em backend.tf de cada ambiente (ver backend.aws.tf.example)."
  value       = "bucket = \"${aws_s3_bucket.state.id}\"  region = \"${var.aws_region}\"  use_lockfile = true"
}
