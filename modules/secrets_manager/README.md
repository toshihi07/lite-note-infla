# 🔐 Secrets Manager Module

このモジュールは **LiteNote** プロジェクトで使用する **APIキーやDB認証情報などの機密情報** を AWS Secrets Manager で安全に管理するための構成を提供します。

---

## 📌 作成されるリソース

| リソース | 説明 |
|----------|------|
| `aws_secretsmanager_secret` | APIキーやDBパスワードなどの秘密情報を保存 |
| `aws_secretsmanager_secret_version` | Secrets のバージョン管理 |
| `output` | Lambda など他モジュールから参照可能な Secret ARN |

---

## 📁 ファイル構成

├── main.tf # Secrets Manager リソース定義
├── variables.tf # 環境名・シークレット値
└── outputs.tf # Lambdaから参照可能なSecret ARNを出力

### 1. **モジュール呼び出し（例：`environments/dev/main.tf`）**

```hcl
module "secrets_manager" {
  source        = "./modules/secrets_manager"
  environment   = "dev"
  api_key_value = "your-secret-api-key"
}


