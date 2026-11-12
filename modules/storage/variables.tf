variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "bucket_name" {
  description = "Storage bucket name. Null uses <project>-<environment>-storage."
  type        = string
  default     = null
}
