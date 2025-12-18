# Monitoring Module - CloudWatch (Serverless Architecture)

data "aws_region" "current" {}

# ============================================================================
# CloudWatch Log Groups
# ============================================================================
resource "aws_cloudwatch_log_group" "application" {
  name              = "/aws/${var.project_name}/${var.environment}/application"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "/aws/${var.project_name}/${var.environment}/api"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# ============================================================================
# CloudWatch Dashboard - Serverless
# ============================================================================
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}"

  dashboard_body = jsonencode({
    widgets = flatten([
      # Lambda Metrics
      [
        {
          type   = "metric"
          x      = 0
          y      = 0
          width  = 12
          height = 6
          properties = {
            title  = "Lambda Invocations"
            view   = "timeSeries"
            region = data.aws_region.current.id
            metrics = [
              for fn in var.lambda_function_names : ["AWS/Lambda", "Invocations", "FunctionName", fn]
            ]
            period = 60
            stat   = "Sum"
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = 0
          width  = 12
          height = 6
          properties = {
            title  = "Lambda Duration"
            view   = "timeSeries"
            region = data.aws_region.current.id
            metrics = [
              for fn in var.lambda_function_names : ["AWS/Lambda", "Duration", "FunctionName", fn]
            ]
            period = 60
            stat   = "Average"
          }
        },
        {
          type   = "metric"
          x      = 0
          y      = 6
          width  = 12
          height = 6
          properties = {
            title  = "Lambda Errors"
            view   = "timeSeries"
            region = data.aws_region.current.id
            metrics = [
              for fn in var.lambda_function_names : ["AWS/Lambda", "Errors", "FunctionName", fn]
            ]
            period = 60
            stat   = "Sum"
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = 6
          width  = 12
          height = 6
          properties = {
            title  = "Lambda Concurrent Executions"
            view   = "timeSeries"
            region = data.aws_region.current.id
            metrics = [
              for fn in var.lambda_function_names : ["AWS/Lambda", "ConcurrentExecutions", "FunctionName", fn]
            ]
            period = 60
            stat   = "Maximum"
          }
        }
      ],
      # Aurora Serverless Metrics (if configured)
      var.aurora_cluster_id != "" ? [
        {
          type   = "metric"
          x      = 0
          y      = 12
          width  = 8
          height = 6
          properties = {
            title  = "Aurora Serverless CPU"
            view   = "timeSeries"
            region = data.aws_region.current.id
            metrics = [
              ["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", var.aurora_cluster_id]
            ]
            period = 60
            stat   = "Average"
          }
        },
        {
          type   = "metric"
          x      = 8
          y      = 12
          width  = 8
          height = 6
          properties = {
            title  = "Aurora Serverless Capacity (ACU)"
            view   = "timeSeries"
            region = data.aws_region.current.id
            metrics = [
              ["AWS/RDS", "ServerlessDatabaseCapacity", "DBClusterIdentifier", var.aurora_cluster_id]
            ]
            period = 60
            stat   = "Average"
          }
        },
        {
          type   = "metric"
          x      = 16
          y      = 12
          width  = 8
          height = 6
          properties = {
            title  = "Aurora Database Connections"
            view   = "timeSeries"
            region = data.aws_region.current.id
            metrics = [
              ["AWS/RDS", "DatabaseConnections", "DBClusterIdentifier", var.aurora_cluster_id]
            ]
            period = 60
            stat   = "Average"
          }
        }
      ] : [],
      # API Gateway Metrics (if configured)
      var.api_gateway_id != "" ? [
        {
          type   = "metric"
          x      = 0
          y      = 18
          width  = 8
          height = 6
          properties = {
            title  = "API Gateway Requests"
            view   = "timeSeries"
            region = data.aws_region.current.id
            metrics = [
              ["AWS/ApiGateway", "Count", "ApiId", var.api_gateway_id]
            ]
            period = 60
            stat   = "Sum"
          }
        },
        {
          type   = "metric"
          x      = 8
          y      = 18
          width  = 8
          height = 6
          properties = {
            title  = "API Gateway Latency"
            view   = "timeSeries"
            region = data.aws_region.current.id
            metrics = [
              ["AWS/ApiGateway", "Latency", "ApiId", var.api_gateway_id],
              ["AWS/ApiGateway", "IntegrationLatency", "ApiId", var.api_gateway_id]
            ]
            period = 60
            stat   = "Average"
          }
        },
        {
          type   = "metric"
          x      = 16
          y      = 18
          width  = 8
          height = 6
          properties = {
            title  = "API Gateway Errors"
            view   = "timeSeries"
            region = data.aws_region.current.id
            metrics = [
              ["AWS/ApiGateway", "4xx", "ApiId", var.api_gateway_id],
              ["AWS/ApiGateway", "5xx", "ApiId", var.api_gateway_id]
            ]
            period = 60
            stat   = "Sum"
          }
        }
      ] : [],
      # CloudFront Metrics (if configured)
      var.cloudfront_distribution_id != "" ? [
        {
          type   = "metric"
          x      = 0
          y      = 24
          width  = 12
          height = 6
          properties = {
            title  = "CloudFront Requests"
            view   = "timeSeries"
            region = "us-east-1" # CloudFront metrics are in us-east-1
            metrics = [
              ["AWS/CloudFront", "Requests", "DistributionId", var.cloudfront_distribution_id, "Region", "Global"]
            ]
            period = 60
            stat   = "Sum"
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = 24
          width  = 12
          height = 6
          properties = {
            title  = "CloudFront Cache Hit Rate"
            view   = "timeSeries"
            region = "us-east-1"
            metrics = [
              ["AWS/CloudFront", "CacheHitRate", "DistributionId", var.cloudfront_distribution_id, "Region", "Global"]
            ]
            period = 60
            stat   = "Average"
          }
        }
      ] : []
    ])
  })
}

# ============================================================================
# CloudWatch Alarms - Lambda
# ============================================================================
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = var.enable_alarms ? toset(var.lambda_function_names) : []

  alarm_name          = "${var.project_name}-${var.environment}-lambda-errors-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = var.lambda_error_threshold
  alarm_description   = "Lambda function ${each.key} is experiencing errors"

  dimensions = {
    FunctionName = each.key
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  for_each = var.enable_alarms ? toset(var.lambda_function_names) : []

  alarm_name          = "${var.project_name}-${var.environment}-lambda-duration-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Average"
  threshold           = var.lambda_duration_threshold_ms
  alarm_description   = "Lambda function ${each.key} duration exceeds threshold"

  dimensions = {
    FunctionName = each.key
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "lambda_concurrent" {
  for_each = var.enable_alarms ? toset(var.lambda_function_names) : []

  alarm_name          = "${var.project_name}-${var.environment}-lambda-concurrent-${each.key}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Maximum"
  threshold           = var.lambda_concurrent_threshold
  alarm_description   = "Lambda function ${each.key} concurrent executions high"

  dimensions = {
    FunctionName = each.key
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}

# ============================================================================
# CloudWatch Alarms - Aurora Serverless
# ============================================================================
resource "aws_cloudwatch_metric_alarm" "aurora_cpu" {
  count = var.enable_alarms && var.aurora_cluster_id != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-aurora-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.aurora_cpu_threshold
  alarm_description   = "Aurora Serverless CPU utilization is high"

  dimensions = {
    DBClusterIdentifier = var.aurora_cluster_id
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "aurora_connections" {
  count = var.enable_alarms && var.aurora_cluster_id != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-aurora-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = var.aurora_connections_threshold
  alarm_description   = "Aurora Serverless database connections are high"

  dimensions = {
    DBClusterIdentifier = var.aurora_cluster_id
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}

# ============================================================================
# CloudWatch Alarms - API Gateway
# ============================================================================
resource "aws_cloudwatch_metric_alarm" "api_gateway_5xx" {
  count = var.enable_alarms && var.api_gateway_id != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-api-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "5xx"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = var.api_gateway_5xx_threshold
  alarm_description   = "API Gateway is returning 5xx errors"

  dimensions = {
    ApiId = var.api_gateway_id
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "api_gateway_latency" {
  count = var.enable_alarms && var.api_gateway_id != "" ? 1 : 0

  alarm_name          = "${var.project_name}-${var.environment}-api-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Latency"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Average"
  threshold           = var.api_gateway_latency_threshold_ms
  alarm_description   = "API Gateway latency is high"

  dimensions = {
    ApiId = var.api_gateway_id
  }

  alarm_actions = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []
  ok_actions    = var.alarm_sns_topic_arn != "" ? [var.alarm_sns_topic_arn] : []

  tags = var.tags
}

# ============================================================================
# X-Ray Tracing (Serverless)
# ============================================================================
resource "aws_xray_sampling_rule" "main" {
  count = var.enable_xray ? 1 : 0

  rule_name      = "${var.project_name}-${var.environment}"
  priority       = 1000
  version        = 1
  reservoir_size = 5
  fixed_rate     = 0.05
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"
}

# ============================================================================
# SNS Topic for Alarms (if not provided)
# ============================================================================
resource "aws_sns_topic" "alarms" {
  count = var.enable_alarms && var.alarm_sns_topic_arn == "" ? 1 : 0

  name = "${var.project_name}-${var.environment}-alarms"

  tags = var.tags
}

locals {
  alarm_topic_arn = var.alarm_sns_topic_arn != "" ? var.alarm_sns_topic_arn : try(aws_sns_topic.alarms[0].arn, "")
}

# ============================================================================
# CloudWatch Insights Query (for Lambda analysis)
# ============================================================================
resource "aws_cloudwatch_query_definition" "lambda_cold_starts" {
  name = "${var.project_name}/${var.environment}/Lambda Cold Starts"

  log_group_names = [
    for fn in var.lambda_function_names : "/aws/lambda/${fn}"
  ]

  query_string = <<-EOT
    fields @timestamp, @message, @logStream
    | filter @message like /INIT_START/
    | stats count(*) as coldStarts by bin(1h)
    | sort @timestamp desc
    | limit 100
  EOT
}

resource "aws_cloudwatch_query_definition" "lambda_errors_query" {
  name = "${var.project_name}/${var.environment}/Lambda Errors"

  log_group_names = [
    for fn in var.lambda_function_names : "/aws/lambda/${fn}"
  ]

  query_string = <<-EOT
    fields @timestamp, @message, @logStream
    | filter @message like /ERROR/ or @message like /Error/ or @message like /Exception/
    | sort @timestamp desc
    | limit 100
  EOT
}

resource "aws_cloudwatch_query_definition" "lambda_performance" {
  name = "${var.project_name}/${var.environment}/Lambda Performance"

  log_group_names = [
    for fn in var.lambda_function_names : "/aws/lambda/${fn}"
  ]

  query_string = <<-EOT
    filter @type = "REPORT"
    | parse @log /\d+:\/aws\/lambda\/(?<function>.*)/
    | stats
      avg(@duration) as avgDuration,
      max(@duration) as maxDuration,
      min(@duration) as minDuration,
      pct(@duration, 95) as p95Duration,
      avg(@maxMemoryUsed) as avgMemoryUsed
      by function
  EOT
}
