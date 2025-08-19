# Variables for S3 static website hosting module

variable "domain_name" {
  description = "The domain name for the website"
  type        = string
}

variable "bucket_name" {
  description = "Name of the S3 bucket (optional, will be auto-generated if not provided)"
  type        = string
  default     = null
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "enable_versioning" {
  description = "Enable S3 bucket versioning"
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "S3 bucket lifecycle rules"
  type = list(object({
    id     = string
    status = string
    expiration = object({
      days = number
    })
    noncurrent_version_expiration = object({
      noncurrent_days = number
    })
  }))
  default = [
    {
      id     = "delete_old_versions"
      status = "Enabled"
      expiration = {
        days = 90
      }
      noncurrent_version_expiration = {
        noncurrent_days = 30
      }
    }
  ]
}

variable "force_destroy" {
  description = "Allow force destruction of the bucket (useful for development)"
  type        = bool
  default     = false
}
