# 🌐 LiteNote Infrastructure (Terraform)

LiteNote は、習慣管理・日記・ToDo が一体となった個人向け生産性アプリです。  
本リポジトリは、LiteNote の AWS サーバーレスインフラを Terraform によりコード化したものです。

---

## 📐 アーキテクチャ概要

AWS サーバーレス構成を Terraform で定義し、以下のリソースを構築します：

- VPC（Lambda 実行用／Private Subnet 設計）
- S3 + CloudFront（SPA ホスティング／WAF 付き）
- ACM（独自ドメイン対応）
- Route53（DNS 管理）
- Cognito（ユーザー認証）
- API Gateway + Lambda（バックエンド API）
- DynamoDB（ToDo／日記／習慣の保存）
- CloudWatch Logs + SNS（監視・通知）
- SSM Parameter Store / Secrets Manager（機密情報管理）

---

## 🗂️ ディレクトリ構成

lite-note-infra/
├── main.tf
├── variables.tf
├── outputs.tf
├── backend.tf
├── environments/
│ └── dev/
│ └── terraform.tfvars # 値を外部化した変数定義（.gitignore 推奨）
├── modules/
│ ├── vpc/
│ ├── s3/
│ ├── cloudfront/
│ ├── acm/
│ ├── route53/
│ ├── cognito/
│ ├── api_gateway/
│ ├── lambda/
│ ├── dynamodb/
│ ├── waf/
│ ├── cloudwatch/
│ └── sns/
└── README.md  
└── README.md  
└── README.md  
└── README.md  
└── README.md

## 各ファイルの役割と定義内容

| ファイル名           | 内容（定義すべきもの）                                                       |
| -------------------- | ---------------------------------------------------------------------------- |
| **main.tf**          | 各モジュールの呼び出し・AWS プロバイダーの指定・リージョン設定など           |
| **variables.tf**     | 外部から受け取る変数の定義（例：環境名、VPC CIDR、ドメイン名）               |
| **outputs.tf**       | モジュールから出力された値の定義（例：ALB DNS 名、S3 バケット名）            |
| **backend.tf**       | Terraform ステートの保存先を定義（例：S3 バケット＋ DynamoDB ロック）        |
| **terraform.tfvars** | `variables.tf` に定義した変数の値を実際に指定するファイル（.gitignore 推奨） |

🧱 モジュール構成（modules/以下）
| ディレクトリ | 内容（定義するリソース） |
| ----------------- | -------------------------------------------------- |
| `vpc/` | VPC 本体、サブネット、ルートテーブル、Internet Gateway、NAT Gateway など |
| `security_group/` | 各種 Security Group（ALB 用、ECS 用、Lambda 用、RDS 用など） |
| `alb/` | ALB + TargetGroup + Listener、HTTPS 設定 |
| `ecs/` | ECS Cluster, Service, Task Definition、必要な IAM ロール |
| `s3/` | 静的サイトホスティング用の S3 バケット（フロントエンド） |
| `cloudfront/` | CloudFront ディストリビューションと S3 の連携、ACM 証明書 |
| `acm/` | TLS 証明書（ACM）の取得、Route53 との連携（DNS 検証） |
| `route53/` | Hosted Zone、A/AAAA/CNAME などの DNS レコード設定 |
| `cognito/` | Cognito User Pool, Client, Domain など |
| `lambda/` | Lambda 関数、IAM ロール、API Gateway 連携（必要に応じて） |
| `dynamodb/` | DynamoDB テーブルとその設定（PK/SK/TTL など） |
| `monitoring/` | WAF の WebACL、CloudWatch Logs、SNS 通知設定など |

## 事前準備

- [x] Terraform v1.5 以上（`tfenv` 推奨）
- [x] AWS でユーザー作成し、アクセスキーとシークレットアクセスキーを払い出す。
- [x] 上記ユーザーを AWS CLI で設定済み（`aws configure`）
- [x] ドメイン名（お名前.com 等で取得済み）
- [x] WSL / Linux 上の作業を推奨

## 初期化

