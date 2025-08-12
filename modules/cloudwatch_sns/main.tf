# ✅ SNS Topic
resource "aws_sns_topic" "lambda_error" {
  name = "lambda-error-topic"
}

# ✅ メール通知サブスクリプション
resource "aws_sns_topic_subscription" "lambda_error_email" {
  topic_arn = aws_sns_topic.lambda_error.arn
  protocol  = "email"
  endpoint  = var.alert_email # 例: your-email@example.com
}

# ✅ Lambda エラーログ + 例外検知（ERROR / error / Exception 全て対象）
resource "aws_cloudwatch_log_metric_filter" "lambda_error_filter" {
  name           = "lambda-error-filter"
  log_group_name = "/aws/lambda/${var.lambda_name}"

  # ✅ ERROR (大文字小文字問わず) または Exception を検知
  pattern = "{($.message = *ERROR*) || ($.message = *error*) || ($.message = *Exception*)}"

  metric_transformation {
    name      = "LambdaErrorCount"
    namespace = "LiteNote"
    value     = "1"
  }
}


# ✅ CloudWatch アラーム
resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "lambda-error-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.lambda_error_filter.metric_transformation[0].name
  namespace           = "LiteNote"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Notify when Lambda errors occur"
  alarm_actions       = [aws_sns_topic.lambda_error.arn]
}
