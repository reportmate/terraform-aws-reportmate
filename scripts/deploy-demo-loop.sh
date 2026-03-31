#!/usr/bin/env bash
# Deploy the ReportMate demo-loop container to ECS Fargate via ECR.
# This container keeps the demo environment alive by continuously re-submitting
# device payloads with fresh timestamps.
#
# Usage: ./scripts/deploy-demo-loop.sh [--force-build]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$ROOT_DIR/../.." && pwd)"

REGION=$(cd "$ROOT_DIR" && terraform output -raw region 2>/dev/null || echo "ca-central-1")
ECR_URL=$(cd "$ROOT_DIR" && terraform output -raw demo_loop_ecr_repository_url 2>/dev/null)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

if [ -z "$ECR_URL" ]; then
  echo "ERROR: Could not read demo-loop ECR URL from Terraform outputs."
  echo "       Run 'terraform apply' first to create the demo-loop infrastructure."
  exit 1
fi

echo "==> Authenticating to ECR ($REGION)"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

TAG="$(date +%Y%m%d%H%M%S)-$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo 'manual')"
IMAGE="$ECR_URL:$TAG"

echo "==> Building demo-loop image: $IMAGE"
docker build \
  --platform linux/amd64 \
  -t "$IMAGE" \
  -t "$ECR_URL:latest" \
  -f "$REPO_ROOT/scripts/Dockerfile.demo-loop" \
  "$REPO_ROOT/scripts"

echo "==> Pushing to ECR"
docker push "$IMAGE"
docker push "$ECR_URL:latest"

echo "==> Updating ECS service"
CLUSTER_NAME="reportmate-prod-cluster"
SERVICE_NAME="reportmate-prod-demo-loop"
aws ecs update-service \
  --cluster "$CLUSTER_NAME" \
  --service "$SERVICE_NAME" \
  --force-new-deployment \
  --region "$REGION" \
  --no-cli-pager

echo "==> Demo loop deployed: $IMAGE"
echo "    ECS will roll out the new task automatically."
echo "    Check logs: aws logs tail /ecs/reportmate-prod/demo-loop --follow --region $REGION"
