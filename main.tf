terraform {
  required_version = ">= 1.3.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# デフォルトプロバイダー（東京リージョン想定）
provider "aws" {
  region = "ap-northeast-1"
}

# バージニア北部リージョン（CloudFront / ACM 用）
provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

data "aws_route53_zone" "this" {
  name         = "litenote.click"
  private_zone = false
}

module "acm" {
  source         = "./modules/acm"
  domain_name    = var.domain_name
  hosted_zone_id = data.aws_route53_zone.this.zone_id

  providers = {
    aws = aws.virginia # ← この "aws" が module 側の "provider = aws" に対応
  }

}

module "cloudfront_static_site" {
  source = "./modules/cloudfront_static_site"

  bucket_name         = "static.litenote.click"
  domain_name         = "static.litenote.click"
  acm_certificate_arn = module.acm.certificate_arn
}

module "s3_static_site" {
  source                      = "./modules/s3_static_site"
  bucket_name                 = "static.litenote.click"
  cloudfront_distribution_arn = module.cloudfront_static_site.cloudfront_distribution_arn
  bucket_policy_json          = module.cloudfront_static_site.bucket_policy_json
}


resource "aws_route53_record" "cloudfront_alias" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = "static"
  type    = "A"

  alias {
    name                   = module.cloudfront_static_site.cloudfront_domain_name
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}

module "cognito" {
  source         = "./modules/cognito"
  user_pool_name = "litenote-userpool"
  client_name    = "litenote-client"
  domain_prefix  = "litenote-auth" # 任意、空でもOK
}

module "lambda" {
  source          = "./modules/lambda"
  lambda_name     = "lite-note-backend"
  region          = var.region                                              # ✅ 追加
  lambda_jar_path = "../lite-note-backend/target/lite-note-backend-fat.jar" # ✅ Jarを直接指定
  # ✅ DynamoDB モジュールの出力を渡す
  table_name = module.dynamodb.table_name
  # ✅ SSM と Secrets の値を渡す
  table_name_param   = module.ssm_parameter.ssm_table_name
  secret_api_key_arn = module.secrets_manager.secret_api_key_arn
}

module "api_gateway" {
  source            = "./modules/api_gateway"
  api_name          = "my-protected-api"
  lambda_invoke_arn = module.lambda.invoke_arn
  authorizer_id     = module.cognito_authorizer.authorizer_id # 👈 ここで接続
  region            = var.region
  lambda_name       = module.lambda.lambda_name
}

module "cognito_authorizer" {
  source          = "./modules/cognito_authorizer"
  authorizer_name = "lite-authz"
  api_id          = module.api_gateway.api_id
  user_pool_arn   = module.cognito.user_pool_arn
}

module "dynamodb" {
  source     = "./modules/dynamodb"
  table_name = "lite_note_items"
}

module "cloudwatch_sns" {
  source      = "./modules/cloudwatch_sns"
  lambda_name = module.lambda.lambda_name
  alert_email = "toshihi0717@gmail.com"
}

module "ssm_parameter" {
  source      = "./modules/ssm"
  environment = "dev"
  table_name  = "lite_note_items"
}

module "secrets_manager" {
  source        = "./modules/secrets_manager"
  environment   = "dev"
  api_key_value = "my-secret-api-key"
}


