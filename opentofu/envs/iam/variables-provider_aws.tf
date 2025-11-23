# `provider_aws_{region,allowed_account_ids} and
# `backend_aws_s3_{region,allowed_account_ids} are defined seperately
# because it is possible to have the backend AWS S3 bucket in one
# region, while the AWS resources could be deployed in another
# region

variable "provider_aws_region" {
  description = "The region where the AWS provider will deploy the resources."
  type        = string
}

variable "provider_aws_allowed_account_ids" {
  description = "Account IDs that AWS provider is allowed to use."
  type        = list(string)
}
