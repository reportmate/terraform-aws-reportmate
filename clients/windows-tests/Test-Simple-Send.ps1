# Simple test script to send data to local dev server on port 3003
param(
    [string]$ServerUrl = "http://localhost:3003"
)

# Test data
$testEvent = @{
    device_id = $env:COMPUTERNAME
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    payload = @{
        test_mode = $true
        computer_name = $env:COMPUTERNAME
        user_name = $env:USERNAME
        system_info = @{
            os_version = (Get-CimInstance Win32_OperatingSystem).Caption
            total_memory = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
        }
    } | ConvertTo-Json -Depth 3
}

Write-Host "Sending test data to $ServerUrl" -ForegroundColor Cyan

try {
    $headers = @{
        'Content-Type' = 'application/json'
        'User-Agent' = 'ReportMate-Windows-Client/1.0'
    }
    
    $body = $testEvent | ConvertTo-Json -Depth 4
    Write-Host "Request body: $body" -ForegroundColor Gray
    
    $response = Invoke-RestMethod -Uri "$ServerUrl/api/events" -Method POST -Body $body -Headers $headers -TimeoutSec 30
    Write-Host "Success! Response: $response" -ForegroundColor Green
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $_" -ForegroundColor Red
}
