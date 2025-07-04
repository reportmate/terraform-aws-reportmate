# ReportMate Local Development Setup
# This script configures the Windows client to send data to local development environment

param(
    [Parameter(Mandatory=$false)]
    [string]$LocalServerUrl = "http://localhost:3004",
    
    [Parameter(Mandatory=$false)]
    [string]$Passphrase = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Reset = $false
)

# Registry paths
$REGISTRY_PATH = "HKLM:\SOFTWARE\Policies\ReportMate"
$REGISTRY_PASSPHRASE_KEY = "Passphrase"
$REGISTRY_SERVER_KEY = "ServerUrl"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARNING" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
    )
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Value
    )
    
    try {
        # Create registry path if it doesn't exist
        if (!(Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
            Write-Log "Created registry path: $Path"
        }
        
        # Set the registry value
        Set-ItemProperty -Path $Path -Name $Name -Value $Value
        Write-Log "Set registry value: $Path\$Name = $Value" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Failed to set registry value: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-LocalServer {
    param([string]$ServerUrl)
    
    try {
        Write-Log "Testing connection to local server: $ServerUrl"
        $response = Invoke-WebRequest -Uri "$ServerUrl/api/ingest" -Method GET -TimeoutSec 10 -UseBasicParsing
        
        if ($response.StatusCode -eq 200) {
            $content = $response.Content | ConvertFrom-Json
            if ($content.service -eq "reportmate-ingest") {
                Write-Log "✅ Local server is running and responding correctly!" "SUCCESS"
                return $true
            }
        }
        
        Write-Log "❌ Local server responded but not with expected format" "WARNING"
        return $false
    }
    catch {
        Write-Log "❌ Cannot connect to local server: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Main execution
Write-Host ""
Write-Host "🔧 ReportMate Local Development Setup" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Check admin rights
if (!(Test-AdminRights)) {
    Write-Log "This script requires administrator privileges. Please run as administrator." "ERROR"
    exit 1
}

if ($Reset) {
    Write-Host "🔄 Resetting to production configuration..." -ForegroundColor Yellow
    Set-RegistryValue -Path $REGISTRY_PATH -Name $REGISTRY_SERVER_KEY -Value ($env:REPORTMATE_API_URL -or "https://your-reportmate-api.com")
    if ($Passphrase) {
        Set-RegistryValue -Path $REGISTRY_PATH -Name $REGISTRY_PASSPHRASE_KEY -Value $Passphrase
    } else {
        Remove-ItemProperty -Path $REGISTRY_PATH -Name $REGISTRY_PASSPHRASE_KEY -ErrorAction SilentlyContinue
    }
    Write-Log "✅ Reset to production configuration" "SUCCESS"
    exit 0
}

# Test local server first
if (!(Test-LocalServer -ServerUrl $LocalServerUrl)) {
    Write-Host ""
    Write-Host "❌ Local development server is not running or not responding correctly." -ForegroundColor Red
    Write-Host "Please ensure your local dev server is running on $LocalServerUrl" -ForegroundColor Red
    Write-Host "Run this command in your ReportMate directory:" -ForegroundColor Yellow
    Write-Host "   cd apps\www && npm run dev" -ForegroundColor Yellow
    exit 1
}

# Configure for local development
Write-Host ""
Write-Host "🔧 Configuring Windows client for local development..." -ForegroundColor Green

# Set server URL to local development
if (!(Set-RegistryValue -Path $REGISTRY_PATH -Name $REGISTRY_SERVER_KEY -Value $LocalServerUrl)) {
    Write-Log "Failed to configure server URL" "ERROR"
    exit 1
}

# Set passphrase if provided, or remove it for local dev
if ($Passphrase) {
    if (!(Set-RegistryValue -Path $REGISTRY_PATH -Name $REGISTRY_PASSPHRASE_KEY -Value $Passphrase)) {
        Write-Log "Failed to configure passphrase" "ERROR"
        exit 1
    }
} else {
    # Remove passphrase for local development (no auth needed)
    Remove-ItemProperty -Path $REGISTRY_PATH -Name $REGISTRY_PASSPHRASE_KEY -ErrorAction SilentlyContinue
    Write-Log "Removed passphrase for local development (no authentication)"
}

Write-Host ""
Write-Host "✅ Windows client configured for local development!" -ForegroundColor Green
Write-Host ""
Write-Host "Configuration:" -ForegroundColor White
Write-Host "  Server URL: $LocalServerUrl" -ForegroundColor White
Write-Host "  Authentication: $($Passphrase ? 'Enabled' : 'Disabled (local dev)')" -ForegroundColor White
Write-Host ""
Write-Host "🚀 You can now run the collector to send data to your local dev environment:" -ForegroundColor Cyan
Write-Host "   .\ReportMate-Collector.ps1 -Verbose" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔄 To reset back to production:" -ForegroundColor Cyan
Write-Host "   .\Setup-LocalDev.ps1 -Reset" -ForegroundColor Yellow


