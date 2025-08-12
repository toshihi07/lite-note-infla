output "user_pool_id" {
  value = aws_cognito_user_pool.this.id
}

output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.this.id
}

output "user_pool_domain" {
  value = try(aws_cognito_user_pool_domain.this[0].domain, null)
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.this.arn
}
