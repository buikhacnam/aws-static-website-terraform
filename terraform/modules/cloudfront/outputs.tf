# Outputs for CloudFront distribution module

output "distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.website.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.website.arn
}

output "domain_name" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.website.domain_name
}

output "hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID for Route53 alias records"
  value       = aws_cloudfront_distribution.website.hosted_zone_id
}

output "status" {
  description = "Current status of the distribution"
  value       = aws_cloudfront_distribution.website.status
}

output "origin_access_control_id" {
  description = "Origin Access Control ID"
  value       = aws_cloudfront_origin_access_control.website.id
}

output "distribution_etag" {
  description = "Current version of the distribution's information"
  value       = aws_cloudfront_distribution.website.etag
}

# Useful for cache invalidation
output "invalidation_command" {
  description = "AWS CLI command to invalidate the entire distribution cache"
  value       = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.website.id} --paths '/*'"
}

# Distribution configuration details
output "aliases" {
  description = "List of domain aliases for the distribution"
  value       = aws_cloudfront_distribution.website.aliases
}

output "price_class" {
  description = "Price class of the distribution"
  value       = aws_cloudfront_distribution.website.price_class
}

output "enabled" {
  description = "Whether the distribution is enabled"
  value       = aws_cloudfront_distribution.website.enabled
}

# Logging information (if enabled)
output "logging_bucket" {
  description = "S3 bucket for CloudFront logs (if logging is enabled)"
  value       = var.enable_logging ? aws_s3_bucket.cloudfront_logs[0].id : null
}

# For debugging and monitoring
output "origin_access_control_arn" {
  description = "Origin Access Control ARN"
  value       = aws_cloudfront_origin_access_control.website.etag
}
