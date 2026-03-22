output "websocket_api_id" {
  description = "API Gateway WebSocket API ID"
  value       = aws_apigatewayv2_api.websocket.id
}

output "websocket_url" {
  description = "WebSocket connection URL"
  value       = aws_apigatewayv2_stage.production.invoke_url
}

output "websocket_api_endpoint" {
  description = "WebSocket API endpoint (wss://)"
  value       = aws_apigatewayv2_api.websocket.api_endpoint
}
