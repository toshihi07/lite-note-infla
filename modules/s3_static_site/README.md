# S3 Static Site Module

このモジュールは、React などの静的 Web サイトをホスティングするための **S3バケットとオプションのバケットポリシー** を管理します。  
CloudFront（OAC構成）と連携することで、セキュアな署名付きアクセスに対応可能です。

---

## 🔧 作成されるリソース

| リソース種類             | 説明                                                                  |
|--------------------------|-----------------------------------------------------------------------|
| `aws_s3_bucket`          | 静的サイトホスティング用のS3バケット                                 |
| `aws_s3_bucket_policy`   | CloudFront OAC用のバケットポリシー（`bucket_policy_json` が指定されている場合のみ） |

---

## 📥 入力変数（variables.tf）

| 変数名                        | 必須 | 説明                                                                 |
|-------------------------------|------|----------------------------------------------------------------------|
| `bucket_name`                 | ✅   | 作成するS3バケット名                                                 |
| `bucket_policy_json`          | ⛔/✅ | CloudFront OACからの署名付きアクセスを許可するポリシー（JSON文字列） |
| `cloudfront_distribution_arn`| ⛔/✅ | ポリシー内の `AWS:SourceArn` に使用するCloudFrontのARN               |

> `bucket_policy_json` と `cloudfront_distribution_arn` は CloudFrontモジュールの `output` を使用して渡すのが一般的です。

---

## 📤 出力値（outputs.tf）

| 出力名               | 説明                        |
|----------------------|-----------------------------|
| `s3_bucket_name`     | 作成されたS3バケットの名前 |
| `s3_bucket_arn`      | 作成されたS3バケットのARN  |
| `s3_bucket_policy_id`| バケットポリシーリソースのID（存在する場合） |

---

## 🧪 使用例（ルートモジュールから）

```hcl
module "s3_static_site" {
  source = "./modules/s3_static_site"

  bucket_name                 = "static.litenote.click"
  cloudfront_distribution_arn = module.cloudfront_static_site.cloudfront_distribution_arn
  bucket_policy_json           = module.cloudfront_static_site.bucket_policy_json
}

CloudFront → S3 のアクセスを制限するためには、bucket_policy_json が必須です。

💡 注意点
このモジュールは bucket_policy_json を明示的に渡すことで CloudFront OAC に対応します。

CloudFront作成後に再度applyする必要があります（循環依存を避けるため）。

S3バケットを削除する際に中身があると terraform destroy に失敗します。必要に応じて force_destroy = true を aws_s3_bucket に追加してください。




このチャットでやったこと
CloudFront + S3 の AccessDenied 問題調査

/callback?... で Cognito の認可コードを受け取った後、S3 ホスティングページにアクセスしようとして 403(Access Denied) が発生していた。

原因として、SPA のルーティングで callback/index.html にマッピングされないことが分かった。

Terraform で CloudFront Function を追加

/foo → /foo/index.html のように自動変換する CloudFront Function を Terraform に定義。

その際、Terraform のヒアドキュメント記法 (<<'JS') がエラーを引き起こした。

Terraform 構文エラーの原因と修正方法

HCL ではシングルクォート付きヒアドキュメントは無効。

<<JS または <<-JS に修正すれば OK。

さらに、JavaScript を別ファイルに分けて file() 関数で読み込む方式の方が安全で可読性も高いと提案。

詰まったことと解決策
詰まった内容	原因	解決策
/callback?... で AccessDenied	SPA ルーティングが CloudFront/S3 で正しく処理されない	CloudFront Function を追加してディレクトリ URI に index.html を付与
Terraform で CloudFront Function 定義時に構文エラー	<<'JS' 記法や ; の扱いなど、HCL と JS の記法が衝突	ヒアドキュメント記法を <<-JS に変更、または JS を外部ファイル化して file() で読み込み

学んだこと
SPA を S3 + CloudFront で動かす場合、ディレクトリや拡張子なしの URL を正しく index.html に解決する設定が必須。

Terraform のヒアドキュメント記法は、シングルクォートを使わず <<-（インデント許可）で書くのが安全。

コードは外部ファイル化して file() 読み込みすると構文エラーを防げ、保守性が上がる。

次のチャットへの引き継ぎ
CloudFront Function を Terraform に追加したら terraform apply → CloudFront の /* 無効化（キャッシュ削除）を必ず行うこと。

修正後に /callback?... アクセスが 403 にならず、Next.js の pages/callback.tsx にルーティングされるか確認する。

もしまだ 403 が出る場合は、CloudFront Function の割り当てが viewer-request になっているか、default_cache_behavior に設定されているかを再確認すること。

この流れを踏まえると、次のステップは
「CloudFront Function を外部 JS ファイル化 → Terraform 反映 → キャッシュ無効化 → 動作確認」
になります。

