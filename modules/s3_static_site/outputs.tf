output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "s3_bucket_policy_id" {
  description = "S3バケットポリシーのID"
  value       = length(aws_s3_bucket_policy.this) > 0 ? aws_s3_bucket_policy.this[0].id : null
}
