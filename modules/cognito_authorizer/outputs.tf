output "authorizer_id" {
  description = "作成された Cognito オーソライザーの ID"
  value       = aws_api_gateway_authorizer.this.id
}
