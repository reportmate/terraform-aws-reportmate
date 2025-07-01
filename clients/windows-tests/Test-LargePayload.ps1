# Enhanced ReportMate Test Collector - Large Payload Test
param(
    [string]$ServerUrl = "http://localhost:3000"
)

Write-Host ""
Write-Host "ReportMate Enhanced Test Collector" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Test osquery
$osqueryPath = "C:\Program Files\osquery\osqueryi.exe"
$configPath = "C:\Program Files\osquery\osquery.conf"

Write-Host "Testing osquery with large payloads..." -ForegroundColor Yellow

if (!(Test-Path $osqueryPath)) {
    Write-Host "osquery not found at: $osqueryPath" -ForegroundColor Red
    exit 1
}

if (!(Test-Path $configPath)) {
    Write-Host "osquery config not found at: $configPath" -ForegroundColor Red
    exit 1
}

# Define multiple queries that will generate large payloads
$queries = @{
    "system_info" = "SELECT * FROM system_info;"
    "processes" = "SELECT pid, name, path, cmdline, state, resident_size, total_size FROM processes LIMIT 50;"
    "registry_large" = "SELECT * FROM registry WHERE path LIKE 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\%';"
    "file_system" = "SELECT path, filename, size, type FROM file WHERE directory = 'C:\Program Files' AND type = 'regular' LIMIT 100;"
    "network_connections" = "SELECT * FROM process_open_sockets LIMIT 30;"
    "hardware_events" = "SELECT * FROM hardware_events LIMIT 20;"
    "users" = "SELECT * FROM users;"
    "services" = "SELECT * FROM services LIMIT 50;"
}

$successCount = 0
$errorCount = 0

foreach ($queryName in $queries.Keys) {
    Write-Host ""
    Write-Host "Running query: $queryName" -ForegroundColor Yellow
    
    try {
        $result = & $osqueryPath --json --config_path=$configPath $queries[$queryName]
        
        if ($LASTEXITCODE -eq 0) {
            $data = $result | ConvertFrom-Json
            $dataCount = $data.Count
            
            Write-Host "  Collected $dataCount rows" -ForegroundColor Green
            
            # Create a large payload with metadata
            $payload = @{
                device = $env:COMPUTERNAME
                kind = $queryName
                ts = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                payload = @{
                    query = $queries[$queryName]
                    row_count = $dataCount
                    data = $data
                    metadata = @{
                        collection_time = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
                        osquery_version = "5.17.0"
                        windows_version = (Get-WmiObject Win32_OperatingSystem).Version
                        hostname = $env:COMPUTERNAME
                        domain = $env:USERDOMAIN
                        username = $env:USERNAME
                    }
                }
            }
            
            $json = $payload | ConvertTo-Json -Depth 15
            $payloadSize = [System.Text.Encoding]::UTF8.GetByteCount($json)
            
            Write-Host "  Payload size: $($payloadSize / 1024) KB" -ForegroundColor Cyan
            
            # Send to ReportMate
            try {
                $response = Invoke-RestMethod -Uri "$ServerUrl/api/events" -Method POST -Body $json -ContentType "application/json"
                Write-Host "  ✅ Data sent successfully!" -ForegroundColor Green
                $successCount++
            }
            catch {
                Write-Host "  ❌ Failed to send data: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "  Error details: $($_.Exception.Response)" -ForegroundColor Red
                $errorCount++
            }
        } else {
            Write-Host "  osquery command failed with exit code $LASTEXITCODE" -ForegroundColor Red
            $errorCount++
        }
    }
    catch {
        Write-Host "  Failed to execute osquery: $($_.Exception.Message)" -ForegroundColor Red
        $errorCount++
    }
    
    # Small delay between requests
    Start-Sleep -Milliseconds 500
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Test Summary:" -ForegroundColor Cyan
Write-Host "  Successful: $successCount" -ForegroundColor Green
Write-Host "  Failed: $errorCount" -ForegroundColor Red
Write-Host "  Total: $($successCount + $errorCount)" -ForegroundColor Cyan

if ($errorCount -eq 0) {
    Write-Host ""
    Write-Host "🎉 All tests passed! Large payloads handled successfully!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "⚠️  Some tests failed. Check logs for details." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Enhanced test complete." -ForegroundColor Cyan
