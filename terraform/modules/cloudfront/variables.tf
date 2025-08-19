# Variables for CloudFront distribution module

variable "domain_name" {
  description = "The domain name for the website"
  type        = string
}

variable "bucket_id" {
  description = "S3 bucket ID/name"
  type        = string
}

variable "bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

variable "bucket_domain_name" {
  description = "S3 bucket domain name"
  type        = string
}

variable "bucket_regional_domain_name" {
  description = "S3 bucket regional domain name"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for SSL/TLS"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "price_class" {
  description = "CloudFront distribution price class"
  type        = string
  default     = "PriceClass_100"
  validation {
    condition     = contains(["PriceClass_All", "PriceClass_200", "PriceClass_100"], var.price_class)
    error_message = "Price class must be one of: PriceClass_All, PriceClass_200, PriceClass_100."
  }
}

variable "enable_ipv6" {
  description = "Enable IPv6 for CloudFront distribution"
  type        = bool
  default     = true
}

variable "minimum_protocol_version" {
  description = "Minimum SSL/TLS protocol version"
  type        = string
  default     = "TLSv1.2_2021"
}

variable "default_root_object" {
  description = "Default root object for the distribution"
  type        = string
  default     = "index.html"
}

variable "custom_error_responses" {
  description = "Custom error responses for SPA routing"
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
  description = "Cache behavior settings"
  type = object({
    default_ttl = number
    max_ttl     = number
    min_ttl     = number
  })
  default = {
    default_ttl = 86400    # 1 day
    max_ttl     = 31536000 # 1 year
    min_ttl     = 0
  }
}

variable "enable_logging" {
  description = "Enable CloudFront access logging"
  type        = bool
  default     = false
}

variable "comment" {
  description = "Comment for the CloudFront distribution"
  type        = string
  default     = ""
}
