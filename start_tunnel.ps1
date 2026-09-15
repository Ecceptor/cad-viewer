param(
    [string]$Username = "admin",
    [string]$Password = "CadVR2026!",
    [int]$Port = 8080
)

$ErrorActionPreference = "Stop"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Starting Confidential CAD WebXR Viewer + Cloudflare Tunnel" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan

# 1. Start the local server in a separate background job
$serverScript = Join-Path $PSScriptRoot "test_local_server.ps1"
$serverJob = Start-Job -ScriptBlock {
    param($script, $u, $p, $port)
    & powershell -ExecutionPolicy Bypass -File $script -Username $u -Password $p -Port $port
} -ArgumentList $serverScript, $Username, $Password, $Port

Start-Sleep -Seconds 2

# Verify local server is listening
try {
    $test = Invoke-WebRequest -Uri "http://localhost:$Port/healthz" -UseBasicParsing -TimeoutSec 3
    Write-Host "[Local Server] Active on http://localhost:$Port" -ForegroundColor Green
} catch {
    Write-Warning "Local server check failed: $_"
}

# 2. Check for cloudflared executable
$cloudflared = Join-Path $PSScriptRoot "cloudflared.exe"
if (-not (Test-Path $cloudflared)) {
    Write-Error "cloudflared.exe not found at $cloudflared. Run download first."
    exit 1
}

Write-Host "[Cloudflare] Establishing secure HTTPS tunnel..." -ForegroundColor Cyan

# Start cloudflared and capture tunnel URL
$logFile = Join-Path $PSScriptRoot "tunnel.log"
if (Test-Path $logFile) { Remove-Item $logFile -Force }

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $cloudflared
$psi.Arguments = "tunnel --url http://localhost:$Port"
$psi.RedirectStandardError = $true
$psi.RedirectStandardOutput = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$proc = [System.Diagnostics.Process]::Start($psi)

$tunnelUrl = $null
$timeout = [DateTime]::Now.AddSeconds(20)

while ([DateTime]::Now -lt $timeout -and -not $tunnelUrl) {
    Start-Sleep -Milliseconds 500
    if (-not $proc.StandardError.EndOfStream) {
        $line = $proc.StandardError.ReadLine()
        Add-Content -Path $logFile -Value $line
        if ($line -match "(https://[a-zA-Z0-9-]+\.trycloudflare\.com)") {
            $tunnelUrl = $matches[1]
            break
        }
    }
}

if ($tunnelUrl) {
    Write-Host "`n========================================================" -ForegroundColor Green
    Write-Host " Secure Cloudflare Tunnel is LIVE!" -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host "Public HTTPS URL:   $tunnelUrl" -ForegroundColor Cyan
    Write-Host "HTTP Basic Auth:" -ForegroundColor Yellow
    Write-Host "  Username:         $Username" -ForegroundColor White
    Write-Host "  Password:         $Password" -ForegroundColor White
    Write-Host "`nOpen this URL in Meta Quest Browser on Quest 2/3." -ForegroundColor Green
    Write-Host "WebXR Device API is strictly active over HTTPS." -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Cyan
} else {
    Write-Error "Could not retrieve Cloudflare Tunnel URL within 20 seconds. Check $logFile."
}
