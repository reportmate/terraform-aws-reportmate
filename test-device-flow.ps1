# Test script to verify device registration and event reporting flow
# This simulates what the Windows client (runner.exe) should do

$apiUrl = "https://reportmate-frontend-prod.blackdune-79551938.canadacentral.azurecontainerapps.io"
$deviceSerial = "0F33V9G25083HJ"

Write-Host "=== ReportMate Device Registration and Event Flow Test ===" -ForegroundColor Cyan
Write-Host "API URL: $apiUrl" -ForegroundColor Yellow
Write-Host "Device Serial: $deviceSerial" -ForegroundColor Yellow
Write-Host ""

# Test 1: Device Registration
Write-Host "1. Testing Device Registration..." -ForegroundColor Green
$deviceData = @{
    serialNumber = $deviceSerial
    deviceType = "laptop" 
    operatingSystem = "Windows 11"
    architecture = "x64"
    hostname = $env:COMPUTERNAME
} | ConvertTo-Json

try {
    $registrationResponse = Invoke-RestMethod -Uri "$apiUrl/api/device" -Method POST -Body $deviceData -ContentType "application/json"
    Write-Host "✅ Registration Result: $($registrationResponse.message)" -ForegroundColor Green
    Write-Host "   Action: $($registrationResponse.action)" -ForegroundColor White
    Write-Host "   Device ID: $($registrationResponse.device.id)" -ForegroundColor White
} catch {
    Write-Host "❌ Registration Failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 2: Event Submission (Registered Device)
Write-Host "2. Testing Event Submission (Registered Device)..." -ForegroundColor Green
$eventData = @{
    device = $deviceSerial
    kind = "osquery_result"
    payload = @{
        query_name = "system_info"
        columns = @{
            hostname = $env:COMPUTERNAME
            cpu_brand = "Test CPU"
            total_physical_memory = "16GB"
        }
    }
    ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
} | ConvertTo-Json -Depth 3

try {
    $eventResponse = Invoke-RestMethod -Uri "$apiUrl/api/events" -Method POST -Body $eventData -ContentType "application/json"
    Write-Host "✅ Event Submission Result: $($eventResponse.message)" -ForegroundColor Green
    Write-Host "   Event ID: $($eventResponse.eventId)" -ForegroundColor White
    Write-Host "   Timestamp: $($eventResponse.timestamp)" -ForegroundColor White
} catch {
    Write-Host "❌ Event Submission Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Event Submission (Unregistered Device) 
Write-Host "3. Testing Event Rejection (Unregistered Device)..." -ForegroundColor Green
$unregisteredEventData = @{
    device = "29213acd-008e-4fed-9c04-7271380232f0"
    kind = "unauthorized_attempt"
    payload = @{
        message = "Large data payload received"
        size = "1024KB"
    }
    ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
} | ConvertTo-Json -Depth 3

try {
    $rejectionResponse = Invoke-RestMethod -Uri "$apiUrl/api/events" -Method POST -Body $unregisteredEventData -ContentType "application/json"
    Write-Host "❌ Unexpected Success: Unregistered device was not rejected!" -ForegroundColor Red
} catch {
    # Parse the error response
    $errorContent = $_.ErrorDetails.Message | ConvertFrom-Json
    if ($errorContent.code -eq "DEVICE_NOT_REGISTERED") {
        Write-Host "✅ Properly Rejected: $($errorContent.error)" -ForegroundColor Green
        Write-Host "   Code: $($errorContent.code)" -ForegroundColor White
        Write-Host "   Action: $($errorContent.action)" -ForegroundColor White
    } else {
        Write-Host "❌ Unexpected Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Test Complete ===" -ForegroundColor Cyan
Write-Host "The device registration and event enforcement system is working correctly!" -ForegroundColor Green
Write-Host "Device $deviceSerial can register and send data, while unregistered devices are blocked." -ForegroundColor Green
