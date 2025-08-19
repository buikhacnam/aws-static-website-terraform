# Terraform configuration for S3 static website hosting with CloudFront and Route53
# Domain: casey.click with redirect to www.casey.click

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "casey-click-website"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Provider for ACM certificate (must be in us-east-1 for CloudFront)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "casey-click-website"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}

# Data source for AWS region
data "aws_region" "current" {}

# S3 module for static website hosting
module "s3_website" {
  source = "./modules/s3"

  domain_name                   = var.domain_name
  bucket_name                   = var.bucket_name
  environment                   = var.environment
  cloudfront_distribution_arn   = module.cloudfront.distribution_arn
}

# ACM certificate for SSL/TLS
resource "aws_acm_certificate" "website_cert" {
  provider          = aws.us_east_1
  domain_name       = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.domain_name}-certificate"
  }
}

# Certificate validation (will be handled by Route53 module)
resource "aws_acm_certificate_validation" "website_cert" {
  provider        = aws.us_east_1
  certificate_arn = aws_acm_certificate.website_cert.arn
  validation_record_fqdns = [
    for record in module.route53.certificate_validation_records : record.fqdn
  ]

  timeouts {
    create = "10m"
  }

  depends_on = [module.route53]
}

# Route53 module for DNS management (certificate validation only)
module "route53" {
  source = "./modules/route53"

  domain_name                            = var.domain_name
  certificate_domain_validation_options  = aws_acm_certificate.website_cert.domain_validation_options
}

# CloudFront module for CDN distribution
module "cloudfront" {
  source = "./modules/cloudfront"

  domain_name                    = var.domain_name
  bucket_id                     = module.s3_website.bucket_id
  bucket_arn                    = module.s3_website.bucket_arn
  bucket_domain_name            = module.s3_website.bucket_domain_name
  bucket_regional_domain_name   = module.s3_website.bucket_regional_domain_name
  certificate_arn               = aws_acm_certificate_validation.website_cert.certificate_arn
  environment                   = var.environment
  price_class                   = var.cloudfront_price_class
  enable_ipv6                   = var.enable_ipv6
  minimum_protocol_version      = var.minimum_protocol_version
  default_root_object           = var.default_root_object
  custom_error_responses        = var.custom_error_response
  cache_behavior_settings       = var.cache_behavior_settings
  enable_logging                = var.enable_cloudfront_logging
  comment                       = "Static website for ${var.domain_name}"

  depends_on = [
    aws_acm_certificate_validation.website_cert
  ]
}

# Route53 DNS records for CloudFront (created after CloudFront is ready)
resource "aws_route53_record" "www" {
  zone_id = module.route53.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = module.cloudfront.domain_name
    zone_id                = module.cloudfront.hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

resource "aws_route53_record" "www_ipv6" {
  zone_id = module.route53.zone_id
  name    = "www.${var.domain_name}"
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.domain_name
    zone_id                = module.cloudfront.hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

resource "aws_route53_record" "apex" {
  zone_id = module.route53.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = module.cloudfront.domain_name
    zone_id                = module.cloudfront.hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

resource "aws_route53_record" "apex_ipv6" {
  zone_id = module.route53.zone_id
  name    = var.domain_name
  type    = "AAAA"

  alias {
    name                   = module.cloudfront.domain_name
    zone_id                = module.cloudfront.hosted_zone_id
    evaluate_target_health = false
  }

  depends_on = [module.cloudfront]
}

# S3 bucket policy to allow CloudFront Origin Access Control
resource "aws_s3_bucket_policy" "website" {
  bucket = module.s3_website.bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.s3_website.bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.cloudfront.distribution_arn
          }
        }
      }
    ]
  })

  depends_on = [module.cloudfront, module.s3_website]
}
