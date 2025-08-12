output "certificate_arn" {
  description = "ACM証明書のARN"
  value       = aws_acm_certificate.this.arn
}