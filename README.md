# ReportMate AWS Infrastructure

A sample Terraform configuration for deploying ReportMate on AWS, as the AWS counterpart to the Azure deployment.

This is a reference to adapt, not a turnkey deployment. Fork or copy it, then set your own region, names, domains, sizing, state backend and secrets before you plan anything. It carries no organization's real values, and nothing here deploys automatically.

Development guide: [wiki](wiki/README.md)

## Architecture

- **Compute**: ECS Fargate (API + Frontend services)
- **Database**: RDS PostgreSQL 16
- **Registry**: ECR (API + Frontend repositories)
- **Networking**: VPC, public/private subnets, NAT Gateway, ALB (or additive subnets in an existing VPC)
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
  auth/         Cognito user pool for dashboard sign-in (skipped with enable_cognito = false)
  storage/      SQS ingest queue and S3 bucket
  messaging/    API Gateway WebSocket API for real-time events
  maintenance/  Scheduled database maintenance task
  monitoring/   CloudWatch log groups, SNS alerts, budget
  demo-loop/    Optional synthetic-payload demo service
bootstrap/      S3 bucket and DynamoDB table for the state backend
```

## Continuous Integration

[`.github/workflows/terraform.yml`](.github/workflows/terraform.yml) runs on pull requests and pushes to `main` that change Terraform files or the workflow. It checks formatting with `terraform fmt -check -recursive`, then runs `terraform init -backend=false` and `terraform validate` in the root module (which covers every module under `modules/`) and in `bootstrap/`. It uses no cloud credentials and never plans or applies; plan and apply belong in your own adapted copy.

## Deploying into an existing VPC with Entra ID and a CDN

Every input in this section is optional. With none of them set, the module behaves exactly as before: its own VPC, Cognito sign-in and an open ALB. Commented placeholders for all of them are in `terraform.tfvars.example`.

### Existing VPC

Set `existing_vpc_id` to deploy into a VPC you already run. The module then creates no VPC, internet gateway or NAT gateway. It adds its own subnets from `private_subnet_cidrs` and `public_subnet_cidrs` (each maps an availability zone to a CIDR, with at least two zones and the same zones in both). It also adds one private route table whose default route goes to `existing_nat_gateway_id`, and one public route table whose default route goes to the internet gateway already attached to the VPC. Existing subnets and route tables are never modified.

In this mode VPC flow logs cover only the module's own subnets. Leave `enable_vpc_endpoints` off if the VPC already has interface endpoints with private DNS for ECR, CloudWatch Logs or Secrets Manager, and set `enable_s3_gateway_endpoint = false` if S3 endpoints are managed centrally.

### Microsoft Entra ID sign-in

Set `enable_cognito = false` to skip the Cognito user pool and sign in with Entra ID instead. Provide `azure_ad_client_id`, `azure_ad_tenant_id`, `azure_ad_client_secret` and `public_url`, and optionally `allowed_domains` and `nextauth_secret` (generated when empty). The client secret and NextAuth secret are stored in Secrets Manager. The app registration's redirect URI is `<public_url>/api/auth/callback/azure-ad`.

The API can accept Entra ID bearer tokens through `api_oidc_enabled`, `api_oidc_issuers` and `api_oidc_audiences`. Anything else either container needs goes in `api_extra_environment` and `frontend_extra_environment` (name to value), or in `api_extra_secrets` and `frontend_extra_secrets` (name to Secrets Manager ARN, which the execution role is granted read on).

### External CDN in front of the ALB

`cdn_origin_restriction` limits the ALB to a CDN. Its `prefix_list_id` is a managed prefix list holding the CDN's backend ranges, which you create for a CDN outside AWS. With it set, the ALB security group allows only HTTPS from that list, and the HTTPS listener returns 403 unless the request carries `header_name` with `header_value`, which the CDN adds on its way to the origin. Each prefix-list entry counts against the security group's rule quota.

In this mode anything that reaches the ALB without going through the CDN is refused. That includes the demo loop's default target and the WebSocket API's negotiate call, so point those at the CDN URL if you use them.

### Origin certificate with DNS outside AWS

The HTTPS listener uses `acm_certificate_arn`. To have Terraform request the certificate instead, set `create_origin_certificate = true` and `origin_domain_name`. ACM cannot attach a certificate it has not issued yet, so this takes two applies.

On the first apply, create the CNAME from the `origin_certificate_validation_records` output in your DNS provider, and CNAME `origin_domain_name` to the `alb_dns_name` output.

On the second apply, set `wait_for_certificate_validation = true`. Terraform waits for ACM to issue the certificate and puts it on the HTTPS listener.

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
