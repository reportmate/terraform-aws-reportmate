variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for ECS tasks"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs for ALB"
}

variable "frontend_image" {
  type        = string
  description = "Frontend container image"
}

variable "frontend_image_tag" {
  type        = string
  description = "Frontend container image tag"
  default     = "latest"
}

variable "ecr_repository_url" {
  type        = string
  description = "ECR repository URL"
}

variable "create_ecr_repository" {
  type        = bool
  description = "Whether ECR repository is being created"
  default     = false
}

variable "container_cpu" {
  type        = number
  description = "CPU units for the container"
  default     = 512
}

variable "container_memory" {
  type        = number
  description = "Memory for the container in MB"
  default     = 1024
}

variable "container_port" {
  type        = number
  description = "Container port"
  default     = 3000
}

variable "desired_count" {
  type        = number
  description = "Desired number of tasks"
  default     = 2
}

variable "database_url" {
  type        = string
  description = "Database connection URL"
  sensitive   = true
}

variable "api_base_url" {
  type        = string
  description = "API Gateway base URL"
}

variable "websocket_endpoint" {
  type        = string
  description = "WebSocket API endpoint"
}

variable "nextauth_secret_arn" {
  type        = string
  description = "ARN of NextAuth secret in Secrets Manager"
}

variable "client_passphrases_arn" {
  type        = string
  description = "ARN of client passphrases secret in Secrets Manager"
}

variable "cognito_client_id" {
  type        = string
  description = "Cognito App Client ID"
  default     = ""
}

variable "cognito_client_secret" {
  type        = string
  description = "Cognito App Client Secret"
  default     = ""
  sensitive   = true
}

variable "cognito_issuer" {
  type        = string
  description = "Cognito Issuer URL"
  default     = ""
}

variable "custom_domain_name" {
  type        = string
  description = "Custom domain name"
  default     = ""
}

variable "acm_certificate_arn" {
  type        = string
  description = "ACM certificate ARN for HTTPS"
  default     = ""
}

variable "use_fargate_spot" {
  type        = bool
  description = "Use Fargate Spot for cost savings"
  default     = false
}

variable "enable_container_insights" {
  type        = bool
  description = "Enable Container Insights"
  default     = true
}

variable "log_retention_days" {
  type        = number
  description = "CloudWatch log retention in days"
  default     = 30
}

variable "enable_autoscaling" {
  type        = bool
  description = "Enable auto scaling"
  default     = true
}

variable "min_capacity" {
  type        = number
  description = "Minimum number of tasks"
  default     = 1
}

variable "max_capacity" {
  type        = number
  description = "Maximum number of tasks"
  default     = 10
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
