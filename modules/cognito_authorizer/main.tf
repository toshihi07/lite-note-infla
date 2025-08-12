resource "aws_api_gateway_authorizer" "this" {
  name            = var.authorizer_name
  rest_api_id     = var.api_id
  identity_source = "method.request.header.Authorization"
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [var.user_pool_arn]
}
