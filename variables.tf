variable "domain_name" {
  description = "独自ドメイン名（例: litenote.click）"
  type        = string
}

variable "region" {
  description = "AWS Region"
  type        = string
}

variable "environment" {
  type        = string
  description = "環境名 (例: dev, prod)"
}

variable "authorizer_id" {
  type        = string
  description = "API Gateway Cognito Authorizer ID"
  default     = null
}
