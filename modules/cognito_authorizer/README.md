# Cognito オーソライザーモジュール

このモジュールは API Gateway に対して Cognito User Pool を用いたオーソライザー（Authorizer）を作成します。  
これにより、API Gateway のエンドポイントにアクセスする前に **Cognito で発行されたトークンの検証**が行われます。

---

## 📦 作成されるリソース

- `aws_api_gateway_authorizer`：Cognito User Pool に基づく認証オーソライザー

---

## 🔧 入力変数（`variables.tf`）

| 名前           | 型     | 説明                                                           | 必須 |
|----------------|--------|----------------------------------------------------------------|------|
| `name`         | string | オーソライザーの名前（例：`CognitoAuthorizer`）                 | ✅   |
| `rest_api_id`  | string | 対象となる API Gateway REST API の ID                           | ✅   |
| `user_pool_arn`| string | 認証に使用する Cognito User Pool の ARN                         | ✅   |

---

## 📤 出力値（`outputs.tf` で定義想定）

| 名前          | 説明                            |
|---------------|---------------------------------|
| `id`          | 作成されたオーソライザーの ID   |

---

## 🧪 使用例（他モジュールからの呼び出し）

```hcl
module "authorizer" {
  source        = "../../modules/cognito_authorizer"
  name          = "CognitoAuthorizer"
  rest_api_id   = module.api_gateway.rest_api_id
  user_pool_arn = data.aws_cognito_user_pool.this.arn
}

その後、aws_api_gateway_method で次のように指定：
authorization = "COGNITO_USER_POOLS"
authorizer_id = module.authorizer.id


✅ 注意事項
identity_source は method.request.header.Authorization に固定されています。

このモジュール単体では認証を強制しません。API Gateway 側でオーソライザーを適用する必要があります。

user_pool_arn の取得には data "aws_cognito_user_pool" を併用することを推奨します。