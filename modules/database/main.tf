locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# --- Security Group ---

resource "aws_security_group" "database" {
  name_prefix = "${local.name_prefix}-db-"
  description = "Allow PostgreSQL access from ECS tasks"
  vpc_id      = var.vpc_id

  tags = { Name = "${local.name_prefix}-db-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_ecs" {
  count                        = length(var.allowed_security_group_ids)
  security_group_id            = aws_security_group.database.id
  referenced_security_group_id = var.allowed_security_group_ids[count.index]
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  description                  = "PostgreSQL from ECS"
}

# --- Subnet Group ---

resource "aws_db_subnet_group" "main" {
  name       = "${local.name_prefix}-db-subnet"
  subnet_ids = var.private_subnet_ids

  tags = { Name = "${local.name_prefix}-db-subnet" }
}

# --- RDS PostgreSQL ---

resource "aws_db_instance" "main" {
  identifier = "${local.name_prefix}-postgres"

  engine            = "postgres"
  engine_version    = "16"
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.database.id]

  multi_az            = false
  publicly_accessible = false

  backup_retention_period   = 7
  skip_final_snapshot       = false
  final_snapshot_identifier = "${local.name_prefix}-final-snapshot"

  performance_insights_enabled = false
  deletion_protection          = true

  tags = { Name = "${local.name_prefix}-postgres" }

  lifecycle {
    prevent_destroy = true
  }
}
