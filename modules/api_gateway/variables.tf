

variable "authorizer_id" {
  description = "Cognito オーソライザーの ID"
  default     = null
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "api_name" {
  description = "API Gateway の名前"
  type        = string
}

variable "lambda_invoke_arn" {
  description = "Lambda 関数の Invoke ARN"
  type        = string
}

variable "lambda_name" {
  description = "Lambda function name to be invoked by API Gateway"
  type        = string
}

