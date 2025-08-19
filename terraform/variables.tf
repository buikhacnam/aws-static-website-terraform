# Variables for S3 static website hosting with CloudFront and Route53

variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "domain_name" {
  description = "The domain name for the website (e.g., casey.click)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]\\.[a-z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid domain format."
  }
}

variable "bucket_name" {
  description = "Name of the S3 bucket for static website hosting"
  type        = string
  default     = null
  validation {
    condition = var.bucket_name == null || can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "Bucket name must be between 3 and 63 characters, start and end with lowercase letter or number, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "enable_cloudfront_logging" {
  description = "Enable CloudFront access logging"
  type        = bool
  default     = false
}

variable "cloudfront_price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_100"
  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.cloudfront_price_class)
    error_message = "Price class must be one of: PriceClass_All, PriceClass_200, PriceClass_100."
  }
}

variable "enable_ipv6" {
  description = "Enable IPv6 for CloudFront distribution"
  type        = bool
  default     = true
}

variable "minimum_protocol_version" {
  description = "Minimum SSL/TLS protocol version for CloudFront"
  type        = string
  default     = "TLSv1.2_2021"
  validation {
    condition = contains([
      "SSLv3", "TLSv1", "TLSv1_2016", "TLSv1.1_2016", "TLSv1.2_2018", "TLSv1.2_2019", "TLSv1.2_2021"
    ], var.minimum_protocol_version)
    error_message = "Invalid SSL/TLS protocol version."
  }
}

variable "default_root_object" {
  description = "Default root object for CloudFront distribution"
  type        = string
  default     = "index.html"
}

variable "custom_error_response" {
  description = "Custom error responses for CloudFront"
  type = list(object({
    error_code            = number
    response_code         = number
    response_page_path    = string
    error_caching_min_ttl = number
  }))
  default = [
    {
      error_code            = 404
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 300
    },
    {
      error_code            = 403
      response_code         = 200
      response_page_path    = "/index.html"
      error_caching_min_ttl = 300
    }
  ]
}

variable "cache_behavior_settings" {
  description = "Cache behavior settings for different file types"
  type = object({
    default_ttl = number
    max_ttl     = number
    min_ttl     = number
  })
  default = {
    default_ttl = 86400   # 1 day
    max_ttl     = 31536000 # 1 year
    min_ttl     = 0
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
