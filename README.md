# ReportMate AWS Infrastructure

A sample Terraform configuration for deploying ReportMate on AWS, as the AWS counterpart to the Azure deployment.

This is a reference to adapt, not a turnkey deployment. Fork or copy it, then set your own region, names, domains, sizing, state backend and secrets before you plan anything. It carries no organization's real values, and nothing here deploys automatically.

Development guide: [wiki](wiki/README.md)

## Architecture

- **Compute**: ECS Fargate (API + Frontend services)
- **Database**: RDS PostgreSQL 16
- **Registry**: ECR (API + Frontend repositories)
- **Networking**: VPC, public/private subnets, NAT Gateway, ALB (or an existing VPC, and optionally ECS Express Mode instead of the ALB)
- **Secrets**: AWS Secrets Manager
- **Monitoring**: CloudWatch Logs + SNS alerts
- **Identity**: IAM roles for ECS task execution and application access

## Prerequisites

- AWS CLI configured (`~/.aws/credentials`)
- Terraform >= 1.5 and AWS provider 6.71 or later
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

## Options

Every input in this section is optional. With none of them set, the module behaves as it did before: its own VPC with NAT, Cognito sign-in and its own open ALB. Commented placeholders for all of them are in `terraform.tfvars.example`.

### Existing VPC

Set `existing_vpc_id` to deploy into a VPC that another Terraform root owns, for example one shared by several applications. In this mode the module creates no VPC, internet gateway or NAT gateway. For each tier, private and public, choose one option:

- **Subnets that already exist**: pass `existing_private_subnet_ids` or `existing_public_subnet_ids`, with at least two subnets in different AZs. Their route tables stay with the VPC owner.
- **The module's own subnets**: pass `private_subnet_cidrs` or `public_subnet_cidrs`, mapping each AZ to a CIDR, with at least two AZs. The module creates the subnets and one route table per tier. Created private subnets route 0.0.0.0/0 to `existing_nat_gateway_id`. Created public subnets route to the internet gateway already attached to the VPC.

Existing subnets, route tables and gateways are never modified. VPC flow logs cover only the subnets the module creates. Leave `enable_vpc_endpoints` off if the VPC already has interface endpoints with private DNS for ECR, CloudWatch Logs or Secrets Manager. Set `enable_s3_gateway_endpoint = false` if S3 endpoints are managed centrally.

### Running without NAT

In the module's own VPC, `enable_nat_gateway = false` removes the NAT gateway and its cost. Private subnets then have no internet route, so set `tasks_in_public_subnets = true`. The API, frontend, maintenance and demo-loop tasks then run in the public subnets with public IPs, and reach ECR, Secrets Manager and CloudWatch Logs directly. Their security group still admits only the load balancer. RDS stays in the private subnets.

Turning NAT off on an existing deployment can leave the old default route in the private route tables. AWS keeps an inline route when its block is removed from the configuration, and the route then points at a deleted NAT gateway. Delete that route once the tasks have moved to the public subnets.

### Ingress: ALB or ECS Express Mode

`ingress_mode = "alb"` (the default) is the module's own ALB, target groups and ECS services. Use `acm_certificate_arn` to serve HTTPS on it.

`ingress_mode = "express"` runs the API and frontend as ECS Express Mode services (`aws_ecs_express_gateway_service`, AWS provider 6.71 or later). Each service gets an AWS-managed load balancer, HTTPS certificate and URL on `*.ecs.<region>.on.aws`, with no certificate or DNS of your own. The URLs are in the `api_service_url` and `frontend_service_url` outputs. CPU, memory, minimum and maximum task counts, CPU architecture, environment, secrets, task and execution roles, log groups and health-check paths carry over. The module adds the ECS infrastructure role that Express needs.

Express Mode has limits that the ALB mode does not:

- **Public subnets only**: Express creates an internet-facing load balancer only for public subnets, and then gives the tasks public IPs, so these services always run there.
- **No origin restriction**: the load balancer, its security group and its listener rules belong to AWS. The module cannot limit ingress to a CDN prefix list or check an origin header, so `cdn_origin_restriction` is rejected in this mode.
- **No container health check**: Express sets the target-group health check (5-second timeout) and accepts no container-level health check. An API that is slow to open a database connection can fail it more readily than in ALB mode.
- **URLs exist only after the first apply**: when `public_api_url` is empty, the frontend's `API_BASE_URL` falls back to the API's Express URL. The frontend cannot reference its own URL, so after the first apply, set `public_url` to the `frontend_service_url` output (or to your CDN hostname) and apply again so that NextAuth gets its canonical URL.
- **One routing path**: the API and frontend are separate hostnames, not one host with path routing.
- **Fixed settings**: the service name, cluster and infrastructure role cannot change after creation. Express also uses its own deployment strategy and scaling-policy defaults.

### Microsoft Entra ID sign-in

Set `enable_cognito = false` to skip the Cognito user pool and sign in with Entra ID instead. Provide `azure_ad_client_id`, `azure_ad_tenant_id`, `azure_ad_client_secret` and `public_url`, and optionally `allowed_domains` and `nextauth_secret` (generated when empty). The client secret and NextAuth secret are stored in Secrets Manager. The app registration's redirect URI is `<public_url>/api/auth/callback/azure-ad`.

The API can accept Entra ID bearer tokens through `api_oidc_enabled`, `api_oidc_issuers` and `api_oidc_audiences`. Anything else either container needs goes in `api_extra_environment` and `frontend_extra_environment` (name to value), or in `api_extra_secrets` and `frontend_extra_secrets` (name to Secrets Manager ARN, which the execution role is granted read on).

### External CDN in front of the ALB

In ALB mode, `cdn_origin_restriction` limits the ALB to a CDN. Its `prefix_list_id` is a managed prefix list holding the CDN's backend ranges, which you create for a CDN outside AWS. With it set, the ALB security group allows only HTTPS from that list, and the HTTPS listener returns 403 unless the request carries `header_name` with `header_value`, which the CDN adds on its way to the origin. Each prefix-list entry counts against the security group's rule quota.

Anything that reaches the ALB without going through the CDN is refused. That includes the demo loop's default target and the WebSocket API's negotiate call, so point those at the CDN URL if you use them.

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
