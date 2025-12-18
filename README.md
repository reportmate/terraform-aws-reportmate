# ReportMate AWS Infrastructure (100% Serverless)

Terraform modules for deploying ReportMate infrastructure on Amazon Web Services (AWS) using a **serverless-first architecture**. This provides feature parity with the Azure infrastructure while minimizing operational overhead and costs.

## 🎯 Architecture Overview

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
     │   S3 Assets     │           │  Lambda URL     │           │  API Gateway    │
     │    Bucket       │           │  (Next.js SSR)  │           │   HTTP API      │
     └─────────────────┘           └────────┬────────┘           └────────┬────────┘
                                            │                             │
                                   ┌────────▼────────┐           ┌────────▼────────┐
                                   │  Lambda@Edge    │           │     Lambda      │
                                   │ (Image Optim)   │           │   Functions     │
                                   └────────┬────────┘           └────────┬────────┘
                                            │                             │
                                            │                     ┌───────▼───────┐
                                            │                     │  RDS Proxy    │
                                            │                     │ (Conn Pool)   │
                                            │                     └───────┬───────┘
                                            │                             │
                                   ┌────────▼─────────────────────────────▼────────┐
                                   │              Aurora Serverless v2             │
                                   │                 (PostgreSQL)                  │
                                   │         ┌─────────────────────────┐          │
                                   │         │      Data API           │──────────│──► Direct Lambda Access
                                   │         │   (No VPC Required)     │          │    (No connection mgmt)
                                   │         └─────────────────────────┘          │
                                   └───────────────────────────────────────────────┘

Supporting Services:
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│     Cognito     │  │     Secrets     │  │   CloudWatch    │  │    SQS/SNS      │
│  (Auth/OIDC)    │  │     Manager     │  │   + X-Ray       │  │   (Messaging)   │
└─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────────┘
```

## ⚡ Serverless Benefits

| Benefit | Description |
|---------|-------------|
| **Zero servers to manage** | No EC2, no ECS clusters, no patches |
| **Pay-per-use** | Only pay for actual invocations |
| **Auto-scaling** | Scales from 0 to thousands automatically |
| **High availability** | Built-in across multiple AZs |
| **Fast deployments** | Deploy new code in seconds |

## 🔄 Azure to AWS Service Mapping

| Azure Service | AWS Serverless Equivalent | Module |
|--------------|---------------------------|--------|
| Azure Container Apps | **Lambda + Function URLs** | `serverless-nextjs` |
| Azure Functions | **Lambda + API Gateway HTTP** | `api` |
| Azure PostgreSQL Flexible | **Aurora Serverless v2** | `database` |
| Azure Storage Account | S3 | `storage` |
| Azure Web PubSub | **API Gateway WebSocket + SQS** | `messaging` |
| Azure Front Door | CloudFront | `cdn` |
| Azure Key Vault | Secrets Manager | `secrets` |
| Azure App Insights | CloudWatch + X-Ray | `monitoring` |
| Azure Managed Identity | IAM Roles | (integrated) |
| Azure Entra ID | Cognito | `auth` |
| Azure DNS | Route 53 | `dns` |
| Azure VNet | VPC (minimal, with endpoints) | `networking` |

## 📦 Module Structure

```
aws/
├── main.tf              # Root module orchestration
├── variables.tf         # Input variables
├── outputs.tf           # Output values
├── providers.tf         # AWS provider config
├── versions.tf          # Terraform version constraints
└── modules/
    ├── serverless-nextjs/   # Lambda-based Next.js (replaces ECS)
    │   ├── main.tf          # Lambda + Function URLs
    │   ├── variables.tf
    │   └── outputs.tf
    ├── database/            # Aurora Serverless v2 (replaces RDS)
    │   ├── main.tf          # Aurora cluster + Data API
    │   ├── variables.tf
    │   └── outputs.tf
    ├── api/                 # Lambda + API Gateway
    ├── cdn/                 # CloudFront with Lambda origins
    ├── storage/             # S3 buckets
    ├── secrets/             # Secrets Manager
    ├── messaging/           # WebSocket API + SQS
    ├── auth/                # Cognito User Pools
    ├── monitoring/          # CloudWatch + X-Ray
    ├── networking/          # VPC with endpoints
    └── dns/                 # Route 53
```

## 🚀 Quick Start

### Prerequisites

- Terraform >= 1.5.0
- AWS CLI configured with appropriate credentials
- Node.js 18+ (for building Next.js Lambda package)

### 1. Clone and Configure

```bash
git clone https://github.com/reportmate/terraform-aws-reportmate.git
cd terraform-aws-reportmate
```

### 2. Create terraform.tfvars

```hcl
# ===========================================
# BASIC CONFIGURATION
# ===========================================
project_name = "reportmate"
environment  = "prod"

# ===========================================
# DATABASE (Aurora Serverless v2)
# ===========================================
db_password = "your-secure-password-here"

