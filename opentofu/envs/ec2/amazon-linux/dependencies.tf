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

data "aws_ami" "amzn_linux_2023_latest" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
