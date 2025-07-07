Write-Host "🚀 Simple Start - No Testing" -ForegroundColor Green

# 기존 컨테이너 정리
docker-compose -f docker-compose.prod.yml down

# 서비스 시작
docker-compose -f docker-compose.prod.yml up -d frontend backend

# 상태만 확인
docker-compose -f docker-compose.prod.yml ps

Write-Host ""
Write-Host "✅ Services started!" -ForegroundColor Green
Write-Host "🌐 Frontend: http://fanxytv.com:4000" -ForegroundColor Cyan
Write-Host "🌐 Backend: http://fanxytv.com:8080/api" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔧 Port Forwarding Settings:" -ForegroundColor Yellow
Write-Host "   Port 4000 → 192.168.2.111:4000" -ForegroundColor White
Write-Host "   Port 8080 → 192.168.2.111:8080" -ForegroundColor White
Write-Host ""
Write-Host "⚠️ Check your router port forwarding!" -ForegroundColor Red 