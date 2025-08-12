# 🔧 SSM Parameter Store Module

このモジュールは **LiteNote** プロジェクトで使用する **構成情報（例：DynamoDBテーブル名）** を AWS Systems Manager (SSM) Parameter Store で安全に管理するための構成を提供します。

---

## 📌 作成されるリソース

| リソース | 説明 |
|----------|------|
| `aws_ssm_parameter` | DynamoDBテーブル名など環境設定値を格納する Parameter Store |
| `output` | Lambda など他モジュールから参照可能な SSM パラメータ名 |

---

## 📁 ファイル構成

modules/ssm_parameter/
├── main.tf # SSM Parameter Store リソース定義
├── variables.tf # 環境名・テーブル名などの変数
└── outputs.tf # Lambdaから参照可能なパラメータ名を出力

### 1. **モジュール呼び出し（例：`environments/dev/main.tf`）**

module "ssm_parameter" {
  source      = "../../modules/ssm_parameter"
  environment = "dev"
  table_name  = "lite_note_items"
}

## Lambdaから参照

environment {
  variables = {
    TABLE_NAME_PARAM = module.ssm_parameter.ssm_table_name
  }
}

🔑 出力される値（outputs）
Output	
ssm_table_name	DynamoDBテーブル名を格納した SSM パラメータの名前

📜 変数（variables）
変数名	型	必須	説明
environment	string	✅	環境名（例：dev）
table_name	string	✅	DynamoDBテーブル名
