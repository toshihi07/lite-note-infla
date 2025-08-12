variable "bucket_name" {
  description = "S3バケット名（例：static.litenote.click）"
  type        = string
}

variable "bucket_policy_json" {
  description = "CloudFrontからのアクセスのみ許可するS3バケットポリシー"
  type        = string
  default     = null
}

variable "cloudfront_distribution_arn" {
  description = "OACからの署名付きリクエスト元を制限するためのCloudFront Distribution ARN"
  type        = string
  default     = ""
}
