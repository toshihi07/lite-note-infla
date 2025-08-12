output "secret_api_key_arn" {
  value       = aws_secretsmanager_secret.api_key.arn
  description = "Secrets Manager SecretのARN"
}
