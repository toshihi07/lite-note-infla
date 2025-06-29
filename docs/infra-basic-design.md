1. 概要
   | 項目 | 内容 |
   | ----- | ----------------------------------------------------- |
   | システム名 | LiteNote |
   | 開発者 | \新町俊裕 |
   | 構成技術 | Terraform（IaC）、AWS、GitHub Actions（CI/CD） |
   | 目的 | サーバーレス構成のフルマネージドなポートフォリオ環境の構築 |
   | 特徴 | Next.js SPA + Lambda API + Cognito 認証 + セキュリティ強化（WAF 等） |

2. インフラ構成図（要件レベル）
   ユーザー
   ↓
   Route 53（独自ドメイン）
   ↓
   CloudFront（ACM 証明書付き）
   ↓
   S3（静的ホスティング） ＋ API Gateway（REST）
   ↓
   Lambda（Spring Boot）
   ↓
   DynamoDB

Cognito で認証 → JWT を付与し、API Gateway → Lambda → DynamoDB の流れで処理

3. モジュール構成
   | モジュール名 | 説明 |
   | ----------------- | --------------------------------------------- |
   | `vpc` | Lambda などの VPC 配置に必要な基礎 NW（Public/Private Subnet） |
   | `s3` | フロントエンド静的ファイルのホスティング先 |
   | `cloudfront` | CDN + HTTPS 配信のためのエンドポイント |
   | `acm` | SSL/TLS 証明書（CloudFront 用・バージニアリージョン） |
   | `route53` | 独自ドメインの DNS 管理 |
   | `cognito` | ログイン・サインアップなどの認証処理 |
   | `api_gateway` | REST エンドポイント構成（Cognito 連携） |
   | `lambda` | バックエンドアプリケーションをホスト（Spring Boot） |
   | `dynamodb` | ToDo／日記／習慣管理データの保存先 |
   | `waf` | CloudFront 配下に対してセキュリティルールを適用 |
   | `cloudwatch` | Lambda/API Gateway ログ収集 |
   | `sns` | 異常通知・監視（CloudWatch アラームの送信先） |
   | `ssm` / `secrets` | パラメータ・秘密情報の安全な管理 |

4. 環境
   | 項目 | 値 |
   | -------------- | ------------------------------------- |
   | リージョン | `ap-northeast-1`（東京） |
   | ドメイン名 | ``（予定） |
| Terraformバージョン | `1.5.x`以上                            |
| Terraform管理方式  |`S3 backend + DynamoDB lock`（予定） |
   | 作業環境 | WSL2 (Ubuntu) 上でのローカル開発を前提 |
   | CI/CD | GitHub Actions を使用予定（手動 apply も可能） |

5. セキュリティ設計
   | 項目 | 内容 |
   | ----- | ---------------------------------------- |
   | WAF | CloudFront にアタッチ。IP 制限・Bot 対策 |
   | HTTPS | ACM 証明書を用いた HTTPS 対応 |
   | 認証 | Cognito による JWT ベース認証 |
   | IAM | Lambda・API Gateway など最小権限 IAM ロールで構成 |
   | 機密情報 | SSM Parameter Store / Secrets Manager で管理 |

6. CI/CD 計画（構成例）
   | 対象 | ツール | 処理内容 |
   | -------- | ------------------ | ------------------------------------ |
   | frontend | GitHub Actions | S3 アップロード → CloudFront Invalidation |
   | backend | GitHub Actions | Lambda ビルド → ECR / ZIP デプロイ |
   | infra | GitHub Actions（予定） | `terraform plan` + `terraform apply` |

7. 保守運用設計
   | 項目 | 内容 |
   | ------ | -------------------------------------- |
   | ログ管理 | CloudWatch Logs に集約（Lambda/API Gateway） |
   | 監視 | CloudWatch アラーム → SNS で通知 |
   | 環境分離 | 今後 `dev`／`prod` 切り分けを想定し、構成を分離設計 |
   | ステート管理 | S3 バケットによる remote backend 使用予定 |

8. その他設計指針
   Terraform モジュール化で保守性・再利用性を高める

AWS リソースには明示的な Name タグを付与

terraform-docs による構成ドキュメント生成対応可

コスト意識：無料枠や最小構成を意識（Lambda, DynamoDB, CloudFront 無料枠あり）
