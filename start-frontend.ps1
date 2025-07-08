# PowerShell Frontend Starter Script
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "[Frontend] Starting Next.js development server..." -ForegroundColor Green
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$FrontendDir = Join-Path $ScriptDir "remote-controller-app"

# Navigate to frontend directory
Write-Host "[Frontend] Navigating to frontend directory..." -ForegroundColor Yellow
if (-not (Test-Path $FrontendDir)) {
    Write-Host "[ERROR] Frontend directory not found: $FrontendDir" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Set-Location $FrontendDir

# Check for node_modules
Write-Host "[Frontend] Checking for node_modules..." -ForegroundColor Yellow
if (-not (Test-Path "node_modules")) {
    Write-Host "[Frontend] node_modules not found. Installing dependencies..." -ForegroundColor Yellow
    try {
        npm install
        if ($LASTEXITCODE -ne 0) {
            throw "npm install failed"
        }
        Write-Host "[SUCCESS] npm dependencies installed successfully!" -ForegroundColor Green
    } catch {
        Write-Host "[ERROR] Failed to install npm dependencies: $_" -ForegroundColor Red
        Set-Location $ScriptDir
        Read-Host "Press Enter to exit"
        exit 1
    }
} else {
    Write-Host "[INFO] node_modules found. Skipping npm install." -ForegroundColor Cyan
}

# Start Next.js development server
Write-Host "[Frontend] Starting Next.js development server on port 4000..." -ForegroundColor Green
try {
    # Use environment variable to set port
    $env:PORT = "4000"
    npm run dev
} catch {
    Write-Host "[ERROR] Frontend server crashed: $_" -ForegroundColor Red
} finally {
    Set-Location $ScriptDir
    Write-Host ""
    Write-Host "[Frontend] Server stopped." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
} 