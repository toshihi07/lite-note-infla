# API Gateway モジュール（Cognito認証付き）

このモジュールは AWS API Gateway の REST API を作成し、Cognito User Pool を使用した認証機能を付加します。

---

## 📦 作成されるリソース

- `aws_api_gateway_rest_api`：REST API 本体
- `aws_api_gateway_resource`：`/hello` エンドポイント
- `aws_api_gateway_method`：HTTP メソッド（GET）
- `aws_api_gateway_integration`：Lambda 連携（AWS_PROXY）
- `aws_api_gateway_authorizer`（別モジュール）：Cognito オーソライザーと連携
- `aws_api_gateway_deployment`：ステージ（`/dev`）のデプロイ

---

## 🔧 入力変数（`variables.tf`）

| 名前               | 型     | 説明                                         | 必須 |
|--------------------|--------|----------------------------------------------|------|
| `api_name`         | string | API Gateway の名前                           | ✅   |
| `lambda_invoke_arn`| string | 対象となる Lambda 関数の Invoke ARN          | ✅   |
| `authorizer_id`    | string | Cognito オーソライザーの ID                  | ✅   |

---

## 📤 出力値（`outputs.tf`）

| 名前       | 説明                              |
|------------|-----------------------------------|
| `api_id`   | 作成された API Gateway の ID       |
| `endpoint` | 呼び出し可能なエンドポイントURL    |

---

## 🧪 動作確認手順（ステージ: `dev`）

### ① アクセストークンを取得（Cognito Hosted UI → /oauth2/token）

### ② API エンドポイントにリクエスト

