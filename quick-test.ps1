Write-Host "🔥 Quick Test Script" -ForegroundColor Red

# Docker 상태 확인
Write-Host "🐳 Checking Docker..." -ForegroundColor Yellow
docker info 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Docker is not running! Start Docker Desktop first!" -ForegroundColor Red
    exit 1
}

# 기존 컨테이너 정리
Write-Host "🧹 Cleaning up..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml down

# 프론트엔드만 시작 (포트 3000)
Write-Host "🚀 Starting frontend only..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml up -d frontend

# 5초 대기
Start-Sleep -Seconds 5

# 상태 확인
Write-Host "📊 Status:" -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml ps

# 포트 확인
Write-Host "🔌 Port check:" -ForegroundColor Yellow
netstat -an | Select-String ":3000"

Write-Host ""
Write-Host "✅ Test completed!" -ForegroundColor Green
Write-Host "🌐 Try: http://localhost:3000" -ForegroundColor Cyan
Write-Host "🌐 Try: http://211.243.245.42:3000" -ForegroundColor Cyan 