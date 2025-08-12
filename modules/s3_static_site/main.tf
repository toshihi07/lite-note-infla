resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = true # ⚠️ 中身を自動削除してからバケット削除する
  lifecycle {
    prevent_destroy = false
  }
}

# S3 バケット内のオブジェクトの所有権に関する設定
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# S3 バケットへのパブリックアクセスを制限する設定
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudFrontからのアクセスのみ許可するポリシー（OAI/OACと連携）
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = var.bucket_policy_json

  count = var.bucket_policy_json != null ? 1 : 0
}

data "aws_iam_policy_document" "s3_oac_policy" {
  statement {
    actions = ["s3:GetObject"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    resources = ["arn:aws:s3:::${var.bucket_name}/*"]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [var.cloudfront_distribution_arn]
    }
  }
}