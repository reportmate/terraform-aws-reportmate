# Open Source Configuration Guide

This document outlines the configuration changes needed to make ReportMate fully open source and environment-agnostic.

## Overview

ReportMate is designed to be cloud-agnostic and configurable for any environment. No hardcoded URLs or environment-specific values should exist in the codebase.

## Configuration Philosophy

### Client-Side Configuration Priority (Highest to Lowest)

1. **CSP/Group Policy Registry** (Enterprise deployment)
   - `HKLM\SOFTWARE\Policies\ReportMate`
   - Applied via Intune/GPO for enterprise environments

2. **Environment Variables**
   - `REPORTMATE_API_URL`
   - `REPORTMATE_PASSPHRASE`
   - `REPORTMATE_DEVICE_ID`

3. **Local Configuration Files**
   - `C:\ProgramData\ManagedReports\appsettings.yaml`
   - User-editable configuration

4. **Application Defaults**
   - Only generic defaults (no specific URLs)
   - Prompts for configuration if not set

### Web Application Configuration

The web application should use environment variables exclusively:

```bash
# API Configuration
NEXT_PUBLIC_API_BASE_URL=https://your-api-domain.com
DATABASE_URL=postgresql://user:pass@host:5432/db

# SignalR/WebPubSub (optional)
NEXT_PUBLIC_WPS_URL=wss://your-signalr.domain.com/client/hubs/fleet
WPS_CONNECTION_STRING=Endpoint=...
```

### Cloud Functions Configuration

Functions should be environment-agnostic and configurable via environment variables:

```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/db

# Storage
AZURE_STORAGE_CONNECTION_STRING=DefaultEndpointsProtocol=https;...
QUEUE_NAME=ingest-queue

# Authentication (optional)
CLIENT_PASSPHRASES=passphrase1,passphrase2
ENABLE_MACHINE_GROUPS=true
```

## Required Changes

### 1. Remove Hardcoded URLs

**Files to update:**
- `clients/windows-tests/Register-Device.ps1` - Remove default Azure URL
- `clients/windows-tests/ReportMate-Collector.ps1` - Remove default Azure URL
- `clients/windows-tests/ReportMate-Setup.ps1` - Remove default Azure URL
- `clients/windows-tests/Setup-LocalDev.ps1` - Remove default Azure URL
- `clients/windows-tests/ReportMate.adm` - Remove default Azure URL
- `test-api-endpoints.js` - Use environment variable
- `scripts/setup-custom-domain.sh` - Make domain configurable
- All documentation files - Replace with placeholder examples

### 2. Client Configuration Updates

**Windows Client (`clients/windows/`):**
- Remove any hardcoded API URLs
- Ensure all configuration comes from registry/env vars
- Add configuration validation that prompts for missing values

**Example Registry Structure:**
```
HKLM\SOFTWARE\Policies\ReportMate\
  ├── ServerUrl (REG_SZ) = https://your-reportmate-api.com
  ├── Passphrase (REG_SZ) = your-secure-passphrase
  ├── DeviceId (REG_SZ) = [optional custom device ID]
  └── CollectionInterval (REG_DWORD) = 3600 (seconds)
```

### 3. Web Application Updates

**Next.js App (`apps/www/`):**
- Remove hardcoded API URLs
- Use environment variables exclusively
- Add runtime configuration validation

### 4. Infrastructure Updates

**Terraform (`infrastructure/`):**
- Make all domain names configurable via variables
- Remove hardcoded domain references
- Add examples for different cloud providers

### 5. Documentation Updates

**All documentation:**
- Replace specific URLs with `your-domain.com` placeholders
- Add configuration examples for different environments
- Include setup guides for different cloud providers

## Device Registration Flow

The device registration should work as follows:

1. **First Run**: Device checks if it's registered via GET `/api/device/{deviceId}`
2. **If Not Registered**: Device sends registration event via POST `/api/ingest`
3. **Registration Event**: Creates "new_client" event in database
4. **Subsequent Runs**: Device sends data via POST `/api/ingest`

## Cloud Provider Support

### Azure (Current Implementation)
- Azure Functions for API
- Azure Database for PostgreSQL
- Azure Storage Queue for message processing
- Azure SignalR for real-time updates

### AWS (Future Support)
- AWS Lambda for API
- AWS RDS PostgreSQL
- AWS SQS for message processing
- AWS WebSocket API for real-time updates

### Google Cloud (Future Support)
- Cloud Functions for API
- Cloud SQL PostgreSQL
- Cloud Tasks for message processing
- Cloud Pub/Sub for real-time updates

## Environment-Specific Configuration Examples

### Development Environment
```bash
# .env.local
NEXT_PUBLIC_API_BASE_URL=http://localhost:7071
DATABASE_URL=postgresql://localhost:5432/reportmate_dev
```

### Production Environment
```bash
# .env.production
NEXT_PUBLIC_API_BASE_URL=https://api.your-domain.com
DATABASE_URL=postgresql://prod-host:5432/reportmate
```

### Self-Hosted Environment
```bash
# .env.selfhosted
NEXT_PUBLIC_API_BASE_URL=https://reportmate.your-company.com
DATABASE_URL=postgresql://your-db-server:5432/reportmate
```

## Security Considerations

1. **API Authentication**: Use passphrases for device authentication
2. **Database Security**: Use connection strings with proper credentials
3. **TLS/SSL**: All communication must use HTTPS
4. **Environment Variables**: Never commit secrets to version control
5. **CSP Configuration**: Use Group Policy for enterprise deployments

## Migration Steps

1. **Audit Current Hardcoded Values**: Search for all hardcoded URLs
2. **Update Configuration System**: Implement environment-based configuration
3. **Update Documentation**: Replace specific URLs with placeholders
4. **Test Multi-Environment**: Verify deployment works in different environments
5. **Update Client Software**: Ensure clients use configurable endpoints

## Future Enhancements

1. **Configuration UI**: Web-based configuration management
2. **Multi-Tenant Support**: Support for multiple organizations
3. **Cloud Provider Abstraction**: Unified interface for different cloud providers
4. **Auto-Discovery**: Automatic endpoint discovery for clients
