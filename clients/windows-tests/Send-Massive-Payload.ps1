# Send extremely large payloads to trigger memory issues
param(
    [string]$ServerUrl = "http://localhost:3003"
)

Write-Host "Sending extremely large payloads to trigger memory issues..." -ForegroundColor Red

# Create a massive payload that simulates a real osquery dump
$massiveProcessList = @()
for ($i = 1; $i -le 500; $i++) {
    $massiveProcessList += @{
        process_id = Get-Random -Maximum 99999
        process_name = "large_application_$i.exe"
        command_line = "C:\Program Files\VeryLongApplicationName\SubDirectory\AnotherSubDirectory\YetAnotherFolder\large_application_$i.exe --config-file=C:\ProgramData\VeryLongConfigurationDirectoryName\configuration_files\application_settings\detailed_configuration_file_with_very_long_name_$i.config --log-level=verbose --output-directory=C:\Users\Administrator\Documents\ApplicationLogs\DetailedLogs\ProcessSpecificLogs\Session_$(Get-Random) --enable-advanced-monitoring --performance-counter-collection --memory-dump-on-exception --crash-dump-location=C:\CrashDumps\ProcessCrashes\Session_$(Get-Random)"
        cpu_percent = (Get-Random -Maximum 100)
        memory_mb = (Get-Random -Maximum 16384)
        threads = (Get-Random -Maximum 500)
        handles = (Get-Random -Maximum 10000)
        start_time = (Get-Date).AddMinutes(-(Get-Random -Maximum 10080)).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        working_set = (Get-Random -Maximum 2147483647)
        virtual_size = (Get-Random -Maximum 2147483647)
        page_faults = (Get-Random -Maximum 1000000)
        environment_variables = @{
            PATH = "C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Program Files\Git\cmd;C:\Program Files\Docker\Docker\resources\bin;C:\ProgramData\DockerDesktop\version-bin;C:\Users\Administrator\AppData\Local\Microsoft\WindowsApps;C:\Program Files\Microsoft VS Code\bin"
            TEMP = "C:\Users\Administrator\AppData\Local\Temp"
            TMP = "C:\Users\Administrator\AppData\Local\Temp"
            USERNAME = "Administrator"
            USERPROFILE = "C:\Users\Administrator"
            COMPUTERNAME = $env:COMPUTERNAME
        }
        modules = @(
            @{ name = "kernel32.dll"; path = "C:\Windows\System32\kernel32.dll"; size = 1234567 }
            @{ name = "ntdll.dll"; path = "C:\Windows\System32\ntdll.dll"; size = 2345678 }
            @{ name = "user32.dll"; path = "C:\Windows\System32\user32.dll"; size = 3456789 }
        )
    }
}

$massiveEvent = @{
    device_id = $env:COMPUTERNAME
    timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
    event_type = "massive_processes"
    payload = ($massiveProcessList | ConvertTo-Json -Depth 5)
}

try {
    $headers = @{
        'Content-Type' = 'application/json'
        'User-Agent' = 'ReportMate-Windows-Client/1.0'
    }
    
    $body = $massiveEvent | ConvertTo-Json -Depth 6
    
    Write-Host "Sending massive payload (size: $($body.Length) bytes - $('{0:N2}' -f ($body.Length / 1MB)) MB)" -ForegroundColor Yellow
    
    $response = Invoke-RestMethod -Uri "$ServerUrl/api/events" -Method POST -Body $body -Headers $headers -TimeoutSec 60
    Write-Host "  ✅ Success! Event ID: $($response.eventId)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full error: $_" -ForegroundColor Red
}

Write-Host "Massive payload sent - this should trigger memory issues in the frontend!" -ForegroundColor Red
