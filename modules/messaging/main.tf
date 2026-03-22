locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# API Gateway WebSocket API for real-time event streaming
# Mirrors Azure Web PubSub (SignalR) functionality
resource "aws_apigatewayv2_api" "websocket" {
  name                       = "${local.name_prefix}-realtime"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"

  tags = { Name = "${local.name_prefix}-realtime" }
}

# Default route ($default) - forwards messages to backend
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.default.id}"
}

# Connect route - client connects
resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.default.id}"
}

# Disconnect route - client disconnects
resource "aws_apigatewayv2_route" "disconnect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.default.id}"
}

# Integration pointing to the API container via ALB
resource "aws_apigatewayv2_integration" "default" {
  api_id             = aws_apigatewayv2_api.websocket.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = var.api_negotiate_url
  integration_method = "POST"
}

# Stage (auto-deploy)
resource "aws_apigatewayv2_stage" "production" {
  api_id      = aws_apigatewayv2_api.websocket.id
  name        = "production"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
  }

  tags = { Name = "${local.name_prefix}-realtime-production" }
}
