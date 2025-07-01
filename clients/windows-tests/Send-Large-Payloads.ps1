# Send multiple large payloads to trigger the error
param(
    [string]$ServerUrl = "http://localhost:3003",
    [int]$Count = 5
)

Write-Host "Sending $Count large payloads to $ServerUrl" -ForegroundColor Cyan

for ($i = 1; $i -le $Count; $i++) {
    # Create a large payload similar to what osquery would send
    $largeData = @()
    for ($j = 1; $j -le 100; $j++) {
        $largeData += @{
            process_id = Get-Random -Maximum 99999
            process_name = "test_process_$j.exe"
            command_line = "C:\Windows\System32\test_process_$j.exe --param1 value1 --param2 value2 --very-long-parameter-name-that-makes-the-payload-larger some_very_long_value_that_simulates_real_world_data"
            cpu_percent = (Get-Random -Maximum 100)
            memory_mb = (Get-Random -Maximum 8192)
            start_time = (Get-Date).AddMinutes(-(Get-Random -Maximum 1440)).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
    }
    
    $testEvent = @{
        device_id = $env:COMPUTERNAME
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        event_type = "processes"
        payload = ($largeData | ConvertTo-Json -Depth 3)
    }

    try {
        $headers = @{
            'Content-Type' = 'application/json'
            'User-Agent' = 'ReportMate-Windows-Client/1.0'
        }
        
        $body = $testEvent | ConvertTo-Json -Depth 4
        
        Write-Host "Sending payload $i of $Count (size: $($body.Length) bytes)" -ForegroundColor Yellow
        
        $response = Invoke-RestMethod -Uri "$ServerUrl/api/events" -Method POST -Body $body -Headers $headers -TimeoutSec 30
        Write-Host "  ✅ Success! Event ID: $($response.eventId)" -ForegroundColor Green
        
        Start-Sleep -Milliseconds 500
    } catch {
        Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "Finished sending $Count payloads" -ForegroundColor Cyan
