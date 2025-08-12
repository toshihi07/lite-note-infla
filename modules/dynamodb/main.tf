resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST" # ✅ オンデマンド課金

  hash_key  = "userId"
  range_key = "itemId"

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "itemId"
    type = "S"
  }

  tags = {
    Name = var.table_name
    Env  = "dev"
  }
}