variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for Lambda access"
  type        = string
}

variable "database_subnet_ids" {
  description = "List of database subnet IDs"
  type        = list(string)
}

variable "allowed_security_groups" {
  description = "List of security group IDs allowed to connect"
  type        = list(string)
  default     = []
}

# Aurora Serverless v2 Scaling
variable "serverless_min_capacity" {
  description = "Minimum ACU capacity (0.5 = ~1GB RAM, scales to 0 when idle)"
  type        = number
  default     = 0.5
}

variable "serverless_max_capacity" {
  description = "Maximum ACU capacity (up to 128)"
  type        = number
  default     = 16
}

variable "instance_count" {
  description = "Number of Aurora instances (1 for dev, 2+ for HA)"
  type        = number
  default     = 1
}

# Database credentials
variable "db_username" {
  description = "Master username"
  type        = string
  default     = "reportmate"
}

variable "db_password" {
  description = "Master password"
  type        = string
  sensitive   = true
}

variable "db_secret_arn" {
  description = "ARN of Secrets Manager secret containing DB credentials"
  type        = string
  default     = ""
}

# Features
variable "enable_data_api" {
  description = "Enable Data API for serverless queries (Lambda without VPC)"
  type        = bool
  default     = true
}

variable "enable_iam_auth" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = true
}

variable "enable_rds_proxy" {
  description = "Enable RDS Proxy for connection pooling (recommended for Lambda)"
  type        = bool
  default     = false
}

# Encryption
variable "kms_key_arn" {
  description = "KMS key ARN for encryption (uses AWS managed key if not specified)"
  type        = string
  default     = ""
}

# Backup
variable "backup_retention_days" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

# Monitoring
variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "enhanced_monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0 to disable)"
  type        = number
  default     = 60
}

# Protection
variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on deletion"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
