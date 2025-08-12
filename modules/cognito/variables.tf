variable "user_pool_name" {
  type        = string
  description = "Cognito User Pool name"
}

variable "client_name" {
  type        = string
  description = "Cognito App Client name"
}

variable "domain_prefix" {
  type        = string
  description = "Prefix for Cognito hosted UI domain (optional)"
  default     = ""
}
