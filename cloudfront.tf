/*************
* CLOUDFRONT *
*************/
// Production
resource "aws_cloudfront_distribution" "static_distribution" {
  origin {
    domain_name              = aws_s3_bucket.static_bucket.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.static_bucket.bucket
    origin_access_control_id = aws_cloudfront_origin_access_control.static_bucket.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = []

  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.static_bucket.bucket
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD"
    ]

    cached_methods = [
      "GET",
      "HEAD"
    ]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000

    compress = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.acm_certificate_arn
    ssl_support_method = "sni-only"
  }

  tags = var.tags
}

resource "aws_cloudfront_origin_access_control" "static_bucket" {
  name                              = "prod static bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

// Staging
resource "aws_cloudfront_distribution" "static_distribution_staging" {
  origin {
    domain_name              = aws_s3_bucket.static_bucket_staging.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.static_bucket_staging.bucket
    origin_access_control_id = aws_cloudfront_origin_access_control.static_bucket_staging.id
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name_staging]


  default_cache_behavior {
    target_origin_id       = aws_s3_bucket.static_bucket_staging.bucket
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD"
    ]

    cached_methods = [
      "GET",
      "HEAD"
    ]

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400
    max_ttl     = 31536000

    compress = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.acm_certificate_arn
    ssl_support_method = "sni-only"
  }

  tags = var.tags
}

resource "aws_cloudfront_origin_access_control" "static_bucket_staging" {
  name                              = "staging static bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}