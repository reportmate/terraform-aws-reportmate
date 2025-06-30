# ReportMate Windows Client Deployment Guide

This guide provides comprehensive instructions for deploying and configuring the ReportMate Windows client across your organization.

## Overview

The ReportMate Windows client collects system information using osquery and securely transmits it to the ReportMate dashboard. The client runs as a scheduled task and can be deployed manually or through Group Policy.

## Prerequisites

- Windows 10/11 or Windows Server 2016+
- PowerShell 5.1 or later
- Administrator privileges for installation
- Network access to the ReportMate server
- Valid authentication passphrase (recommended)

## Installation Methods

### Method 1: Interactive Installation

For single-system deployment or testing:

```powershell
# Basic installation with custom server URL
.\Install-ReportMate.ps1 -ServerUrl "https://reportmate.ecuad.ca" -Passphrase "your-secure-passphrase"

# Installation with custom path
.\Install-ReportMate.ps1 -ServerUrl "https://reportmate.ecuad.ca" -Passphrase "your-secure-passphrase" -InstallPath "C:\ReportMate"
```

### Method 2: Silent Installation

For automated deployment or scripting:

```powershell
.\Install-ReportMate.ps1 -ServerUrl "https://reportmate.ecuad.ca" -Passphrase "your-secure-passphrase" -Silent
```

### Method 3: Group Policy Deployment

For enterprise-wide deployment, use Group Policy with a startup script:

1. Copy the ReportMate installer files to a network share
2. Create a Group Policy Object (GPO)
3. Add a computer startup script with the installation command
4. Link the GPO to the appropriate Organizational Units

## Installation Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `ServerUrl` | No | `https://reportmate-api.azurewebsites.net` | ReportMate server endpoint URL |
| `Passphrase` | No | Empty | Authentication passphrase for secure communication |
| `InstallPath` | No | `C:\Program Files\ReportMate` | Installation directory |
| `Uninstall` | No | False | Remove the ReportMate client |
| `Silent` | No | False | Run without interactive output |

## Required Files

Ensure these files are present in the same directory as the installer:

- `Install-ReportMate.ps1` - Main installer script
- `ReportMate-Collector.ps1` - Data collection script
- `ReportMate-Setup.ps1` - Setup configuration script
- `osquery.conf` - osquery configuration file
- `ReportMate-ScheduledTask.xml` - Scheduled task template (optional)

## Installation Process

The installer performs the following actions:

1. **Administrator Check** - Verifies script is running with admin privileges
2. **Directory Creation** - Creates the installation directory
3. **File Copy** - Copies required files to the installation path
4. **Registry Configuration** - Sets up configuration in `HKLM:\SOFTWARE\Policies\ReportMate`
5. **Scheduled Task** - Creates a recurring data collection task
6. **Configuration Test** - Validates the installation

## Registry Configuration

The installer configures the following registry values:

| Registry Value | Purpose | Default |
|----------------|---------|---------|
| `ServerUrl` | ReportMate server endpoint | User-specified or default |
| `InstallPath` | Installation directory path | `C:\Program Files\ReportMate` |
| `EnableLogging` | Enable client logging | `1` (enabled) |
| `LogLevel` | Logging verbosity level | `3` (info) |
| `CollectionInterval` | Data collection frequency (seconds) | `3600` (1 hour) |
| `Passphrase` | Authentication passphrase | User-specified (if provided) |

## Scheduled Task Configuration

The installer creates a scheduled task with these properties:

- **Name**: `ReportMate Data Collection`
- **Account**: SYSTEM
- **Frequency**: Every hour
- **Start Condition**: System startup + 5 minutes
- **Power Settings**: Run on battery, don't stop on battery
- **Command**: PowerShell execution of the collector script

## Security Recommendations

### 1. Use Authentication Passphrase

**⚠️ Important**: Always specify a passphrase for production deployments:

```powershell
.\Install-ReportMate.ps1 -ServerUrl "https://reportmate.ecuad.ca" -Passphrase "your-strong-passphrase-here"
```

### 2. Update Default Server URL

The current default server URL (`https://reportmate-api.azurewebsites.net`) should be updated to your production endpoint. Consider modifying the installer script for your organization:

```powershell
# Recommended: Update the default in the script
[string]$ServerUrl = "https://reportmate.ecuad.ca"
```

### 3. Network Security

- Ensure HTTPS communication to the ReportMate server
- Configure firewall rules if necessary
- Use network segmentation for client systems

