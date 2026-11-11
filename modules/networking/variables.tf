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

variable "enable_s3_gateway_endpoint" {
  description = "Create the free S3 gateway endpoint on the module's private route tables."
  type        = bool
  default     = true
}

# --- Existing-VPC mode ---

variable "existing_vpc_id" {
  description = "Deploy into this existing VPC instead of creating one. Null (default) creates a new VPC."
  type        = string
  default     = null
}

variable "existing_nat_gateway_id" {
  description = "NAT gateway in the existing VPC that the module's private route table sends 0.0.0.0/0 to. Required with existing_vpc_id."
  type        = string
  default     = null
}

variable "private_subnet_cidrs" {
  description = "Existing-VPC mode: map of availability zone to CIDR for the module's private subnets (ECS tasks, RDS)."
  type        = map(string)
  default     = {}
}

variable "public_subnet_cidrs" {
  description = "Existing-VPC mode: map of availability zone to CIDR for the module's public subnets (ALB)."
  type        = map(string)
  default     = {}
}
