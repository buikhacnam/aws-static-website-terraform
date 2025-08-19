# S3 module for static website hosting with private bucket and CloudFront access

# Generate bucket name if not provided
locals {
  bucket_name = var.bucket_name != null ? var.bucket_name : "${replace(var.domain_name, ".", "-")}-website-${var.environment}"
}

# Create the S3 bucket
resource "aws_s3_bucket" "website" {
  bucket        = local.bucket_name
  force_destroy = var.force_destroy

  tags = {
    Name        = local.bucket_name
    Purpose     = "Static Website Hosting"
    Domain      = var.domain_name
    Environment = var.environment
  }
}

# Configure bucket versioning
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Configure server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Block public access (bucket will be private, accessed only through CloudFront)
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configure bucket lifecycle rules
resource "aws_s3_bucket_lifecycle_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      filter {
        prefix = ""
      }

      expiration {
        days = rule.value.expiration.days
      }

      noncurrent_version_expiration {
        noncurrent_days = rule.value.noncurrent_version_expiration.noncurrent_days
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.website]
}

# CORS configuration for web assets
resource "aws_s3_bucket_cors_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = [
      "https://${var.domain_name}",
      "https://www.${var.domain_name}"
    ]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Bucket notification configuration (optional, for future use)
resource "aws_s3_bucket_notification" "website" {
  bucket = aws_s3_bucket.website.id
  # No notifications configured initially, but resource is created for future use
}
