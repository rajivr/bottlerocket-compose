provider "aws" {
  region              = var.provider_aws_region
  allowed_account_ids = var.provider_aws_allowed_account_ids
}
