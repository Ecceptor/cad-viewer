param(
    [string]$Username = "admin",
    [string]$Password = "CadVR2026!",
    [int]$Port = 8080
)

$publicDir = Join-Path $PSScriptRoot "public"
if (-not (Test-Path $publicDir)) {
    Write-Error "public directory not found: $publicDir"
    exit 1
}

$listener = New-Object System.Net.HttpListener
$prefix = "http://*:$Port/"
$listener.Prefixes.Add($prefix)

try {
    $listener.Start()
} catch {
    # Fallback to localhost if wild-card requires administrator permissions
    $listener = New-Object System.Net.HttpListener
    $prefix = "http://localhost:$Port/"
    $listener.Prefixes.Add($prefix)
    $listener.Start()
}

Write-Host "========================================================" -ForegroundColor Cyan
Write-Host " Confidential 1:1 CAD WebXR Local Preview Server" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "URL:          http://localhost:$Port" -ForegroundColor Yellow
Write-Host "Basic Auth:   User='$Username' | Password='$Password'" -ForegroundColor Yellow
Write-Host "Serving from: $publicDir" -ForegroundColor Gray
Write-Host "Press Ctrl+C to stop the server." -ForegroundColor Gray
Write-Host "--------------------------------------------------------"

$expectedAuth = "Basic " + [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes("$Username`:$Password"))

$mimeTypes = @{
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".mjs"  = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
    ".glb"  = "model/gltf-binary"
    ".gltf" = "model/gltf+json"
    ".png"  = "image/png"
    ".jpg"  = "image/jpeg"
    ".svg"  = "image/svg+xml"
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        # Security & CORS Headers
        $response.AddHeader("X-Content-Type-Options", "nosniff")
        $response.AddHeader("X-Frame-Options", "SAMEORIGIN")
        $response.AddHeader("Access-Control-Allow-Origin", "*")

        # Health check bypass
        if ($request.Url.LocalPath -eq "/healthz") {
            $buf = [Text.Encoding]::UTF8.GetBytes("OK")
            $response.ContentType = "text/plain"
            $response.OutputStream.Write($buf, 0, $buf.Length)
            $response.Close()
            continue
        }

        # Check HTTP Basic Authentication
        $authHeader = $request.Headers["Authorization"]
        if (-not $authHeader -or $authHeader -ne $expectedAuth) {
            $response.StatusCode = 401
            $response.AddHeader("WWW-Authenticate", 'Basic realm="Confidential CAD VR Review"')
            $unauthBody = [Text.Encoding]::UTF8.GetBytes("401 Unauthorized: Access Denied")
            $response.OutputStream.Write($unauthBody, 0, $unauthBody.Length)
            $response.Close()
            Write-Host "[$([DateTime]::Now.ToString('HH:mm:ss'))] 401 Unauthorized from $($request.RemoteEndPoint)" -ForegroundColor Red
            continue
        }

        # Resolve requested file path
        $relPath = $request.Url.LocalPath.TrimStart('/')
        if ([string]::IsNullOrEmpty($relPath) -or $relPath -eq "/") {
            $relPath = "index.html"
        }
        $filePath = Join-Path $publicDir $relPath

        if (Test-Path $filePath -PathType Leaf) {
            $ext = [IO.Path]::GetExtension($filePath).ToLower()
            $contentType = if ($mimeTypes.ContainsKey($ext)) { $mimeTypes[$ext] } else { "application/octet-stream" }
            $response.ContentType = $contentType
            $bytes = [IO.File]::ReadAllBytes($filePath)
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
            $response.StatusCode = 200
            Write-Host "[$([DateTime]::Now.ToString('HH:mm:ss'))] 200 OK: $relPath ($($bytes.Length) bytes)" -ForegroundColor Green
        } else {
            $response.StatusCode = 404
            $notFound = [Text.Encoding]::UTF8.GetBytes("404 Not Found")
            $response.OutputStream.Write($notFound, 0, $notFound.Length)
            Write-Host "[$([DateTime]::Now.ToString('HH:mm:ss'))] 404 Not Found: $relPath" -ForegroundColor Yellow
        }

        $response.Close()
    } catch {
        if (-not $listener.IsListening) { break }
        Write-Warning $_.Exception.Message
    }
}
