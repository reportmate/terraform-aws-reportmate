#!/usr/bin/env bash
# Deploy the ReportMate API container to ECS Fargate via ECR.
# Usage: ./scripts/deploy-api.sh [--force-build]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

REGION=$(cd "$ROOT_DIR" && terraform output -raw region 2>/dev/null || echo "ca-central-1")
ECR_URL=$(cd "$ROOT_DIR" && terraform output -raw ecr_api_repository_url)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
CLUSTER=$(cd "$ROOT_DIR" && terraform output -raw api_url | sed 's|http.*//||;s|\..*||' || echo "reportmate-prod")

if [ -z "$ECR_URL" ]; then
  echo "ERROR: Could not read ECR URL from Terraform outputs. Run terraform apply first."
  exit 1
fi

echo "==> Authenticating to ECR ($REGION)"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

TAG="$(git -C "$ROOT_DIR/../azure/modules/api" rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)"
IMAGE="$ECR_URL:$TAG"

echo "==> Building API image: $IMAGE"
docker build \
  --platform linux/amd64 \
  -t "$IMAGE" \
  -t "$ECR_URL:latest" \
  -f "$ROOT_DIR/../azure/modules/api/Dockerfile" \
  "$ROOT_DIR/../azure/modules/api"

echo "==> Pushing to ECR"
docker push "$IMAGE"
docker push "$ECR_URL:latest"

echo "==> Updating ECS service"
CLUSTER_NAME="reportmate-prod"
SERVICE_NAME="reportmate-prod-api"
aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service "$SERVICE_NAME" \
  --force-new-deployment \
  --region "$REGION" \
  --no-cli-pager

echo "==> API deployed: $IMAGE"
echo "    ECS will roll out the new task automatically."
