# ReportMate Local Development Verification Script
# Run this script to verify your local environment is properly configured

param(
    [switch]$SkipClientTest
)

$ErrorActionPreference = "Stop"

function Write-Status {
    param(
        [string]$Message,
        [string]$Status = "INFO"
    )
    
    $color = switch ($Status) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    
    $symbol = switch ($Status) {
        "SUCCESS" { "✅" }
        "ERROR" { "❌" }
        "WARNING" { "⚠️" }
        default { "ℹ️" }
    }
    
    Write-Host "$symbol $Message" -ForegroundColor $color
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-RegistryConfiguration {
    $registryPath = "HKLM:\SOFTWARE\ReportMate"
    $serverKey = "ServerUrl"
    
    try {
        if (Test-Path $registryPath) {
            $serverUrl = Get-ItemProperty -Path $registryPath -Name $serverKey -ErrorAction SilentlyContinue
            if ($serverUrl) {
                return $serverUrl.$serverKey
            }
        }
        return $null
    }
    catch {
        return $null
    }
}

function Test-LocalServer {
    param([string]$Url = "http://localhost:3000")
    
    try {
        $response = Invoke-WebRequest -Uri "$Url/api/ingest" -Method GET -TimeoutSec 5 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            $content = $response.Content | ConvertFrom-Json
            return $content.service -eq "reportmate-ingest"
        }
        return $false
    }
    catch {
        return $false
    }
}

function Test-OsqueryInstallation {
    try {
        $result = & osqueryi --version 2>$null
        return $result -match "osquery"
    }
    catch {
        return $false
    }
}

# Main verification
Write-Host ""
Write-Host "🔍 ReportMate Local Development Environment Verification" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# Check 1: Admin Rights
if (Test-AdminRights) {
    Write-Status "Administrator privileges available" "SUCCESS"
} else {
    Write-Status "Administrator privileges required for full functionality" "WARNING"
}

# Check 2: Local Development Server
if (Test-LocalServer) {
    Write-Status "Local development server is running and responding" "SUCCESS"
} else {
    Write-Status "Local development server not running on http://localhost:3000" "ERROR"
    Write-Host "   Start with: cd apps\www && npm run dev" -ForegroundColor Yellow
}

# Check 3: Registry Configuration
$registryUrl = Test-RegistryConfiguration
if ($registryUrl) {
    if ($registryUrl -eq "http://localhost:3000") {
        Write-Status "Registry configured for local development ($registryUrl)" "SUCCESS"
    } else {
        Write-Status "Registry configured for: $registryUrl" "WARNING"
        Write-Host "   Run: .\Setup-LocalDev.ps1 to configure for local dev" -ForegroundColor Yellow
    }
} else {
    Write-Status "Registry not configured" "WARNING"
    Write-Host "   Run: .\Setup-LocalDev.ps1 to configure" -ForegroundColor Yellow
}

# Check 4: osquery Installation
if (Test-OsqueryInstallation) {
    Write-Status "osquery is installed and accessible" "SUCCESS"
} else {
    Write-Status "osquery not found or not in PATH" "ERROR"
    Write-Host "   Install osquery from: https://osquery.io/downloads/" -ForegroundColor Yellow
}

# Check 5: Environment Files
$envFiles = @(
    "c:\Users\rchristiansen\DevOps\ReportMate\apps\www\.env.local",
    "c:\Users\rchristiansen\DevOps\ReportMate\apps\www\.env.production-mirror"
)

foreach ($envFile in $envFiles) {
    if (Test-Path $envFile) {
        Write-Status "Environment file exists: $(Split-Path $envFile -Leaf)" "SUCCESS"
    } else {
        Write-Status "Environment file missing: $(Split-Path $envFile -Leaf)" "ERROR"
    }
}

# Check 6: Client Scripts
$clientScripts = @(
    ".\Setup-LocalDev.ps1",
    ".\ReportMate-Collector.ps1"
)

foreach ($script in $clientScripts) {
    if (Test-Path $script) {
        Write-Status "Client script available: $script" "SUCCESS"
    } else {
        Write-Status "Client script missing: $script" "ERROR"
    }
}

# Optional: Test client functionality
if (!$SkipClientTest -and (Test-Path ".\ReportMate-Collector.ps1") -and (Test-LocalServer)) {
    Write-Host ""
    Write-Host "🚀 Ready to test client functionality!" -ForegroundColor Green
    Write-Host "Run the following commands:" -ForegroundColor Yellow
    Write-Host "   .\Setup-LocalDev.ps1          # Configure for local dev" -ForegroundColor Yellow
    Write-Host "   .\ReportMate-Collector.ps1    # Send data to local server" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✨ Verification complete!" -ForegroundColor Cyan
