variable "environment" {
  type        = string
  description = "環境名 (例: dev, prod)"
}

variable "table_name" {
  type        = string
  description = "DynamoDBテーブル名"
}
