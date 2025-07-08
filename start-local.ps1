# PowerShell Local Server Starter
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "Starting Backend and Frontend servers..." -ForegroundColor Green
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Start Backend Server (PowerShell)
Write-Host "Starting Backend Server..." -ForegroundColor Yellow
$BackendScript = Join-Path $ScriptDir "start-backend.ps1"
if (Test-Path $BackendScript) {
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$BackendScript`"" -WindowStyle Normal
    Write-Host "[SUCCESS] Backend server started in new window" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Backend script not found: $BackendScript" -ForegroundColor Red
}

Start-Sleep -Seconds 2

# Start Frontend Server (PowerShell)
Write-Host "Starting Frontend Server..." -ForegroundColor Yellow
$FrontendScript = Join-Path $ScriptDir "start-frontend.ps1"
if (Test-Path $FrontendScript) {
    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$FrontendScript`"" -WindowStyle Normal
    Write-Host "[SUCCESS] Frontend server started in new window" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Frontend script not found: $FrontendScript" -ForegroundColor Red
}

Write-Host ""
Write-Host "[INFO] Both servers have been started in separate windows." -ForegroundColor Cyan
Write-Host "[INFO] Backend: http://localhost:8080" -ForegroundColor Cyan
Write-Host "[INFO] Frontend: http://localhost:4000" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit" 