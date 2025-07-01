# Simple ReportMate Test Collector
param(
    [string]$ServerUrl = "http://localhost:3001"
)

Write-Host ""
Write-Host "ReportMate Test Collector" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

# Test osquery
$osqueryPath = "C:\Program Files\osquery\osqueryi.exe"
$configPath = "C:\Program Files\osquery\osquery.conf"

Write-Host "Testing osquery..." -ForegroundColor Yellow

if (!(Test-Path $osqueryPath)) {
    Write-Host "osquery not found at: $osqueryPath" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $configPath)) {
    Write-Host "osquery config not found at: $configPath" -ForegroundColor Red
    exit 1
}

# Run a simple osquery command
try {
    Write-Host "Running osquery system_info..." -ForegroundColor Yellow
    $result = & $osqueryPath --json --config_path=$configPath "SELECT hostname, cpu_brand, physical_memory FROM system_info;"
    
    if ($LASTEXITCODE -eq 0) {
        $systemInfo = $result | ConvertFrom-Json
        Write-Host "System info collected successfully:" -ForegroundColor Green
        $systemInfo | Format-Table
        
        # Prepare payload
        $payload = @{
            device = $env:COMPUTERNAME
            kind = "system_info"
            ts = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
            payload = $systemInfo
        }
        
        $json = $payload | ConvertTo-Json -Depth 10
        
        Write-Host "Sending data to ReportMate at $ServerUrl..." -ForegroundColor Yellow
        
        # Send to ReportMate
        try {
            $response = Invoke-RestMethod -Uri "$ServerUrl/api/events" -Method POST -Body $json -ContentType "application/json"
            Write-Host "Data sent successfully!" -ForegroundColor Green
            Write-Host "Response: $response" -ForegroundColor Gray
        }
        catch {
            Write-Host "Failed to send data: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "Error details: $($_.Exception.Response)" -ForegroundColor Red
        }
    } else {
        Write-Host "osquery command failed with exit code $LASTEXITCODE" -ForegroundColor Red
        Write-Host "Output: $result" -ForegroundColor Red
    }
}
catch {
    Write-Host "Failed to execute osquery: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test complete." -ForegroundColor Cyan
