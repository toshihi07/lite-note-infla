# LiteNote インフラ構築手順書

本ドキュメントは、Terraform を用いて AWS 上に LiteNote のインフラ環境を構築するための手順をまとめたものです。  
対象環境：`dev`

---

## 🔧 作業環境

- 実行環境：WSL2（Ubuntu）
- 作業ディレクトリ：`~/projects/litenote/lite-note-infra`
- Terraform バージョン：`v1.8.4`（`terraform -version`で確認）
- AWS CLI：`aws-cli/2.x`（`aws --version`で確認）
- Git：管理対象

---

## 📁 ディレクトリ構成（環境別）

```
lite-note-infra/
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── terraform.tfvars
│       └── backend.tf
├── modules/
│   ├── vpc/
│   ├── s3/
│   ├── cloudfront/
│   ├── acm/
│   ├── route53/
│   ├── cognito/
│   ├── api_gateway/
│   ├── lambda/
│   ├── dynamodb/
│   ├── waf/
│   ├── cloudwatch/
│   └── sns/
├── docs/
├── logs/
└── evidence/
```

---

## 🔖 独自ドメイン取得手順（Route53）

2025/06/29

Terraform での管理は推奨されていないため、**手動で取得**する。最初に実施しておくこと。

1. AWS マネジメントコンソールにログイン
2. 「Route 53」→「ドメインの登録」→ `example.tech` など安価な TLD を検索
3. 最安の空きドメイン（100 円〜1000 円/年）を選択
4. 1 年分を選んで登録（自動更新は任意）
5. 完了後、Hosted Zone が自動生成される

📸 **証跡**：取得完了後の Hosted Zone 一覧のスクリーンショットを `evidence/` に保存

---

## ✅ 構築手順

### 1. 事前準備

```bash
# 作業ディレクトリに移動
cd ~/projects/litenote/lite-note-infra/environments/dev
```

- `terraform.tfvars` に環境変数（例：VPC CIDR、ドメイン名、環境名など）を定義
- AWS 認証情報の確認：`aws sts get-caller-identity` でアクセス確認

### 2. Terraform 初期化

```bash
terraform init
```

- 📸 **証跡取得**：実行ログを保存
  ```bash
  terraform init | tee ../../logs/init-$(date +%Y%m%d).log
  ```

### 3. 実行計画の確認

```bash
terraform plan -var-file="terraform.tfvars"
```

- 📸 **証跡取得**：リソース変更内容をログ出力
  ```bash
  terraform plan -var-file="terraform.tfvars" | tee ../../logs/plan-$(date +%Y%m%d).log
  ```

### 4. 適用（本番反映）

```bash
terraform apply -var-file="terraform.tfvars"
```

- 確認プロンプトで `yes` を入力
- 📸 **証跡取得**：結果のスクリーンショット or ログ保存（ALB DNS などが表示される）

```bash
terraform apply -var-file="terraform.tfvars" | tee ../../logs/apply-$(date +%Y%m%d).log
```

---

## 📌 証跡取得ガイドライン

| タイミング                            | 取得方法                                       | 保存先（推奨） |
| ------------------------------------- | ---------------------------------------------- | -------------- |
| `terraform init` / `plan` / `apply`   | `tee`でログ保存                                | `logs/`        |
| AWS リソース構築後（VPC, ALB, S3 等） | AWS マネジメントコンソールのスクリーンショット | `evidence/`    |
| コスト確認（例：CloudFront コスト）   | AWS 請求ダッシュボードのスクショ               | `evidence/`    |

---

## ✅ エラーが出た場合の対処

1. `debug-log.md` に状況と試したことを記録
2. スクショやリンクを残す
3. `terraform destroy` でリセット可能（慎重に）

---

## 💡 備考

- 構成変更の際は `plan` 結果を必ずレビューすること
- GitHub Actions などの CI/CD を導入する際も `terraform plan/apply` のステップをログ化する

---

## 🗂 参考ファイル

- `terraform.tfvars.example`：変数定義テンプレート
- `modules/`：各リソース単位のモジュール群

---

## 🏁 完了チェックリスト

- [ ] Route53 ドメイン取得済（スクリーンショット保存）
- [ ] `terraform init` 実行済
- [ ] `terraform plan` ログ取得済
- [ ] `terraform apply` により AWS リソース構築済
- [ ] スクリーンショット等の証跡が `evidence/` に保存済
- [ ] GitHub にコミット／Push 済

---

（作成者：@Toshihiro / 最終更新：2025-06-29）
