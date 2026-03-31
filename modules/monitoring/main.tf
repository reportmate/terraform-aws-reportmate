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

# --- CloudWatch Alarms ---

resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"

  tags = { Name = "${local.name_prefix}-alerts" }
}
