# ReportMate - Real-Time Security Events Dashboard

[![Azure DevOps](https://img.shields.io/badge/Azure%20DevOps-Pipeline%20Ready-blue?logo=azuredevops)](./docs/DEPLOYMENT.md)
[![Terraform](https://img.shields.io/badge/Infrastructure-Terraformed-purple?logo=terraform)](./infrastructure/)
[![Docker](https://img.shields.io/badge/Deployment-Containerized-blue?logo=docker)](./docs/DEPLOYMENT.md#container-deployment)

> A professional, real-time security events dashboard built for enterprise device management, inspired by MunkiReport's design principles.

## Features

- **Real-Time Events** - Live dashboard with SignalR/WebPubSub integration
- **Modular Architecture** - Plugin-based widget system for extensibility
- **Container Ready** - Modern containerized deployment with Azure Container Apps
- **Serverless Backend** - Azure Functions for scalable event processing
- **Enterprise Security** - Managed identity authentication with comprehensive RBAC
- **Professional UI** - Modern dashboard with glassmorphism effects and dark theme
- **CI/CD Ready** - Azure DevOps pipelines with Infrastructure as Code

## Quick Start

### Option 1: Container Deployment (Recommended)

```bash
# 1. Set up Azure DevOps service connection (see docs/DEPLOYMENT.md)
# 2. Run container pipeline
# Result: Modern, scalable container deployment
```

### Option 2: Local Development

```bash
# Clone and setup
git clone <your-repo>
cd ReportMate

# Start local environment
cp .env.example .env
docker-compose up -d
./scripts/setup-database.sh

# Access dashboard
open http://localhost:3000/dashboard
```

### Option 3: Azure Developer CLI (AZD)

```bash
# Deploy with AZD
azd init --template ./
azd up
```

## Architecture

```text
┌─────────────────────────────────────────────────────────────┐
│                    REPORTMATE ARCHITECTURE                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────┐    ┌──────────────┐    ┌────────────────┐  │
│  │   Devices   │───▶│ Azure        │───▶│ Container Apps │  │
│  │             │    │ Functions    │    │                │  │
│  │ - Endpoints │    │ - Ingest API │    │ - Frontend     │  │
│  │ - OSQuery   │    │ - Queue      │    │ - Dashboard    │  │
│  │ - Cimian    │    │ - Processing │    │ - Auto-scale   │  │
│  └─────────────┘    └──────────────┘    └────────────────┘  │
│                             │                               │
│                             ▼                               │
│  ┌─────────────┐    ┌──────────────┐    ┌────────────────┐  │
│  │ PostgreSQL  │◀───│ Web PubSub   │───▶│ Real-time      │  │
│  │             │    │              │    │ Dashboard      │  │
│  │ - Events    │    │ - SignalR    │    │ - Live Updates │  │
│  │ - Devices   │    │ - WebSockets │    │ - Status       │  │
│  │ - History   │    │ - Broadcast  │    │ - Monitoring   │  │
│  └─────────────┘    └──────────────┘    └────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

## Project Status

### Production Ready Components

- **Infrastructure**: Comprehensive Terraform with RBAC *(No manual `az` commands needed!)*
- **Backend APIs**: Azure Functions with managed identity authentication
- **Real-time**: Web PubSub integration for live dashboard updates
- **Database**: PostgreSQL Flexible Server with automated schema setup
- **CI/CD**: Azure DevOps pipelines with multiple deployment strategies
- **Security**: Enterprise-grade managed identity with least-privilege access

### Latest Enhancements

- **Container Support**: Optimized Dockerfiles for production deployment
- **Modular UI**: Widget-based architecture inspired by MunkiReport
- **Enhanced Pipelines**: Three deployment options (infrastructure, containers, full)
- **Local Development**: Complete Docker Compose environment
- **RBAC Migration**: All permissions managed by Terraform (zero manual commands)

## Latest Updates

### Modular System Migration Complete

The ReportMate dashboard has been fully migrated to use the new modular plugin system:

- **Dynamic Dashboard**: The main `/dashboard` now uses modular widgets that can be installed, enabled, and disabled at runtime
- **Module Management**: Full lifecycle management UI at `/modules` and `/settings`
- **Per-Repository Modules**: Each module (`reportmate-module-NAME`) is its own GitHub repository
- **Runtime Discovery**: Automatic discovery of official and community modules
- **Legacy Preserved**: Original static dashboard backed up for reference

**Key Benefits:**
- **Extensible**: Add new widgets and functionality through modules
- **Dynamic**: Install/remove modules without code changes
- **Distributed**: Each module can be maintained independently
- **Community**: 3rd parties can create and distribute modules
- **Secure**: Modules are sandboxed and validated before loading

See [`docs/MODULE_SYSTEM.md`](./docs/MODULE_SYSTEM.md) for complete technical details.

## Test Your Deployment

Once deployed, test with your devices:

```bash
# Health check
curl https://reportmate-api.azurewebsites.net/api/negotiate?device=test-device

# Send test event
curl -X POST https://reportmate-api.azurewebsites.net/api/ingest \
  -H "Content-Type: application/json" \
  -d '{
    "device": "device-001",
    "kind": "info",
    "payload": {
      "message": "Device online",
      "uptime": "5 days",
      "cpu_usage": "23%"
    }
  }'

# Watch real-time updates on dashboard!
# https://reportmate-frontend.{random}.canadacentral.azurecontainerapps.io
```

## Project Structure

```text
ReportMate/
├── apps/
│   ├── www/                    # Next.js frontend dashboard
│   ├── csharp/                 # C# client libraries
│   └── swift/                  # Swift/iOS client libraries
├── functions/                  # Azure Functions (Python)
│   ├── ingest/                 # Event ingestion API
│   ├── negotiate/              # SignalR negotiation
│   └── queue/                  # Queue processing
├── infrastructure/             # Terraform Infrastructure as Code
│   ├── main.tf                 # Core infrastructure
│   ├── rbac.tf                 # RBAC permissions (comprehensive!)
│   ├── containers.tf           # Container Apps configuration
│   └── variables.tf            # Configuration variables
├── pipelines/                  # Azure DevOps CI/CD
│   ├── reportmate-deploy-full.yml
│   └── reportmate-containers-only.yml
├── database/                   # Database schema and migrations
├── scripts/                    # Deployment and utility scripts
└── docs/                       # Documentation
    ├── DEPLOYMENT.md           # Complete deployment guide
    ├── DEVELOPMENT.md          # Development and architecture
    └── TROUBLESHOOTING.md      # Support and debugging
```

## Deployment Options

| Option | Use Case | Time | Features |
|--------|----------|------|----------|
| **Container Apps** | Production, scalable | 30 min | Auto-scaling, zero-downtime, modern |
| **Azure Functions** | Event-driven, serverless | 20 min | Pay-per-use, proven architecture |
| **Hybrid** | Migration, A/B testing | 45 min | Best of both worlds |
| **Local Development** | Testing, development | 10 min | Full environment locally |

## Documentation

- **[Deployment Guide](./docs/DEPLOYMENT.md)** - Complete deployment instructions
- **[Development Guide](./docs/DEVELOPMENT.md)** - Modular architecture and development
- **[Troubleshooting](./docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Frontend README](./apps/www/README.md)** - Dashboard-specific documentation

## Security & Compliance

- **Managed Identity**: No hardcoded credentials or connection strings
- **RBAC**: Comprehensive role-based access control via Terraform
- **Least Privilege**: Each component has minimal required permissions
- **Enterprise Ready**: Supports Azure AD integration and conditional access
- **Audit Trail**: All permissions and access tracked in Azure logs

## Contributing

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** your changes: `git commit -m 'Add amazing feature'`
4. **Push** to the branch: `git push origin feature/amazing-feature`
5. **Open** a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **MunkiReport** - UI design inspiration and modular architecture concepts
- **Azure Engineering** - For excellent container and serverless services
- **Open Source Community** - For the amazing tools and libraries used

---

**Ready for enterprise device management at scale!**

For immediate deployment, see **[docs/DEPLOYMENT.md](./docs/DEPLOYMENT.md)** for step-by-step instructions.


## Project Structure Update

**Web Dashboard Split**: The web dashboard has been split into a separate open-source repository:

- **Public Repository**: https://github.com/reportmate/reportmate-app-web
- **Local Path**: `apps/www` (now a git submodule)

### Working with the Submodule

To clone this repository with the web dashboard:
```bash
git clone --recursive https://github.com/your-org/reportmate.git
```

To update the submodule to the latest version:
```bash
git submodule update --remote apps/www
```

To make changes to the web dashboard:
1. Navigate to `apps/www`
2. Make your changes
3. Commit and push to the public repository
4. Update the parent repository to reference the new commit

This allows the web dashboard to be developed independently while remaining integrated with the main ReportMate infrastructure.

