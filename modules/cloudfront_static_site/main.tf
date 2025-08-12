data "aws_caller_identity" "current" {}

# ← 追加: CloudFront Function 用に安全な名前を作る
locals {
  cf_function_name = substr(
    replace("${var.bucket_name}-add-index-html", ".", "-"),
    0,
    64
  )
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.bucket_name}-oac"
  description                       = "OAC for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name              = "${var.bucket_name}.s3.amazonaws.com"
    origin_id                = "s3-${var.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id

    s3_origin_config {
      origin_access_identity = "" # OAC 使用時は空文字でOK
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-${var.bucket_name}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }

    # CloudFront Function を関連付け
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.add_index_html.arn
    }
  }

  viewer_certificate {
    acm_certificate_arn = var.acm_certificate_arn
    ssl_support_method  = "sni-only"
  }

  aliases = [var.domain_name]

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  depends_on = [aws_cloudfront_origin_access_control.this]
}

resource "aws_cloudfront_function" "add_index_html" {
  name    = local.cf_function_name   # ← 修正: サニタイズ済みの名前を使用
  runtime = "cloudfront-js-1.0"
  publish = true
  comment = "Append index.html to directory URIs"
  code    = file("${path.module}/cf-functions/add-index-html.js")
}
