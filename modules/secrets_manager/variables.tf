variable "environment" {
  type        = string
  description = "環境名 (例: dev, prod)"
}

variable "api_key_value" {
  type        = string
  sensitive   = true
  description = "保存するAPIキー"
}
