variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "api_negotiate_url" {
  description = "URL of the API negotiate endpoint for WebSocket integration"
  type        = string
}
