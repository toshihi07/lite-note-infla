variable "authorizer_name" {
  description = "オーソライザーの名前"
  type        = string
}

variable "api_id" {
  description = "API Gateway の REST API ID"
  type        = string
}

variable "user_pool_arn" {
  description = "Cognito User Pool の ARN"
  type        = string
}
