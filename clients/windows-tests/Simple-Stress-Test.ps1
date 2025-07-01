# Simple stress test to overwhelm client memory
param(
    [string]$ServerUrl = "http://localhost:3003",
    [int]$Count = 3
)

Write-Host "STRESS TEST: Sending $Count massive payloads to overwhelm client memory..." -ForegroundColor Red

for ($i = 1; $i -le $Count; $i++) {
    # Create extremely large payload
    $largeArray = @()
    for ($j = 1; $j -le 300; $j++) {
        $largeArray += @{
            id = $j
            name = "very_long_process_name_with_lots_of_details_and_parameters_$j"
            command = "C:\Program Files\Very Long Application Name\Sub Directory\Another Directory\executable_$j.exe --parameter1 very_long_value_$j --parameter2 another_very_long_value_$j --config-file C:\Very Long Path\Configuration Files\config_$j.xml"
            data = "This is a very long string that simulates large osquery payloads with lots of detailed information about system processes, performance counters, installed applications, system configuration, network connections, file system details, registry entries, security events, and other comprehensive system monitoring data that would typically be collected by osquery in a production environment and sent to ReportMate for analysis and reporting purposes. This string is intentionally verbose to simulate real-world scenarios where osquery returns extensive system information. Process ID: $j, Session: $(Get-Random), Memory: $(Get-Random -Maximum 8192) MB, CPU: $(Get-Random -Maximum 100)%, Threads: $(Get-Random -Maximum 500), Handles: $(Get-Random -Maximum 10000)"
            modules = @(1..20 | ForEach-Object { @{ name = "module_$_.dll"; path = "C:\Windows\System32\module_$_.dll"; size = $(Get-Random -Maximum 10485760) } })
        }
    }

    $testEvent = @{
        device_id = $env:COMPUTERNAME
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        event_type = "stress_test_$i"
        payload = ($largeArray | ConvertTo-Json -Depth 5)
    }

    try {
        $body = $testEvent | ConvertTo-Json -Depth 6
        Write-Host "Sending payload $i of $Count (size: $([math]::Round($body.Length / 1MB, 2)) MB)" -ForegroundColor Yellow
        
        $response = Invoke-RestMethod -Uri "$ServerUrl/api/events" -Method POST -Body $body -Headers @{'Content-Type'='application/json'} -TimeoutSec 120
        Write-Host "  Success! Event ID: $($response.eventId)" -ForegroundColor Green
        
        Start-Sleep -Milliseconds 200
    } catch {
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "STRESS TEST COMPLETE - Check dashboard for memory issues!" -ForegroundColor Red
