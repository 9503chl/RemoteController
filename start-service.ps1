Write-Host "🚀 FanxyTV Remote Controller - Service Start" -ForegroundColor Green
Write-Host "포트 4000 (Frontend), 8080 (Backend)" -ForegroundColor Cyan
Write-Host ""

# 기존 서비스 정리
Write-Host "📋 기존 서비스 정리 중..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml down

# 서비스 시작
Write-Host "🔄 서비스 시작 중..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml up -d

# 서비스 상태 확인
Write-Host ""
Write-Host "📊 서비스 상태:" -ForegroundColor Green
docker-compose -f docker-compose.prod.yml ps

Write-Host ""
Write-Host "✅ 서비스 시작 완료!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 접속 주소:" -ForegroundColor Cyan
Write-Host "   로컬: http://localhost:4000" -ForegroundColor White
Write-Host "   외부: http://fanxytv.com:4000" -ForegroundColor White
Write-Host ""
Write-Host "🔑 PIN 번호: 1234" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔧 포트 포워딩 설정이 필요한 경우:" -ForegroundColor Red
Write-Host "   포트 4000 → 192.168.2.111:4000" -ForegroundColor White
Write-Host "   포트 8080 → 192.168.2.111:8080" -ForegroundColor White 