# Outputs for S3 static website hosting module

output "bucket_id" {
  description = "The ID/name of the S3 bucket"
  value       = aws_s3_bucket.website.id
}

output "bucket_arn" {
  description = "The ARN of the S3 bucket"
  value       = aws_s3_bucket.website.arn
}

output "bucket_domain_name" {
  description = "The bucket domain name for CloudFront origin"
  value       = aws_s3_bucket.website.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "The bucket regional domain name"
  value       = aws_s3_bucket.website.bucket_regional_domain_name
}

output "bucket_hosted_zone_id" {
  description = "The Route 53 Hosted Zone ID for this bucket's region"
  value       = aws_s3_bucket.website.hosted_zone_id
}

output "bucket_region" {
  description = "The AWS region this bucket resides in"
  value       = aws_s3_bucket.website.region
}

# For use by CloudFront Origin Access Control
output "bucket_website_endpoint" {
  description = "The website endpoint (for reference, not used with OAC)"
  value       = "https://${aws_s3_bucket.website.bucket_domain_name}"
}
