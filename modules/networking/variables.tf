variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of AZs to use (minimum 2 for ALB)"
  type        = list(string)
  default     = []
}

variable "enable_multi_az_nat" {
  description = "Provision one NAT gateway per AZ instead of a single shared NAT."
  type        = bool
  default     = false
}

variable "enable_vpc_flow_logs" {
  description = "Send VPC Flow Logs to a private S3 bucket with a 30-day lifecycle."
  type        = bool
  default     = true
}

variable "enable_vpc_endpoints" {
  description = "Create interface endpoints for ECR / Logs / Secrets Manager. The S3 gateway endpoint is created unconditionally (free)."
  type        = bool
  default     = false
}

variable "vpc_endpoint_security_group_id" {
  description = "Security group whose members are allowed to reach the interface endpoints (typically the ECS tasks SG). Required when enable_vpc_endpoints is true."
  type        = string
  default     = ""
}
