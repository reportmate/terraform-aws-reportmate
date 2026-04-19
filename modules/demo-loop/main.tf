locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# ECR repository for demo-loop container
resource "aws_ecr_repository" "demo_loop" {
  name                 = "${var.project_name}-demo-loop"
  image_tag_mutability = "MUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${local.name_prefix}-demo-loop-ecr" }
}

resource "aws_ecr_lifecycle_policy" "demo_loop" {
  repository = aws_ecr_repository.demo_loop.name

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

# ECS task definition for demo-loop (long-running service)
resource "aws_ecs_task_definition" "demo_loop" {
  family                   = "${local.name_prefix}-demo-loop"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([{
    name  = "demo-loop"
    image = "${aws_ecr_repository.demo_loop.repository_url}:latest"

    environment = [
      { name = "DEMO_API_URL", value = var.api_url },
      { name = "BATCH_SIZE", value = tostring(var.batch_size) },
      { name = "BATCH_INTERVAL", value = tostring(var.batch_interval) },
      { name = "FULL_INTERVAL", value = tostring(var.full_interval) },
      { name = "DEVICE_COUNT", value = tostring(var.device_count) },
    ]

    secrets = [
      { name = "REPORTMATE_PASSPHRASE", valueFrom = var.client_passphrase_secret_arn },
    ]

    # Script name / flags match the reportmate-demo-loop container image.
    command = [
      "python", "-u", "demo-data-generator.py",
      "--loop",
      "--api-url", var.api_url,
      "--count", tostring(var.device_count),
      "--batch-size", tostring(var.batch_size),
      "--batch-interval", tostring(var.batch_interval),
      "--full-interval", tostring(var.full_interval),
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.log_group_name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "demo-loop"
      }
    }
  }])

  tags = { Name = "${local.name_prefix}-demo-loop-task" }
}

# ECS service -- keeps demo-loop running continuously
resource "aws_ecs_service" "demo_loop" {
  name            = "${local.name_prefix}-demo-loop"
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.demo_loop.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = var.security_group_ids
    assign_public_ip = false
  }

  # Allow rolling updates with zero downtime
  deployment_minimum_healthy_percent = 0
  deployment_maximum_percent         = 100

  tags = { Name = "${local.name_prefix}-demo-loop-service" }
}
