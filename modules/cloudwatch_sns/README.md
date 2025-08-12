# 📡 CloudWatch Logs + SNS 通知モジュール

## ✅ 概要
このモジュールは **AWS Lambda のエラーログを CloudWatch Logs で検出し、SNS 経由でメール通知**します。  
CloudWatch Metric Alarm を使用して、Lambda のエラー発生時に自動で通知が送信されます。

---

## 📂 作成されるリソース
| リソース | 説明 |
|----------|------|
| `aws_sns_topic.lambda_error` | Lambda エラーログ通知用 SNS トピック |
| `aws_sns_topic_subscription.lambda_error_email` | 通知用メールアドレスの SNS サブスクリプション |
| `aws_cloudwatch_log_metric_filter.lambda_error_filter` | Lambda エラーログ ("ERROR") 検出用メトリクスフィルター |
| `aws_cloudwatch_metric_alarm.lambda_error_alarm` | Lambda エラー検出時に SNS 通知を送信する CloudWatch アラーム |

---

## ⚙️ 入力変数
| 変数名        | 型     | 必須 | 説明 |
|---------------|--------|------|------|
| `lambda_name` | string | ✅   | 監視対象の Lambda 関数名 |
| `alert_email` | string | ✅   | 通知を受け取るメールアドレス |

---

## 📤 出力値
| 出力名 | 説明 |
|--------|------|
| `sns_topic_arn` | 作成された SNS トピックの ARN |

---

## 🚀 使用例
```hcl
module "cloudwatch_sns" {
  source       = "../../modules/cloudwatch_sns"
  lambda_name  = module.lambda.lambda_name
  alert_email  = "your-email@example.com"
}


✅ LiteNote バックエンド（AWS Lambda + API Gateway + DynamoDB）構築で学んだこと・詰まったことまとめ
1. Lambda Java (Maven) デプロイの基本
🔹 詰まったこと
Lambda にアップロードするファイルとして zip を使用していたが、ClassNotFoundException が発生。

maven-shade-plugin で fat jar (依存関係込みの jar) を正しく生成できていなかった。

🔹 解消手順
pom.xml に maven-shade-plugin を正しく設定し、finalName を明示。

mvn clean package で fat jar を生成。

terraform では filename に jar を直接指定。

hcl
コピーする
編集する
filename         = var.lambda_jar_path
source_code_hash = filebase64sha256(var.lambda_jar_path)
handler は **完全修飾名（com.litenote.lambda.Handler::handleRequest）**を指定。

✅ 学び
AWS Lambda Java では zip に jar を含める必要はなく、jar 単体をデプロイすればよい。

ClassNotFoundException は jar 内にクラスが含まれていない or handler が間違っている場合に発生。

2. API Gateway + Lambda 連携
🔹 詰まったこと
API Gateway のデプロイ時に

kotlin
コピーする
編集する
Active stages pointing to this deployment must be moved or deleted
が発生。

🔹 解消手順
aws_api_gateway_deployment に

hcl
コピーする
編集する
lifecycle {
  create_before_destroy = true
}
を追加し、既存ステージ削除の前に新しいデプロイを作成。

✅ 学び
API Gateway では deployment と stage の役割を分けて理解する必要がある。

deployment → Lambda 連携のバージョン（静的スナップショット）

stage → deployment を公開する環境（dev, prod など）

3. DynamoDB 接続
🔹 詰まったこと
GET の際に "Item not found" が頻発。

userId が anonymous となり、DynamoDB のキー不一致が発生。

🔹 解消手順
Lambda 内で Cognito Authorizer から sub を取得する処理を追加。

DynamoDB の PK = userId, SK = itemId で一意管理。

✅ 学び
API Gateway の Lambda Proxy 統合では Cognito の sub が requestContext.authorizer.claims に含まれる。

4. PUT / DELETE 実装の課題
🔹 詰まったこと
PUT で "Missing parameters" エラー発生。

🔹 解消手順
API Gateway 経由では Body が JSON 文字列として渡されるため、Lambda 側で extractBodyField でパース。

Query Param は queryStringParameters から抽出。

✅ 学び
Lambda Proxy Integration ではリクエスト形式が

json
コピーする
編集する
{
  "httpMethod": "PUT",
  "queryStringParameters": { "itemId": "xxx" },
  "body": "{\"title\":\"new\"}"
}
となるため、query と body を個別に処理する必要がある。

5. Cognito 認証 & トークン検証
🔹 詰まったこと
Authorization ヘッダーの形式エラー
"Invalid key=value pair (missing equal-sign)" が発生。

🔹 解消手順
curl で Bearer トークンを渡す際は ダブルクォート不要。

bash
コピーする
編集する
curl -H "Authorization: Bearer $TOKEN" ...
✅ 学び
PKCE フローを正しく実装し、id_token を API Gateway の COGNITO_USER_POOLS 認証に利用。

6. CloudWatch Logs + SNS 通知（今後の予定）
Lambda のエラーログを CloudWatch → SNS で通知予定。

API Gateway のアクセスログを CloudWatch に記録し、分析可能にする。

7. SSM Parameter Store / Secrets Manager（今後の予定）
DynamoDB の TABLE_NAME など環境変数を SSM Parameter Store で管理予定。

Secrets は Secrets Manager で安全に保管。


✅ まとめ
Lambda Java は fat.jar を直接アップロードするのが正解。

API Gateway の deployment と stage の仕組みを理解する必要がある。

Cognito 認証 → Lambda で sub を userId に使用が正しいパターン。

CRUD 全実装完了し、DynamoDB 連携動作確認済み。

次は CloudWatch + SNS + SSM を追加して監視・セキュリティを強化予定。

👉 このまとめは、新チャット移行時に参照しやすい完全版です。