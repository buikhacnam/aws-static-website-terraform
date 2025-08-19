# S3 bucket policy for CloudFront Origin Access Control

# Data source to get the current AWS caller identity
data "aws_caller_identity" "current" {}

# Data source to get the current AWS region
data "aws_region" "current" {}

# Variable to receive CloudFront distribution ARN (passed from parent module)
variable "cloudfront_distribution_arn" {
  description = "CloudFront distribution ARN for bucket policy"
  type        = string
  default     = ""
}

# Note: S3 bucket policy will be created separately after CloudFront distribution
# This avoids circular dependency issues during initial apply
