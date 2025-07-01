# Test Device Registration and Event Sending
# This script tests the complete flow: registration check, registration, and event sending

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerUrl = "http://localhost:3000",
    
    [Parameter(Mandatory=$false)]
    [string]$SerialNumber = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseOutput = $false
)

function Write-TestLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Get-DeviceSerial {
    if ($SerialNumber) {
        return $SerialNumber
    }
    
    try {
        $serial = Get-WmiObject -Class Win32_BIOS | Select-Object -ExpandProperty SerialNumber
        if ($serial -and $serial.Trim() -ne "") {
            return $serial.Trim()
        }
    }
    catch {
        Write-TestLog "Failed to get BIOS serial: $($_.Exception.Message)" "WARNING"
    }
    
    return $env:COMPUTERNAME
}

function Test-DeviceRegistration {
    param([string]$ServerUrl, [string]$DeviceSerial)
    
    try {
        $checkUrl = "$ServerUrl/api/device/$DeviceSerial"
        Write-TestLog "Checking device registration: $checkUrl"
        
        $response = Invoke-RestMethod -Uri $checkUrl -Method GET -TimeoutSec 30
        
        if ($response -and $response.deviceInfo) {
            Write-TestLog "Device is registered: $($response.deviceInfo.name)" "SUCCESS"
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
            Write-TestLog "Device is not registered (404)" "WARNING"
        } elseif ($statusCode -eq 403) {
            Write-TestLog "Device registration check failed (403)" "ERROR"
        } else {
            Write-TestLog "Registration check failed: $($_.Exception.Message)" "ERROR"
        }
        
        return $false
    }
}

function Register-Device {
    param([string]$ServerUrl, [string]$DeviceSerial)
    
    try {
        $registrationUrl = "$ServerUrl/api/device"
        Write-TestLog "Registering device: $registrationUrl"
        
        $deviceInfo = @{
            serialNumber = $DeviceSerial
            id = $DeviceSerial
            name = $env:COMPUTERNAME
            hostname = $env:COMPUTERNAME
            model = "Test Device"
            os = "Windows Test"
        }
        
        $jsonData = $deviceInfo | ConvertTo-Json
        Write-TestLog "Registration data: $jsonData"
        
        $headers = @{
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri $registrationUrl -Method POST -Body $jsonData -Headers $headers -TimeoutSec 60
        
        if ($response.success) {
            Write-TestLog "Device registered successfully!" "SUCCESS"
            return $true
        } else {
            Write-TestLog "Registration failed: $($response.error)" "ERROR"
            return $false
        }
    }
    catch {
        Write-TestLog "Registration failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Send-TestEvent {
    param([string]$ServerUrl, [string]$DeviceSerial)
    
    try {
        $eventUrl = "$ServerUrl/api/events"
        Write-TestLog "Sending test event: $eventUrl"
        
        $eventData = @{
            device = $DeviceSerial
            kind = "test"
            ts = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            payload = @{
                message = "Test event from registration verification"
                timestamp = (Get-Date).ToString()
                computer = $env:COMPUTERNAME
                user = $env:USERNAME
            }
        }
        
        $jsonData = $eventData | ConvertTo-Json -Depth 10
        Write-TestLog "Event data: $jsonData"
        
        $headers = @{
            "Content-Type" = "application/json"
        }
        
        $response = Invoke-RestMethod -Uri $eventUrl -Method POST -Body $jsonData -Headers $headers -TimeoutSec 60
        
        if ($response.success) {
            Write-TestLog "Test event sent successfully!" "SUCCESS"
            return $true
        } else {
            Write-TestLog "Event send failed: $($response.error)" "ERROR"
            return $false
        }
    }
    catch {
        $statusCode = $null
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
        }
        
        if ($statusCode -eq 403) {
            Write-TestLog "Event rejected - device not registered (403)" "ERROR"
        } elseif ($statusCode -eq 400) {
            Write-TestLog "Bad request - missing device serial (400)" "ERROR"
        } else {
            Write-TestLog "Event send failed: $($_.Exception.Message)" "ERROR"
        }
        return $false
    }
}

# Main execution
try {
    Write-TestLog "Starting device registration and event sending test"
    Write-TestLog "Server URL: $ServerUrl"
    
    # Get device serial
    $deviceSerial = Get-DeviceSerial
    Write-TestLog "Device Serial: $deviceSerial"
    
    # Test 1: Check if device is already registered
    Write-TestLog "=== Test 1: Check Device Registration ===" 
    $isRegistered = Test-DeviceRegistration -ServerUrl $ServerUrl -DeviceSerial $deviceSerial
    
    # Test 2: Register device if not registered or forced
    if (-not $isRegistered -or $Force) {
        Write-TestLog "=== Test 2: Register Device ==="
        if (-not (Register-Device -ServerUrl $ServerUrl -DeviceSerial $deviceSerial)) {
            Write-TestLog "FAILED: Device registration failed" "ERROR"
            exit 1
        }
        
        # Verify registration
        if (-not (Test-DeviceRegistration -ServerUrl $ServerUrl -DeviceSerial $deviceSerial)) {
            Write-TestLog "FAILED: Device registration verification failed" "ERROR"
            exit 1
        }
    }
    
    # Test 3: Send test event
    Write-TestLog "=== Test 3: Send Test Event ==="
    if (-not (Send-TestEvent -ServerUrl $ServerUrl -DeviceSerial $deviceSerial)) {
        Write-TestLog "FAILED: Test event sending failed" "ERROR"
        exit 1
    }
    
    Write-TestLog "=== ALL TESTS PASSED ===" "SUCCESS"
    Write-TestLog "Device registration and event sending flow is working correctly!" "SUCCESS"
    exit 0
}
catch {
    Write-TestLog "Test failed with error: $($_.Exception.Message)" "ERROR"
    exit 1
}
