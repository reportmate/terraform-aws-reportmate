# ReportMate Windows Client

This directory contains the Windows client implementation for ReportMate, providing automated data collection and secure authentication using passphrases.

## Files Overview

| File | Description |
|------|-------------|
| `Install-ReportMate.ps1` | Complete installer script for Windows environments |
| `ReportMate-Setup.ps1` | Configuration script for manual setup |
| `ReportMate-Collector.ps1` | Data collection and transmission script |
| `ReportMate-ScheduledTask.xml` | Windows Task Scheduler configuration |
| `ReportMate.adm` | Group Policy Administrative Template |
| `osquery.conf` | Example osquery configuration |

## Quick Start

### 1. Basic Installation

```powershell
# Run as Administrator
.\Install-ReportMate.ps1 -ServerUrl "https://your-reportmate-server.com" -Passphrase "your-secret-passphrase"
```

### 2. Group Policy Deployment

1. Copy `ReportMate.adm` to your Group Policy template folder
2. Configure policies in Group Policy Management Console
3. Deploy the client scripts via Group Policy or SCCM

### 3. Manual Configuration

```powershell
# Configure authentication
.\ReportMate-Setup.ps1 -ServerUrl "https://your-server.com" -Passphrase "secret123"

# Test configuration
.\ReportMate-Collector.ps1 -TestMode

# Run data collection
.\ReportMate-Collector.ps1
```

## Authentication Configuration

### Via Registry (Manual)

```powershell
# Set server URL
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\ReportMate" -Name "ServerUrl" -Value "https://your-server.com"

# Set passphrase
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\ReportMate" -Name "Passphrase" -Value "your-passphrase"
```

### Via Group Policy (Recommended)

1. Import `ReportMate.adm` into Group Policy
2. Navigate to: `Computer Configuration > Administrative Templates > ReportMate > Client Configuration`
3. Configure:
   - **Server URL**: Your ReportMate server endpoint
   - **Passphrase**: Client authentication passphrase
   - **Collection Interval**: How often to collect data (seconds)
   - **Logging**: Enable/disable event logging

### Via OMA-URI (Intune/MDM)

```
OMA-URI: ./Device/Vendor/MSFT/Registry/HKLM/SOFTWARE/Policies/ReportMate/ServerUrl
Data type: String
Value: https://your-reportmate-server.com

OMA-URI: ./Device/Vendor/MSFT/Registry/HKLM/SOFTWARE/Policies/ReportMate/Passphrase
Data type: String
Value: your-secret-passphrase
```

## Data Collection

The client collects the following information using osquery:

### System Information
- Hostname, CPU, memory, hardware details
- Operating system version and build
- Network interface configuration

### Security Features
- Windows Security Center status
- BitLocker encryption status
- Windows Defender configuration
- Firewall status

### Applications & Processes
- Installed applications and versions
- Running processes
- Startup items and services

### Network & Connectivity
- Listening ports and services
- Network connections
- DNS configuration

## Advanced Configuration

### Custom Data Collection

Modify `osquery.conf` to add custom queries:

```json
{
  "schedule": {
    "custom_security_check": {
      "query": "SELECT * FROM windows_security_products;",
      "interval": 1800,
      "description": "Custom security product check"
    }
  }
}
```

### Logging Configuration

```powershell
# Enable verbose logging
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\ReportMate" -Name "LogLevel" -Value 4

# View logs in Event Viewer
Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='ReportMate'}
```

### Collection Interval

```powershell
# Set collection to every 30 minutes (1800 seconds)
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\ReportMate" -Name "CollectionInterval" -Value 1800
```

## 🛠️ Troubleshooting

### Common Issues

#### Authentication Failures
```powershell
# Test connectivity and authentication
.\ReportMate-Collector.ps1 -TestMode -Verbose

# Check event logs
Get-WinEvent -FilterHashtable @{LogName='Application'; ProviderName='ReportMate'; Level=2}
```

#### Missing Data
```powershell
# Verify osquery is working
& "C:\ProgramData\osquery\osqueryd.exe" --json "SELECT * FROM system_info;"

# Check scheduled task
Get-ScheduledTask -TaskName "ReportMate Data Collection"
```

#### Network Connectivity
```powershell
# Test server connectivity
$serverUrl = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\ReportMate" -Name "ServerUrl").ServerUrl
Invoke-WebRequest -Uri "$serverUrl/api/health" -Method GET
```

### Debug Mode

Run the collector with verbose output:

```powershell
.\ReportMate-Collector.ps1 -Verbose
```

### Manual Data Submission

```powershell
# Submit test data
$testData = @{
    device = $env:COMPUTERNAME
    kind = "manual_test"
    passphrase = "your-passphrase"
    payload = @{ test = $true; timestamp = (Get-Date).ToString() }
}

$json = $testData | ConvertTo-Json
Invoke-WebRequest -Uri "https://your-server.com/api/ingest" -Method POST -Body $json -ContentType "application/json"
```

## Registry Keys Reference

| Key | Type | Description | Default |
|-----|------|-------------|---------|
| `ServerUrl` | String | ReportMate server endpoint | - |
| `Passphrase` | String | Authentication passphrase | - |
| `CollectionInterval` | DWORD | Collection interval (seconds) | 3600 |
| `EnableLogging` | DWORD | Enable event logging (1/0) | 1 |
| `LogLevel` | DWORD | Log verbosity (1-4) | 3 |
| `InstallPath` | String | Client installation path | - |

## Security Considerations

### Best Practices

1. **Use Group Policy**: Deploy passphrases via Group Policy, not scripts
2. **Strong Passphrases**: Minimum 16 characters with complexity
3. **Regular Rotation**: Change passphrases periodically
4. **Monitor Access**: Check Application Insights for unauthorized attempts
5. **Secure Transport**: Always use HTTPS endpoints

### Passphrase Management

- Store passphrases securely in Group Policy or password managers
- Use different passphrases for different environments
- Implement regular rotation schedules
- Monitor for authentication failures

## Deployment Checklist

- [ ] Server-side passphrase configured
- [ ] Group Policy template deployed
- [ ] Client passphrase configured
- [ ] Scheduled task created and running
- [ ] Event logging enabled
- [ ] Network connectivity verified
- [ ] Test data submission successful
- [ ] Monitoring configured in Azure Application Insights

## 🆘 Support

For troubleshooting and support:

1. Check Windows Event Log (Application > ReportMate)
2. Review Azure Application Insights logs
3. Verify network connectivity to server
4. Test authentication with manual submission
5. Consult main ReportMate documentation

## 📚 Related Documentation

- [CLIENT_AUTHENTICATION.md](../../docs/CLIENT_AUTHENTICATION.md) - Authentication overview
- [DEPLOYMENT.md](../../docs/DEPLOYMENT.md) - Server deployment
- [TROUBLESHOOTING.md](../../docs/TROUBLESHOOTING.md) - General troubleshooting
