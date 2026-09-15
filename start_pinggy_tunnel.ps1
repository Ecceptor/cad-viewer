param(
    [string]$Username = "admin",
    [string]$Password = "CadVR2026!",
    [int]$Port = 8080
)

$serverScript = Join-Path $PSScriptRoot "test_local_server.ps1"
$job = Start-Job -ScriptBlock {
    param($s, $u, $p, $port)
    & powershell -ExecutionPolicy Bypass -File $s -Username $u -Password $p -Port $port
} -ArgumentList $serverScript, $Username, $Password, $Port

Start-Sleep -Seconds 2

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Starting Port-443 HTTPS Tunnel (Pinggy via OpenSSH)" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Local Basic Auth: $Username / $Password" -ForegroundColor Yellow
Write-Host "Bypasses outbound port blocks (uses standard HTTPS port 443)" -ForegroundColor Gray
Write-Host "--------------------------------------------------------"

# Run OpenSSH reverse tunnel over port 443
ssh -o StrictHostKeyChecking=no -p 443 -R0:localhost:$Port a.pinggy.io
