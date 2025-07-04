# Register Device with ReportMate
# This script registers the device with ReportMate before sending events

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerUrl = "",
    
    [Parameter(Mandatory=$false)]
    [string]$SerialNumber = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput = $false
)

# Registry paths for ReportMate configuration
$REGISTRY_PATH = "HKLM:\SOFTWARE\Policies\ReportMate"
$REGISTRY_PASSPHRASE_KEY = "Passphrase"
$REGISTRY_SERVER_KEY = "ServerUrl"
$REGISTRY_DEVICE_REGISTERED_KEY = "DeviceRegistered"

# Default server URL - should be configured via registry or environment variable
$DEFAULT_SERVER_URL = $env:REPORTMATE_API_URL

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] DEVICE REGISTRATION: $Message"
    
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
        
        Write-EventLog -LogName "Application" -Source $source -EntryType $entryType -EventId 2001 -Message $Message
    }
    catch {
        # Silently continue if event log fails
    }
}

function Get-Configuration {
    try {
        $config = @{}
        
        if (Test-Path $REGISTRY_PATH) {
            $regKey = Get-ItemProperty -Path $REGISTRY_PATH -ErrorAction SilentlyContinue
            
            if ($regKey) {
                $config.ServerUrl = $regKey.$REGISTRY_SERVER_KEY
                $config.Passphrase = $regKey.$REGISTRY_PASSPHRASE_KEY
                $config.DeviceRegistered = $regKey.$REGISTRY_DEVICE_REGISTERED_KEY
            }
        }
        
        # Use provided parameters or fallbacks
        if ($ServerUrl) {
            $config.ServerUrl = $ServerUrl
        } elseif (-not $config.ServerUrl) {
            $config.ServerUrl = $DEFAULT_SERVER_URL
        }
        
        return $config
    }
    catch {
        Write-Log "Failed to read configuration: $($_.Exception.Message)" "ERROR"
        return @{ ServerUrl = $DEFAULT_SERVER_URL }
    }
}

function Get-DeviceSerial {
    try {
        if ($SerialNumber) {
            return $SerialNumber
        }
        
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
        
        # Last resort - generate based on MAC address
        $mac = Get-WmiObject -Class Win32_NetworkAdapter | Where-Object { $_.NetEnabled -eq $true -and $_.MACAddress } | Select-Object -First 1 -ExpandProperty MACAddress
        if ($mac) {
            return "WIN-" + ($mac -replace ":", "").Substring(0, 8)
        }
        
        throw "Unable to determine device serial number"
    }
    catch {
        Write-Log "Failed to get device serial: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Get-DeviceInfo {
    try {
        $computerSystem = Get-WmiObject -Class Win32_ComputerSystem
        $operatingSystem = Get-WmiObject -Class Win32_OperatingSystem
        $processor = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
        $memory = Get-WmiObject -Class Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
        
        return @{
            name = $computerSystem.Name
            hostname = $env:COMPUTERNAME
            model = "$($computerSystem.Manufacturer) $($computerSystem.Model)".Trim()
            os = "$($operatingSystem.Caption) (Build $($operatingSystem.BuildNumber))"
            processor = $processor.Name
            memory = [math]::Round($memory.Sum / 1GB, 2)
            domain = $computerSystem.Domain
            workgroup = $computerSystem.Workgroup
            lastBootTime = $operatingSystem.ConvertToDateTime($operatingSystem.LastBootUpTime).ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
    }
    catch {
        Write-Log "Failed to get device info: $($_.Exception.Message)" "WARNING"
        return @{
            name = $env:COMPUTERNAME
            hostname = $env:COMPUTERNAME
        }
    }
}

function Test-DeviceRegistration {
    param([string]$ServerUrl, [string]$DeviceSerial)
    
    try {
        $checkUrl = "$ServerUrl/api/device/$DeviceSerial"
        Write-Log "Checking if device is registered: $checkUrl"
        
        $response = Invoke-RestMethod -Uri $checkUrl -Method GET -TimeoutSec 30
        
        if ($response -and $response.deviceInfo) {
            Write-Log "Device $DeviceSerial is already registered as: $($response.deviceInfo.name)"
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
            Write-Log "Device $DeviceSerial is not registered (404)"
            return $false
        }
        
        Write-Log "Failed to check device registration: $($_.Exception.Message)" "WARNING"
        return $false
    }
}

function Register-Device {
    param([string]$ServerUrl, [string]$DeviceSerial, [hashtable]$DeviceInfo)
    
    try {
        $registrationUrl = "$ServerUrl/api/device"
        Write-Log "Registering device $DeviceSerial at: $registrationUrl"
        
        $registrationData = @{
            serialNumber = $DeviceSerial
            id = $DeviceSerial
        }
        
        # Add device info if available
        foreach ($key in $DeviceInfo.Keys) {
            $registrationData[$key] = $DeviceInfo[$key]
        }
        
        $jsonData = $registrationData | ConvertTo-Json -Depth 10
        Write-Log "Registration payload: $jsonData"
        
        $headers = @{
            "Content-Type" = "application/json"
            "User-Agent" = "ReportMate-Windows-Client/1.0"
        }
        
        $response = Invoke-RestMethod -Uri $registrationUrl -Method POST -Body $jsonData -Headers $headers -TimeoutSec 60
        
        if ($response.success) {
            Write-Log "Device registered successfully: $($response.message)"
            
            # Mark device as registered in registry
            try {
                if (-not (Test-Path $REGISTRY_PATH)) {
                    New-Item -Path $REGISTRY_PATH -Force | Out-Null
                }
                Set-ItemProperty -Path $REGISTRY_PATH -Name $REGISTRY_DEVICE_REGISTERED_KEY -Value "true"
                Write-Log "Marked device as registered in registry"
            }
            catch {
                Write-Log "Failed to update registry: $($_.Exception.Message)" "WARNING"
            }
            
            return $true
        }
        else {
            Write-Log "Device registration failed: $($response.error)" "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Device registration failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
try {
    Write-Log "Starting device registration process"
    
    # Get configuration
    $config = Get-Configuration
    Write-Log "Using server URL: $($config.ServerUrl)"
    
    # Get device serial number
    $deviceSerial = Get-DeviceSerial
    Write-Log "Device serial number: $deviceSerial"
    
    # Check if already registered (unless forced)
    if (-not $Force -and $config.DeviceRegistered -eq "true") {
        # Double-check with server
        if (Test-DeviceRegistration -ServerUrl $config.ServerUrl -DeviceSerial $deviceSerial) {
            Write-Log "Device is already registered and verified with server"
            exit 0
        }
        else {
            Write-Log "Registry says device is registered, but server check failed. Re-registering..."
        }
    }
    
    # Get device information
    Write-Log "Collecting device information..."
    $deviceInfo = Get-DeviceInfo
    
    # Register device
    $success = Register-Device -ServerUrl $config.ServerUrl -DeviceSerial $deviceSerial -DeviceInfo $deviceInfo
    
    if ($success) {
        Write-Log "Device registration completed successfully"
        exit 0
    }
    else {
        Write-Log "Device registration failed" "ERROR"
        exit 1
    }
}
catch {
    Write-Log "Device registration failed with error: $($_.Exception.Message)" "ERROR"
    exit 1
}
