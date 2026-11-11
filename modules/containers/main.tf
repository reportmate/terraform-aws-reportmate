locals {
  name_prefix = "${var.project_name}-${var.environment}"

  # True when the ALB only accepts traffic from an external CDN. The variable
  # is sensitive (it carries the shared header value), so the on/off decision
  # is unwrapped explicitly for use in count and dynamic blocks.
  cdn_restricted = nonsensitive(var.cdn_origin_restriction != null)

  # "alb": the module's own ALB, target groups and ECS services (default).
  # "express": ECS Express Mode services with AWS-managed HTTPS URLs.
  alb_mode     = var.ingress_mode == "alb"
  express_mode = var.ingress_mode == "express"

  task_subnet_ids = var.tasks_in_public_subnets ? var.public_subnet_ids : var.private_subnet_ids

  # Express endpoints may come back as bare hostnames; normalise to URLs.
  api_express_endpoint      = try(aws_ecs_express_gateway_service.api[0].ingress_paths[0].endpoint, "")
  frontend_express_endpoint = try(aws_ecs_express_gateway_service.frontend[0].ingress_paths[0].endpoint, "")
  api_express_url           = local.api_express_endpoint == "" ? "" : (startswith(local.api_express_endpoint, "http") ? local.api_express_endpoint : "https://${local.api_express_endpoint}")
  frontend_express_url      = local.frontend_express_endpoint == "" ? "" : (startswith(local.frontend_express_endpoint, "http") ? local.frontend_express_endpoint : "https://${local.frontend_express_endpoint}")

  # In express mode an empty public_api_url falls back to the API's own URL.
  public_api_url = var.public_api_url != "" ? var.public_api_url : local.api_express_url

  entra_enabled = var.auth_provider == "azure-ad"
  site_url      = var.public_url
  site_hostname = var.public_url == "" ? "" : regex("^(?:[a-zA-Z][a-zA-Z0-9+.-]*://)?([^/:]+)", var.public_url)[0]

  # --- API container environment ---

  api_environment_base = concat(
    [
      { name = "ENVIRONMENT", value = var.environment },
      { name = "PORT", value = "8000" },
    ],
    var.api_oidc_enabled ? [
      { name = "ENABLE_OIDC_AUTH", value = "true" },
      { name = "OIDC_ISSUERS", value = join(",", var.api_oidc_issuers) },
      { name = "OIDC_AUDIENCE", value = join(",", var.api_oidc_audiences) },
    ] : [],
    length(var.allowed_domains) > 0 ? [{ name = "ALLOWED_DOMAINS", value = join(",", var.allowed_domains) }] : [],
    var.db_pool_max == null ? [] : [{ name = "DB_POOL_MAX", value = tostring(var.db_pool_max) }],
    var.db_pool_min == null ? [] : [{ name = "DB_POOL_MIN", value = tostring(var.db_pool_min) }],
  )

  api_environment = concat(
    [for e in local.api_environment_base : e if !contains(keys(var.api_extra_environment), e.name)],
    [for k, v in var.api_extra_environment : { name = k, value = v }],
  )

  api_secrets_base = concat(
    [
      { name = "DATABASE_URL", valueFrom = var.db_connection_string_secret_arn },
      { name = "API_INTERNAL_SECRET", valueFrom = var.api_internal_secret_arn },
      { name = "REPORTMATE_PASSPHRASE", valueFrom = var.client_passphrase_secret_arn },
    ],
    var.applicationinsights_connection_string_secret_arn == null ? [] : [
      { name = "APPLICATIONINSIGHTS_CONNECTION_STRING", valueFrom = var.applicationinsights_connection_string_secret_arn },
    ],
  )

  api_secrets = concat(
    [for e in local.api_secrets_base : e if !contains(keys(var.api_extra_secrets), e.name)],
    [for k, v in var.api_extra_secrets : { name = k, valueFrom = v }],
  )

  # --- Frontend container environment ---

  frontend_environment_base = concat(
    [
      { name = "ENVIRONMENT", value = var.environment },
      { name = "PORT", value = "3000" },
      { name = "NEXT_PUBLIC_DEMO_MODE", value = tostring(var.demo_mode) },
      { name = "API_BASE_URL", value = local.public_api_url },
      # NextAuth requires its own canonical URL in production.
      { name = "NEXTAUTH_URL", value = local.site_url == "" ? local.public_api_url : local.site_url },
    ],
    local.site_url == "" ? [] : [
      { name = "NEXTAUTH_URL_INTERNAL", value = local.site_url },
      { name = "NEXT_PUBLIC_SITE_URL", value = local.site_url },
      { name = "NEXT_PUBLIC_URL", value = local.site_url },
      { name = "HOST", value = local.site_hostname },
    ],
    local.entra_enabled ? [
      { name = "AUTH_PROVIDERS", value = "azure-ad" },
      { name = "DEFAULT_AUTH_PROVIDER", value = "azure-ad" },
      { name = "AZURE_AD_CLIENT_ID", value = var.azure_ad_client_id },
      { name = "AZURE_AD_TENANT_ID", value = var.azure_ad_tenant_id },
      { name = "NEXT_PUBLIC_AZURE_AD_CLIENT_ID", value = var.azure_ad_client_id },
      # Behind a CDN the Host header is the origin's, not the public one.
      { name = "AUTH_TRUST_HOST", value = "true" },
    ] : [],
    length(var.allowed_domains) > 0 ? [{ name = "ALLOWED_DOMAINS", value = join(",", var.allowed_domains) }] : [],
  )

  frontend_environment = concat(
    [for e in local.frontend_environment_base : e if !contains(keys(var.frontend_extra_environment), e.name)],
    [for k, v in var.frontend_extra_environment : { name = k, value = v }],
  )

  frontend_secrets_base = concat(
    [
      { name = "API_INTERNAL_SECRET", valueFrom = var.api_internal_secret_arn },
      { name = "KIOSK_TOKENS", valueFrom = var.kiosk_tokens_secret_arn },
      # Without NEXTAUTH_SECRET, NextAuth raises MissingSecretError (NO_SECRET)
      # and every /api/auth/session call 500s, gating the whole dashboard.
      { name = "NEXTAUTH_SECRET", valueFrom = var.nextauth_secret_arn },
    ],
    local.entra_enabled ? [
      { name = "AZURE_AD_CLIENT_SECRET", valueFrom = var.azure_ad_client_secret_arn },
    ] : [],
  )

  frontend_secrets = concat(
    [for e in local.frontend_secrets_base : e if !contains(keys(var.frontend_extra_secrets), e.name)],
    [for k, v in var.frontend_extra_secrets : { name = k, valueFrom = v }],
  )
}

