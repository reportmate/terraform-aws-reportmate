# Aurora Serverless v2 PostgreSQL (Serverless-First)
# Scales automatically from 0.5 to 128 ACUs based on demand

locals {
  db_name = replace("${var.project_name}_${var.environment}", "-", "_")
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  })
}

# Security Group for Aurora
resource "aws_security_group" "aurora" {
  name_prefix = "${var.project_name}-${var.environment}-aurora-"
  description = "Security group for Aurora Serverless PostgreSQL"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.allowed_security_groups
    description     = "PostgreSQL from allowed security groups"
  }

  # Allow from VPC CIDR for Lambda functions
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "PostgreSQL from VPC (Lambda)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-aurora-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Aurora Cluster Parameter Group
resource "aws_rds_cluster_parameter_group" "main" {
  name        = "${var.project_name}-${var.environment}-aurora-pg16"
  family      = "aurora-postgresql16"
  description = "Aurora PostgreSQL 16 cluster parameter group"

  parameter {
    name  = "log_statement"
    value = "all"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = var.tags
}

# Aurora DB Instance Parameter Group
resource "aws_db_parameter_group" "aurora" {
  name        = "${var.project_name}-${var.environment}-aurora-instance-pg16"
  family      = "aurora-postgresql16"
  description = "Aurora PostgreSQL 16 instance parameter group"

  tags = var.tags
}

# Aurora Serverless v2 Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier = "${var.project_name}-${var.environment}-aurora"

  # Engine - Aurora PostgreSQL with Serverless v2
  engine         = "aurora-postgresql"
  engine_mode    = "provisioned" # Required for Serverless v2
  engine_version = "16.4"

  # Serverless v2 Scaling - Pay only for what you use!
  serverlessv2_scaling_configuration {
    min_capacity = var.serverless_min_capacity # 0.5 ACU = ~1GB RAM
    max_capacity = var.serverless_max_capacity # Scale up as needed
  }

  # Database
  database_name   = local.db_name
  master_username = var.db_username
  master_password = var.db_password
  port            = 5432

  # Network
  db_subnet_group_name            = aws_db_subnet_group.main.name
  vpc_security_group_ids          = [aws_security_group.aurora.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name

  # Storage encryption
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  # Enable Data API for serverless queries from Lambda without VPC
  enable_http_endpoint = var.enable_data_api

  # IAM Database Authentication for passwordless Lambda access
  iam_database_authentication_enabled = var.enable_iam_auth

  # Backup
  backup_retention_period      = var.backup_retention_days
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "Mon:04:00-Mon:05:00"
  copy_tags_to_snapshot        = true

  # Deletion protection
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${var.environment}-final-${formatdate("YYYY-MM-DD", timestamp())}"

  # CloudWatch Logs
  enabled_cloudwatch_logs_exports = ["postgresql"]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-aurora"
  })

  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}

# Aurora Serverless v2 Instance(s)
resource "aws_rds_cluster_instance" "main" {
  count = var.instance_count

  identifier         = "${var.project_name}-${var.environment}-aurora-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.serverless" # Required for Serverless v2
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  db_parameter_group_name = aws_db_parameter_group.aurora.name

  # Monitoring
  performance_insights_enabled = var.performance_insights_enabled
  monitoring_interval          = var.enhanced_monitoring_interval
  monitoring_role_arn          = var.enhanced_monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  auto_minor_version_upgrade = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-aurora-${count.index + 1}"
  })
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  count = var.enhanced_monitoring_interval > 0 ? 1 : 0

  name = "${var.project_name}-${var.environment}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.enhanced_monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# IAM Policy for Data API access (for Lambda functions)
resource "aws_iam_policy" "data_api_access" {
  count = var.enable_data_api ? 1 : 0

  name        = "${var.project_name}-${var.environment}-aurora-data-api"
  description = "Allows access to Aurora Data API"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-data:ExecuteStatement",
          "rds-data:BatchExecuteStatement",
          "rds-data:BeginTransaction",
          "rds-data:CommitTransaction",
          "rds-data:RollbackTransaction"
        ]
        Resource = aws_rds_cluster.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.db_secret_arn != "" ? var.db_secret_arn : "*"
      }
    ]
  })
}

# RDS Proxy for connection pooling (recommended for Lambda)
resource "aws_db_proxy" "main" {
  count = var.enable_rds_proxy ? 1 : 0

  name                   = "${var.project_name}-${var.environment}-proxy"
  debug_logging          = false
  engine_family          = "POSTGRESQL"
  idle_client_timeout    = 1800
  require_tls            = true
  role_arn               = aws_iam_role.rds_proxy[0].arn
  vpc_security_group_ids = [aws_security_group.aurora.id]
  vpc_subnet_ids         = var.database_subnet_ids

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = var.enable_iam_auth ? "REQUIRED" : "DISABLED"
    secret_arn  = var.db_secret_arn
    description = "Database credentials"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-proxy"
  })
}

resource "aws_db_proxy_default_target_group" "main" {
  count = var.enable_rds_proxy ? 1 : 0

  db_proxy_name = aws_db_proxy.main[0].name

  connection_pool_config {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "main" {
  count = var.enable_rds_proxy ? 1 : 0

  db_proxy_name         = aws_db_proxy.main[0].name
  target_group_name     = aws_db_proxy_default_target_group.main[0].name
  db_cluster_identifier = aws_rds_cluster.main.id
}

# IAM Role for RDS Proxy
resource "aws_iam_role" "rds_proxy" {
  count = var.enable_rds_proxy ? 1 : 0

  name = "${var.project_name}-${var.environment}-rds-proxy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "rds_proxy" {
  count = var.enable_rds_proxy ? 1 : 0

  name = "secrets-access"
  role = aws_iam_role.rds_proxy[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.db_secret_arn
      },
      {
        Effect   = "Allow"
        Action   = "kms:Decrypt"
        Resource = var.kms_key_arn != "" ? var.kms_key_arn : "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${data.aws_region.current.id}.amazonaws.com"
          }
        }
      }
    ]
  })
}

data "aws_region" "current" {}
