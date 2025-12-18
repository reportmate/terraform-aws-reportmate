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

variable "database_subnet_ids" {
  type        = list(string)
  description = "List of database subnet IDs"
}

variable "allowed_security_groups" {
  type        = list(string)
  description = "Security groups allowed to access the database"
  default     = []
}

variable "db_instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "db_name" {
  type        = string
  description = "Database name"
}

variable "db_username" {
  type        = string
  description = "Database admin username"
}

variable "db_password" {
  type        = string
  description = "Database admin password"
  sensitive   = true
}

variable "db_storage_gb" {
  type        = number
  description = "Allocated storage in GB"
  default     = 20
}

variable "db_max_storage_gb" {
  type        = number
  description = "Maximum storage for autoscaling in GB"
  default     = 100
}

variable "engine_version" {
  type        = string
  description = "PostgreSQL engine version"
  default     = "16.3"
}

variable "multi_az" {
  type        = bool
  description = "Enable Multi-AZ deployment"
  default     = false
}

variable "backup_retention_days" {
  type        = number
  description = "Backup retention period in days"
  default     = 7
}

variable "enable_performance_insights" {
  type        = bool
  description = "Enable Performance Insights"
  default     = false
}

variable "enhanced_monitoring_interval" {
  type        = number
  description = "Enhanced monitoring interval (0 to disable)"
  default     = 0
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}