# --- ECR Repositories ---

resource "aws_ecr_repository" "api" {
  name                 = "${var.project_name}-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${local.name_prefix}-api-ecr" }
}

resource "aws_ecr_repository" "frontend" {
  name                 = "${var.project_name}-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = false

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = { Name = "${local.name_prefix}-frontend-ecr" }
}

# Lifecycle policy to keep only last 10 images
resource "aws_ecr_lifecycle_policy" "api" {
  repository = aws_ecr_repository.api.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "frontend" {
  repository = aws_ecr_repository.frontend.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

# --- ECS Cluster ---

resource "aws_ecs_cluster" "main" {
  name = "${local.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = { Name = "${local.name_prefix}-cluster" }
}

# --- Security Groups ---

resource "aws_security_group" "alb" {
  count       = local.alb_mode ? 1 : 0
  name_prefix = "${local.name_prefix}-alb-"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  tags = { Name = "${local.name_prefix}-alb-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

# Open to the internet unless cdn_origin_restriction is set, in which case the
# only ingress is HTTPS from the CDN's prefix list.
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  count             = local.alb_mode && !local.cdn_restricted ? 1 : 0
  security_group_id = aws_security_group.alb[0].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  description       = "HTTP"
}

moved {
  from = aws_vpc_security_group_ingress_rule.alb_http
  to   = aws_vpc_security_group_ingress_rule.alb_http[0]
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  count             = local.alb_mode && !local.cdn_restricted ? 1 : 0
  security_group_id = aws_security_group.alb[0].id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS"
}

moved {
  from = aws_vpc_security_group_ingress_rule.alb_https
  to   = aws_vpc_security_group_ingress_rule.alb_https[0]
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_cdn" {
  count             = local.alb_mode && local.cdn_restricted ? 1 : 0
  security_group_id = aws_security_group.alb[0].id
  prefix_list_id    = nonsensitive(var.cdn_origin_restriction.prefix_list_id)
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS from the CDN origin prefix list"
}

resource "aws_vpc_security_group_egress_rule" "alb_out" {
  count             = local.alb_mode ? 1 : 0
  security_group_id = aws_security_group.alb[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All outbound"
}

resource "aws_security_group" "ecs_tasks" {
  name_prefix = "${local.name_prefix}-ecs-"
  description = "ECS tasks security group"
  vpc_id      = var.vpc_id

  tags = { Name = "${local.name_prefix}-ecs-sg" }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  count                        = local.alb_mode ? 1 : 0
  security_group_id            = aws_security_group.ecs_tasks.id
  referenced_security_group_id = aws_security_group.alb[0].id
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
  description                  = "Traffic from ALB"
}

resource "aws_vpc_security_group_egress_rule" "ecs_out" {
  security_group_id = aws_security_group.ecs_tasks.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "All outbound"
}

# --- ALB ---

resource "aws_lb" "main" {
  count              = local.alb_mode ? 1 : 0
  name               = "${local.name_prefix}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb[0].id]
  subnets            = var.public_subnet_ids

  tags = { Name = "${local.name_prefix}-alb" }
}

# HTTP listener - redirect to HTTPS
resource "aws_lb_listener" "http" {
  count             = local.alb_mode ? 1 : 0
  load_balancer_arn = aws_lb.main[0].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# 443 listener. HTTPS when acm_certificate_arn is set, HTTP otherwise.
# Most production deployments will set acm_certificate_arn; the HTTP fallback
# exists only so a fresh apply can stand up before a cert is requested.
resource "aws_lb_listener" "https" {
  count             = local.alb_mode ? 1 : 0
  load_balancer_arn = aws_lb.main[0].arn
  port              = 443
  protocol          = var.acm_certificate_arn == "" ? "HTTP" : "HTTPS"
  ssl_policy        = var.acm_certificate_arn == "" ? null : "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn == "" ? null : var.acm_certificate_arn

  # With cdn_origin_restriction, anything that did not come through the CDN
  # (no shared origin header) gets a 403; the listener rules below forward
  # only requests that carry it.
  default_action {
    type             = local.cdn_restricted ? "fixed-response" : "forward"
    target_group_arn = local.cdn_restricted ? null : aws_lb_target_group.frontend[0].arn

    dynamic "fixed_response" {
      for_each = local.cdn_restricted ? [1] : []
      content {
        content_type = "text/plain"
        message_body = "Forbidden"
        status_code  = "403"
      }
    }
  }
}

# --- Target Groups ---

resource "aws_lb_target_group" "api" {
  count       = local.alb_mode ? 1 : 0
  name        = "${local.name_prefix}-api-tg"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/api/v1/health"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    matcher             = "200"
  }

  tags = { Name = "${local.name_prefix}-api-tg" }
}

resource "aws_lb_target_group" "frontend" {
  count       = local.alb_mode ? 1 : 0
  name        = "${local.name_prefix}-fe-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 10
    interval            = 30
    matcher             = "200"
  }

  tags = { Name = "${local.name_prefix}-frontend-tg" }
}

# Route /api/* to the API target group
resource "aws_lb_listener_rule" "api" {
  count        = local.alb_mode ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api[0].arn
  }

  condition {
    path_pattern {
      values = ["/api/v1/*"]
    }
  }

  dynamic "condition" {
    for_each = local.cdn_restricted ? [1] : []
    content {
      http_header {
        http_header_name = nonsensitive(var.cdn_origin_restriction.header_name)
        values           = [var.cdn_origin_restriction.header_value]
      }
    }
  }
}

# Everything else goes to the frontend, but only through the CDN.
resource "aws_lb_listener_rule" "frontend_cdn" {
  count        = local.alb_mode && local.cdn_restricted ? 1 : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend[0].arn
  }

  condition {
    http_header {
      http_header_name = nonsensitive(var.cdn_origin_restriction.header_name)
      values           = [var.cdn_origin_restriction.header_value]
    }
  }
}

# --- ECS Task Definitions ---

resource "aws_ecs_task_definition" "api" {
  count                    = local.alb_mode ? 1 : 0
  family                   = "${local.name_prefix}-api"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.api_cpu
  memory                   = var.api_memory
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([{
    name  = "api"
    image = "${aws_ecr_repository.api.repository_url}:${var.api_image_tag}"

    portMappings = [{
      containerPort = 8000
      protocol      = "tcp"
    }]

    environment = local.api_environment
    secrets     = local.api_secrets

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.api_log_group_name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "api"
      }
    }

    # The health check hits /api/v1/health, which opens a DB connection. Under
    # DB memory pressure / write contention a fresh connection can exceed a 5s
    # timeout, failing the check and crash-looping the task. Generous thresholds
    # (15s timeout, 5 retries, 90s start grace) let a cold-starting task ride
    # out transient DB slowness instead of being killed.
    healthCheck = {
      command     = ["CMD-SHELL", "curl -f http://localhost:8000/api/v1/health || exit 1"]
      interval    = 30
      timeout     = 15
      retries     = 5
      startPeriod = 90
    }
  }])

  # Omitted for the X86_64 default so existing task definitions are unchanged.
  dynamic "runtime_platform" {
    for_each = var.cpu_architecture == "X86_64" ? [] : [1]
    content {
      cpu_architecture        = var.cpu_architecture
      operating_system_family = "LINUX"
    }
  }

  tags = { Name = "${local.name_prefix}-api-task" }
}

