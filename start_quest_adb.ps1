# One-click ADB Reverse port forwarding for Meta Quest Browser
$adbPath = "C:\Program Files\Meta Quest Developer Hub\resources\bin\adb.exe"

if (-not (Test-Path $adbPath)) {
    Write-Error "adb.exe not found at $adbPath"
    exit 1
}

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Meta Quest Direct USB/Wi-Fi Port Forwarding" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan

Write-Host "Checking connected Quest headsets..." -ForegroundColor Yellow
& $adbPath devices

Write-Host "`nSetting up reverse port forwarding (tcp:8080 -> tcp:8080)..." -ForegroundColor Cyan
& $adbPath reverse tcp:8080 tcp:8080

Write-Host "`n========================================================" -ForegroundColor Green
Write-Host " Ready! In your Meta Quest Browser, navigate to:" -ForegroundColor Green
Write-Host "   http://localhost:8080" -ForegroundColor Yellow
Write-Host " WebXR is automatically enabled (localhost is secure context)." -ForegroundColor Gray
Write-Host "========================================================" -ForegroundColor Cyan

# Start the local server
& powershell -ExecutionPolicy Bypass -File .\test_local_server.ps1 -Username admin -Password CadVR2026! -Port 8080
