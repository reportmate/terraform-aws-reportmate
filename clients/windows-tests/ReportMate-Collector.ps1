# ReportMate osquery Data Sender
# This script reads osquery results and sends them to ReportMate with authentication

param(
    [Parameter(Mandatory=$false)]
    [string]$OsqueryPath = "C:\ProgramData\osquery\osqueryd.exe",
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = "C:\ProgramData\osquery\osquery.conf",
    
    [Parameter(Mandatory=$false)]
    [switch]$TestMode = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput = $false
)

# Registry paths for ReportMate configuration
$REGISTRY_PATH = "HKLM:\SOFTWARE\Policies\ReportMate"
$REGISTRY_PASSPHRASE_KEY = "Passphrase"
$REGISTRY_SERVER_KEY = "ServerUrl"
$REGISTRY_DEVICE_REGISTERED_KEY = "DeviceRegistered"

# Default server URL (fallback)
$DEFAULT_SERVER_URL = "https://reportmate-api.azurewebsites.net"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    if ($VerboseOutput -or $Level -eq "ERROR") {
        Write-Host $logMessage
    }
    
    # Log to Windows Event Log
    try {
        $source = "ReportMate"
        if (![System.Diagnostics.EventLog]::SourceExists($source)) {
            New-EventLog -LogName "Application" -Source $source
        }
        
        $entryType = switch ($Level) {
            "ERROR" { "Error" }
            "WARNING" { "Warning" }
            default { "Information" }
        }
        
        Write-EventLog -LogName "Application" -Source $source -EntryType $entryType -EventId 1001 -Message $Message
    }
    catch {
        # Silently continue if event log writing fails
    }
}

function Get-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )
    
    try {
        if (Test-Path $Path) {
            $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($value) {
                return $value.$Name
            }
        }
        return $null
    }
    catch {
        return $null
    }
}

function Get-ReportMateConfiguration {
    $config = @{
        ServerUrl = $null
        Passphrase = $null
    }
    
    # Try to read from registry
    $config.ServerUrl = Get-RegistryValue -Path $REGISTRY_PATH -Name $REGISTRY_SERVER_KEY
    $config.Passphrase = Get-RegistryValue -Path $REGISTRY_PATH -Name $REGISTRY_PASSPHRASE_KEY
    
    # Use default server URL if not configured
    if (!$config.ServerUrl) {
        $config.ServerUrl = $DEFAULT_SERVER_URL
        Write-Log "Using default server URL: $DEFAULT_SERVER_URL" "WARNING"
    }
    
    return $config
}

function Invoke-OsqueryCommand {
    param(
        [string]$Query,
        [string]$OsqueryPath,
        [string]$ConfigPath
    )
    
    try {
        $osqueryArgs = @(
            "--json",
            "--config_path=$ConfigPath",
            $Query
        )
        
        Write-Log "Executing osquery: $Query" "DEBUG"
        
        $result = & $OsqueryPath $osqueryArgs 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            return $result | ConvertFrom-Json
        } else {
            Write-Log "osquery command failed with exit code ${LASTEXITCODE}: $result" "ERROR"
            return $null
        }
    }
    catch {
        Write-Log "Failed to execute osquery: $($_.Exception.Message)" "ERROR"
        return $null
    }
}

