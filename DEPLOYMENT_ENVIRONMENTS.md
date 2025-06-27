# Deployment Script Environment Support Update

## Summary

The `deploy.sh` script has been successfully updated to support deploying to development, production, or both environments simultaneously.

## New Features

### Environment Selection
- `--env dev` - Deploy development container app only
- `--env prod` - Deploy production container app only (default)
- `--env both` - Deploy both development and production apps

### Terraform Integration
The script now passes the appropriate variables to Terraform:
- `environment` - The target environment (dev/prod/both)
- `deploy_dev` - Boolean flag for development deployment
- `deploy_prod` - Boolean flag for production deployment
- `frontend_image_tag` - Docker image tag for containers

### Infrastructure Configuration
The existing Terraform configuration in `infrastructure/containers.tf` already supports:
- Development container app (`azurerm_container_app.frontend_dev`)
- Production container app (`azurerm_container_app.frontend_prod`)
- Conditional deployment based on variables

## Usage Examples

```bash
# Deploy only to development
./deploy.sh --full --env dev

# Deploy only to production (default)
./deploy.sh --full --env prod
./deploy.sh --full  # same as above

# Deploy to both environments
./deploy.sh --full --env both

# Update containers for development only
./deploy.sh --containers --env dev

# Deploy infrastructure for both environments
./deploy.sh --infra --env both
```

## Configuration Display

The script now shows environment targets in the configuration summary:

```
Environment Targets:
  Development: ✅ YES
  Production: ✅ YES
```

## Container App Differences

### Development Environment
- Lower resource allocation (0.25 CPU, 0.5Gi memory)
- Can scale to zero (min_replicas = 0)
- Debugging enabled
- Lower max replicas (2)

### Production Environment
- Higher resource allocation (0.5 CPU, 1Gi memory)
- Always maintains at least one instance (min_replicas = 1)
- Optimized for performance
- Higher max replicas (5)

## Terraform Variables

The script automatically sets these Terraform variables based on environment selection:

| Environment | deploy_dev | deploy_prod |
|-------------|------------|-------------|
| dev         | true       | false       |
| prod        | false      | true        |
| both        | true       | true        |

## Next Steps

The infrastructure and deployment script are now ready for selective environment deployment. You can:

1. Deploy to development for testing: `./deploy.sh --full --env dev`
2. Deploy to production for live use: `./deploy.sh --full --env prod`
3. Deploy to both for comprehensive updates: `./deploy.sh --full --env both`