```bash
curl -H "Authorization: Bearer <access_token>" \
  https://<api_id>.execute-api.ap-northeast-1.amazonaws.com/dev/hello

✅ 注意事項
Cognito 認証を使うため、API 呼び出し時は必ず Authorization ヘッダーが必要です。

Lambda 関数は AWS_PROXY 統合方式でデプロイされている前提です。

Lambda や Authorizer モジュールと合わせて使用してください。



✅①「Lambda 関数は AWS_PROXY 統合方式でデプロイされている」とは？
🔧 意味：
「API Gateway が受け取った HTTP リクエスト全体を、JSON形式で Lambda にそのまま渡す方式」です。

📦 AWS_PROXY統合（＝Lambda プロキシ統合）の特徴
項目	内容
呼び出し形式	イベントとして event 引数に HTTPリクエスト全体が渡る
自由度	高い（すべて自前でレスポンスを組み立てられる）
レスポンス形式	JSON形式で statusCode, headers, body を Lambda 側で返す
フロントエンドとの連携	✅ 向いている（SPAやCORS対応など細かく制御できる）

🧪 Lambda 側の受け取り例（Node.js）
js
コピーする
編集する
exports.handler = async (event) => {
  console.log(event); // 全てのHTTP情報（path, query, headers, body）がここに入る

  return {
    statusCode: 200,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ message: "Hello from Lambda!" }),
  };
};
✅② REST API と HTTP API の違い（API Gateway）
AWS API Gateway には2種類あります：

項目	REST API（v1）	HTTP API（v2）
機能の充実度	✅ 高い（WAF, Cognitoオーソライザーなど）	限定的（WAF未対応、Cognito制約あり）
設定項目	複雑だが詳細に制御できる	シンプル
料金	やや高い	安い（30〜70% 安い）
対応オーソライザー	✅ IAM, Lambda, ✅ Cognito	✅ IAM, Lambda, ❌ Cognito（制限あり）
使用用途	認可・制御が必要な本格API	軽量API、Webhook受信、社内API

🧭 今回使うのはどっち？ → ✅ REST API
✔ 理由：
Cognitoオーソライザーを使いたい（HTTP APIは制限あり）

今後の拡張性（WAF、APIキー、ステージ変数など）を考慮

AWS_PROXY統合との相性がよく、柔軟なレスポンス制御ができる

🎯 まとめ
項目	今回の選択
API種別	✅ REST API
統合方式（Integration Type）	✅ AWS_PROXY（Lambdaプロキシ統合）
理由	Cognito認証＋柔軟なHTTP制御のため



✅ AWS_PROXY（Lambdaプロキシ統合）とは？
AWS API Gateway には統合タイプが複数ありますが、**AWS_PROXY（Lambdaプロキシ統合）**は最も一般的な方式です。

✅ Lambdaプロキシ統合の特徴
API Gateway → Lambda のリクエスト・レスポンスを そのまま渡す

Lambda のレスポンスに ステータスコード / ヘッダー / ボディを含める必要がある

API Gateway 側でレスポンスのマッピングを設定しなくても済む

 CORSプリフライトが発生する条件
ブラウザがプリフライト（OPTIONS）を送るのは、次の条件のいずれかを満たすときです：

カスタムヘッダー（例：Authorization）を送信する

GET/POST 以外のHTTPメソッド（PUT/DELETEなど）を使う

Content-Type が application/json 以外の特殊な値（例：text/xml）

Cookieを含むクロスオリジンリクエスト（withCredentialsがtrue）


✅ 適用手順
Terraformコードを追加

terraform apply

API Gateway再デプロイ（必須）

aws apigateway create-deployment \
  --rest-api-id mlxi90v6ah \
  --stage-name dev


ChatGPT:
✅ LiteNote（フロント + API Gateway + Cognito）構築まとめ
📌 1. やったことの流れ
Next.js SPAを作成し、Cognito（PKCE）認証を実装

API Gateway + Lambda + Cognito Authorizer 構成をTerraformでデプロイ

フロントエンド → API Gateway → Lambda の認証付き通信を構築

CORS / 認証 / デプロイ周りで複数のエラーを解決しながら完成

📌 2. 詰まったことと解決策
詰まったポイント	原因	解決策
CORSエラー（No 'Access-Control-Allow-Origin'）	API GatewayのOPTIONSレスポンスにCORSヘッダーがなかった	MOCK統合のOPTIONSメソッドをTerraformで追加し、CORSレスポンスを設定
API Gatewayから401 Unauthorized	id_tokenではなくaccess_tokenを送信していた	API GatewayのCognito Authorizerはid_tokenのaud検証に基づくため、id_tokenを使用するよう修正
再ログイン後も401	古いデプロイメントやキャッシュ	API Gatewayを強制再デプロイし、最新設定を反映
Cognito PKCEフロー invalid_grant	code_verifierの不一致	localStorageから正しいcode_verifierを保持・送信するよう修正
CloudFrontのAccessDenied	OAC設定後にS3バケットポリシーが未反映	terraform apply -target=module.s3_static_siteで依存関係を整理し解消

📌 3. 学んだこと
✅ API Gateway × Cognito Authorizer
標準ではid_tokenを期待 → audが一致するため認証が通る

access_tokenは署名検証で弾かれる場合が多い（aud検証を回避できない）

複数クライアント対応や柔軟な検証をしたい場合 → Lambda Authorizerを使う

✅ CORS
**ブラウザのプリフライト（OPTIONS）**が通らないとGET/POSTも失敗

Lambda Proxy統合（AWS_PROXY）ではCORSレスポンスをLambdaが返す必要がある

非Proxy統合ならintegration_response + method_responseでヘッダーを設定

✅ PKCE
code_verifier → フロントが生成し、トークン交換時に送信

code_challenge → verifierから派生し、認可サーバが検証

これによりクライアントシークレットなしでもセキュア

✅ 学習ポイント
AWS標準の構成はシンプルな分、柔軟性に欠ける（aud検証を緩和できない）

認証付きSPA → id_tokenを使うのが正しい選択

Terraformでは**apply後のデプロイ反映が必要なリソース（API Gatewayなど）**がある

✅ 最終成果
LiteNoteのフロントエンドはCognitoログイン後、id_tokenを使ってAPI Gatewayを認証付きで呼び出せる

CORSも完全に解決し、GET/POSTともに動作可能



📌 1. aws_api_gateway_deployment
**API Gateway のスナップショット（リリース版）**を表します。

リソース（パス）やメソッド、統合設定など 現在のAPI構成を固める役割。

新しいメソッドや統合を追加しても、Deploymentを作り直さない限り反映されない。

Terraformでは頻繁に再作成される → triggers や timestamp() で毎回新しいバージョンが作られる。

📌 2. aws_api_gateway_stage
どのDeploymentを公開するかを指定する エイリアス（環境）。

例: dev, staging, prod など。

Stage は常に Deployment を参照しており、どのバージョンを公開するかを切り替える。

✅ 依存関係の流れ
コピーする
編集する
リソース & メソッド → Deployment → Stage
Stage は 特定の Deployment を参照する

Deployment は API の状態を固めたスナップショット

Stage を削除せずに Deployment を削除すると Stage の参照が壊れる → エラーになる

✅ なぜ create_before_destroy = true が必要か？
Terraform はデフォルトで 「古いリソースを削除 → 新しいリソースを作成」 という順で動きます。

しかし Deployment は Stage に参照されているため、先に削除するとエラー。

create_before_destroy = true を付けると、

「新しい Deployment を作成 → Stage を新しいものに切り替え → 古い Deployment を削除」
という順になるので安全です。

🚩 OPTIONSメソッドとは？
OPTIONSメソッドとは、HTTPで提供されるメソメソッドの一種で、
サーバがサポートしているHTTPメソッド（GET, POST, PUTなど）や、
特定のリクエストを送信する際の許可設定を確認する目的で使用されます。

🚩 プリフライトリクエスト（Preflight request）とは？
CORS（Cross-Origin Resource Sharing） において、
ブラウザが実際のリクエスト（本番リクエスト）を送る前に、
『安全にそのリクエストを送っても良いかをサーバに事前確認する』リクエストです。

プリフライトリクエストは、OPTIONSメソッドで送信されます。

📌 プリフライトリクエストが必要になるケース
オリジン（ドメイン、ポート、プロトコル）が異なるサイトへリクエストする場合

特定の条件を満たした『単純でない』リクエストを送信する場合（POST＋JSON送信や、カスタムヘッダー使用など）

例:

JSONデータをPOSTする場合

認証用のカスタムヘッダーを送信する場合（例: X-Api-Key）

🔄 OPTIONSメソッド（プリフライト）の仕組み
ブラウザが特定のHTTPリクエストを送る前に、
以下のようなOPTIONSリクエストを送ります。

OPTIONS /api/items HTTP/1.1
Origin: https://example.com
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Content-Type, X-Api-Key
✅ サーバは以下のような応答を返します。

HTTP/1.1 204 No Content
Access-Control-Allow-Origin: https://example.com
Access-Control-Allow-Methods: GET,POST,OPTIONS
Access-Control-Allow-Headers: Content-Type, X-Api-Key
Access-Control-Max-Age: 3600
Access-Control-Allow-Origin

リクエスト許可されたオリジンを指定

Access-Control-Allow-Methods

利用可能なHTTPメソッドを指定

Access-Control-Allow-Headers

許可されたカスタムヘッダー

Access-Control-Max-Age

ブラウザがプリフライト結果をキャッシュする時間（秒単位）

この応答でブラウザが安全と判断すると、
実際のリクエスト（POSTなど）をサーバに送信します。

📌 なぜプリフライトが必要か？
CORSの仕組みでは、クロスオリジン通信に潜むリスクを軽減するため、
ブラウザが事前確認（プリフライト）で『許可されている通信か』を
サーバ側に確認し、安全性を確保しています。

もしプリフライトで許可されなければ、実際のリクエストはブラウザ側で中止されます。

💡 単純リクエスト（Simple Request）と比較
単純リクエストの場合は、プリフライトは行われず、直接リクエストが送信されます。

✅ 単純リクエストの条件:
HTTPメソッドが、GET、POST、HEAD のいずれか

Content-Typeヘッダーが以下のいずれか：

application/x-www-form-urlencoded

multipart/form-data

text/plain

この条件を満たさない場合は、プリフライト（OPTIONS）リクエストが必須です。