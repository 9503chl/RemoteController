# HTTP 전용 임시 실행 스크립트
Write-Host "🌐 Starting HTTP-only version..." -ForegroundColor Cyan

# 1. 현재 서비스 중지
Write-Host "⏹️ Stopping current services..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml down

# 2. 기존 nginx 설정 백업
Write-Host "💾 Backing up nginx config..." -ForegroundColor Yellow
if (Test-Path "nginx.conf") {
    Copy-Item "nginx.conf" "nginx.conf.backup"
    Write-Host "✅ Backup created: nginx.conf.backup" -ForegroundColor Green
}

# 3. HTTP 전용 설정으로 교체
Write-Host "🔄 Switching to HTTP-only config..." -ForegroundColor Yellow
Copy-Item "nginx-http-only.conf" "nginx.conf"

# 4. 서비스 재시작
Write-Host "🚀 Starting services with HTTP-only..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml up -d

# 5. 상태 확인
Write-Host "📊 Service status..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
docker-compose -f docker-compose.prod.yml ps

# 6. 로그 확인
Write-Host "📋 Checking logs..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml logs nginx --tail=10

Write-Host ""
Write-Host "✅ HTTP-only version started!" -ForegroundColor Green
Write-Host "🌐 Test now: http://fanxytv.com" -ForegroundColor Cyan
Write-Host ""
Write-Host "⚠️  To restore SSL version later, run:" -ForegroundColor Yellow
Write-Host "   Copy-Item 'nginx.conf.backup' 'nginx.conf'" -ForegroundColor White
Write-Host "   docker-compose -f docker-compose.prod.yml restart nginx" -ForegroundColor White 