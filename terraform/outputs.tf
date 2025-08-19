# Outputs for S3 static website hosting with CloudFront and Route53

# S3 Bucket Information
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3_website.bucket_id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3_website.bucket_arn
}

output "s3_bucket_domain_name" {
  description = "Domain name of the S3 bucket"
  value       = module.s3_website.bucket_domain_name
}

# CloudFront Distribution Information
output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = module.cloudfront.distribution_id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = module.cloudfront.distribution_arn
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = module.cloudfront.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "CloudFront distribution hosted zone ID"
  value       = module.cloudfront.hosted_zone_id
}

# SSL Certificate Information
output "certificate_arn" {
  description = "ARN of the validated SSL certificate"
  value       = aws_acm_certificate_validation.website_cert.certificate_arn
}

output "certificate_domain_validation_options" {
  description = "Certificate domain validation options"
  value       = aws_acm_certificate.website_cert.domain_validation_options
  sensitive   = true
}

# Route53 Information
output "route53_zone_id" {
  description = "Route53 hosted zone ID"
  value       = module.route53.zone_id
}

output "route53_zone_name_servers" {
  description = "Route53 hosted zone name servers"
  value       = module.route53.name_servers
}

# DNS Records
output "www_record_fqdn" {
  description = "FQDN of the www A record"
  value       = aws_route53_record.www.fqdn
}

output "apex_record_fqdn" {
  description = "FQDN of the apex A record"
  value       = aws_route53_record.apex.fqdn
}

# Website URLs
output "website_url" {
  description = "Main website URL"
  value       = "https://www.${var.domain_name}"
}

output "redirect_url" {
  description = "Redirect URL (apex domain)"
  value       = "https://${var.domain_name}"
}

# Deployment Information
output "deployment_bucket_sync_command" {
  description = "AWS CLI command to sync files to S3 bucket"
  value       = "aws s3 sync ./static-fe/dist/ s3://${module.s3_website.bucket_id}/ --delete"
}

output "cloudfront_invalidation_command" {
  description = "AWS CLI command to invalidate CloudFront cache"
  value       = "aws cloudfront create-invalidation --distribution-id ${module.cloudfront.distribution_id} --paths '/*'"
}

# DNS Configuration Instructions
output "dns_configuration_instructions" {
  description = "Instructions for configuring DNS with your domain registrar"
  value = <<-EOT
    To complete the setup, update your domain registrar's nameservers to:
    ${join("\n    ", module.route53.name_servers)}
    
    This will delegate DNS management to Route53 for your domain ${var.domain_name}.
  EOT
}

# Security Information
output "origin_access_control_id" {
  description = "CloudFront Origin Access Control ID"
  value       = module.cloudfront.origin_access_control_id
}

# Useful AWS Console Links
output "aws_console_links" {
  description = "Useful AWS Console links for managing resources"
  value = {
    s3_bucket    = "https://s3.console.aws.amazon.com/s3/buckets/${module.s3_website.bucket_id}"
    cloudfront   = "https://console.aws.amazon.com/cloudfront/v3/home#/distributions/${module.cloudfront.distribution_id}"
    route53      = "https://console.aws.amazon.com/route53/v2/hostedzones#ListRecordSets/${module.route53.zone_id}"
    certificate  = "https://console.aws.amazon.com/acm/home?region=us-east-1#/certificates/${aws_acm_certificate.website_cert.arn}"
  }
}
