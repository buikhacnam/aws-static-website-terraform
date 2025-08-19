# CloudFront module for CDN distribution with Origin Access Control

# Create Origin Access Control for secure S3 access
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${var.domain_name}-oac"
  description                       = "Origin Access Control for ${var.domain_name} static website"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront function for apex domain redirect
resource "aws_cloudfront_function" "redirect_apex_to_www" {
  name    = "${replace(var.domain_name, ".", "-")}-redirect-apex-to-www"
  runtime = "cloudfront-js-1.0"
  comment = "Redirect apex domain to www subdomain"
  publish = true
  code    = <<-EOF
function handler(event) {
    var request = event.request;
    var host = request.headers.host.value;
    
    // If request is for apex domain, redirect to www
    if (host === '${var.domain_name}') {
        var response = {
            statusCode: 301,
            statusDescription: 'Moved Permanently',
            headers: {
                'location': { value: 'https://www.${var.domain_name}' + request.uri }
            }
        };
        return response;
    }
    
    // Otherwise, continue with request
    return request;
}
EOF
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "website" {
  comment             = var.comment != "" ? var.comment : "CloudFront distribution for ${var.domain_name}"
  default_root_object = var.default_root_object
  enabled             = true
  is_ipv6_enabled     = var.enable_ipv6
  price_class         = var.price_class

  # Aliases (custom domain names)
  aliases = [
    var.domain_name,
    "www.${var.domain_name}"
  ]

  # S3 origin configuration
  origin {
    domain_name              = var.bucket_regional_domain_name
    origin_id                = "S3-${var.bucket_id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id

    # No custom headers or origin_path needed for root bucket access
  }

  # Default cache behavior
  default_cache_behavior {
    target_origin_id         = "S3-${var.bucket_id}"
    viewer_protocol_policy   = "redirect-to-https"
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    compress                 = true

    # Cache settings
    default_ttl = var.cache_behavior_settings.default_ttl
    max_ttl     = var.cache_behavior_settings.max_ttl
    min_ttl     = var.cache_behavior_settings.min_ttl

    # Forward headers, query strings, and cookies
    forwarded_values {
      query_string = false
      headers      = []
      cookies {
        forward = "none"
      }
    }

    # Function associations for apex domain redirect
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect_apex_to_www.arn
    }
  }

  # Additional cache behaviors for different file types
  ordered_cache_behavior {
    path_pattern           = "*.css"
    target_origin_id       = "S3-${var.bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    default_ttl = 31536000 # 1 year for CSS
    max_ttl     = 31536000
    min_ttl     = 0

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "*.js"
    target_origin_id       = "S3-${var.bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    default_ttl = 31536000 # 1 year for JS
    max_ttl     = 31536000
    min_ttl     = 0

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "*.png"
    target_origin_id       = "S3-${var.bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = false # Images don't benefit from compression

    default_ttl = 31536000 # 1 year for images
    max_ttl     = 31536000
    min_ttl     = 0

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "*.jpg"
    target_origin_id       = "S3-${var.bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = false

    default_ttl = 31536000 # 1 year for images
    max_ttl     = 31536000
    min_ttl     = 0

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "*.svg"
    target_origin_id       = "S3-${var.bucket_id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true # SVGs benefit from compression

    default_ttl = 31536000 # 1 year for SVGs
    max_ttl     = 31536000
    min_ttl     = 0

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # SSL/TLS certificate configuration
  viewer_certificate {
    acm_certificate_arn            = var.certificate_arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = var.minimum_protocol_version
    cloudfront_default_certificate = false
  }

  # Custom error pages for SPA routing
  dynamic "custom_error_response" {
    for_each = var.custom_error_responses
    content {
      error_code            = custom_error_response.value.error_code
      response_code         = custom_error_response.value.response_code
      response_page_path    = custom_error_response.value.response_page_path
      error_caching_min_ttl = custom_error_response.value.error_caching_min_ttl
    }
  }

  # Geographic restrictions (none by default)
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Logging configuration (optional)
  dynamic "logging_config" {
    for_each = var.enable_logging ? [1] : []
    content {
      bucket          = aws_s3_bucket.cloudfront_logs[0].bucket_domain_name
      include_cookies = false
      prefix          = "cloudfront-logs/"
    }
  }

  # Wait for certificate validation
  depends_on = [aws_cloudfront_origin_access_control.website]

  tags = {
    Name        = "${var.domain_name}-distribution"
    Environment = var.environment
    Domain      = var.domain_name
  }
}

# Optional: S3 bucket for CloudFront logs
resource "aws_s3_bucket" "cloudfront_logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = "${replace(var.domain_name, ".", "-")}-cloudfront-logs-${var.environment}"

  tags = {
    Name        = "${var.domain_name}-cloudfront-logs"
    Environment = var.environment
    Purpose     = "CloudFront Access Logs"
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs[0].id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 90
    }
  }
}
