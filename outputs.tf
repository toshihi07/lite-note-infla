output "user_pool_id" {
  value = module.cognito.user_pool_id
}

output "user_pool_client_id" {
  value = module.cognito.user_pool_client_id
}

output "user_pool_domain" {
  value = module.cognito.user_pool_domain
}

output "api_url" {
  value = "https://${module.api_gateway.api_id}.execute-api.${var.region}.amazonaws.com/${module.api_gateway.stage_name}/hello"
}

output "frontend_s3_bucket_name" {
  value = module.s3_static_site.bucket_name
}

output "frontend_cloudfront_distribution_id" {
  value = module.cloudfront_static_site.frontend_cloudfront_distribution_id
}
