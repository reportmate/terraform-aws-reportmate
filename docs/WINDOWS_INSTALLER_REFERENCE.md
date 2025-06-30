# ReportMate Windows Installer Reference Guide

This guide provides comprehensive documentation for the ReportMate Windows client installer script (`Install-ReportMate.ps1`).

## Overview

The ReportMate Windows installer is a PowerShell script that automates the installation, configuration, and management of the ReportMate client on Windows systems. It handles all aspects of deployment including file copying, registry configuration, scheduled task creation, and validation.

## Script Parameters

### Required Parameters

None - all parameters have default values, but some should be customized for production use.

### Optional Parameters

| Parameter | Type | Default Value | Description |
|-----------|------|---------------|-------------|
| `ServerUrl` | String | `https://reportmate-api.azurewebsites.net` | The ReportMate server endpoint URL |
| `Passphrase` | String | `""` (empty) | Authentication passphrase for secure communication |
| `InstallPath` | String | `C:\Program Files\ReportMate` | Installation directory path |
| `Uninstall` | Switch | `$false` | Removes the ReportMate client installation |
| `Silent` | Switch | `$false` | Runs the installer without interactive output |

## Installation Features

### 🔧 Core Installation Tasks

1. **Directory Creation**: Creates the installation directory structure
2. **File Deployment**: Copies required client files to the installation path
3. **Registry Configuration**: Sets up Windows registry settings for the client
4. **Scheduled Task**: Creates automated data collection task
5. **Validation**: Tests the configuration after installation

### 📁 Files Installed

The installer copies the following files to the installation directory:

- `ReportMate-Collector.ps1` - Main data collection script
- `ReportMate-Setup.ps1` - Configuration setup script  
- `osquery.conf` - OSQuery configuration file

### 🔐 Registry Configuration

Registry path: `HKLM:\SOFTWARE\Policies\ReportMate`

| Registry Key | Description | Default Value |
|--------------|-------------|---------------|
| `ServerUrl` | Target server endpoint | Parameter value |
| `InstallPath` | Installation directory | Parameter value |
| `EnableLogging` | Enable client logging | `1` |
| `LogLevel` | Logging verbosity level | `3` |
| `CollectionInterval` | Data collection frequency (seconds) | `3600` |
| `Passphrase` | Authentication passphrase | Set if provided |

### ⏰ Scheduled Task Configuration

- **Task Name**: "ReportMate Data Collection"
- **Execution**: Runs under SYSTEM account with highest privileges
- **Schedule**: Hourly execution (configurable)
- **Command**: PowerShell execution of collector script
- **Settings**: Runs on battery, starts when available

## Usage Examples

### Basic Installation

```powershell
# Install with default settings
.\Install-ReportMate.ps1
```

### Production Installation

```powershell
# Install with custom server and authentication
.\Install-ReportMate.ps1 -ServerUrl "https://reportmate.ecuad.ca" -Passphrase "your-secure-passphrase"
```

### Custom Installation Path

```powershell
# Install to custom directory
.\Install-ReportMate.ps1 -InstallPath "D:\ReportMate" -ServerUrl "https://reportmate.ecuad.ca"
```

### Silent Installation

```powershell
# Silent installation for automated deployment
.\Install-ReportMate.ps1 -ServerUrl "https://reportmate.ecuad.ca" -Passphrase "secure-key" -Silent
```

### Uninstallation

```powershell
# Remove ReportMate client
.\Install-ReportMate.ps1 -Uninstall
```

### Configuration Check

```powershell
# View current configuration (no parameters)
.\Install-ReportMate.ps1
```

## Security Features

### 🔒 Administrator Requirements

- Script requires Administrator privileges to run
- Validates elevated permissions before execution
- Fails gracefully if not run as Administrator

### 🛡️ Authentication Support

- Optional passphrase-based authentication
- Secure storage in Windows registry
- Configurable per-deployment

### 📝 Audit Logging

- Comprehensive installation logging
- Logs stored in `%TEMP%\ReportMate-Install.log`
- Color-coded console output (when not silent)
- Timestamp and severity level tracking

