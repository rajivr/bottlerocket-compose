data "terraform_remote_state" "iam" {
  backend = "s3"

  config = {
    bucket = var.remote_state_administrator_role_bucket
    key    = "envs/iam/terraform.tfstate"
    region = var.backend_aws_s3_region
  }
}

data "terraform_remote_state" "vpc" {
  backend = "s3"

  config = {
    bucket = "${var.backend_aws_s3_state_bucket}-${var.backend_aws_s3_state_bucket_role_suffix}"
    key    = "envs/vpc/terraform.tfstate"
    region = var.backend_aws_s3_region
  }
}