### 4. Access Control

- Restrict access to the installation directory
- Use Group Policy to manage configuration centrally
- Monitor scheduled task execution

## Verification Commands

### Check Installation Status

```powershell
# View current configuration
.\Install-ReportMate.ps1

# Check registry settings
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\ReportMate"

# Verify scheduled task
Get-ScheduledTask -TaskName "ReportMate Data Collection"
```

### Test Connectivity

```powershell
# Test server connectivity
Test-NetConnection -ComputerName "reportmate.ecuad.ca" -Port 443

# Check DNS resolution
Resolve-DnsName "reportmate.ecuad.ca"
```

### Monitor Logs

```powershell
# View installation log
Get-Content "$env:TEMP\ReportMate-Install.log" -Tail 20

# Check Windows Event Log
Get-WinEvent -LogName Application | Where-Object {$_.ProviderName -like "*ReportMate*"}
```

## Troubleshooting

### Common Issues

#### 1. Access Denied Errors
**Cause**: Insufficient privileges
**Solution**: Run PowerShell as Administrator

#### 2. Scheduled Task Not Running
**Cause**: Task configuration or permissions
**Solution**: 
```powershell
# Check task status
Get-ScheduledTask -TaskName "ReportMate Data Collection" | Get-ScheduledTaskInfo

# Restart the task
Start-ScheduledTask -TaskName "ReportMate Data Collection"
```

#### 3. Network Connectivity Issues
**Cause**: Firewall, DNS, or network configuration
**Solution**: Verify network access and DNS resolution

#### 4. Authentication Failures
**Cause**: Incorrect or missing passphrase
**Solution**: Verify passphrase configuration in registry

### Log Locations

- **Installation Log**: `%TEMP%\ReportMate-Install.log`
- **Collection Logs**: Check the ReportMate installation directory
- **Windows Event Log**: Application and System logs
- **Scheduled Task History**: Task Scheduler console

## Uninstallation

To remove the ReportMate client:

```powershell
# Complete removal
.\Install-ReportMate.ps1 -Uninstall

# Silent removal
.\Install-ReportMate.ps1 -Uninstall -Silent
```

The uninstall process removes:
- Scheduled task
- Registry configuration
- Installation directory and files

## Group Policy Deployment

For enterprise deployment, create a Group Policy with these settings:

1. **Computer Configuration** > **Policies** > **Windows Settings** > **Scripts**
2. **Startup Scripts** > Add the installation command
3. **Script Parameters**: 
   ```
   -ServerUrl "https://reportmate.ecuad.ca" -Passphrase "your-passphrase" -Silent
   ```

### Group Policy Template

Use the included `ReportMate.adm` template to manage settings via Group Policy:

1. Import the template into Group Policy Management
2. Configure settings under **Computer Configuration** > **Administrative Templates** > **ReportMate**
3. Deploy the policy to target organizational units

## Best Practices

### 1. Deployment Strategy

- **Pilot Group**: Test with a small group first
- **Phased Rollout**: Deploy in phases across departments
- **Monitoring**: Monitor initial deployments before full rollout

### 2. Configuration Management

- Use Group Policy for centralized configuration
- Document all custom settings and passphrases
- Implement change management for configuration updates

### 3. Security Hardening

- Use strong, unique passphrases
- Regularly rotate authentication credentials
- Monitor client communication for anomalies
- Implement network security controls

### 4. Maintenance

- Regularly update client software
- Monitor scheduled task execution
- Review and rotate logs
- Test backup and recovery procedures

## Support and Documentation

- **Technical Documentation**: See `CLIENT_AUTHENTICATION.md` for authentication details
- **Troubleshooting**: Refer to `TROUBLESHOOTING.md` for common issues
- **Deployment Guide**: This document for deployment procedures
- **Module System**: See `MODULE_SYSTEM.md` for advanced configuration

## Production Deployment Checklist

- [ ] Update default server URL in installer script
- [ ] Generate strong authentication passphrase
- [ ] Test installation on pilot systems
- [ ] Configure Group Policy for enterprise deployment
- [ ] Set up monitoring and alerting
- [ ] Document deployment parameters and procedures
- [ ] Train support staff on troubleshooting procedures
- [ ] Implement backup and recovery procedures
- [ ] Schedule regular security reviews

---

**Last Updated**: June 29, 2025  
**Version**: 1.0  
**Author**: ReportMate Development Team
