Write-Host "🌟 FanxyTV Simple HTTP Deployment Starting..." -ForegroundColor Cyan

# 1. 공인 IP 확인
Write-Host "🌍 Checking public IP..." -ForegroundColor Yellow
$publicIP = (Invoke-RestMethod -Uri "https://api.ipify.org").Trim()
Write-Host "🔍 Current public IP: $publicIP" -ForegroundColor Green

# 2. Docker 상태 확인
Write-Host "🐳 Checking Docker status..." -ForegroundColor Yellow
$dockerStatus = docker info 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Docker is running" -ForegroundColor Green
} else {
    Write-Host "❌ Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# 3. 기존 컨테이너 정리
Write-Host "🧹 Cleaning up existing containers..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml down 2>$null

# 4. 필요한 디렉토리 생성
Write-Host "📁 Creating directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path ".\logs" | Out-Null

# 5. 프론트엔드와 백엔드만 직접 실행
Write-Host "🚀 Starting frontend and backend services only..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml up -d frontend backend

# 6. 서비스 상태 확인
Write-Host "🔍 Checking service status..." -ForegroundColor Yellow
Start-Sleep -Seconds 5
docker-compose -f docker-compose.prod.yml ps

# 7. 프론트엔드 로그 확인
Write-Host "📋 Checking frontend logs..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml logs frontend | Select-Object -Last 5

# 8. 백엔드 로그 확인
Write-Host "🔍 Checking backend logs..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml logs backend | Select-Object -Last 5

# 9. 포트 사용 상황 확인
Write-Host "🔌 Checking port usage..." -ForegroundColor Yellow
$port3000 = netstat -an | Select-String ":3000 " | Select-Object -First 1
$port8000 = netstat -an | Select-String ":8000 " | Select-Object -First 1

if ($port3000) {
    Write-Host "✅ Port 3000 (Frontend) is in use" -ForegroundColor Green
} else {
    Write-Host "⚠️ Port 3000 (Frontend) is not in use." -ForegroundColor Yellow
}

if ($port8000) {
    Write-Host "✅ Port 8000 (Backend) is in use" -ForegroundColor Green
} else {
    Write-Host "⚠️ Port 8000 (Backend) is not in use." -ForegroundColor Yellow
}

# 10. 방화벽 규칙 확인
Write-Host "🔥 Checking firewall rules..." -ForegroundColor Yellow
netsh advfirewall firewall add rule name="Frontend" dir=in action=allow protocol=TCP localport=3000 2>$null
netsh advfirewall firewall add rule name="Backend" dir=in action=allow protocol=TCP localport=8000 2>$null
Write-Host "✅ Frontend firewall rule added (Port 3000)" -ForegroundColor Green
Write-Host "✅ Backend firewall rule added (Port 8000)" -ForegroundColor Green

Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host "🎉 Simple HTTP Deployment Complete!" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Magenta

Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1️⃣ DNS Settings:" -ForegroundColor Cyan
Write-Host "   - A Record: fanxytv.com → $publicIP" -ForegroundColor White
Write-Host "   - A Record: www.fanxytv.com → $publicIP" -ForegroundColor White
Write-Host ""
Write-Host "2️⃣ Router Port Forwarding:" -ForegroundColor Cyan
Write-Host "   - Port 3000: External → Internal PC IP:3000 (Frontend)" -ForegroundColor White
Write-Host "   - Port 8000: External → Internal PC IP:8000 (Backend)" -ForegroundColor White
Write-Host ""
Write-Host "3️⃣ Direct Testing:" -ForegroundColor Cyan
Write-Host "   - Frontend: http://fanxytv.com:3000" -ForegroundColor White
Write-Host "   - Backend API: http://fanxytv.com:8000/api" -ForegroundColor White
Write-Host ""
$internalIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"} | Select-Object -First 1).IPAddress
Write-Host "🖥️ Internal IP: $internalIP" -ForegroundColor Cyan
Write-Host "🌍 Public IP: $publicIP" -ForegroundColor Cyan
Write-Host ""
Write-Host "🛠️ Useful commands:" -ForegroundColor Yellow
Write-Host "   - Stop services: docker-compose -f docker-compose.prod.yml down" -ForegroundColor White
Write-Host "   - Start services: docker-compose -f docker-compose.prod.yml up -d frontend backend" -ForegroundColor White
Write-Host "   - Check logs: docker-compose -f docker-compose.prod.yml logs -f" -ForegroundColor White
Write-Host ""
Write-Host "🌐 Simple deployment ready!" -ForegroundColor Green
Write-Host "🔓 No SSL, No nginx - Direct connection" -ForegroundColor Yellow

Write-Host ""
Write-Host "✅ Simple HTTP deployment completed!" -ForegroundColor Green
Write-Host "🔄 Test directly: http://fanxytv.com:3000" -ForegroundColor Cyan 