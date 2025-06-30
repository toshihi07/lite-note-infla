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
  source          = "./modules/acm"
  domain_name     = var.domain_name
  hosted_zone_id  = data.aws_route53_zone.this.zone_id

    providers = {
    aws = aws.virginia  # ← この "aws" が module 側の "provider = aws" に対応
  }
  
}