## Production Deployment Recommendations

### ⚠️ Important Updates Needed

**Current Default Server URL**: The installer currently defaults to `https://reportmate-api.azurewebsites.net` which should be updated for production use.

**Recommended Changes**:

1. Update default `ServerUrl` to `https://reportmate.ecuad.ca`
2. Make `Passphrase` a required parameter for security
3. Consider adding domain validation for server URLs

### 🏢 Enterprise Deployment

For large-scale enterprise deployment:

1. **Group Policy Integration**
   - Use GPO to distribute registry settings
   - Deploy via Software Installation policies
   - Centralize configuration management

2. **Network Deployment**
   - Package with configuration files
   - Use deployment tools (SCCM, Intune, etc.)
   - Implement silent installation mode

3. **Security Hardening**
   - Always specify a strong passphrase
   - Use HTTPS endpoints only
   - Implement certificate validation

## Troubleshooting

### Common Issues

#### Permission Errors

```text
Solution: Run PowerShell as Administrator
Command: Right-click PowerShell → "Run as Administrator"
```

#### Missing Files

```text
Issue: Source files not found during installation
Solution: Ensure all required files are in the same directory as the installer
Required: ReportMate-Collector.ps1, ReportMate-Setup.ps1, osquery.conf
```

#### Scheduled Task Failures

```text
Issue: Task creation fails
Solution: Check Windows Task Scheduler service is running
Verify: Administrative privileges and execution policy settings
```

#### Registry Access Denied

```text
Issue: Cannot write to HKLM registry
Solution: Verify Administrator rights and UAC settings
Alternative: Use HKCU for user-specific installation (requires script modification)
```

### Validation Steps

After installation, verify:

1. **Installation Directory**: Check files exist in installation path
2. **Registry Settings**: Verify configuration in registry
3. **Scheduled Task**: Confirm task is created and enabled
4. **Network Connectivity**: Test connection to server endpoint
5. **Data Collection**: Run manual collection test

### Log File Locations

- **Installation Log**: `%TEMP%\ReportMate-Install.log`
- **Client Logs**: Check installation directory for runtime logs
- **Windows Event Log**: Look for ReportMate-related events
- **Task Scheduler History**: View scheduled task execution history

## Script Architecture

### Functions Overview

| Function | Purpose |
|----------|---------|
| `Write-Log` | Centralized logging with color coding |
| `Test-AdminRights` | Validates Administrator privileges |
| `Install-ReportMateClient` | Main installation logic |
| `Uninstall-ReportMateClient` | Complete removal process |
| `Show-Configuration` | Display current installation status |

### Error Handling

- Graceful failure with descriptive error messages
- Continuation on non-critical errors
- Exit codes for automation integration
- Comprehensive logging for troubleshooting

## Integration with ReportMate Ecosystem

### Related Documentation

- [Windows Client Deployment Guide](WINDOWS_CLIENT_DEPLOYMENT.md) - Complete deployment process
- [Client Authentication](CLIENT_AUTHENTICATION.md) - Security configuration
- [Troubleshooting Guide](TROUBLESHOOTING.md) - General troubleshooting

### Dependencies

- PowerShell 5.1 or later
- Windows 10/Server 2016 or later
- Administrator privileges
- Network access to ReportMate server

### Compatibility

- Windows 10 (1909+)
- Windows 11 (all versions)
- Windows Server 2016+
- Windows Server 2019/2022

---

## Quick Reference Commands

```powershell
# Production Installation
.\Install-ReportMate.ps1 -ServerUrl "https://reportmate.ecuad.ca" -Passphrase "your-passphrase"

# Check Status
.\Install-ReportMate.ps1

# Uninstall
.\Install-ReportMate.ps1 -Uninstall

# Silent Mode
.\Install-ReportMate.ps1 -Silent -ServerUrl "https://reportmate.ecuad.ca" -Passphrase "secure-key"
```

---

*Last Updated: June 29, 2025*  
*Version: ReportMate Windows Installer v1.0*
