# ReportMate AWS Infrastructure

Terraform modules for deploying ReportMate infrastructure on Amazon Web Services (AWS). This is a complete replica of the Azure infrastructure, providing the same capabilities using AWS-native services.

## Architecture

```
                                    ┌─────────────────┐
                                    │   Route 53      │
                                    │     DNS         │
                                    └────────┬────────┘
                                             │
                                    ┌────────▼────────┐
                                    │   CloudFront    │
                                    │      CDN        │
                                    └────────┬────────┘
                                             │
              ┌──────────────────────────────┼──────────────────────────────┐
              │                              │                              │
     ┌────────▼────────┐           ┌────────▼────────┐           ┌────────▼────────┐
     │   S3 Assets     │           │      ALB        │           │  API Gateway    │
     │    Bucket       │           │  (App Load Bal) │           │    REST API     │
     └─────────────────┘           └────────┬────────┘           └────────┬────────┘
                                            │                             │
                                   ┌────────▼────────┐           ┌────────▼────────┐
                                   │   ECS Fargate   │           │     Lambda      │
                                   │  (Next.js App)  │           │   Functions     │
                                   └────────┬────────┘           └────────┬────────┘
                                            │                             │
                                   ┌────────▼─────────────────────────────▼────────┐
                                   │                  VPC                          │
                                   │  ┌─────────────────────────────────────────┐  │
                                   │  │           Private Subnets               │  │
                                   │  └─────────────────────┬───────────────────┘  │
                                   │                        │                      │
                                   │  ┌─────────────────────▼───────────────────┐  │
                                   │  │            RDS PostgreSQL               │  │
                                   │  │           (Database Subnets)            │  │
                                   │  └─────────────────────────────────────────┘  │
                                   └───────────────────────────────────────────────┘

Supporting Services:
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│     Cognito     │  │     Secrets     │  │   CloudWatch    │  │       ECR       │
│  (User Pool)    │  │     Manager     │  │  (Monitoring)   │  │   (Registry)    │
└─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘
```

## Azure to AWS Service Mapping

| Azure Service | AWS Equivalent | Module |
|--------------|----------------|--------|
| Azure Container Apps | ECS Fargate + ALB | `containers` |
| Azure Functions | Lambda + API Gateway | `api` |
| Azure PostgreSQL | RDS PostgreSQL | `database` |
| Azure Storage Account | S3 | `storage` |
| Azure Web PubSub | API Gateway WebSocket + DynamoDB | `messaging` |
| Azure Front Door | CloudFront | `cdn` |
| Azure Key Vault | Secrets Manager | `secrets` |
| Azure App Insights | CloudWatch + X-Ray | `monitoring` |
| Azure Managed Identity | IAM Roles | (integrated) |
| Azure Container Registry | ECR | `ecr` |
| Azure Entra ID | Cognito | `auth` |
| Azure DNS | Route 53 | `dns` |
| Azure VNet | VPC | `networking` |

## Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- AWS account with permissions to create resources

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/reportmate/terraform-aws-reportmate.git
   cd terraform-aws-reportmate
   ```

2. **Create a terraform.tfvars file:**
   ```hcl
   project_name = "reportmate"
   environment  = "prod"
   aws_region   = "us-east-1"
   
   # Database
   db_password = "your-secure-password"
   
   # Custom domain (optional)
   enable_custom_domain = true
   domain_name         = "reportmate.example.com"
   ```

3. **Initialize and apply:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Module Structure

```
modules/
├── networking/     # VPC, subnets, NAT, VPC endpoints
├── database/       # RDS PostgreSQL
├── containers/     # ECS Fargate, ALB, auto-scaling
├── api/           # Lambda, API Gateway REST
├── storage/       # S3 buckets for assets, data, logs
├── secrets/       # Secrets Manager
├── messaging/     # WebSocket API, SQS, DynamoDB connections
├── monitoring/    # CloudWatch logs, dashboards, alarms
├── auth/          # Cognito User Pool
├── ecr/           # Elastic Container Registry
├── cdn/           # CloudFront distribution
└── dns/           # Route 53 records
```

## Configuration

### Required Variables

| Variable | Description |
|----------|-------------|
| `project_name` | Name of the project (used for resource naming) |
| `environment` | Environment name (dev, staging, prod) |
| `db_password` | Database password |

### Optional Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `aws_region` | `us-east-1` | AWS region |
| `vpc_cidr` | `10.0.0.0/16` | VPC CIDR block |
| `availability_zones` | `["us-east-1a", "us-east-1b", "us-east-1c"]` | Availability zones |
| `enable_auth` | `true` | Enable Cognito authentication |
| `enable_custom_domain` | `false` | Enable custom domain |
| `enable_ecr` | `true` | Create ECR repository |

### Container Configuration

```hcl
container_config = {
  cpu           = 512
  memory        = 1024
  desired_count = 2
  min_capacity  = 1
  max_capacity  = 10
  port          = 3000
}
```

### Database Configuration

```hcl
db_instance_class = "db.t3.medium"
db_storage_size   = 20
db_max_storage    = 100
```

## Outputs

| Output | Description |
|--------|-------------|
| `frontend_url` | Application URL |
| `api_endpoint` | API Gateway endpoint |
| `database_endpoint` | RDS endpoint |
| `cognito_user_pool_id` | Cognito User Pool ID |
| `cognito_client_id` | Cognito App Client ID |
| `cloudfront_distribution_id` | CloudFront distribution ID |
| `ecr_repository_url` | ECR repository URL |

## Deployment Example

### Production Deployment

```hcl
module "reportmate" {
  source = "github.com/reportmate/terraform-aws-reportmate"
  
  project_name = "reportmate"
  environment  = "prod"
  aws_region   = "us-east-1"
  
  # Networking
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
  
  # Database
  db_password       = var.db_password
  db_instance_class = "db.t3.large"
  
  # Containers
  container_config = {
    cpu           = 1024
    memory        = 2048
    desired_count = 3
    min_capacity  = 2
    max_capacity  = 20
    port          = 3000
  }
  
  # Auth
  enable_auth   = true
  callback_urls = ["https://reportmate.example.com/api/auth/callback/cognito"]
  logout_urls   = ["https://reportmate.example.com"]
  
  # Custom domain
  enable_custom_domain = true
  domain_name         = "reportmate.example.com"
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789:certificate/xxx"
  
  tags = {
    Project     = "ReportMate"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}
```

## Security Considerations

1. **Network Security:**
   - All resources in private subnets (except ALB)
   - VPC endpoints for AWS services
   - Security groups with least privilege

2. **Data Encryption:**
   - RDS encryption at rest
   - S3 server-side encryption
   - Secrets Manager encryption

3. **Access Control:**
   - IAM roles with minimal permissions
   - Cognito for user authentication
   - API key for device clients

## Cost Optimization

- Use Fargate Spot for non-critical workloads
- Enable auto-scaling with appropriate thresholds
- Use S3 lifecycle policies for log retention
- Choose appropriate RDS instance sizes
- Use CloudFront price class appropriate for your audience

## Migration from Azure

See [MIGRATION_GUIDE.md](./docs/MIGRATION_GUIDE.md) for detailed instructions on migrating from Azure infrastructure.

## Contributing

Please see [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

## License

MIT License - See [LICENSE](./LICENSE) for details.
