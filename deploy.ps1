<#
.SYNOPSIS
    Automated Deployment Script for Confidential 1:1 CAD WebXR Viewer
.DESCRIPTION
    Deploys the containerized application to Google Cloud Run (or Firebase Hosting)
    with HTTP Basic Authentication and automatic HTTPS enforcement for Meta Quest Browser.
#>

param(
    [string]$Target = "cloudrun", # 'cloudrun' or 'firebase'
    [string]$Username,
    [string]$Password,
    [string]$Project,
    [string]$Region = "us-central1",
    [string]$ServiceName = "cad-webxr-viewer"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Confidential 1:1 CAD WebXR Viewer - Deployment" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan

# Prompt for credentials if not supplied as parameters
if (-not $Username) {
    $Username = Read-Host "Enter HTTP Basic Auth Username (e.g. admin)"
}
if (-not $Password) {
    $Password = Read-Host "Enter HTTP Basic Auth Password" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
}

if ([string]::IsNullOrWhiteSpace($Username) -or [string]::IsNullOrWhiteSpace($Password)) {
    Write-Error "Username and Password cannot be empty."
    exit 1
}

Write-Host "`n[1/3] Credentials configured for user: $Username" -ForegroundColor Yellow

if ($Target -eq "cloudrun") {
    Write-Host "`n[2/3] Preparing Google Cloud Run Deployment..." -ForegroundColor Cyan

    # Check for gcloud CLI
    $gcloudCmd = Get-Command "gcloud" -ErrorAction SilentlyContinue
    if (-not $gcloudCmd) {
        Write-Warning "Google Cloud SDK (gcloud) is not found in your PATH."
        Write-Host "Please ensure gcloud is installed and authenticated:" -ForegroundColor Yellow
        Write-Host "  1. Install Google Cloud SDK: winget install Google.CloudSDK" -ForegroundColor White
        Write-Host "  2. Authenticate: gcloud auth login" -ForegroundColor White
        Write-Host "  3. Set project:  gcloud config set project <PROJECT_ID>" -ForegroundColor White
        Write-Host "`nAlternative: Test locally right now using ./test_local_server.ps1" -ForegroundColor Green
        exit 1
    }

    # If project not specified, check current gcloud project
    if (-not $Project) {
        $currentProject = (gcloud config get-value project 2>$null).Trim()
        if ($currentProject) {
            $Project = $currentProject
            Write-Host "Using active GCP Project: $Project" -ForegroundColor Gray
        } else {
            $Project = Read-Host "Enter your Google Cloud Project ID"
            gcloud config set project $Project
        }
    }

    Write-Host "`n[3/3] Building container and deploying to Cloud Run..." -ForegroundColor Cyan
    Write-Host "Deploying service '$ServiceName' to region '$Region'..." -ForegroundColor Gray

    $deployArgs = @(
        "run", "deploy", $ServiceName,
        "--source", ".",
        "--platform", "managed",
        "--region", $Region,
        "--allow-unauthenticated",
        "--set-env-vars", "BASIC_AUTH_USER=$Username,BASIC_AUTH_PASS=$Password"
    )

    & gcloud @deployArgs

    if ($LASTEXITCODE -eq 0) {
        $serviceUrl = (gcloud run services describe $ServiceName --platform managed --region $Region --format "value(status.url)" 2>$null).Trim()
        Write-Host "`n========================================================" -ForegroundColor Green
        Write-Host " Deployment Succeeded!" -ForegroundColor Green
        Write-Host "========================================================" -ForegroundColor Green
        Write-Host "Live HTTPS URL: $serviceUrl" -ForegroundColor Cyan
        Write-Host "HTTP Basic Auth:" -ForegroundColor Yellow
        Write-Host "  Username: $Username" -ForegroundColor White
        Write-Host "  Password: [PROTECTED]" -ForegroundColor White
        Write-Host "`nOpen the URL in your Meta Quest Browser (Quest 2/3) to review models in 1:1 scale!" -ForegroundColor Green
    } else {
        Write-Error "Cloud Run deployment failed with exit code $LASTEXITCODE."
    }

} elseif ($Target -eq "firebase") {
    Write-Host "`n[2/3] Preparing Firebase Hosting Deployment..." -ForegroundColor Cyan

    $firebaseCmd = Get-Command "firebase" -ErrorAction SilentlyContinue
    if (-not $firebaseCmd) {
        Write-Warning "Firebase CLI (firebase) is not found in your PATH."
        Write-Host "Please install firebase-tools: npm install -g firebase-tools" -ForegroundColor Yellow
        exit 1
    }

    if ($Project) {
        & firebase use $Project
    }

    Write-Host "`n[3/3] Deploying to Firebase Hosting..." -ForegroundColor Cyan
    & firebase deploy --only hosting

    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nDeployment to Firebase Hosting succeeded!" -ForegroundColor Green
    }
}