resource "aws_ecs_task_definition" "frontend" {
  count                    = local.alb_mode ? 1 : 0
  family                   = "${local.name_prefix}-frontend"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.frontend_cpu
  memory                   = var.frontend_memory
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([{
    name  = "frontend"
    image = "${aws_ecr_repository.frontend.repository_url}:${var.frontend_image_tag}"

    portMappings = [{
      containerPort = 3000
      protocol      = "tcp"
    }]

    environment = local.frontend_environment
    secrets     = local.frontend_secrets

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.frontend_log_group_name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "frontend"
      }
    }

  }])

  # Omitted for the X86_64 default so existing task definitions are unchanged.
  dynamic "runtime_platform" {
    for_each = var.cpu_architecture == "X86_64" ? [] : [1]
    content {
      cpu_architecture        = var.cpu_architecture
      operating_system_family = "LINUX"
    }
  }

  tags = { Name = "${local.name_prefix}-frontend-task" }
}

# --- ECS Services ---

resource "aws_ecs_service" "api" {
  count           = local.alb_mode ? 1 : 0
  name            = "${local.name_prefix}-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api[0].arn
  desired_count   = var.api_min_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.task_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = var.tasks_in_public_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api[0].arn
    container_name   = "api"
    container_port   = 8000
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  tags = { Name = "${local.name_prefix}-api-service" }
}

