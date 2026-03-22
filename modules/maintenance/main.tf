locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ECR repository for maintenance container
resource "aws_ecr_repository" "maintenance" {
  name                 = "${var.project_name}-maintenance"
  image_tag_mutability = "MUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${local.name_prefix}-maintenance-ecr" }
}

resource "aws_ecr_lifecycle_policy" "maintenance" {
  repository = aws_ecr_repository.maintenance.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 5 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 5
      }
      action = { type = "expire" }
    }]
  })
}

# ECS task definition for maintenance job
resource "aws_ecs_task_definition" "maintenance" {
  family                   = "${local.name_prefix}-maintenance"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([{
    name  = "maintenance"
    image = "${aws_ecr_repository.maintenance.repository_url}:latest"

    environment = [
      { name = "EVENT_RETENTION_DAYS", value = tostring(var.event_retention_days) },
    ]

    secrets = [
      { name = "DATABASE_URL", valueFrom = var.db_connection_string_secret_arn },
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.log_group_name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "maintenance"
      }
    }
  }])

  tags = { Name = "${local.name_prefix}-maintenance-task" }
}

# EventBridge rule -- daily at 2 AM UTC (mirrors Azure cron)
resource "aws_scheduler_schedule" "maintenance" {
  name       = "${local.name_prefix}-db-maintenance"
  group_name = "default"

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = "cron(0 2 * * ? *)"
  schedule_expression_timezone = "UTC"

  target {
    arn      = var.ecs_cluster_arn
    role_arn = aws_iam_role.scheduler.arn

    ecs_parameters {
      task_definition_arn = aws_ecs_task_definition.maintenance.arn
      launch_type         = "FARGATE"
      task_count          = 1

      network_configuration {
        subnets          = var.private_subnet_ids
        security_groups  = var.security_group_ids
        assign_public_ip = false
      }
    }
  }
}

# IAM role for EventBridge Scheduler to run ECS tasks
resource "aws_iam_role" "scheduler" {
  name = "${local.name_prefix}-maintenance-scheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "scheduler.amazonaws.com"
      }
    }]
  })

  tags = { Name = "${local.name_prefix}-maintenance-scheduler" }
}

resource "aws_iam_role_policy" "scheduler_ecs" {
  name = "ecs-run-task"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
        ]
        Resource = aws_ecs_task_definition.maintenance.arn
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole",
        ]
        Resource = [
          var.ecs_execution_role_arn,
          var.ecs_task_role_arn,
        ]
      },
    ]
  })
}
