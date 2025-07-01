# Send multiple massive payloads rapidly to overwhelm client memory
param(
    [string]$ServerUrl = "http://localhost:3003",
    [int]$Count = 10
)

Write-Host "🔥 STRESS TEST: Sending $Count massive payloads rapidly to overwhelm client memory..." -ForegroundColor Red

for ($i = 1; $i -le $Count; $i++) {
    # Create extremely large nested data structures
    $complexData = @()
    for ($j = 1; $j -le 200; $j++) {
        $complexData += @{
            process_id = Get-Random -Maximum 99999
            process_name = "complex_application_with_very_long_name_that_includes_version_numbers_and_build_info_$j.exe"
            full_command_line = "C:\Program Files (x86)\VeryLongCompanyName\ApplicationSuiteName\ProductVersionNumber\SubApplicationDirectory\ExecutableWithVeryLongName_$j.exe --configuration-file-path=C:\ProgramData\VeryLongCompanyName\ApplicationSuiteName\Configuration\DetailedConfigurationFiles\application_specific_config_$j.xml --logging-directory=C:\Users\Administrator\Documents\ApplicationLogs\DetailedLogging\ProcessSpecificLogs\Session_$(Get-Random -Maximum 999999) --performance-monitoring-enabled=true --memory-profiling-enabled=true --cpu-usage-tracking=verbose --network-monitoring=detailed --file-system-monitoring=comprehensive --registry-monitoring=full --process-monitoring=advanced --thread-monitoring=detailed --exception-handling=comprehensive --crash-dump-location=C:\CrashDumps\ApplicationSpecificDumps\Session_$(Get-Random -Maximum 999999)\ProcessCrashes --debug-symbols-path=C:\Symbols\ApplicationSymbols\VersionSpecific\BuildSpecific --temporary-files-directory=C:\Temp\ApplicationSpecific\Session_$(Get-Random -Maximum 999999) --cache-directory=C:\Cache\ApplicationCache\UserSpecific\SessionSpecific_$(Get-Random -Maximum 999999)"
            environment_block = @{
                PATH = "C:\Windows\System32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Program Files\Git\cmd;C:\Program Files\Docker\Docker\resources\bin;C:\ProgramData\DockerDesktop\version-bin;C:\Users\Administrator\AppData\Local\Microsoft\WindowsApps;C:\Program Files\Microsoft VS Code\bin;C:\Program Files (x86)\VeryLongCompanyName\ApplicationSuiteName\ProductVersionNumber\bin;C:\Program Files\AnotherVeryLongApplicationName\UtilityDirectory\CommandLineTools"
                TEMP = "C:\Users\Administrator\AppData\Local\Temp\ApplicationSpecific_$(Get-Random -Maximum 999999)"
                APPDATA = "C:\Users\Administrator\AppData\Roaming\VeryLongCompanyName\ApplicationSuiteName\UserSpecificData"
                LOCALAPPDATA = "C:\Users\Administrator\AppData\Local\VeryLongCompanyName\ApplicationSuiteName\CacheAndTempData"
                PROGRAMFILES = "C:\Program Files"
                PROGRAMFILES_X86 = "C:\Program Files (x86)"
                COMPUTERNAME = $env:COMPUTERNAME
                USERNAME = "Administrator"
                USERDOMAIN = "WORKGROUP"
                USERPROFILE = "C:\Users\Administrator"
                APPLICATION_SPECIFIC_CONFIG = "DetailedConfigurationWithManyParametersAndSettings_$j"
            }
            performance_data = @{
                cpu_percent = (Get-Random -Maximum 100)
                memory_working_set_mb = (Get-Random -Maximum 8192)
                memory_virtual_mb = (Get-Random -Maximum 16384)
                memory_private_mb = (Get-Random -Maximum 4096)
                page_faults_per_second = (Get-Random -Maximum 10000)
                handle_count = (Get-Random -Maximum 50000)
                thread_count = (Get-Random -Maximum 1000)
                gdi_objects = (Get-Random -Maximum 10000)
                user_objects = (Get-Random -Maximum 10000)
                io_read_bytes_per_second = (Get-Random -Maximum 104857600)
                io_write_bytes_per_second = (Get-Random -Maximum 104857600)
                network_bytes_sent_per_second = (Get-Random -Maximum 1048576)
                network_bytes_received_per_second = (Get-Random -Maximum 1048576)
            }
            loaded_modules = @()
        }
        
        # Add many modules to increase payload size
        for ($k = 1; $k -le 50; $k++) {
            $complexData[$j-1].loaded_modules += @{
                module_name = "very_long_module_name_with_version_info_$k.dll"
                module_path = "C:\Windows\System32\VeryLongDirectoryStructure\ModuleSpecificDirectory\SubDirectory_$k\very_long_module_name_with_version_info_$k.dll"
                module_size = (Get-Random -Maximum 104857600)
                module_version = "$(Get-Random -Maximum 10).$(Get-Random -Maximum 10).$(Get-Random -Maximum 1000).$(Get-Random -Maximum 1000)"
                module_description = "This is a very long module description that contains detailed information about the module functionality, version history, compatibility notes, and technical specifications that make the payload much larger than typical osquery results would be in a normal production environment but simulates the worst-case scenario where applications load many modules with verbose descriptions_$k"
            }
        }
    }

    $massiveEvent = @{
        device_id = $env:COMPUTERNAME
        timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        event_type = "stress_test_processes_$i"
        payload = ($complexData | ConvertTo-Json -Depth 10)
    }

    try {
        $headers = @{
            'Content-Type' = 'application/json'
            'User-Agent' = 'ReportMate-StressTest-Client/1.0'
        }
        
        $body = $massiveEvent | ConvertTo-Json -Depth 11
        
        Write-Host "🚀 Payload $i/$Count (size: $('{0:N2}' -f ($body.Length / 1MB)) MB)" -ForegroundColor Yellow
        
        $response = Invoke-RestMethod -Uri "$ServerUrl/api/events" -Method POST -Body $body -Headers $headers -TimeoutSec 120
        Write-Host "  ✅ Payload $i sent! Event ID: $($response.eventId)" -ForegroundColor Green
        
        # Send rapidly to stress the system
        Start-Sleep -Milliseconds 100
    } catch {
        Write-Host "  ❌ Payload $i FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "🔥 STRESS TEST COMPLETE - Client should now experience memory issues!" -ForegroundColor Red
Write-Host "📊 Total data sent: approximately $($Count * 10) MB" -ForegroundColor Magenta
