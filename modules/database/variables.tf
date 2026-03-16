variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security group"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for DB subnet group"
  type        = list(string)
}

variable "db_username" {
  description = "PostgreSQL admin username"
  type        = string
}

variable "db_password" {
  description = "PostgreSQL admin password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "reportmate"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Storage in GB"
  type        = number
  default     = 32
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to connect to the database"
  type        = list(string)
  default     = []
}
