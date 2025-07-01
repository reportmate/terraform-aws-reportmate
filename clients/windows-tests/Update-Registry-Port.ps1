# Update ReportMate registry to use port 3003
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\ReportMate" -Name "ServerUrl" -Value "http://localhost:3003" -Force
Write-Host "Updated ServerUrl to http://localhost:3003"
Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\ReportMate"
