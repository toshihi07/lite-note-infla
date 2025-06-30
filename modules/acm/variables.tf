variable "domain_name" {
  description = "独自ドメイン名（ACM証明書に使う）"
  type        = string
}

variable "hosted_zone_id" {
  description = "ACM用に検証レコードを登録するRoute53のホストゾーンID"
  type        = string
}
