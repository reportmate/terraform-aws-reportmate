# ReportMate Windows Client Installer
# This script installs and configures the ReportMate client on Windows systems

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerUrl = "https://reportmate-api.azurewebsites.net",
    
    [Parameter(Mandatory=$false)]
    [string]$Passphrase = "",
    
    [Parameter(Mandatory=$false)]
    [string]$InstallPath = "C:\Program Files\ReportMate",
    
    [Parameter(Mandatory=$false)]
    [switch]$Uninstall = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Silent = $false
)

# Script paths and configuration
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$REGISTRY_PATH = "HKLM:\SOFTWARE\Policies\ReportMate"
$TASK_NAME = "ReportMate Data Collection"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    if (!$Silent) {
        switch ($Level) {
            "ERROR" { Write-Host $logMessage -ForegroundColor Red }
            "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
            default { Write-Host $logMessage }
        }
    }
    
    # Log to file
    $logFile = "$env:TEMP\ReportMate-Install.log"
    Add-Content -Path $logFile -Value $logMessage
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-ReportMateClient {
    Write-Log "Starting ReportMate client installation..." "INFO"
    
    # Create installation directory
    if (!(Test-Path $InstallPath)) {
        New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
        Write-Log "Created installation directory: $InstallPath" "SUCCESS"
    }
    
    # Copy files
    $filesToCopy = @(
        "ReportMate-Collector.ps1",
        "ReportMate-Setup.ps1",
        "osquery.conf"
    )
    
    foreach ($file in $filesToCopy) {
        $sourcePath = Join-Path $SCRIPT_DIR $file
        $destPath = Join-Path $InstallPath $file
        
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            Write-Log "Copied $file to installation directory" "SUCCESS"
        } else {
            Write-Log "Source file not found: $file" "WARNING"
        }
    }
    
    # Configure registry settings
    Write-Log "Configuring registry settings..."
    
    if (!(Test-Path $REGISTRY_PATH)) {
        New-Item -Path $REGISTRY_PATH -Force | Out-Null
    }
    
    Set-ItemProperty -Path $REGISTRY_PATH -Name "ServerUrl" -Value $ServerUrl
    Set-ItemProperty -Path $REGISTRY_PATH -Name "InstallPath" -Value $InstallPath
    Set-ItemProperty -Path $REGISTRY_PATH -Name "EnableLogging" -Value 1
    Set-ItemProperty -Path $REGISTRY_PATH -Name "LogLevel" -Value 3
    Set-ItemProperty -Path $REGISTRY_PATH -Name "CollectionInterval" -Value 3600
    
    if ($Passphrase) {
        Set-ItemProperty -Path $REGISTRY_PATH -Name "Passphrase" -Value $Passphrase
        Write-Log "Configured authentication passphrase" "SUCCESS"
    }
    
    Write-Log "Registry configuration completed" "SUCCESS"
    
    # Create scheduled task
    Write-Log "Creating scheduled task..."
    
    $taskXmlPath = Join-Path $SCRIPT_DIR "ReportMate-ScheduledTask.xml"
    if (Test-Path $taskXmlPath) {
        # Update the XML with the correct installation path
        $taskXml = Get-Content $taskXmlPath -Raw
        $taskXml = $taskXml -replace 'C:\\Program Files\\ReportMate', $InstallPath.Replace('\', '\\')
        $tempXmlPath = "$env:TEMP\ReportMate-Task.xml"
        Set-Content -Path $tempXmlPath -Value $taskXml
        
        try {
            Register-ScheduledTask -Xml (Get-Content $tempXmlPath -Raw) -TaskName $TASK_NAME -Force | Out-Null
            Write-Log "Scheduled task created successfully" "SUCCESS"
            
            # Clean up temp file
            Remove-Item $tempXmlPath -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Log "Failed to create scheduled task: $($_.Exception.Message)" "ERROR"
        }
    } else {
        Write-Log "Scheduled task XML not found - creating basic task" "WARNING"
        
        # Create a basic scheduled task
        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$InstallPath\ReportMate-Collector.ps1`""
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(5) -RepetitionInterval (New-TimeSpan -Hours 1)
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
        
        Register-ScheduledTask -TaskName $TASK_NAME -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
        Write-Log "Basic scheduled task created" "SUCCESS"
    }
    
    # Test configuration
    Write-Log "Testing client configuration..."
    
    try {
        $testScript = Join-Path $InstallPath "ReportMate-Collector.ps1"
        if (Test-Path $testScript) {
            & PowerShell.exe -NoProfile -ExecutionPolicy Bypass -File $testScript -TestMode | Out-Null
            if ($LASTEXITCODE -eq 0) {
                Write-Log "Configuration test passed" "SUCCESS"
            } else {
                Write-Log "Configuration test failed - check settings" "WARNING"
            }
        }
    }
    catch {
        Write-Log "Could not run configuration test: $($_.Exception.Message)" "WARNING"
    }
    
    Write-Log "ReportMate client installation completed!" "SUCCESS"
}

function Uninstall-ReportMateClient {
    Write-Log "Starting ReportMate client uninstallation..." "INFO"
    
    # Remove scheduled task
    try {
        Unregister-ScheduledTask -TaskName $TASK_NAME -Confirm:$false -ErrorAction SilentlyContinue
        Write-Log "Removed scheduled task" "SUCCESS"
    }
    catch {
        Write-Log "Failed to remove scheduled task: $($_.Exception.Message)" "WARNING"
    }
    
    # Remove registry settings
    try {
        Remove-Item -Path $REGISTRY_PATH -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Removed registry settings" "SUCCESS"
    }
    catch {
        Write-Log "Failed to remove registry settings: $($_.Exception.Message)" "WARNING"
    }
    
    # Remove installation directory
    if (Test-Path $InstallPath) {
        try {
            Remove-Item -Path $InstallPath -Recurse -Force
            Write-Log "Removed installation directory" "SUCCESS"
        }
        catch {
            Write-Log "Failed to remove installation directory: $($_.Exception.Message)" "WARNING"
        }
    }
    
    Write-Log "ReportMate client uninstallation completed!" "SUCCESS"
}

function Show-Configuration {
    Write-Host ""
    Write-Host "📋 Current ReportMate Configuration:" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    
    # Check if installed
    if (Test-Path $InstallPath) {
        Write-Host "✅ Installation Status: Installed" -ForegroundColor Green
        Write-Host "📁 Installation Path: $InstallPath"
    } else {
        Write-Host "❌ Installation Status: Not Installed" -ForegroundColor Red
        return
    }
    
    # Check registry settings
    if (Test-Path $REGISTRY_PATH) {
        $serverUrl = Get-ItemProperty -Path $REGISTRY_PATH -Name "ServerUrl" -ErrorAction SilentlyContinue
        $passphrase = Get-ItemProperty -Path $REGISTRY_PATH -Name "Passphrase" -ErrorAction SilentlyContinue
        $interval = Get-ItemProperty -Path $REGISTRY_PATH -Name "CollectionInterval" -ErrorAction SilentlyContinue
        
        Write-Host "🌐 Server URL: $($serverUrl.ServerUrl ?? 'Not configured')"
        Write-Host "🔐 Authentication: $($passphrase.Passphrase ? 'Enabled' : 'Disabled')"
        Write-Host "⏱️  Collection Interval: $($interval.CollectionInterval ?? 'Default (3600)') seconds"
    }
    
    # Check scheduled task
    $task = Get-ScheduledTask -TaskName $TASK_NAME -ErrorAction SilentlyContinue
    if ($task) {
        Write-Host "📅 Scheduled Task: $($task.State)" -ForegroundColor Green
        Write-Host "🔄 Next Run: $($task.NextRunTime ?? 'Not scheduled')"
    } else {
        Write-Host "❌ Scheduled Task: Not configured" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Main execution
if (!$Silent) {
    Write-Host ""
    Write-Host "🔧 ReportMate Windows Client Installer" -ForegroundColor Cyan
    Write-Host "=======================================" -ForegroundColor Cyan
    Write-Host ""
}

# Check administrator rights
if (!(Test-AdminRights)) {
    Write-Log "This script must be run as Administrator" "ERROR"
    if (!$Silent) {
        Write-Host ""
        Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
    }
    exit 1
}

# Show current configuration if no action specified
if (!$Uninstall -and !$ServerUrl -and !$Passphrase) {
    Show-Configuration
    exit 0
}

# Perform installation or uninstallation
try {
    if ($Uninstall) {
        Uninstall-ReportMateClient
    } else {
        Install-ReportMateClient
    }
    
    if (!$Silent) {
        Write-Host ""
        Show-Configuration
        
        Write-Host ""
        Write-Host "📋 Next Steps:" -ForegroundColor Yellow
        Write-Host "  1. Verify the scheduled task is running properly"
        Write-Host "  2. Check Windows Event Log for ReportMate events"
        Write-Host "  3. Monitor Azure Application Insights for incoming data"
        Write-Host "  4. Use Group Policy to deploy settings across your environment"
        Write-Host ""
        Write-Host "🔗 Documentation: See CLIENT_AUTHENTICATION.md for more details" -ForegroundColor Cyan
        Write-Host ""
    }
    
    exit 0
}
catch {
    Write-Log "Installation failed: $($_.Exception.Message)" "ERROR"
    exit 1
}
