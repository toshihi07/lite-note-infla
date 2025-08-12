resource "aws_api_gateway_rest_api" "this" {
  name = var.api_name
}

resource "aws_api_gateway_resource" "hello" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  parent_id   = aws_api_gateway_rest_api.this.root_resource_id
  path_part   = "hello"
}

resource "aws_api_gateway_method" "get" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "GET"
  authorization = var.authorizer_id != null ? "COGNITO_USER_POOLS" : "NONE"
  authorizer_id = var.authorizer_id # 👈 Cognito オーソライザーの ID を指定
}

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.hello.id
  http_method             = aws_api_gateway_method.get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

resource "aws_api_gateway_stage" "this" {
  stage_name    = "dev"
  rest_api_id   = aws_api_gateway_rest_api.this.id
  deployment_id = aws_api_gateway_deployment.this.id
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format          = "$context.identity.sourceIp - $context.requestId - $context.status"
  }

  xray_tracing_enabled = true

  # 追加: ログレベル設定
  variables = {
    loglevel = "INFO"
  }

  # 👇 CloudWatch Logs ロールが必ず先に設定されるよう依存関係を追加
  depends_on = [
    aws_api_gateway_account.account
  ]
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  stage_name  = aws_api_gateway_stage.this.stage_name

  method_path = "*/*" # 全メソッド対象

  settings {
    metrics_enabled    = true
    logging_level      = "INFO" # 実行ログを有効化
    data_trace_enabled = true   # リクエスト/レスポンス詳細ログ
  }
}


resource "aws_cloudwatch_log_group" "api_gateway" {
  name = "/aws/apigateway/litenote-dev"
}

resource "aws_iam_role" "apigateway_cloudwatch" {
  name = "APIGatewayCloudWatchLogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "apigateway.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "apigateway_cloudwatch" {
  role       = aws_iam_role.apigateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = aws_iam_role.apigateway_cloudwatch.arn
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_name
  principal     = "apigateway.amazonaws.com"

  # API Gateway の REST API ARN を指定
  source_arn = "${aws_api_gateway_rest_api.this.execution_arn}/*/*"
}

#############################################
# ✅ CORS対応: OPTIONS メソッドを追加
#############################################

# OPTIONS メソッドを作成（プリフライトリクエスト用）
resource "aws_api_gateway_method" "options" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "OPTIONS" # CORSプリフライト用メソッド
  authorization = "NONE"    # OPTIONSは認証不要
}

# OPTIONS メソッド用のMOCK統合（Lambda呼び出し不要）
resource "aws_api_gateway_integration" "options" {
  rest_api_id       = aws_api_gateway_rest_api.this.id
  resource_id       = aws_api_gateway_resource.hello.id
  http_method       = aws_api_gateway_method.options.http_method
  type              = "MOCK" # モック統合で即200を返す
  request_templates = { "application/json" = "{\"statusCode\":200}" }
}

# OPTIONS レスポンスの定義（レスポンスヘッダーを設定可能にする）
resource "aws_api_gateway_method_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.hello.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  # ✅ ブラウザに返すヘッダーを許可
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
  }
}

# OPTIONS メソッドの統合レスポンス（実際にヘッダーを付与）
resource "aws_api_gateway_integration_response" "options" {
  rest_api_id = aws_api_gateway_rest_api.this.id
  resource_id = aws_api_gateway_resource.hello.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = aws_api_gateway_method_response.options.status_code

  # ✅ CORSレスポンスヘッダーを追加
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'https://static.litenote.click'"       # フロントエンドのオリジン
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"  # Authorizationヘッダーを許可
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,POST,DELETE,PUT'" # 許可するHTTPメソッド
  }
}

#############################################
# ✅ 既存の GET メソッドにも CORSレスポンスを追加
#############################################

