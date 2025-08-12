# CloudFront Static Site Module (with OAC)

このモジュールは、React などの静的 Web サイトをホスティングするために使用される **S3 + CloudFront + OAC (Origin Access Control)** の構成を定義します。CloudFront からのみ S3 へアクセス可能なセキュアな配信環境を構築します。

---

## 🔧 作成されるリソース

| リソース種類                           | 説明                                                       |
| -------------------------------------- | ---------------------------------------------------------- |
| `aws_cloudfront_origin_access_control` | CloudFront から S3 へ SigV4 署名付きアクセスを許可する OAC |
| `aws_cloudfront_distribution`          | CloudFront のディストリビューション本体                    |
| `aws_iam_policy_document`              | S3バケットポリシーを生成するポリシードキュメント（OAC対応） |
| `aws_route53_record`（※任意）         | CloudFront向けのAliasレコード（ルートモジュールで追加可能） |

---

## 📁 ファイル構成の要点

### `main.tf`

CloudFrontディストリビューションと OAC を定義し、SPA（Single Page Application）対応の404設定や、HTTPS + 独自ドメインでの配信を実現します。

> 詳細な構成は省略します（元の `main.tf` 参照）

---

## 🔸 入力変数（variables.tf）

| 変数名               | 説明                                                       |
|----------------------|------------------------------------------------------------|
| `bucket_name`        | S3バケット名（CloudFrontのオリジンとして使用）             |
| `domain_name`        | CloudFrontのCNAMEに設定する独自ドメイン（例：static.○○） |
| `acm_certificate_arn`| us-east-1 に発行された ACM 証明書の ARN                    |

---

## 🔹 出力値（outputs.tf）

| 出力名                     | 説明                                                                 |
|----------------------------|----------------------------------------------------------------------|
| `cloudfront_domain_name`   | CloudFrontディストリビューションのドメイン名（例：dxxx.cloudfront.net） |
| `cloudfront_distribution_arn` | CloudFront ディストリビューションの ARN                                 |
| `bucket_policy_json`       | S3 に設定する OAC 向けのバケットポリシー（jsonencode済み）             |

---

## 🧪 使用例（ルートモジュールから）

```hcl
module "cloudfront_static_site" {
  source              = "./modules/cloudfront_static_site"
  bucket_name         = "static.litenote.click"
  domain_name         = "static.litenote.click"
  acm_certificate_arn = module.acm.certificate_arn
}

CloudFront 作成後、module.cloudfront_static_site.bucket_policy_json を
S3 モジュールの bucket_policy_json に渡してください。

module "s3_static_site" {
  source                    = "./modules/s3_static_site"
  bucket_name               = "static.litenote.click"
  cloudfront_distribution_arn = module.cloudfront_static_site.cloudfront_distribution_arn
  bucket_policy_json           = module.cloudfront_static_site.bucket_policy_json
}

🔐 S3署名付きアクセス（OAC）とは？
この構成では、S3オリジンへのアクセスを CloudFront に完全に制限し、署名付きリクエスト（SigV4）以外を拒否します。
そのため、S3バケットには OAC に対応したポリシーが必要となります（当モジュールで生成し output されます）。

💡 注意点
ACM証明書は us-east-1 で作成してください（CloudFrontの仕様）。

CloudFront → S3 の循環依存を避けるため、apply順に注意（またはリファクタリング構成を導入）。

force_destroy を使わない場合、S3バケットの中身を事前に削除してから terraform destroy を実行してください。

aws s3 cp static-site/index.html s3://static.litenote.click/index.html --acl private

✅ 補足：今後のおすすめ運用
手順	理由
① CloudFront（OAC付き）を先に terraform apply	OACの ARN を先に確定させるため
② 次にS3モジュールを apply	CloudFront ARN を使った正しいポリシーを反映できる
③ 全体構成に戻して terraform apply（循環がないとき）	安定運用に戻す

✅ 結論：OAC（Origin Access Control）＝ CloudFront → S3 署名付きアクセスの“新方式”
旧方式	OAI（Origin Access Identity）
CloudFrontがS3にアクセスする手段として使われていた	
IAMロールのようなIDをS3バケットポリシーで許可	

↓

新方式（推奨）	OAC（Origin Access Control）
CloudFrontが**署名付きリクエスト（SigV4）**でS3にアクセス	
より細かい制御、将来的な拡張性あり	
2022年以降、AWSが推奨	

✅ OACの特徴
特徴	内容
🔐 SigV4署名	CloudFrontが送信するリクエストに署名がつく（S3が信頼できる）
⚙️ IAMなし	IAMユーザーやロールを作らなくてもバケットポリシーで制御可能
☁️ バケットポリシーの書き方が変わる	Principal = cloudfront.amazonaws.com + AWS:SourceArn が必要
✅ Terraformでサポート済み	aws_cloudfront_origin_access_control リソースを使う

✅ Terraform でのOACの例（あなたの構成に近い）
aws_cloudfront_origin_access_control
hcl
コピーする
編集する
resource "aws_cloudfront_origin_access_control" "this" {
  name                              = "${var.bucket_name}-oac"
  description                       = "OAC for ${var.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}
CloudFrontの origin に OAC を指定
hcl
コピーする
編集する
origin {
  domain_name              = "${var.bucket_name}.s3.amazonaws.com"
  origin_id                = "s3-${var.bucket_name}"
  origin_access_control_id = aws_cloudfront_origin_access_control.this.id

  s3_origin_config {
    origin_access_identity = "" # OAIは使わないので空文字
  }
}
✅ OAC利用時のS3バケットポリシー（例）
json
コピーする
編集する
{
  "Effect": "Allow",
  "Principal": {
    "Service": "cloudfront.amazonaws.com"
  },
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::your-bucket-name/*",
  "Condition": {
    "StringEquals": {
      "AWS:SourceArn": "arn:aws:cloudfront::YOUR_ACCOUNT_ID:distribution/YOUR_DISTRIBUTION_ID"
    }
  }
}
✅ なぜOACが推奨される？
理由	内容
IAM設定不要で簡潔	OAIはIDのやり取りが必要だが、OACはサービス指定のみでOK
セキュア	リクエストごとに署名（SigV4）が付く
モダン	2022年にリリースされた新方式、AWSの公式推奨方式に

✅ まとめ
項目	内容
OACとは	CloudFront → S3 の署名付きアクセスを行う新しい仕組み
OAIとの違い	OAIはCloudFront専用IDをS3に登録、OACは署名ベースで制御
あなたの構成	Terraformで origin_access_control_id を使っており、OACを使っている構成です ✔️


https://litenote-auth.auth.ap-northeast-1.amazoncognito.com/login?client_id=<APP_CLIENT_ID>&response_type=token&scope=openid&redirect_uri=http://localhost
