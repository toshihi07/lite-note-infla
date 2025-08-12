✅ LiteNote（localhost）での Cognito 認証フロー（今回の構成）
あなたの環境では以下の構成で 認証 → ID Token 取得 が行われています。

🚩 1. SPA (Next.js) → Cognito Hosted UI にリダイレクト
フロントエンド（http://localhost:3000）が Cognito Hosted UI にリダイレクト

リクエストパラメータに含まれる：

response_type=code（認可コードを要求）

client_id=xxxx

redirect_uri=http://localhost:3000/callback

code_challenge=xxxx（PKCEのSHA256ハッシュ）

code_challenge_method=S256

👉 ここで SPA が code_verifier を生成し、LocalStorage（またはSessionStorage）に一時保存

🚩 2. Cognito Hosted UI → Googleログイン or Cognitoユーザ認証
ユーザーが Google か Cognito のユーザー名/パスワードでログイン

Cognito が認証成功後、認可コード（code） を SPA にリダイレクト

🚩 3. SPA (Next.js) ← 認可コードを受け取る
例:

bash
コピーする
編集する
http://localhost:3000/callback?code=abcd1234&state=xyz
SPA は LocalStorage に残っている code_verifier を読み出し、この後のトークン交換に使用

🚩 4. SPA → Cognito Token エンドポイントにトークン要求
SPA は code + code_verifier を POST で送信

Cognito が PKCEの検証を行う：

code_challenge と code_verifier が一致 → OK

🚩 5. Cognito → ID Token, Access Token, Refresh Token 発行
レスポンス例：

json
コピーする
編集する
{
  "id_token": "eyJraWQiOiJhbGciOi...",
  "access_token": "eyJraWQiOiJhbGciOi...",
  "refresh_token": "eyJjdHkiOiJKV1QiLC...",
  "expires_in": 3600,
  "token_type": "Bearer"
}
SPA は id_token を LocalStorage に保存（今回の fetchWithAuth で使用）

🚩 6. SPA → API Gateway に ID Token を付与してアクセス
API リクエスト例：

sql
コピーする
編集する
GET /hello
Authorization: Bearer <id_token>
API Gateway → CognitoオーソライザーでID Token検証 → Lambda 呼び出し

✅ LocalStorage の pkce_verifier が消えるとき
トークン交換完了後、ライブラリが自動で削除する場合

認証済みセッションが確立されており、再ログイン時はPKCEを再生成する場合

✅ まとめ（LiteNote 認証の流れ）
localhost SPA → Cognito Hosted UI → Google/Cognito認証

認可コード + PKCE → Cognito → トークン発行

SPA が ID Token を取得し LocalStorage に保存

API Gateway に Bearer 認証で ID Token を送信

API Gateway が Cognitoオーソライザーで検証 → Lambda 実行

