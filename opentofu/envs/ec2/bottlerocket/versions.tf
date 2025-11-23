terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket              = "${var.backend_aws_s3_state_bucket}-${var.backend_aws_s3_state_bucket_role_suffix}"
    key                 = "envs/ec2/bottlerocket/terraform.tfstate"
    region              = var.backend_aws_s3_region
    use_lockfile        = true
    allowed_account_ids = var.backend_aws_s3_allowed_account_ids
  }
}
