param(
    [string]$Username = "admin",
    [string]$Password = "CadVR2026!",
    [int]$Port = 8080
)

$publicDir = Join-Path $PSScriptRoot "public"
$cloudflared = Join-Path $PSScriptRoot "cloudflared.exe"

# Start local server job
$serverScript = Join-Path $PSScriptRoot "test_local_server.ps1"
$job = Start-Job -ScriptBlock {
    param($s, $u, $p, $port)
    & powershell -ExecutionPolicy Bypass -File $s -Username $u -Password $p -Port $port
} -ArgumentList $serverScript, $Username, $Password, $Port

Start-Sleep -Seconds 2

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Running CAD WebXR Viewer + Cloudflare Tunnel Daemon" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "Local: http://localhost:$Port (User: $Username)" -ForegroundColor Yellow

# Launch cloudflared directly with http2 protocol for enterprise proxy / firewall compatibility
& $cloudflared tunnel --protocol http2 --url "http://localhost:$Port"