function Send-DataToReportMate {
    param(
        [string]$ServerUrl,
        [string]$Passphrase,
        [string]$DataKind,
        [object]$Data,
        [string]$DeviceSerial
    )
    
    try {
        # Prepare payload
        $payload = @{
            device = $DeviceSerial
            kind = $DataKind
            ts = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            payload = $Data
        }
        
        # Add passphrase if configured
        if ($Passphrase) {
            $payload.passphrase = $Passphrase
        }
        
        $json = $payload | ConvertTo-Json -Depth 10 -Compress
        
        Write-Log "Sending $DataKind data to ReportMate for device $DeviceSerial..." "DEBUG"
        
        $response = Invoke-WebRequest -Uri "$ServerUrl/api/events" -Method POST -Body $json -ContentType "application/json" -TimeoutSec 30 -UseBasicParsing
        
        if ($response.StatusCode -eq 200) {
            Write-Log "Successfully sent $DataKind data to ReportMate"
            return $true
        } else {
            Write-Log "Unexpected response code $($response.StatusCode) when sending $DataKind data" "WARNING"
            return $false
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        $statusCode = $null
        
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        
        if ($statusCode -eq 403) {
            Write-Log "Device $DeviceSerial is not registered. Events rejected by server." "ERROR"
        } elseif ($statusCode -eq 400) {
            Write-Log "Bad request when sending $DataKind data - device serial may be missing" "ERROR"
        } elseif ($errorMessage -like "*401*") {
            Write-Log "Authentication failed when sending $DataKind data - check passphrase configuration" "ERROR"
        } else {
            Write-Log "Failed to send $DataKind data: $errorMessage" "ERROR"
        }
        return $false
    }
}

function Get-SystemInfo {
    param([string]$OsqueryPath, [string]$ConfigPath)
    
    Write-Log "Collecting system information..."
    
    $queries = @{
        "system_info" = "SELECT hostname, cpu_brand, physical_memory, hardware_vendor, hardware_model FROM system_info;"
        "os_version" = "SELECT name, version, build, platform, platform_like, arch FROM os_version;"
        "security_features" = "SELECT * FROM windows_security_center;"
        "bitlocker_status" = "SELECT drive_letter, protection_status, lock_status, encryption_method FROM bitlocker_info;"
        "network_interfaces" = "SELECT interface, address, mask, broadcast FROM interface_addresses WHERE interface NOT LIKE 'Loopback%';"
        "installed_applications" = "SELECT name, version, publisher, install_date FROM programs LIMIT 100;"
        "running_processes" = "SELECT pid, name, path, parent, start_time FROM processes WHERE name != '' LIMIT 50;"
    }
    
    $results = @{}
    
    foreach ($queryName in $queries.Keys) {
        $query = $queries[$queryName]
        $result = Invoke-OsqueryCommand -Query $query -OsqueryPath $OsqueryPath -ConfigPath $ConfigPath
        
        if ($result) {
            $results[$queryName] = $result
            $recordCount = if ($result.Count) { $result.Count } else { 1 }
            Write-Log "Collected ${queryName}: $recordCount records"
        } else {
            Write-Log "Failed to collect $queryName" "WARNING"
        }
    }
    
    return $results
}

function Test-ReportMateConnection {
    param([string]$ServerUrl, [string]$Passphrase)
    
    Write-Log "Testing connection to ReportMate..."
    
    $testData = @{
        test = $true
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        hostname = $env:COMPUTERNAME
    }
    
    return Send-DataToReportMate -ServerUrl $ServerUrl -Passphrase $Passphrase -DataKind "test" -Data $testData
}

function Get-DeviceSerial {
    try {
        # Try to get serial number from WMI
        $serial = Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SerialNumber
        if ($serial -and $serial.Trim() -ne "") {
            return $serial.Trim()
        }
        
        # Fallback to computer name
        $computerName = $env:COMPUTERNAME
        if ($computerName) {
            return $computerName
        }
        
        throw "Unable to determine device serial number"
    }
    catch {
        Write-Log "Failed to get device serial: $($_.Exception.Message)" "ERROR"
        return $env:COMPUTERNAME
    }
}

function Test-DeviceRegistration {
    param([string]$ServerUrl, [string]$DeviceSerial)
    
    try {
        $checkUrl = "$ServerUrl/api/device/$DeviceSerial"
        Write-Log "Checking if device is registered: $checkUrl"
        
        $response = Invoke-RestMethod -Uri $checkUrl -Method GET -TimeoutSec 30
        
        if ($response -and $response.deviceInfo) {
            Write-Log "Device $DeviceSerial is registered as: $($response.deviceInfo.name)"
            return $true
        }
        
        return $false
    }
    catch {
        $statusCode = $null
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        
        if ($statusCode -eq 404) {
            Write-Log "Device $DeviceSerial is not registered (404)" "ERROR"
            return $false
        } elseif ($statusCode -eq 403) {
            Write-Log "Device $DeviceSerial registration check failed (403)" "ERROR"
            return $false
        }
        
        Write-Log "Failed to check device registration: $($_.Exception.Message)" "WARNING"
        return $false
    }
}

function Ensure-DeviceRegistered {
    param([string]$ServerUrl, [string]$DeviceSerial)
    
    # Check if device is registered
    if (Test-DeviceRegistration -ServerUrl $ServerUrl -DeviceSerial $DeviceSerial) {
        return $true
    }
    
    Write-Log "Device $DeviceSerial is not registered. Attempting registration..." "WARNING"
    
    # Try to run registration script
    $scriptPath = Join-Path (Split-Path $MyInvocation.ScriptName) "Register-Device.ps1"
    
    if (Test-Path $scriptPath) {
        try {
            Write-Log "Running device registration script: $scriptPath"
            & $scriptPath -ServerUrl $ServerUrl -SerialNumber $DeviceSerial -VerboseOutput:$VerboseOutput
            
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Device registration completed successfully"
                return $true
            } else {
                Write-Log "Device registration script failed with exit code: $LASTEXITCODE" "ERROR"
            }
        }
        catch {
            Write-Log "Failed to run registration script: $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-Log "Registration script not found at: $scriptPath" "ERROR"
    }
    
    return $false
}

# Main execution
Write-Host ""
Write-Host "🔍 ReportMate osquery Data Collector" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Check if osquery exists
if (!(Test-Path $OsqueryPath)) {
    Write-Log "osquery not found at: $OsqueryPath" "ERROR"
    Write-Host "Please install osquery or specify the correct path with -OsqueryPath" -ForegroundColor Red
    exit 1
}

# Check if config exists
if (!(Test-Path $ConfigPath)) {
    Write-Log "osquery config not found at: $ConfigPath" "ERROR"
    Write-Host "Please create osquery configuration or specify the correct path with -ConfigPath" -ForegroundColor Red
    exit 1
}

# Get ReportMate configuration
$config = Get-ReportMateConfiguration

Write-Log "ReportMate Configuration:"
Write-Log "  Server URL: $($config.ServerUrl)"
Write-Log "  Authentication: $(if ($config.Passphrase) { 'Enabled' } else { 'Disabled' })"

# Test mode - just test connection
if ($TestMode) {
    Write-Host ""
    Write-Host "🧪 Test Mode - Testing connection only" -ForegroundColor Yellow
    
    if (Test-ReportMateConnection -ServerUrl $config.ServerUrl -Passphrase $config.Passphrase) {
        Write-Host "✅ Connection test successful!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "❌ Connection test failed!" -ForegroundColor Red
        exit 1
    }
}

# Collect system information
Write-Host ""
Write-Log "Starting data collection..."

$systemData = Get-SystemInfo -OsqueryPath $OsqueryPath -ConfigPath $ConfigPath

if ($systemData.Count -eq 0) {
    Write-Log "No data collected - exiting" "ERROR"
    exit 1
}

# Ensure device is registered
Write-Host ""
Write-Log "Ensuring device is registered..."

$deviceSerial = Get-DeviceSerial

if (!(Ensure-DeviceRegistered -ServerUrl $config.ServerUrl -DeviceSerial $deviceSerial)) {
    Write-Host "❌ Device registration failed! Please check logs." -ForegroundColor Red
    exit 1
}

# Send data to ReportMate
Write-Host ""
Write-Log "Sending data to ReportMate..."

$successCount = 0
$totalCount = $systemData.Count

foreach ($dataType in $systemData.Keys) {
    $data = $systemData[$dataType]
    
    if (Send-DataToReportMate -ServerUrl $config.ServerUrl -Passphrase $config.Passphrase -DataKind $dataType -Data $data -DeviceSerial $deviceSerial) {
        $successCount++
    }
    
    # Small delay between requests
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Log "Data collection complete: $successCount/$totalCount datasets sent successfully"

if ($successCount -eq $totalCount) {
    Write-Host "All data sent successfully!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Some data failed to send. Check logs for details." -ForegroundColor Yellow
    exit 1
}