resource "aws_ecs_service" "frontend" {
  count           = local.alb_mode ? 1 : 0
  name            = "${local.name_prefix}-frontend"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frontend[0].arn
  desired_count   = var.frontend_min_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.task_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = var.tasks_in_public_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend[0].arn
    container_name   = "frontend"
    container_port   = 3000
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  tags = { Name = "${local.name_prefix}-frontend-service" }
}

# --- Auto Scaling ---

resource "aws_appautoscaling_target" "api" {
  count              = local.alb_mode ? 1 : 0
  max_capacity       = var.api_max_count
  min_capacity       = var.api_min_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "api_cpu" {
  count              = local.alb_mode ? 1 : 0
  name               = "${local.name_prefix}-api-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api[0].resource_id
  scalable_dimension = aws_appautoscaling_target.api[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.api[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

resource "aws_appautoscaling_target" "frontend" {
  count              = local.alb_mode ? 1 : 0
  max_capacity       = var.frontend_max_count
  min_capacity       = var.frontend_min_count
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.frontend[0].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "frontend_cpu" {
  count              = local.alb_mode ? 1 : 0
  name               = "${local.name_prefix}-frontend-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.frontend[0].resource_id
  scalable_dimension = aws_appautoscaling_target.frontend[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.frontend[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}

# --- Moved addresses (resources gained a count for ingress_mode) ---

moved {
  from = aws_security_group.alb
  to   = aws_security_group.alb[0]
}

moved {
  from = aws_vpc_security_group_egress_rule.alb_out
  to   = aws_vpc_security_group_egress_rule.alb_out[0]
}

moved {
  from = aws_vpc_security_group_ingress_rule.ecs_from_alb
  to   = aws_vpc_security_group_ingress_rule.ecs_from_alb[0]
}

moved {
  from = aws_lb.main
  to   = aws_lb.main[0]
}

moved {
  from = aws_lb_listener.http
  to   = aws_lb_listener.http[0]
}

moved {
  from = aws_lb_listener.https
  to   = aws_lb_listener.https[0]
}

moved {
  from = aws_lb_target_group.api
  to   = aws_lb_target_group.api[0]
}

moved {
  from = aws_lb_target_group.frontend
  to   = aws_lb_target_group.frontend[0]
}

moved {
  from = aws_lb_listener_rule.api
  to   = aws_lb_listener_rule.api[0]
}

moved {
  from = aws_ecs_task_definition.api
  to   = aws_ecs_task_definition.api[0]
}

moved {
  from = aws_ecs_task_definition.frontend
  to   = aws_ecs_task_definition.frontend[0]
}

moved {
  from = aws_ecs_service.api
  to   = aws_ecs_service.api[0]
}

moved {
  from = aws_ecs_service.frontend
  to   = aws_ecs_service.frontend[0]
}

moved {
  from = aws_appautoscaling_target.api
  to   = aws_appautoscaling_target.api[0]
}

moved {
  from = aws_appautoscaling_policy.api_cpu
  to   = aws_appautoscaling_policy.api_cpu[0]
}

moved {
  from = aws_appautoscaling_target.frontend
  to   = aws_appautoscaling_target.frontend[0]
}

moved {
  from = aws_appautoscaling_policy.frontend_cpu
  to   = aws_appautoscaling_policy.frontend_cpu[0]
}

# --- Express Mode (ingress_mode = "express") ---
#
# Each service gets an AWS-managed load balancer, HTTPS listener, certificate
# and URL on *.ecs.<region>.on.aws. Express provisions an internet-facing load
# balancer only for public subnets, and then gives the tasks public IPs, so
# these services always run in the public subnets. The load balancer, its
# security group and its listener rules belong to AWS, not to this module.

resource "aws_vpc_security_group_ingress_rule" "ecs_from_vpc" {
  for_each          = local.express_mode ? toset(["3000", "8000"]) : toset([])
  security_group_id = aws_security_group.ecs_tasks.id
  cidr_ipv4         = var.vpc_cidr_block
  from_port         = tonumber(each.value)
  to_port           = tonumber(each.value)
  ip_protocol       = "tcp"
  description       = "Express Mode load balancer to container port ${each.value}"
}

resource "aws_ecs_express_gateway_service" "api" {
  count = local.express_mode ? 1 : 0

  service_name            = "${local.name_prefix}-api-express"
  cluster                 = aws_ecs_cluster.main.name
  execution_role_arn      = var.ecs_execution_role_arn
  infrastructure_role_arn = var.infrastructure_role_arn
  task_role_arn           = var.ecs_task_role_arn
  cpu                     = tostring(var.api_cpu)
  memory                  = tostring(var.api_memory)
  cpu_architecture        = var.cpu_architecture
  health_check_path       = "/api/v1/health"

  primary_container {
    image          = "${aws_ecr_repository.api.repository_url}:${var.api_image_tag}"
    container_port = 8000

    aws_logs_configuration {
      log_group         = var.api_log_group_name
      log_stream_prefix = "api"
    }

    dynamic "environment" {
      for_each = local.api_environment
      content {
        name  = environment.value.name
        value = environment.value.value
      }
    }

    dynamic "secret" {
      for_each = local.api_secrets
      content {
        name       = secret.value.name
        value_from = secret.value.valueFrom
      }
    }
  }

  network_configuration {
    subnets         = var.public_subnet_ids
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  scaling_target {
    auto_scaling_metric       = "AVERAGE_CPU"
    auto_scaling_target_value = 70
    min_task_count            = var.api_min_count
    max_task_count            = var.api_max_count
  }

  tags = { Name = "${local.name_prefix}-api-express" }
}

resource "aws_ecs_express_gateway_service" "frontend" {
  count = local.express_mode ? 1 : 0

  service_name            = "${local.name_prefix}-frontend-express"
  cluster                 = aws_ecs_cluster.main.name
  execution_role_arn      = var.ecs_execution_role_arn
  infrastructure_role_arn = var.infrastructure_role_arn
  task_role_arn           = var.ecs_task_role_arn
  cpu                     = tostring(var.frontend_cpu)
  memory                  = tostring(var.frontend_memory)
  cpu_architecture        = var.cpu_architecture
  health_check_path       = "/"

  primary_container {
    image          = "${aws_ecr_repository.frontend.repository_url}:${var.frontend_image_tag}"
    container_port = 3000

    aws_logs_configuration {
      log_group         = var.frontend_log_group_name
      log_stream_prefix = "frontend"
    }

    dynamic "environment" {
      for_each = local.frontend_environment
      content {
        name  = environment.value.name
        value = environment.value.value
      }
    }

    dynamic "secret" {
      for_each = local.frontend_secrets
      content {
        name       = secret.value.name
        value_from = secret.value.valueFrom
      }
    }
  }

  network_configuration {
    subnets         = var.public_subnet_ids
    security_groups = [aws_security_group.ecs_tasks.id]
  }

  scaling_target {
    auto_scaling_metric       = "AVERAGE_CPU"
    auto_scaling_target_value = 70
    min_task_count            = var.frontend_min_count
    max_task_count            = var.frontend_max_count
  }

  tags = { Name = "${local.name_prefix}-frontend-express" }
}
