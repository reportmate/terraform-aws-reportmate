# ReportMate AWS infrastructure wiki

This repository is a sample Terraform configuration for running ReportMate on AWS, meant to be copied and adapted rather than deployed as is. It provisions the network, PostgreSQL database, container services, secrets, authentication, messaging, scheduled maintenance and monitoring that the ReportMate API and web dashboard run on, as the AWS counterpart to the Azure deployment.

## Read first

- [Project setup and quick start](../README.md)
- [Root module wiring](../main.tf)
- [Input variables](../variables.tf) and [example values](../terraform.tfvars.example)
- [Outputs](../outputs.tf)
- [State backend bootstrap](../bootstrap/main.tf) and [backend example](../backend.hcl.example)

## Architecture

The root module in [main.tf](../main.tf) composes one module per concern under [modules/](../modules). It requires Terraform 1.5 or later and the AWS provider 5.x, as pinned in [versions.tf](../versions.tf), and keeps state in an S3 backend configured at `terraform init` time.

[networking](../modules/networking/main.tf) creates the VPC, public and private subnets, NAT gateways and route tables, with optional VPC flow logs and VPC endpoints. [database](../modules/database/main.tf) runs RDS PostgreSQL in the private subnets and accepts connections only from the ECS task security group.

[containers](../modules/containers/main.tf) owns the ECR repositories, the ECS Fargate cluster, the API and frontend services, and the Application Load Balancer. The ALB serves HTTPS when an ACM certificate ARN is supplied and HTTP otherwise. The API image is built by the reportmate-api repository and mirrored from GHCR into ECR rather than built here.

[secrets](../modules/secrets/main.tf) stores the database password and connection string, the API internal secret, the client passphrase and kiosk viewer tokens in Secrets Manager. [auth](../modules/auth/main.tf) creates a Cognito user pool for dashboard sign-in and the NextAuth secret. [identity](../modules/identity/main.tf) defines the IAM roles that let ECS tasks pull images, read those secrets and write logs.

[storage](../modules/storage/main.tf) creates an SQS ingest queue with a dead-letter queue and an encrypted, versioned S3 bucket. [messaging](../modules/messaging/main.tf) provides an API Gateway WebSocket API for real-time events, mirroring Web PubSub on Azure. [maintenance](../modules/maintenance/main.tf) runs a database maintenance task on ECS from an EventBridge Scheduler rule at 02:00 UTC daily.

[monitoring](../modules/monitoring/main.tf) creates CloudWatch log groups, an SNS alert topic with optional email subscription, a daily cost budget and a NAT gateway egress alarm. [demo-loop](../modules/demo-loop/main.tf) is off by default; setting `enable_demo_loop` runs a service that resubmits synthetic device payloads for a public demo site.

## Development and verification

Follow the [README](../README.md) for prerequisites and the quick start. Create the state bucket and lock table once with the [bootstrap](../bootstrap/main.tf) module, copy [backend.hcl.example](../backend.hcl.example) and [terraform.tfvars.example](../terraform.tfvars.example) to their untracked names, then initialize and plan.

```bash
terraform init -backend-config=backend.hcl
```

Before opening a pull request, format and validate the configuration and review a plan against a non-production environment.

```bash
terraform fmt -check -recursive && terraform validate && terraform plan
```

The scripts in [scripts/](../scripts) read Terraform outputs to deploy images: [deploy-api.sh](../scripts/deploy-api.sh) mirrors a GHCR API image into ECR and restarts the service, [deploy-containers.sh](../scripts/deploy-containers.sh) and [deploy-demo-loop.sh](../scripts/deploy-demo-loop.sh) also build images from a parent source checkout, and [status.sh](../scripts/status.sh) summarizes outputs and ECS service state.

The [Terraform workflow](../.github/workflows/terraform.yml) runs on pull requests and pushes to `main` that touch Terraform files or the workflow itself. It runs `terraform fmt -check -recursive`, then `terraform init -backend=false` and `terraform validate` in the root module and in `bootstrap/`. It holds no cloud credentials and never plans or applies, so a plan against your own environment stays a local step in your adapted copy.

## Documentation ownership

Keep this wiki as the entry point and update the linked pages where the facts belong: setup in the README, inputs in `variables.tf`, and module behaviour beside each module. Examples use fictional data. Real `terraform.tfvars` and `backend.hcl` files, account IDs, domain names, credentials and organization-specific operations belong with their deployment owner and are never committed.
