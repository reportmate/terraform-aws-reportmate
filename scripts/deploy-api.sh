#!/usr/bin/env bash
# Deploy the ReportMate API container to ECS Fargate via ECR.
# The API image is built once by the reportmate-api repo CI and published to
# GHCR; this script mirrors that prebuilt image into ECR (no local build).
# Usage: ./scripts/deploy-api.sh [tag]   (tag defaults to "latest"; use a sha- tag for prod)
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

GHCR_IMAGE="ghcr.io/reportmate/reportmate-api"
TAG="${1:-latest}"
IMAGE="$ECR_URL:$TAG"

echo "==> Pulling prebuilt API image from GHCR: $GHCR_IMAGE:$TAG"
docker pull --platform linux/amd64 "$GHCR_IMAGE:$TAG"

echo "==> Mirroring to ECR: $IMAGE"
docker tag "$GHCR_IMAGE:$TAG" "$IMAGE"
docker tag "$GHCR_IMAGE:$TAG" "$ECR_URL:latest"
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
