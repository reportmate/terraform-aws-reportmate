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

variable "multi_az" {
  description = "Provision RDS with a synchronous standby in another AZ."
  type        = bool
  default     = false
}

variable "storage_type" {
  description = "RDS storage type (gp3, gp2, io1, io2)."
  type        = string
  default     = "gp3"
}

variable "max_allocated_storage" {
  description = "Upper limit in GB for RDS storage autoscaling. Null leaves autoscaling off."
  type        = number
  default     = null
}

variable "backup_retention_days" {
  description = "Days of automated RDS backups to keep."
  type        = number
  default     = 7
}
