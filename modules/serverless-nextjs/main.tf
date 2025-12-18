# Serverless Next.js using Lambda + CloudFront (OpenNext Pattern)
# This deploys Next.js as Lambda functions behind CloudFront
# No containers, no servers - 100% serverless!

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 5.0"
      configuration_aliases = [aws.us_east_1]
    }
  }
}

# Lambda function for server-side rendering (SSR)
resource "aws_lambda_function" "nextjs_server" {
  function_name = "${var.project_name}-${var.environment}-nextjs-server"
  description   = "Next.js server-side rendering function"
  role          = aws_iam_role.nextjs_lambda.arn

  # Use provided package or placeholder
  filename         = var.lambda_package_path != "" ? var.lambda_package_path : null
  s3_bucket        = var.lambda_s3_bucket != "" ? var.lambda_s3_bucket : null
  s3_key           = var.lambda_s3_key != "" ? var.lambda_s3_key : null
  source_code_hash = var.lambda_source_hash

  handler     = "index.handler"
  runtime     = "nodejs20.x"
  timeout     = var.lambda_timeout
  memory_size = var.lambda_memory

  # VPC config for database access (optional)
  dynamic "vpc_config" {
    for_each = var.enable_vpc ? [1] : []
    content {
      subnet_ids         = var.private_subnet_ids
      security_group_ids = [aws_security_group.lambda[0].id]
    }
  }

  environment {
    variables = merge({
      NODE_ENV              = "production"
      NEXTAUTH_URL          = var.app_url
      NEXTAUTH_SECRET       = var.nextauth_secret
      API_BASE_URL          = var.api_base_url
      DATABASE_URL          = var.database_url
      REPORTMATE_PASSPHRASE = var.api_passphrase
    }, var.environment_variables)
  }

  # Enable X-Ray tracing
  tracing_config {
    mode = var.enable_xray ? "Active" : "PassThrough"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nextjs-server"
  })

  depends_on = [aws_cloudwatch_log_group.nextjs_server]
}

# Lambda function URL (alternative to API Gateway, simpler and cheaper)
resource "aws_lambda_function_url" "nextjs_server" {
  count = var.use_function_url ? 1 : 0

  function_name      = aws_lambda_function.nextjs_server.function_name
  authorization_type = "NONE" # CloudFront handles auth

  cors {
    allow_origins  = ["*"]
    allow_methods  = ["*"]
    allow_headers  = ["*"]
    expose_headers = ["*"]
    max_age        = 86400
  }
}

# Lambda for Image Optimization (Next.js Image component)
resource "aws_lambda_function" "image_optimizer" {
  count = var.enable_image_optimization ? 1 : 0

  function_name = "${var.project_name}-${var.environment}-image-optimizer"
  description   = "Next.js image optimization function"
  role          = aws_iam_role.nextjs_lambda.arn

  filename         = var.image_optimizer_package_path != "" ? var.image_optimizer_package_path : null
  s3_bucket        = var.lambda_s3_bucket != "" ? var.lambda_s3_bucket : null
  s3_key           = var.image_optimizer_s3_key != "" ? var.image_optimizer_s3_key : null
  source_code_hash = var.image_optimizer_source_hash

  handler     = "index.handler"
  runtime     = "nodejs20.x"
  timeout     = 30
  memory_size = 1024 # Image processing needs more memory

  environment {
    variables = {
      BUCKET_NAME = var.assets_bucket_name
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-image-optimizer"
  })
}

# Lambda function URL for image optimizer
resource "aws_lambda_function_url" "image_optimizer" {
  count = var.enable_image_optimization && var.use_function_url ? 1 : 0

  function_name      = aws_lambda_function.image_optimizer[0].function_name
  authorization_type = "NONE"
}

# API Gateway HTTP API (alternative to function URLs)
resource "aws_apigatewayv2_api" "nextjs" {
  count = var.use_api_gateway ? 1 : 0

  name          = "${var.project_name}-${var.environment}-nextjs"
  protocol_type = "HTTP"
  description   = "API Gateway for Next.js application"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS", "HEAD", "PATCH"]
    allow_headers = ["*"]
    max_age       = 86400
  }

  tags = var.tags
}

