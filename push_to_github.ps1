param(
    [string]$Token,
    [string]$RepoUrl = "https://github.com/Ecceptor/cad-viewer.git"
)

$git = "C:\Users\70N4051\AppData\Local\GitHubDesktop\app-3.6.3\resources\app\git\cmd\git.exe"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Push 1:1 CAD WebXR Viewer to GitHub Pages" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan

if ($Token) {
    # If token is provided, push using token in URL
    $authUrl = $RepoUrl -replace "https://", "https://$($Token)@"
    Write-Host "Pushing with provided Personal Access Token to $RepoUrl..." -ForegroundColor Yellow
    & $git push -u $authUrl main
} else {
    Write-Host "Pushing using Git Credential Manager / GitHub Desktop credentials..." -ForegroundColor Yellow
    Write-Host "If prompted, please authorize in your browser or popup window." -ForegroundColor Gray
    & $git push -u origin main
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n========================================================" -ForegroundColor Green
    Write-Host " Successfully pushed to GitHub!" -ForegroundColor Green
    Write-Host "========================================================" -ForegroundColor Green
    Write-Host "Repository:    https://github.com/Ecceptor/cad-viewer" -ForegroundColor Cyan
    Write-Host "GitHub Pages:  https://ecceptor.github.io/cad-viewer/" -ForegroundColor Cyan
    Write-Host "`nNext Step in GitHub (if not already enabled):" -ForegroundColor Yellow
    Write-Host "  1. Go to https://github.com/Ecceptor/cad-viewer/settings/pages" -ForegroundColor White
    Write-Host "  2. Under 'Build and deployment > Source', choose:" -ForegroundColor White
    Write-Host "     - 'GitHub Actions' (Workflow will automatically deploy), OR" -ForegroundColor White
    Write-Host "     - 'Deploy from a branch' -> branch: main -> folder: / (root) -> Save" -ForegroundColor White
    Write-Host "`nYour viewer will be live at: https://ecceptor.github.io/cad-viewer/" -ForegroundColor Green
    Write-Host "Open that link directly in your Meta Quest Browser!" -ForegroundColor Green
}