# Serverless scaling (ACUs)
db_min_capacity = 0.5    # Minimum (can scale to 0 in dev)
db_max_capacity = 16     # Maximum (up to 128 ACUs)

# Serverless features
enable_db_data_api = true   # Query without VPC
enable_db_iam_auth = true   # Passwordless Lambda auth
enable_rds_proxy   = false  # Enable for high-concurrency

# ===========================================
# LAMBDA (Next.js)
# ===========================================
nextjs_lambda_bucket = "my-deployment-bucket"
nextjs_lambda_key    = "deployments/nextjs/server.zip"
nextjs_lambda_memory = 1024  # More memory = more CPU
nextjs_enable_vpc    = false # Use Data API instead

# ===========================================
# AUTHENTICATION
# ===========================================
enable_auth         = true
nextauth_secret     = "your-nextauth-secret"
client_passphrases  = "passphrase1,passphrase2"

# ===========================================
# CUSTOM DOMAIN (Optional)
# ===========================================
enable_custom_domain = true
custom_domain_name   = "reportmate.example.com"
acm_certificate_arn  = "arn:aws:acm:us-east-1:xxx:certificate/xxx"
route53_zone_id      = "ZXXXXXXXXXXXXX"

# ===========================================
# TAGS
# ===========================================
tags = {
  Project     = "ReportMate"
  Environment = "prod"
  ManagedBy   = "Terraform"
  Architecture = "Serverless"
}
```

### 3. Deploy

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply infrastructure
terraform apply
```

## 🔧 Aurora Serverless v2 Features

### Data API (Recommended)
Query your database directly from Lambda without VPC configuration:

```python
import boto3

client = boto3.client('rds-data')

response = client.execute_statement(
    resourceArn='arn:aws:rds:us-east-1:xxx:cluster:reportmate',
    secretArn='arn:aws:secretsmanager:us-east-1:xxx:secret:reportmate-db',
    database='reportmate',
    sql='SELECT * FROM devices WHERE id = :id',
    parameters=[{'name': 'id', 'value': {'stringValue': 'device-123'}}]
)
```

### IAM Authentication
Lambdas authenticate to Aurora using IAM roles - no passwords needed:

```python
import boto3
import psycopg2

rds = boto3.client('rds')
token = rds.generate_db_auth_token(
    DBHostname='cluster.xxx.us-east-1.rds.amazonaws.com',
    Port=5432,
    DBUsername='reportmate'
)

conn = psycopg2.connect(
    host='cluster.xxx.us-east-1.rds.amazonaws.com',
    database='reportmate',
    user='reportmate',
    password=token,
    sslmode='require'
)
```

### RDS Proxy
For high-concurrency scenarios, enable RDS Proxy for connection pooling:

```hcl
enable_rds_proxy = true
```

## 📊 Cost Optimization

### Development Environment
```hcl
environment          = "dev"
db_min_capacity      = 0.5      # Minimum ACUs
db_max_capacity      = 2        # Cap scaling
db_instance_count    = 1        # Single instance
single_nat_gateway   = true     # One NAT for all AZs
enable_rds_proxy     = false    # Skip proxy
deletion_protection  = false    # Allow easy teardown
skip_final_snapshot  = true
```

### Production Environment
```hcl
environment          = "prod"
db_min_capacity      = 2        # Higher baseline
db_max_capacity      = 32       # Scale for load
db_instance_count    = 2        # Reader replica
single_nat_gateway   = false    # HA across AZs
enable_rds_proxy     = true     # Connection pooling
deletion_protection  = true     # Prevent accidents
skip_final_snapshot  = false
```

## 📈 Monitoring

All Lambda functions include:
- **CloudWatch Logs**: Automatic log streaming
- **CloudWatch Metrics**: Invocations, errors, duration
- **X-Ray Tracing**: Distributed tracing across services
- **CloudWatch Alarms**: Automated alerting

Dashboard URL available in outputs:
```bash
terraform output cloudwatch_dashboard_name
```

## 🔐 Security

- **IAM Roles**: Least-privilege access for all Lambdas
- **Secrets Manager**: Encrypted credential storage
- **VPC Endpoints**: Private AWS API access
- **WAF Integration**: Optional web application firewall
- **Cognito**: OIDC-compliant authentication

## 🔗 Outputs

Key outputs after deployment:

```bash
# Application URL
terraform output frontend_url

# API endpoint
terraform output api_endpoint

# Database connection
terraform output database_connection_string

# Deployment summary
terraform output deployment_info
```

## 📚 Additional Resources

- [OpenNext](https://github.com/sst/open-next) - Next.js on Lambda
- [Aurora Serverless v2](https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/aurora-serverless-v2.html)
- [Lambda Function URLs](https://docs.aws.amazon.com/lambda/latest/dg/lambda-urls.html)

## 📝 License

MIT License - See LICENSE file for details.
