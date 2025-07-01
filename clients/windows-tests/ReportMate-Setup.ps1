# ReportMate Windows Client Setup Script
# This script configures the Windows client with authentication settings

param(
    [Parameter(Mandatory=$false)]
    [string]$ServerUrl = "https://reportmate-api.azurewebsites.net",
    
    [Parameter(Mandatory=$false)]
    [string]$Passphrase = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$RemovePassphrase = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ShowConfiguration = $false
)

# Registry paths
$REGISTRY_PATH = "HKLM:\SOFTWARE\Policies\ReportMate"
$REGISTRY_PASSPHRASE_KEY = "Passphrase"
$REGISTRY_SERVER_KEY = "ServerUrl"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
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
        Write-Log "Set registry value: $Path\$Name = $Value"
        return $true
    }
    catch {
        Write-Log "Failed to set registry value: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Remove-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )
    
    try {
        if (Test-Path $Path) {
            Remove-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            Write-Log "Removed registry value: $Path\$Name"
        }
        return $true
    }
    catch {
        Write-Log "Failed to remove registry value: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Get-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )
    
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

function Show-CurrentConfiguration {
    Write-Log "Current ReportMate Configuration:"
    Write-Host ""
    
    $serverUrl = Get-RegistryValue -Path $REGISTRY_PATH -Name $REGISTRY_SERVER_KEY
    $passphrase = Get-RegistryValue -Path $REGISTRY_PATH -Name $REGISTRY_PASSPHRASE_KEY
    
    Write-Host "  Server URL: $($serverUrl ?? 'Not configured')"
    Write-Host "  Passphrase: $($passphrase ? 'Configured' : 'Not configured')"
    Write-Host ""
    
    # Test connectivity
    if ($serverUrl) {
        Write-Log "Testing connectivity to server..."
        try {
            $response = Invoke-WebRequest -Uri "$serverUrl/api/health" -Method GET -TimeoutSec 10 -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                Write-Host "  ✅ Server connectivity: OK" -ForegroundColor Green
            } else {
                Write-Host "  ⚠️  Server connectivity: Unexpected status $($response.StatusCode)" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "  ❌ Server connectivity: Failed - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Test-Configuration {
    Write-Log "Testing ReportMate configuration..."
    
    $serverUrl = Get-RegistryValue -Path $REGISTRY_PATH -Name $REGISTRY_SERVER_KEY
    $passphrase = Get-RegistryValue -Path $REGISTRY_PATH -Name $REGISTRY_PASSPHRASE_KEY
    
    if (!$serverUrl) {
        Write-Log "Server URL not configured" "WARNING"
        return $false
    }
    
    # Create test payload
    $testPayload = @{
        device = $env:COMPUTERNAME
        kind = "test"
        payload = @{
            test = $true
            timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        }
    }
    
    # Add passphrase if configured
    if ($passphrase) {
        $testPayload.passphrase = $passphrase
    }
    
    try {
        $json = $testPayload | ConvertTo-Json -Depth 10
        $response = Invoke-WebRequest -Uri "$serverUrl/api/ingest" -Method POST -Body $json -ContentType "application/json" -TimeoutSec 30 -UseBasicParsing
        
        if ($response.StatusCode -eq 202) {
            Write-Host "  ✅ Authentication test: SUCCESS" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  ❌ Authentication test: Unexpected status $($response.StatusCode)" -ForegroundColor Red
            return $false
        }
    }
    catch {
        if ($_.Exception.Message -like "*401*") {
            Write-Host "  ❌ Authentication test: UNAUTHORIZED - Check passphrase" -ForegroundColor Red
        } else {
            Write-Host "  ❌ Authentication test: FAILED - $($_.Exception.Message)" -ForegroundColor Red
        }
        return $false
    }
}

# Main execution
Write-Host ""
Write-Host "🔐 ReportMate Windows Client Setup" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as administrator
if (!(Test-AdminRights)) {
    Write-Log "This script must be run as Administrator to modify registry settings" "ERROR"
    Write-Host ""
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Red
    exit 1
}

# Show current configuration if requested
if ($ShowConfiguration) {
    Show-CurrentConfiguration
    exit 0
}

# Remove passphrase if requested
if ($RemovePassphrase) {
    Write-Log "Removing passphrase configuration..."
    if (Remove-RegistryValue -Path $REGISTRY_PATH -Name $REGISTRY_PASSPHRASE_KEY) {
        Write-Host "✅ Passphrase removed successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Failed to remove passphrase" -ForegroundColor Red
        exit 1
    }
    exit 0
}

# Configure server URL
if ($ServerUrl) {
    Write-Log "Configuring server URL..."
    if (!(Set-RegistryValue -Path $REGISTRY_PATH -Name $REGISTRY_SERVER_KEY -Value $ServerUrl)) {
        Write-Host "❌ Failed to configure server URL" -ForegroundColor Red
        exit 1
    }
}

# Configure passphrase
if ($Passphrase) {
    Write-Log "Configuring client passphrase..."
    if (!(Set-RegistryValue -Path $REGISTRY_PATH -Name $REGISTRY_PASSPHRASE_KEY -Value $Passphrase)) {
        Write-Host "❌ Failed to configure passphrase" -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Passphrase configured successfully" -ForegroundColor Green
} elseif (!$RemovePassphrase -and !$ShowConfiguration) {
    Write-Log "No passphrase provided - authentication will be disabled" "WARNING"
}

Write-Host ""
Write-Log "Configuration complete!"

# Show final configuration
Show-CurrentConfiguration

# Test the configuration
Write-Host ""
Test-Configuration

Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Deploy your osquery or monitoring agent"
Write-Host "  2. Configure the agent to read registry values from:"
Write-Host "     - Server URL: HKLM\SOFTWARE\Policies\ReportMate\ServerUrl"
Write-Host "     - Passphrase: HKLM\SOFTWARE\Policies\ReportMate\Passphrase"
Write-Host "  3. Monitor Azure Application Insights for client authentication"
Write-Host ""
