resource "aws_s3_bucket" "this" {
  bucket = "${var.backend_aws_s3_state_bucket}-${var.backend_aws_s3_state_bucket_role_suffix}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}