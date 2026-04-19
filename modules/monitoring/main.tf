locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# --- CloudWatch Log Groups ---

resource "aws_cloudwatch_log_group" "api" {
  name              = "/ecs/${local.name_prefix}/api"
  retention_in_days = var.log_retention_days

  tags = { Name = "${local.name_prefix}-api-logs" }
}

resource "aws_cloudwatch_log_group" "frontend" {
  name              = "/ecs/${local.name_prefix}/frontend"
  retention_in_days = var.log_retention_days

  tags = { Name = "${local.name_prefix}-frontend-logs" }
}

resource "aws_cloudwatch_log_group" "maintenance" {
  name              = "/ecs/${local.name_prefix}/maintenance"
  retention_in_days = var.log_retention_days

  tags = { Name = "${local.name_prefix}-maintenance-logs" }
}

resource "aws_cloudwatch_log_group" "demo_loop" {
  name              = "/ecs/${local.name_prefix}/demo-loop"
  retention_in_days = var.log_retention_days

  tags = { Name = "${local.name_prefix}-demo-loop-logs" }
}

# --- Alerts ---

resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"

  tags = { Name = "${local.name_prefix}-alerts" }
}

resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.alert_email == "" ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# Allow AWS Budgets to publish to the alerts topic.
data "aws_iam_policy_document" "alerts_topic_policy" {
  statement {
    sid     = "AllowBudgetsPublish"
    actions = ["SNS:Publish"]
    principals {
      type        = "Service"
      identifiers = ["budgets.amazonaws.com"]
    }
    resources = [aws_sns_topic.alerts.arn]
  }
}

resource "aws_sns_topic_policy" "alerts" {
  arn    = aws_sns_topic.alerts.arn
  policy = data.aws_iam_policy_document.alerts_topic_policy.json
}

# --- Cost Budget ---
#
# Daily ACTUAL + FORECAST budget. Notifies the alerts SNS topic (and the
# subscribed email) the moment spend crosses or is projected to cross the
# threshold. This is the safety net that the previous deployment lacked.
resource "aws_budgets_budget" "daily" {
  name         = "${local.name_prefix}-daily-spend"
  budget_type  = "COST"
  limit_amount = tostring(var.daily_budget_usd)
  limit_unit   = "USD"
  time_unit    = "DAILY"

  # AWS Budgets only supports ACTUAL notifications on DAILY time_unit
  # (FORECASTED is for MONTHLY/QUARTERLY/ANNUALLY).
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [aws_sns_topic.alerts.arn]
    subscriber_email_addresses = var.alert_email == "" ? [] : [var.alert_email]
  }

  depends_on = [aws_sns_topic_policy.alerts]
}
