param(
    [string]$Token,
    [string]$Message = "Add Environment Lighting selector (HDR/EXR) with PMREM pre-filtering and 360 background toggle",
    [string]$RepoUrl = "https://github.com/Ecceptor/cad-viewer.git"
)

$git = "C:\Users\70N4051\AppData\Local\GitHubDesktop\app-3.6.3\resources\app\git\cmd\git.exe"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Push 1:1 CAD WebXR Viewer to GitHub Pages" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan

# 1. Automatically stage all files
Write-Host "[1/3] Staging project files..." -ForegroundColor Yellow
& $git add -A

# 2. Check if there are changes to commit
$status = (& $git status --porcelain)
if ($status) {
    Write-Host "[2/3] Committing changes: '$Message'..." -ForegroundColor Yellow
    & $git -c user.name="Ecceptor" -c user.email="cad@local.review" commit -m $Message
} else {
    Write-Host "[2/3] Working directory clean. Proceeding to push..." -ForegroundColor Gray
}

# 3. Push to GitHub
Write-Host "[3/3] Pushing to GitHub repository..." -ForegroundColor Yellow
if ($Token) {
    $authUrl = $RepoUrl -replace "https://", "https://$($Token)@"
    Write-Host "Using provided Personal Access Token..." -ForegroundColor Gray
    & $git push -u $authUrl main
} else {
    & $git push -u origin main
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n========================================================" -ForegroundColor Green
    Write-Host " Successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host "Repository:    https://github.com/Ecceptor/cad-viewer" -ForegroundColor Cyan
    Write-Host "GitHub Pages:  https://ecceptor.github.io/cad-viewer/" -ForegroundColor Cyan
    Write-Host "`nYour viewer will automatically update at:" -ForegroundColor Yellow
    Write-Host "  https://ecceptor.github.io/cad-viewer/" -ForegroundColor Green
    Write-Host "Open this URL in your Meta Quest Browser (Quest 2/3)!" -ForegroundColor Green
} else {
    Write-Warning "Push failed or requires authorization."
    Write-Host "You can also push directly using GitHub Desktop by clicking 'Push origin'." -ForegroundColor Yellow
}
