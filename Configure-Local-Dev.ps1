# Configure ReportMate Windows Client for Local Development
# Run this script as Administrator to point your Windows client to local dev

param(
    [Parameter(Mandatory=$false)]
    [string]$LocalDevUrl = "http://localhost:3000",
    
    [Parameter(Mandatory=$false)]
    [string]$ProductionUrl = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$RestoreProduction = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowConfig = $false
)

# Registry paths (same as the client uses)
$REGISTRY_PATH = "HKLM:\SOFTWARE\Policies\ReportMate"
$REGISTRY_SERVER_KEY = "ServerUrl"

# Get production URL from environment variable or parameter
$PRODUCTION_URL = if ($ProductionUrl) { $ProductionUrl } else { $env:REPORTMATE_PRODUCTION_URL }
if (-not $PRODUCTION_URL) {
    $PRODUCTION_URL = "https://reportmate.ecuad.ca"  # Default fallback
    Write-Warning "No production URL specified. Using default: $PRODUCTION_URL"
    Write-Warning "Set -ProductionUrl parameter or REPORTMATE_PRODUCTION_URL environment variable to override"
}

function Test-AdminRights {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Set-RegistryValue {
    param([string]$Path, [string]$Name, [string]$Value)
    
    try {
        if (!(Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
            Write-Host "✅ Created registry path: $Path" -ForegroundColor Green
        }
        
        Set-ItemProperty -Path $Path -Name $Name -Value $Value
        Write-Host "✅ Set $Name = $Value" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "❌ Failed to set registry: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Get-RegistryValue {
    param([string]$Path, [string]$Name)
    
    try {
        if (Test-Path $Path) {
            $value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($value) {
                return $value.$Name
            }
        }
        return $null
    }
    catch {
        return $null
    }
}

# Check admin rights
if (!(Test-AdminRights)) {
    Write-Host "❌ This script requires Administrator privileges" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "🔧 ReportMate Local Development Configuration" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Show current configuration
if ($ShowConfig -or (!$RestoreProduction -and !$LocalDevUrl)) {
    $currentUrl = Get-RegistryValue -Path $REGISTRY_PATH -Name $REGISTRY_SERVER_KEY
    Write-Host "📋 Current Configuration:" -ForegroundColor Yellow
    Write-Host "  Server URL: $($currentUrl ? $currentUrl : 'Not configured (will use default)')"
    Write-Host ""
    if (!$RestoreProduction -and !$LocalDevUrl) {
        exit 0
    }
}

# Restore production configuration
if ($RestoreProduction) {
    Write-Host "🔄 Restoring production configuration..." -ForegroundColor Yellow
    
    if (Set-RegistryValue -Path $REGISTRY_PATH -Name $REGISTRY_SERVER_KEY -Value $PRODUCTION_URL) {
        Write-Host ""
        Write-Host "✅ Windows client now configured for PRODUCTION" -ForegroundColor Green
        Write-Host "   URL: $PRODUCTION_URL" -ForegroundColor White
        Write-Host ""
        Write-Host "💡 Run ReportMate-Collector.ps1 to send data to production" -ForegroundColor Cyan
    }
    exit 0
}

# Configure for local development
Write-Host "🏠 Configuring for local development..." -ForegroundColor Yellow
Write-Host "   Target: $LocalDevUrl" -ForegroundColor White

# Test if local dev is running
try {
    Write-Host "🔍 Testing local development server..." -ForegroundColor Yellow
    $testResponse = Invoke-WebRequest -Uri "$LocalDevUrl/api/healthz" -Method GET -TimeoutSec 5 -UseBasicParsing
    if ($testResponse.StatusCode -eq 200) {
        Write-Host "✅ Local development server is running" -ForegroundColor Green
    }
}
catch {
    Write-Host "⚠️  Warning: Could not reach local dev server at $LocalDevUrl" -ForegroundColor Yellow
    Write-Host "   Make sure your Next.js dev server is running (npm run dev)" -ForegroundColor White
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne 'y' -and $continue -ne 'Y') {
        Write-Host "❌ Configuration cancelled" -ForegroundColor Red
        exit 1
    }
}

# Set registry configuration
if (Set-RegistryValue -Path $REGISTRY_PATH -Name $REGISTRY_SERVER_KEY -Value $LocalDevUrl) {
    Write-Host ""
    Write-Host "✅ Windows client now configured for LOCAL DEVELOPMENT" -ForegroundColor Green
    Write-Host "   URL: $LocalDevUrl" -ForegroundColor White
    Write-Host ""
    Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
    Write-Host "   1. Make sure Next.js dev server is running: npm run dev" -ForegroundColor White
    Write-Host "   2. Run ReportMate-Collector.ps1 to send data to local dev" -ForegroundColor White
    Write-Host "   3. Check dashboard at http://localhost:3000/dashboard" -ForegroundColor White
    Write-Host ""
    Write-Host "🔄 To restore production config later:" -ForegroundColor Cyan
    Write-Host "   .\Configure-Local-Dev.ps1 -RestoreProduction" -ForegroundColor White
}
else {
    Write-Host "❌ Failed to configure registry" -ForegroundColor Red
    exit 1
}