```bash
cd environments/dev
terraform init

terraform plan -var-file="terraform.tfvars"
terraform apply -var-file="terraform.tfvars"

## 開発環境について

作業は WSL上のLinuxファイルシステム上（例：~/projects/litenote） で行うこと

terraform.tfvars に環境変数を明記して、dev／prodを切り替え可能

##  開発者向けメモ
各 modules/ 配下のコードは再利用可能な構成単位

IAMポリシーは最小権限原則（PoLP）で設計

terraform-docs を使ってドキュメントを自動生成可
```

✅ 作業の進め方
Route53・ACM から始める（独自ドメイン取得＆HTTPS 準備）

S3 と CloudFront → SPA のデプロイ先を先に確保

Cognito と API Gateway の連携構成

Lambda と DynamoDB → 後で Spring Boot を載せる土台を作る

WAF と CloudWatch Logs/SNS → 最後に追加してセキュリティ・監視強化

優先度 リソース 理由／備考
① Route53 独自ドメインが必要。ACM や CloudFront に紐づく
② ACM（証明書） HTTPS 用。CloudFront や API Gateway に使う（※バージニアリージョン）
③ S3 SPA（Next.js）静的ファイルの配信用
④ CloudFront S3 に紐づけて CDN 構成／WAF もここに適用
⑤ WAF CloudFront にアタッチ。IP 制限や Bot 対策など
⑥ Cognito 認証まわり。UserPool / Client 設定など
⑦ API Gateway Lambda と繋ぐ REST エンドポイント／Cognito 連携あり
⑧ Lambda（空関数） バックエンドの受け皿。後でコードと連携
⑨ DynamoDB ToDo / 日記 / 習慣などのデータ保存用
⑩ SSM Parameter Store／Secrets Manager API キーや環境変数の管理に使用
⑪ CloudWatch Logs / SNS ログ記録・通知用。必要に応じて後付け可能

# lite-note-infra: Terraform 構成リファクタリング後の README

本プロジェクトでは、Terraform を用いた AWS サーバーレスアーキテクチャを構築しています。
各種リソースを module に分割し、環境毎の切り替え・再利用・保守性を高める構成としています。

## 📁 ディレクトリ構成

```
lite-note-infra/
├── main.tf                  # module呼び出し・data定義（Hosted Zoneなど）
├── variables.tf            # 共通の入力変数定義
├── outputs.tf              # 共通の出力変数定義
├── backend.tf              # Terraformのバックエンド定義（S3 + DynamoDBロック）
├── environments/
│   └── dev/
│       └── terraform.tfvars   # 各環境用の変数ファイル（gitignore推奨）
├── modules/                # リソース単位で分割した構築定義
│   ├── vpc/
│   ├── s3/
│   ├── cloudfront/
│   ├── acm/
│   ├── route53/
│   ├── cognito/
│   ├── api_gateway/
│   ├── lambda/
│   ├── dynamodb/
│   ├── waf/
│   ├── cloudwatch/
│   └── sns/
└── README.md
```

## 🔁 リファクタリング方針

### ✅ `data`ブロック（参照）は module 内に閉じ込めず、`main.tf` に集約

- 例：`data "aws_route53_zone" "this"` は `main.tf` にて定義し、module に `hosted_zone_id` として渡す
- 理由：他のモジュール（ACM・CloudFront など）と共有する可能性があるため

```hcl
# main.tf

data "aws_route53_zone" "this" {
  name         = "litenote.click"
  private_zone = false
}

module "route53" {
  source      = "./modules/route53"
  domain_name = var.domain_name
}

module "acm" {
  source          = "./modules/acm"
  domain_name     = var.domain_name
  hosted_zone_id  = data.aws_route53_zone.this.zone_id
}
```

## 🧪 実行コマンド

```bash
cd lite-note-infra
terraform init
terraform plan -var-file=environments/dev/terraform.tfvars
terraform apply -var-file=environments/dev/terraform.tfvars
```

## 📝 注意点

- `terraform.tfvars` には秘匿情報を含める場合があるため `.gitignore` に登録してください
- Terraform Cloud や CI/CD 導入時は `backend.tf` のリモートバックエンドに切り替えることも検討

---

次は `modules/route53/` 以下に不要となった `data "aws_route53_zone"` の削除と `variables.tf` の整理を行いましょうか？
