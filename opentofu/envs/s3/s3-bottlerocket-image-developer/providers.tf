# *NOTE*
#
# In the normal case, this should have been `var.provider_aws_region`
# and `var.provider_aws_allowed_account_ids`.
#
# However, in this module, we are initializing the AWS S3 backend 
# bucket, hence we use `var.backend_aws_s3_region` and
# `var.backend_aws_allowed_account_ids`
provider "aws" {
  region              = var.backend_aws_s3_region
  allowed_account_ids = var.backend_aws_s3_allowed_account_ids
}
