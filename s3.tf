/*************
* S3 BUCKETS *
*************/
// S3 Bucket for Terraform Backend
resource "aws_s3_bucket" "static_backend_bucket" {
  bucket = var.static_backend_bucket
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "backend_bucket_versioning" {
  bucket = aws_s3_bucket.static_backend_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

// Static Bucket
resource "aws_s3_bucket" "static_bucket" {
  bucket = var.static_bucket
  tags   = var.tags
}

// S3 Bucket CORS | https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration
resource "aws_s3_bucket_cors_configuration" "static_backend_bucket_cors" {
  bucket = aws_s3_bucket.static_bucket.id

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = [
      "${aws_cloudfront_distribution.static_distribution.domain_name}",
      "${var.domain_name}",
      "${var.domain_name_www}"
    ]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
  }
}

resource "aws_s3_bucket_versioning" "static_bucket_versioning" {
  bucket = aws_s3_bucket.static_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "static_bucket_staging" {
  bucket = var.static_bucket_staging
  tags   = var.tags
}

resource "aws_s3_bucket_cors_configuration" "static_backend_bucket_staging_cors" {
  bucket = aws_s3_bucket.static_bucket_staging.id

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = [
      "${aws_cloudfront_distribution.static_distribution_staging.domain_name}",
      "${var.domain_name_staging}"
    ]
    allowed_headers = ["*"]
    expose_headers  = ["ETag"]
  }
}

