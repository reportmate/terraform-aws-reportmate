# Aurora Cluster outputs
output "cluster_id" {
  description = "Aurora cluster identifier"
  value       = aws_rds_cluster.main.id
}

output "cluster_arn" {
  description = "Aurora cluster ARN"
  value       = aws_rds_cluster.main.arn
}

output "cluster_endpoint" {
  description = "Aurora cluster writer endpoint"
  value       = aws_rds_cluster.main.endpoint
}

output "cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = aws_rds_cluster.main.reader_endpoint
}

output "cluster_port" {
  description = "Aurora cluster port"
  value       = aws_rds_cluster.main.port
}

output "database_name" {
  description = "Database name"
  value       = aws_rds_cluster.main.database_name
}

# RDS Proxy outputs (when enabled)
output "proxy_endpoint" {
  description = "RDS Proxy endpoint (use this for Lambda connections)"
  value       = var.enable_rds_proxy ? aws_db_proxy.main[0].endpoint : null
}

output "proxy_arn" {
  description = "RDS Proxy ARN"
  value       = var.enable_rds_proxy ? aws_db_proxy.main[0].arn : null
}

# Security Group
output "security_group_id" {
  description = "Aurora security group ID"
  value       = aws_security_group.aurora.id
}

# IAM Policies (for Lambda access)
output "data_api_policy_arn" {
  description = "IAM policy ARN for Data API access"
  value       = var.enable_data_api ? aws_iam_policy.data_api_access[0].arn : null
}

# Connection info for Lambda
output "connection_config" {
  description = "Connection configuration for Lambda functions"
  value = {
    # Use proxy if enabled, otherwise direct cluster endpoint
    host     = var.enable_rds_proxy ? aws_db_proxy.main[0].endpoint : aws_rds_cluster.main.endpoint
    port     = aws_rds_cluster.main.port
    database = aws_rds_cluster.main.database_name
    username = var.db_username
    # For Data API
    cluster_arn = aws_rds_cluster.main.arn
    secret_arn  = var.db_secret_arn
  }
  sensitive = true
}
