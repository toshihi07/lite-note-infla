output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}

output "cloudfront_distribution_arn" {
  description = "CloudFrontディストリビューションのARN"
  value       = aws_cloudfront_distribution.this.arn
}
output "bucket_policy_json" {
  description = "CloudFront OAC署名付きアクセスに対応したS3バケットポリシー（JSON形式）"
  value = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipalReadOnly"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${var.bucket_name}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.this.id}"
          }
        }
      }
    ]
  })
  depends_on = [aws_cloudfront_distribution.this]
}

output "frontend_cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.this.id
}
