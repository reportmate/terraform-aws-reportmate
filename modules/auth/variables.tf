variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "callback_urls" {
  description = "OAuth2 callback URLs for the web application"
  type        = list(string)
  default     = ["http://localhost:3000/api/auth/callback/cognito"]
}

variable "logout_urls" {
  description = "Logout redirect URLs"
  type        = list(string)
  default     = ["http://localhost:3000"]
}
