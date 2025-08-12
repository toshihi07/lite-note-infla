
#SSM Parameter Store に DynamoDB の環境変数を登録
resource "aws_ssm_parameter" "dynamodb_table_name" {
  name  = "/litenote/${var.environment}/dynamodb/table_name"
  type  = "String"
  value = "lite_note_items"
}
