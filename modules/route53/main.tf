data "aws_route53_zone" "this" {
  name         = "litenote.click"
  private_zone = false
}