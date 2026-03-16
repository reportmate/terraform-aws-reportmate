# ReportMate AWS Infrastructure

Terraform modules for deploying ReportMate on AWS. Feature-parity with the Azure deployment.

## Architecture

- **Compute**: ECS Fargate (API + Frontend services)
- **Database**: RDS PostgreSQL 16
- **Registry**: ECR (API + Frontend repositories)
- **Networking**: VPC, public/private subnets, NAT Gateway, ALB
- **Secrets**: AWS Secrets Manager
- **Monitoring**: CloudWatch Logs + SNS alerts
- **Identity**: IAM roles for ECS task execution and application access

## Prerequisites

- AWS CLI configured (`~/.aws/credentials`)
- Terraform >= 1.5
- S3 bucket + DynamoDB table for state backend

## Quick Start

```bash
# 1. Initialize backend
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with real values

# 2. Create backend config
cat > backend.hcl <<EOF
bucket         = "reportmate-terraform-state"
key            = "prod/terraform.tfstate"
region         = "ca-central-1"
dynamodb_table = "reportmate-terraform-locks"
encrypt        = true
EOF

# 3. Initialize and plan
terraform init -backend-config=backend.hcl
terraform plan

# 4. Apply
terraform apply
```

## Module Structure

```
modules/
  networking/   VPC, subnets, NAT Gateway, route tables
  database/     RDS PostgreSQL, security groups, subnet group
  containers/   ECS Fargate cluster, services, ECR, ALB
  identity/     IAM roles and policies for ECS
  secrets/      Secrets Manager entries
  monitoring/   CloudWatch log groups, SNS alerts
```

## Container Deployment

After `terraform apply`, push images to ECR:

```bash
# Authenticate with ECR
aws ecr get-login-password --region ca-central-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.ca-central-1.amazonaws.com

# Build and push API
docker build -t reportmate-api ./infrastructure/azure/modules/api/
docker tag reportmate-api:latest <account>.dkr.ecr.ca-central-1.amazonaws.com/reportmate-api:latest
docker push <account>.dkr.ecr.ca-central-1.amazonaws.com/reportmate-api:latest

# Update ECS service
aws ecs update-service --cluster reportmate-prod-cluster --service reportmate-prod-api --force-new-deployment
```
