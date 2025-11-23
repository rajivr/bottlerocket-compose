# `provider_aws_{region,allowed_account_ids} and
# `backend_aws_s3_{region,allowed_account_ids} are defined seperately
# because it is possible to have the backend AWS S3 bucket in one
# region, while the AWS resources could be deployed in another
# region

variable "backend_aws_s3_region" {
  description = "The region where the AWS S3 backend is present."
  type        = string
}

variable "backend_aws_s3_state_bucket" {
  description = "The name of the AWS S3 backend bucket. Must be globally unique"
  type        = string
}

variable "backend_aws_s3_state_bucket_role_suffix" {
  description = "The (lower and camel case) name of the role that will be used when deploying resources"
  type        = string
}

variable "backend_aws_s3_allowed_account_ids" {
  description = "Account IDs that AWS S3 backend is allowed to use."
  type        = list(string)
}
