# 📌 DynamoDB Module

このモジュールは **AWS DynamoDB テーブル**を作成します。  
ToDo・日記・習慣などのデータ保存用として利用します。

---

## 🔧 **作成されるリソース**

| リソース            | 説明 |
|---------------------|------|
| `aws_dynamodb_table`| DynamoDB テーブル本体 |

---

## 📁 **入力変数**

| 変数名       | 型     | 必須 | デフォルト | 説明 |
|--------------|--------|------|------------|------|
| `table_name` | string | ✅   | なし       | 作成する DynamoDB テーブル名 |

---

## 📤 **出力値**

| 出力名      | 説明 |
|-------------|------|
| `table_name`| 作成されたテーブル名 |
| `table_arn` | 作成されたテーブルのARN |

---

## 🚀 **使用例**

```hcl
module "dynamodb" {
  source     = "./modules/dynamodb"
  table_name = "lite_note_items"
}
