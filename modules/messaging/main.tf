# Messaging Module - WebSocket API (equivalent to Azure Web PubSub/SignalR)

# API Gateway WebSocket API
resource "aws_apigatewayv2_api" "websocket" {
  name                       = "${var.project_name}-${var.environment}-ws"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"

  tags = var.tags
}

# WebSocket integrations
resource "aws_apigatewayv2_integration" "connect" {
  api_id             = aws_apigatewayv2_api.websocket.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.websocket_handler_invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "disconnect" {
  api_id             = aws_apigatewayv2_api.websocket.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.websocket_handler_invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "default" {
  api_id             = aws_apigatewayv2_api.websocket.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.websocket_handler_invoke_arn
  integration_method = "POST"
}

resource "aws_apigatewayv2_integration" "message" {
  api_id             = aws_apigatewayv2_api.websocket.id
  integration_type   = "AWS_PROXY"
  integration_uri    = var.websocket_handler_invoke_arn
  integration_method = "POST"
}

# WebSocket routes
resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.connect.id}"
}

resource "aws_apigatewayv2_route" "disconnect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.disconnect.id}"
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.default.id}"
}

resource "aws_apigatewayv2_route" "message" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "message"
  target    = "integrations/${aws_apigatewayv2_integration.message.id}"
}

# Lambda permission for WebSocket API
resource "aws_lambda_permission" "websocket" {
  statement_id  = "AllowWebSocketInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.websocket_handler_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*/*"
}

# WebSocket stage
resource "aws_apigatewayv2_stage" "websocket" {
  api_id      = aws_apigatewayv2_api.websocket.id
  name        = var.environment
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.websocket.arn
    format = jsonencode({
      requestId          = "$context.requestId"
      ip                 = "$context.identity.sourceIp"
      requestTime        = "$context.requestTime"
      routeKey           = "$context.routeKey"
      status             = "$context.status"
      connectionId       = "$context.connectionId"
      integrationLatency = "$context.integrationLatency"
    })
  }

  default_route_settings {
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "websocket" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}-websocket"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# SQS queue for message fanout (like Azure Service Bus)
resource "aws_sqs_queue" "messages" {
  name                       = "${var.project_name}-${var.environment}-messages"
  visibility_timeout_seconds = 30
  message_retention_seconds  = 86400 # 1 day
  receive_wait_time_seconds  = 20    # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })

  tags = var.tags
}

# Dead letter queue
resource "aws_sqs_queue" "dlq" {
  name                      = "${var.project_name}-${var.environment}-messages-dlq"
  message_retention_seconds = 1209600 # 14 days

  tags = var.tags
}

# SQS queue policy
resource "aws_sqs_queue_policy" "messages" {
  queue_url = aws_sqs_queue.messages.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaSend"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.messages.arn
      }
    ]
  })
}

# SNS topic for pub/sub messaging
resource "aws_sns_topic" "events" {
  name = "${var.project_name}-${var.environment}-events"

  tags = var.tags
}

resource "aws_sns_topic_subscription" "sqs" {
  topic_arn = aws_sns_topic.events.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.messages.arn
}

# DynamoDB table for WebSocket connections (replaces Azure SignalR connection management)
resource "aws_dynamodb_table" "connections" {
  name         = "${var.project_name}-${var.environment}-connections"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "connectionId"

  attribute {
    name = "connectionId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  global_secondary_index {
    name            = "userId-index"
    hash_key        = "userId"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = var.tags
}

# IAM policy for managing connections
resource "aws_iam_policy" "manage_connections" {
  name        = "${var.project_name}-${var.environment}-manage-connections"
  description = "Policy to manage WebSocket connections"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "execute-api:ManageConnections"
        ]
        Resource = "${aws_apigatewayv2_api.websocket.execution_arn}/${var.environment}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.connections.arn,
          "${aws_dynamodb_table.connections.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage"
        ]
        Resource = aws_sqs_queue.messages.arn
      }
    ]
  })

  tags = var.tags
}