resource "aws_apigatewayv2_stage" "nextjs" {
  count = var.use_api_gateway ? 1 : 0

  api_id      = aws_apigatewayv2_api.nextjs[0].id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway[0].arn
    format = jsonencode({
      requestId          = "$context.requestId"
      ip                 = "$context.identity.sourceIp"
      requestTime        = "$context.requestTime"
      httpMethod         = "$context.httpMethod"
      routeKey           = "$context.routeKey"
      status             = "$context.status"
      responseLength     = "$context.responseLength"
      integrationLatency = "$context.integrationLatency"
    })
  }

  default_route_settings {
    throttling_burst_limit = var.api_throttle_burst
    throttling_rate_limit  = var.api_throttle_rate
  }

  tags = var.tags
}

resource "aws_apigatewayv2_integration" "nextjs" {
  count = var.use_api_gateway ? 1 : 0

  api_id                 = aws_apigatewayv2_api.nextjs[0].id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.nextjs_server.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "nextjs" {
  count = var.use_api_gateway ? 1 : 0

  api_id    = aws_apigatewayv2_api.nextjs[0].id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.nextjs[0].id}"
}

resource "aws_lambda_permission" "api_gateway" {
  count = var.use_api_gateway ? 1 : 0

  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.nextjs_server.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.nextjs[0].execution_arn}/*/*"
}

# IAM Role for Lambda
resource "aws_iam_role" "nextjs_lambda" {
  name = "${var.project_name}-${var.environment}-nextjs-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Lambda basic execution
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.nextjs_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC access for Lambda (when enabled)
resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  count = var.enable_vpc ? 1 : 0

  role       = aws_iam_role.nextjs_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# X-Ray tracing
resource "aws_iam_role_policy_attachment" "lambda_xray" {
  count = var.enable_xray ? 1 : 0

  role       = aws_iam_role.nextjs_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

# Custom policy for S3 and Secrets access
resource "aws_iam_role_policy" "nextjs_lambda" {
  name = "nextjs-permissions"
  role = aws_iam_role.nextjs_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = var.assets_bucket_arn != "" ? "${var.assets_bucket_arn}/*" : "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = var.secrets_arns
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage"
        ]
        Resource = var.sqs_queue_arns
      }
    ]
  })
}

# Security Group for Lambda in VPC
resource "aws_security_group" "lambda" {
  count = var.enable_vpc ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-lambda-"
  description = "Security group for Lambda functions"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-lambda-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "nextjs_server" {
  name              = "/aws/lambda/${var.project_name}-${var.environment}-nextjs-server"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  count = var.use_api_gateway ? 1 : 0

  name              = "/aws/apigateway/${var.project_name}-${var.environment}-nextjs"
  retention_in_days = var.log_retention_days

  tags = var.tags
}

# Lambda Provisioned Concurrency (optional, for consistent performance)
resource "aws_lambda_provisioned_concurrency_config" "nextjs_server" {
  count = var.provisioned_concurrency > 0 ? 1 : 0

  function_name                     = aws_lambda_function.nextjs_server.function_name
  provisioned_concurrent_executions = var.provisioned_concurrency
  qualifier                         = aws_lambda_function.nextjs_server.version
}

# Lambda@Edge for static asset caching headers (optional)
resource "aws_lambda_function" "edge_headers" {
  count = var.enable_edge_headers ? 1 : 0

  provider      = aws.us_east_1 # Lambda@Edge must be in us-east-1
  function_name = "${var.project_name}-${var.environment}-edge-headers"
  description   = "Add cache headers to static assets"
  role          = aws_iam_role.edge_lambda[0].arn

  filename = var.edge_lambda_package_path
  handler  = "index.handler"
  runtime  = "nodejs20.x"
  publish  = true # Required for Lambda@Edge

  tags = var.tags
}

resource "aws_iam_role" "edge_lambda" {
  count = var.enable_edge_headers ? 1 : 0

  name = "${var.project_name}-${var.environment}-edge-lambda"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "edgelambda.amazonaws.com"
          ]
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "edge_lambda_basic" {
  count = var.enable_edge_headers ? 1 : 0

  role       = aws_iam_role.edge_lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
