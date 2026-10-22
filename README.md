# ReportMate AWS Infrastructure

A sample Terraform configuration for deploying ReportMate on AWS, as the AWS counterpart to the Azure deployment.

This is a reference to adapt, not a turnkey deployment. Fork or copy it, then set your own region, names, domains, sizing, state backend and secrets before you plan anything. It carries no organization's real values, and nothing here deploys automatically.

Development guide: [wiki](wiki/README.md)

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
  auth/         Cognito user pool for dashboard sign-in
  storage/      SQS ingest queue and S3 bucket
  messaging/    API Gateway WebSocket API for real-time events
  maintenance/  Scheduled database maintenance task
  monitoring/   CloudWatch log groups, SNS alerts, budget
  demo-loop/    Optional synthetic-payload demo service
bootstrap/      S3 bucket and DynamoDB table for the state backend
```

## Continuous Integration

[`.github/workflows/terraform.yml`](.github/workflows/terraform.yml) runs on pull requests and pushes to `main` that change Terraform files or the workflow. It checks formatting with `terraform fmt -check -recursive`, then runs `terraform init -backend=false` and `terraform validate` in the root module (which covers every module under `modules/`) and in `bootstrap/`. It uses no cloud credentials and never plans or applies; plan and apply belong in your own adapted copy.

## Container Deployment

After `terraform apply`, push images to ECR:

```bash
# Authenticate with ECR
aws ecr get-login-password --region ca-central-1 | docker login --username AWS --password-stdin <account>.dkr.ecr.ca-central-1.amazonaws.com

# Mirror the prebuilt API image from GHCR to ECR (the reportmate-api repo CI builds it)
docker pull --platform linux/amd64 ghcr.io/reportmate/reportmate-api:latest
docker tag ghcr.io/reportmate/reportmate-api:latest <account>.dkr.ecr.ca-central-1.amazonaws.com/reportmate-api:latest
docker push <account>.dkr.ecr.ca-central-1.amazonaws.com/reportmate-api:latest

# Update ECS service
aws ecs update-service --cluster reportmate-prod-cluster --service reportmate-prod-api --force-new-deployment
```
