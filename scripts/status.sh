#!/usr/bin/env bash
# Show ReportMate AWS infrastructure status.
# Usage: ./scripts/status.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

REGION=$(cd "$ROOT_DIR" && terraform output -raw region 2>/dev/null || echo "ca-central-1")
CLUSTER_NAME="reportmate-prod"

echo "=== ReportMate AWS Status ==="
echo ""

# Terraform outputs
echo "--- Terraform Outputs ---"
(cd "$ROOT_DIR" && terraform output 2>/dev/null) || echo "  (not initialized)"
echo ""

# ECS services
echo "--- ECS Services ---"
aws ecs list-services \
  --cluster "$CLUSTER_NAME" \
  --region "$REGION" \
  --query 'serviceArns[*]' \
  --output text 2>/dev/null | tr '\t' '\n' | while read -r arn; do
    svc=$(basename "$arn")
    status=$(aws ecs describe-services \
      --cluster "$CLUSTER_NAME" \
      --services "$arn" \
      --region "$REGION" \
      --query 'services[0].{status:status,running:runningCount,desired:desiredCount}' \
      --output text 2>/dev/null)
    echo "  $svc: $status"
done
echo ""

# RDS
echo "--- RDS ---"
aws rds describe-db-instances \
  --region "$REGION" \
  --query 'DBInstances[?starts_with(DBInstanceIdentifier,`reportmate`)].{id:DBInstanceIdentifier,status:DBInstanceStatus,engine:Engine,version:EngineVersion}' \
  --output table 2>/dev/null || echo "  (none found)"
echo ""

# ECR repos
echo "--- ECR Repositories ---"
aws ecr describe-repositories \
  --region "$REGION" \
  --query 'repositories[?starts_with(repositoryName,`reportmate`)].{name:repositoryName,uri:repositoryUri}' \
  --output table 2>/dev/null || echo "  (none found)"
