# Outputs for Route53 DNS management module

output "zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "zone_arn" {
  description = "Route53 hosted zone ARN"
  value       = aws_route53_zone.main.arn
}

output "name_servers" {
  description = "List of name servers for the hosted zone"
  value       = aws_route53_zone.main.name_servers
}

output "zone_name" {
  description = "The hosted zone name"
  value       = aws_route53_zone.main.name
}

output "primary_name_server" {
  description = "The primary name server for the hosted zone"
  value       = aws_route53_zone.main.primary_name_server
}

# Certificate validation record information
output "certificate_validation_records" {
  description = "Certificate validation DNS records"
  value = [
    for record in aws_route53_record.cert_validation : {
      fqdn = record.fqdn
      name = record.name
      type = record.type
    }
  ]
}

# DNS record information (now handled in main.tf)

# Health check information (if enabled)
output "health_check_id" {
  description = "Route53 health check ID (if enabled)"
  value       = var.enable_health_check ? aws_route53_health_check.main[0].id : null
}

# Useful instructions for domain configuration
output "nameserver_instructions" {
  description = "Instructions for updating domain nameservers"
  value = <<-EOT
    To complete DNS setup, update your domain registrar settings:
    
    1. Log into your domain registrar (where you purchased ${var.domain_name})
    2. Find DNS/Nameserver settings
    3. Replace existing nameservers with these Route53 nameservers:
       ${join("\n       ", aws_route53_zone.main.name_servers)}
    
    4. Save changes and wait for DNS propagation (usually 24-48 hours)
    
    After propagation, your domain will resolve to:
    - ${var.domain_name} → CloudFront (redirects to www)
    - www.${var.domain_name} → CloudFront (main site)
  EOT
}

# DNS propagation check commands
output "dns_check_commands" {
  description = "Commands to check DNS propagation"
  value = {
    check_nameservers = "dig NS ${var.domain_name}"
    check_www_record  = "dig www.${var.domain_name}"
    check_apex_record = "dig ${var.domain_name}"
    check_ssl_cert    = "openssl s_client -connect www.${var.domain_name}:443 -servername www.${var.domain_name}"
  }
}

# Zone delegation information
output "delegation_set_id" {
  description = "Delegation set ID (if using reusable delegation set)"
  value       = aws_route53_zone.main.delegation_set_id
}

output "hosted_zone_tags" {
  description = "Tags applied to the hosted zone"
  value       = aws_route53_zone.main.tags_all
}
