output "ssm_table_name" {
  value       = aws_ssm_parameter.dynamodb_table_name.name
  description = "DynamoDBテーブル名を格納したSSMパラメータの名前"
}
