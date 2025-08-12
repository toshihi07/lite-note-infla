variable "lambda_name" {
  description = "Lambda関数の名前"
  type        = string
}

variable "lambda_jar_path" {
  description = "Path to Lambda fat jar file"
}

variable "table_name" {
  description = "DynamoDB table name"
}

variable "table_name_param" {
  type        = string
  description = "SSM Parameter Storeのテーブル名パラメータ名"
}

variable "secret_api_key_arn" {
  type        = string
  description = "Secrets ManagerのAPIキーARN"
}

variable "region" {
  type        = string
  description = "AWSリージョン"
}


