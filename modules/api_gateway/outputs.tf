output "api_id" {
  value       = aws_api_gateway_rest_api.this.id
  description = "The ID of the API Gateway REST API"
}

output "stage_name" {
  value = aws_api_gateway_stage.this.stage_name
}

output "rest_api_id" {
  value = aws_api_gateway_rest_api.this.id
}

output "api_url" {
  value = "https://${aws_api_gateway_rest_api.this.id}.execute-api.${var.region}.amazonaws.com/dev/hello"
}

