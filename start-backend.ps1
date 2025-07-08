# PowerShell Backend Starter Script
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "[INFO] Starting backend server..." -ForegroundColor Green
Write-Host ""

# Set paths
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$VenvDir = Join-Path $ScriptDir "venv_py311"
$PythonExe = Join-Path $VenvDir "Scripts\python.exe"
$RequirementsPath = Join-Path $ScriptDir "remote-controller-app\Deep-Live-Cam-main\requirements.txt"
$BackendDir = Join-Path $ScriptDir "remote-controller-app\Deep-Live-Cam-main"

Write-Host "[DEBUG] Script directory: $ScriptDir" -ForegroundColor Cyan
Write-Host "[DEBUG] Virtual env directory: $VenvDir" -ForegroundColor Cyan
Write-Host "[DEBUG] Requirements path: $RequirementsPath" -ForegroundColor Cyan
Write-Host ""

# Find Python 3.11
Write-Host "[INFO] Searching for Python 3.11..." -ForegroundColor Yellow
$Python311Path = $null

# Search in common locations
$SearchPaths = @(
    "C:\Users\*\AppData\Local\Programs\Python\Python311\python.exe",
    "C:\Python311\python.exe",
    "C:\Program Files\Python311\python.exe",
    "C:\Program Files (x86)\Python311\python.exe"
)

foreach ($Path in $SearchPaths) {
    $PythonExes = Get-ChildItem $Path -ErrorAction SilentlyContinue
    foreach ($PythonExe in $PythonExes) {
        try {
            $Version = & $PythonExe.FullName --version 2>$null
            if ($Version -match "Python 3\.11") {
                $Python311Path = $PythonExe.FullName
                Write-Host "[SUCCESS] Found Python 3.11 at: $Python311Path" -ForegroundColor Green
                break
            }
        } catch {
            continue
        }
    }
    if ($Python311Path) { break }
}

if (-not $Python311Path) {
    Write-Host "[ERROR] Python 3.11 not found. Please install Python 3.11." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Remove old virtual environment
if (Test-Path $VenvDir) {
    Write-Host "[INFO] Removing old virtual environment..." -ForegroundColor Yellow
    Remove-Item $VenvDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Create virtual environment
Write-Host "[INFO] Creating virtual environment..." -ForegroundColor Yellow
try {
    & $Python311Path -m venv $VenvDir
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create virtual environment"
    }
} catch {
    Write-Host "[ERROR] Failed to create virtual environment: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Update Python executable path
$PythonExe = Join-Path $VenvDir "Scripts\python.exe"

# Upgrade pip
Write-Host "[INFO] Upgrading pip..." -ForegroundColor Yellow
try {
    & $PythonExe -m pip install --upgrade pip
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to upgrade pip"
    }
} catch {
    Write-Host "[ERROR] Failed to upgrade pip: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Install dependencies
Write-Host "[INFO] Installing dependencies..." -ForegroundColor Yellow
try {
    & $PythonExe -m pip install -r $RequirementsPath
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install dependencies"
    }
} catch {
    Write-Host "[ERROR] Failed to install dependencies: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "[SUCCESS] All dependencies installed successfully!" -ForegroundColor Green
Write-Host ""

# Start server
Write-Host "[SUCCESS] Starting Python server on port 8080..." -ForegroundColor Green
try {
    Set-Location $BackendDir
    & $PythonExe api_server.py
} catch {
    Write-Host "[ERROR] Server crashed: $_" -ForegroundColor Red
} finally {
    Write-Host ""
    Write-Host "[INFO] Server stopped." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
} 