# GET メソッドのレスポンス設定（CORSヘッダー許可）→　Lambdaプロキシ統合では不要
# resource "aws_api_gateway_method_response" "get_cors" {
#   rest_api_id = aws_api_gateway_rest_api.this.id
#   resource_id = aws_api_gateway_resource.hello.id
#   http_method = aws_api_gateway_method.get.http_method # 既存GETメソッドを参照
#   status_code = "200"

#   response_models = {
#     "application/json" = "Empty"
#   }

#   # ✅ GETレスポンスにもCORS用のヘッダーを定義
#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Origin"  = true
#     "method.response.header.Access-Control-Allow-Headers" = true
#     "method.response.header.Access-Control-Allow-Methods" = true
#   }
# }

# # GET メソッドの統合レスポンス（実際にCORSヘッダーを付与）
# resource "aws_api_gateway_integration_response" "get_cors" {
#   rest_api_id = aws_api_gateway_rest_api.this.id
#   resource_id = aws_api_gateway_resource.hello.id
#   http_method = aws_api_gateway_method.get.http_method
#   status_code = aws_api_gateway_method_response.get_cors.status_code

#   # ✅ ブラウザがCORSチェックを通過できるようヘッダーを設定
#   response_parameters = {
#     "method.response.header.Access-Control-Allow-Origin"  = "'http://localhost:3000'" # SPAのURLを指定
#     "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'" # JWT用Authorizationを許可
#     "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,POST,DELETE,PUT'" # 使うHTTPメソッドを指定
#   }
# }

#############################################
# ✅ Gateway Response for 401 Unauthorized (CORS対応)
#############################################

resource "aws_api_gateway_gateway_response" "unauthorized" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  response_type = "UNAUTHORIZED" # 401 Unauthorized のレスポンスをカスタマイズ

  status_code = "401"

  # ✅ 401レスポンスにCORSヘッダーを追加
  response_parameters = {
    # "gatewayresponse.header.Access-Control-Allow-Origin"  = "'http://localhost:3000'"
    "gatewayresponse.header.Access-Control-Allow-Origin"  = "'https://static.litenote.click'"
    "gatewayresponse.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "gatewayresponse.header.Access-Control-Allow-Methods" = "'OPTIONS,GET,POST,DELETE,PUT'"
  }

  # ✅ 必要に応じてカスタムメッセージも設定可能
  response_templates = {
    "application/json" = "{\"message\":$context.error.messageString}"
  }
}

#############################################
# ✅ POST メソッドと Lambda 統合を追加
#############################################

resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "POST"
  authorization = var.authorizer_id != null ? "COGNITO_USER_POOLS" : "NONE"
  authorizer_id = var.authorizer_id
}

resource "aws_api_gateway_integration" "post_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.hello.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

#############################################
# ✅ PUT メソッド
#############################################
resource "aws_api_gateway_method" "put" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "PUT"
  authorization = var.authorizer_id != null ? "COGNITO_USER_POOLS" : "NONE"
  authorizer_id = var.authorizer_id
}

resource "aws_api_gateway_integration" "put_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.hello.id
  http_method             = aws_api_gateway_method.put.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

#############################################
# ✅ DELETE メソッド
#############################################
resource "aws_api_gateway_method" "delete" {
  rest_api_id   = aws_api_gateway_rest_api.this.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "DELETE"
  authorization = var.authorizer_id != null ? "COGNITO_USER_POOLS" : "NONE"
  authorizer_id = var.authorizer_id
}

resource "aws_api_gateway_integration" "delete_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.this.id
  resource_id             = aws_api_gateway_resource.hello.id
  http_method             = aws_api_gateway_method.delete.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_invoke_arn
}

#############################################
# ✅ デプロイメントに依存関係追加
#############################################
resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = { redeploy = timestamp() }

  lifecycle { create_before_destroy = true }

  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.post_lambda,
    aws_api_gateway_integration.put_lambda,    # ✅ 追加
    aws_api_gateway_integration.delete_lambda, # ✅ 追加
    aws_api_gateway_method.options,
    aws_api_gateway_integration.options
  ]
}


