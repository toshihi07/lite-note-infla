resource "aws_iam_role" "lambda_exec" {
  name_prefix = "${var.lambda_name}-role-"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "this" {
  function_name = var.lambda_name
  runtime       = "java17"
  handler       = "com.litenote.lambda.Handler::handleRequest"
  role          = aws_iam_role.lambda_exec.arn

  # ✅ Jarを直接アップロード
  filename         = var.lambda_jar_path
  source_code_hash = filebase64sha256(var.lambda_jar_path)

  timeout     = 10
  memory_size = 512

  environment {
    variables = {
      TABLE_NAME_PARAM   = var.table_name_param   # ✅ ここ修正
      SECRET_API_KEY_ARN = var.secret_api_key_arn # ✅ ここ修正
    }
  }

}

data "aws_caller_identity" "current" {}

# Lambda IAM ロールに権限追加_DynamoDB用とSSM/Secrets用
resource "aws_iam_role_policy" "lambda_least_privilege_policy" {
  name = "${var.lambda_name}-least-privilege-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      # ✅ DynamoDB（対象テーブルのみ許可）
      {
        Effect = "Allow",
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:DeleteItem",
          "dynamodb:UpdateItem",
          "dynamodb:Scan"
        ],
        Resource = "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/lite_note_items"
      },
      # ✅ SSM Parameter Store（対象パラメータのみ許可）
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/litenote/dev/dynamodb/table_name"
      },
      # ✅ Secrets Manager（対象Secretのみ許可）
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:dev/litenote/api_key*"
      }
    ]
  })
}




