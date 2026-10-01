# Credenciais via ambiente: AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY (ou AWS_PROFILE).
provider "aws" {
  region              = var.aws_region
  allowed_account_ids = [var.aws_account_id]
  default_tags {
    tags = {
      "rbb:organization" = var.organization
      "rbb:network"      = "lab"
      "managed-by"       = "opentofu"
    }
  }
}
