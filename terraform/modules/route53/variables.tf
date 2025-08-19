# Variables for Route53 DNS management module

variable "domain_name" {
  description = "The domain name for the hosted zone"
  type        = string
}

variable "certificate_domain_validation_options" {
  description = "Certificate domain validation options from ACM"
  type        = set(object({
    domain_name           = string
    resource_record_name  = string
    resource_record_type  = string
    resource_record_value = string
  }))
}

variable "enable_health_check" {
  description = "Enable Route53 health checks"
  type        = bool
  default     = false
}

variable "comment" {
  description = "Comment for the hosted zone"
  type        = string
  default     = ""
}
