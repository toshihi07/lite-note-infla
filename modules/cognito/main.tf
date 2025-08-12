resource "aws_cognito_user_pool" "this" {
  name = var.user_pool_name

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_client" "this" {
  name         = var.client_name
  user_pool_id = aws_cognito_user_pool.this.id

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes = [
    "email",
    "openid",
    "profile"
  ]
  supported_identity_providers = ["COGNITO"]
  enable_token_revocation      = true

  callback_urls = [
    "https://static.litenote.click/callback/",
    "http://localhost:3000/callback/"
  ]
  logout_urls = [
    "https://static.litenote.click/logout/",
    "http://localhost:3000/logout/"
  ]
  generate_secret = false
}

resource "aws_cognito_user_pool_domain" "this" {
  count        = var.domain_prefix != "" ? 1 : 0
  domain       = var.domain_prefix
  user_pool_id = aws_cognito_user_pool.this.id
}
