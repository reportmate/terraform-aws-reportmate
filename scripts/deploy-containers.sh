#!/usr/bin/env bash
# Deploy ReportMate frontend + API containers to ECS Fargate via ECR.
# Usage: ./scripts/deploy-containers.sh [api|frontend|both]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
MONO_ROOT="$(cd "$ROOT_DIR/../.." && pwd)"

TARGET="${1:-both}"
REGION=$(cd "$ROOT_DIR" && terraform output -raw region 2>/dev/null || echo "ca-central-1")
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "==> Authenticating to ECR ($REGION)"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

CLUSTER_NAME="reportmate-prod-cluster"
TAG="$(date +%Y%m%d%H%M%S)"

deploy_api() {
  # API image is built by the reportmate-api repo CI and published to GHCR;
  # mirror that prebuilt image into ECR (no local build). Override the GHCR
  # tag to pull via API_GHCR_TAG (defaults to "latest"; use a sha- tag for prod).
  local ECR_URL GHCR_IMAGE GHCR_TAG
  ECR_URL=$(cd "$ROOT_DIR" && terraform output -raw ecr_api_repository_url)
  GHCR_IMAGE="ghcr.io/reportmate/reportmate-api"
  GHCR_TAG="${API_GHCR_TAG:-latest}"
  local IMAGE="$ECR_URL:$TAG"

  echo "==> Pulling prebuilt API image from GHCR: $GHCR_IMAGE:$GHCR_TAG"
  docker pull --platform linux/amd64 "$GHCR_IMAGE:$GHCR_TAG"

  echo "==> Mirroring to ECR: $IMAGE"
  docker tag "$GHCR_IMAGE:$GHCR_TAG" "$IMAGE"
  docker tag "$GHCR_IMAGE:$GHCR_TAG" "$ECR_URL:latest"
  docker push "$IMAGE"
  docker push "$ECR_URL:latest"

  echo "==> Updating ECS API service"
  aws ecs update-service \
    --cluster "$CLUSTER_NAME" \
    --service "reportmate-prod-api" \
    --force-new-deployment \
    --region "$REGION" \
    --no-cli-pager
}

deploy_frontend() {
  local ECR_URL
  ECR_URL=$(cd "$ROOT_DIR" && terraform output -raw ecr_frontend_repository_url)
  local IMAGE="$ECR_URL:$TAG"

  echo "==> Building frontend image: $IMAGE"
  docker build \
    --platform linux/amd64 \
    --build-arg NEXT_PUBLIC_DEMO_MODE=true \
    -t "$IMAGE" -t "$ECR_URL:latest" \
    -f "$MONO_ROOT/apps/www/Dockerfile" \
    "$MONO_ROOT/apps/www"

  echo "==> Pushing frontend image"
  docker push "$IMAGE"
  docker push "$ECR_URL:latest"

  echo "==> Updating ECS frontend service"
  aws ecs update-service \
    --cluster "$CLUSTER_NAME" \
    --service "reportmate-prod-frontend" \
    --force-new-deployment \
    --region "$REGION" \
    --no-cli-pager
}

case "$TARGET" in
  api)      deploy_api ;;
  frontend) deploy_frontend ;;
  both)     deploy_api; deploy_frontend ;;
  *)        echo "Usage: $0 [api|frontend|both]"; exit 1 ;;
esac

echo "==> Deployment complete. ECS will roll out new tasks automatically."
