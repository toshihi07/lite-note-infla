resource "aws_secretsmanager_secret" "api_key" {
  name        = "${var.environment}/litenote/api_key"
  description = "LiteNote API Key Secret"
}

resource "aws_secretsmanager_secret_version" "api_key_version" {
  secret_id     = aws_secretsmanager_secret.api_key.id
  secret_string = jsonencode({ api_key = var.api_key_value })
}