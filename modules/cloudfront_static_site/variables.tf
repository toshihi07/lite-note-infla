variable "bucket_name" {
  description = "S3バケット名（例：static.litenote.click）"
  type        = string
}

variable "domain_name" {
  description = "独自ドメイン名（例：static.litenote.click）"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM証明書のARN（us-east-1）"
  type        = string
}

variable "bucket_policy_json" {
  type    = string
  default = null
}

