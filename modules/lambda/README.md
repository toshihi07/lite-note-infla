# Lambda モジュール

このモジュールは AWS Lambda 関数を作成し、API Gateway などから呼び出せるように構成します。  
簡単な `hello` 関数（Node.js）を想定しており、IAM ロールやログ出力権限も含めて定義されます。

---

## 📦 作成されるリソース

- `aws_lambda_function`：Lambda 関数本体
- `aws_iam_role`：実行ロール（Lambda に必要な最小権限）
- `aws_iam_role_policy_attachment`：CloudWatch Logs 権限付与

---

## 🔧 入力変数（`variables.tf`）

| 名前         | 型     | 説明                                      | 必須 |
|--------------|--------|-------------------------------------------|------|
| `lambda_name`| string | Lambda 関数の名前（例：`hello-lambda`）   | ✅   |

---

## 📤 出力値（`outputs.tf` で定義想定）

| 名前               | 説明                          |
|--------------------|-------------------------------|
| `function_name`     | 作成された Lambda 関数名        |
| `lambda_invoke_arn` | API Gateway 連携用の Invoke ARN |

---

## 🧪 動作確認方法

1. Lambda 関数用の ZIP ファイルを準備（例：`lambda.zip`）
    - `index.js` の中身の例（Node.js）：

    ```js
    exports.handler = async () => ({
      statusCode: 200,
      body: JSON.stringify({ message: "Hello from Lambda!" })
    });
    ```

2. Terraform 実行

    ```bash
    terraform init
    terraform apply -var-file=terraform.tfvars
    ```

3. CloudWatch Logs で出力確認（`/aws/lambda/<関数名>`）

---

## ✅ 注意事項

- Lambda 関数は ZIP 形式で `filename` に指定されたパス（例：`lambda.zip`）に置く必要があります。
- ハンドラーは `index.handler` を想定しています。
- ロールには CloudWatch Logs 出力権限（AWSLambdaBasicExecutionRole）をアタッチしています。



invoke_arn とは、他のサービス（例：API Gateway）が Lambda を呼び出す（invoke）ために使う特別な ARN です。


✅ 理由：Terraformのモジュールキャッシュの仕様
Terraformは、source に指定したモジュールの内容を .terraform/modules/ にキャッシュします。

以前 terraform init を実行したときの modules/lambda の内容をキャッシュしている

その後、modules/lambda の内容を変更（変数やコード修正）した

さらに source のパス（../../modules/lambda）が変わった、もしくは
Terraformが差分を検知した場合、再初期化が必要になります

✅ なぜinitで解決できるのか？
terraform init は：

モジュールの依存関係を再取得・再キャッシュする

ローカルの変更を反映する

よって、モジュールを編集したら一度 terraform init してキャッシュを更新する必要があります。

✅ 対応コマンド
terraform init -upgrade
-upgrade をつけるとモジュールキャッシュを確実に更新します。

  terraform apply -var-file=environments/dev/terraform.tfvars

  
✅ 学んだこと
AWS Lambda Javaは「Jarを直接アップロード」が正解。

terraform apply -replace="module.lambda.aws_lambda_function.this" -var-file=environments/dev/terraform.tfvars

・モジュール内部（modules/lambda/main.tf）では module.ssm や module.secrets_manager は参照できません。
Terraformの仕様として、モジュール間の直接参照はできないためです。

そのため、呼び出し元（ルートモジュール）で

module.ssm_parameter.ssm_table_name

module.secrets_manager.secret_api_key_arn
を lambda モジュールに変数として渡す必要があります。


