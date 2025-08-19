# Route53 module for DNS management

# Create Route53 hosted zone for the domain
resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = var.comment != "" ? var.comment : "Hosted zone for ${var.domain_name} static website"

  tags = {
    Name    = var.domain_name
    Purpose = "Static Website DNS"
  }
}

# Certificate validation records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in var.certificate_domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.main.zone_id
}

# CloudFront DNS records moved to main.tf to avoid circular dependency

# Optional health check for the website
resource "aws_route53_health_check" "main" {
  count                           = var.enable_health_check ? 1 : 0
  fqdn                           = "www.${var.domain_name}"
  port                           = 443
  type                           = "HTTPS"
  resource_path                  = "/"
  failure_threshold              = 3
  request_interval               = 30
  measure_latency                = true
  cloudwatch_alarm_region        = "us-east-1"
  insufficient_data_health_status = "LastKnownStatus"

  tags = {
    Name = "${var.domain_name}-health-check"
  }
}

# MX record (optional, for future email setup)
# Commented out by default since no email service is configured
# resource "aws_route53_record" "mx" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = var.domain_name
#   type    = "MX"
#   ttl     = var.ttl
#   records = ["10 mail.${var.domain_name}"]
# }

# TXT record for domain verification (optional)
# Can be used for various domain verification purposes
# resource "aws_route53_record" "txt" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = var.domain_name
#   type    = "TXT"
#   ttl     = var.ttl
#   records = ["v=spf1 -all"]
# }
