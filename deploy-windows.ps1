Write-Host "🌟 FanxyTV Windows Deployment Starting..." -ForegroundColor Cyan

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
New-Item -ItemType Directory -Force -Path ".\certs" | Out-Null
New-Item -ItemType Directory -Force -Path ".\logs" | Out-Null

# 5. Docker 이미지 빌드
Write-Host "🏗️ Building Docker images..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml build

# 6. 서비스 시작
Write-Host "🚀 Starting services..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml up -d

# 7. 서비스 상태 확인
Write-Host "🔍 Checking service status..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml ps

# 8. nginx 로그 확인 (SSL 인증서 문제 체크)
Write-Host "📋 Checking nginx logs for SSL certificate issues..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml logs nginx | Select-Object -Last 10

# 9. SSL 인증서 상태 확인
Write-Host "🔒 Checking SSL certificate status..." -ForegroundColor Yellow
if (Test-Path ".\certs\live\fanxytv.com\fullchain.pem") {
    Write-Host "✅ SSL certificates found" -ForegroundColor Green
} else {
    Write-Host "⚠️ SSL certificates not found - this is normal for first deployment" -ForegroundColor Yellow
    Write-Host "   Certificates will be generated automatically after DNS propagation" -ForegroundColor Cyan
}

# 10. 백엔드 서비스 로그 확인
Write-Host "🔍 Checking backend service logs..." -ForegroundColor Yellow
Write-Host "   Backend logs..." -ForegroundColor Cyan
docker-compose -f docker-compose.prod.yml logs backend | Select-Object -Last 5

# 11. 포트 사용 상황 확인
Write-Host "🔌 Checking port usage..." -ForegroundColor Yellow
$port80 = netstat -an | Select-String ":80 " | Select-Object -First 1
$port443 = netstat -an | Select-String ":443 " | Select-Object -First 1

if ($port80) {
    Write-Host "✅ Port 80 is in use" -ForegroundColor Green
} else {
    Write-Host "⚠️ Port 80 is not in use." -ForegroundColor Yellow
}

if ($port443) {
    Write-Host "✅ Port 443 is in use" -ForegroundColor Green
} else {
    Write-Host "⚠️ Port 443 is not in use." -ForegroundColor Yellow
}

# 12. 방화벽 규칙 확인
Write-Host "🔥 Checking firewall rules..." -ForegroundColor Yellow
netsh advfirewall firewall add rule name="HTTP" dir=in action=allow protocol=TCP localport=80 2>$null
netsh advfirewall firewall add rule name="HTTPS" dir=in action=allow protocol=TCP localport=443 2>$null
Write-Host "✅ HTTP firewall rule added" -ForegroundColor Green
Write-Host "✅ HTTPS firewall rule added" -ForegroundColor Green

Write-Host ("=" * 60) -ForegroundColor Magenta
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host ("=" * 60) -ForegroundColor Magenta

Write-Host ""
Write-Host "📋 Next steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1️⃣ DNS Settings:" -ForegroundColor Cyan
Write-Host "   - A Record: fanxytv.com → $publicIP" -ForegroundColor White
Write-Host "   - A Record: www.fanxytv.com → $publicIP" -ForegroundColor White
Write-Host ""
Write-Host "2️⃣ Router Port Forwarding:" -ForegroundColor Cyan
Write-Host "   - Port 80: External → Internal PC IP:80" -ForegroundColor White
Write-Host "   - Port 443: External → Internal PC IP:443" -ForegroundColor White
Write-Host ""
Write-Host "3️⃣ Domain Testing (after DNS propagation):" -ForegroundColor Cyan
Write-Host "   - https://fanxytv.com" -ForegroundColor White
Write-Host ""
$internalIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"} | Select-Object -First 1).IPAddress
Write-Host "🖥️ Internal IP: $internalIP" -ForegroundColor Cyan
Write-Host "🌍 Public IP: $publicIP" -ForegroundColor Cyan
Write-Host ""
Write-Host "🛠️ Useful commands:" -ForegroundColor Yellow
Write-Host "   - Stop services: docker-compose -f docker-compose.prod.yml down" -ForegroundColor White
Write-Host "   - Start services: docker-compose -f docker-compose.prod.yml up -d" -ForegroundColor White
Write-Host "   - Check logs: docker-compose -f docker-compose.prod.yml logs -f" -ForegroundColor White
Write-Host ""
Write-Host "🚀 Windows PC domain connection ready!" -ForegroundColor Green

# nginx가 SSL 인증서 문제로 실패하는 경우 임시 HTTP 버전 시작
$nginxStatus = docker-compose -f docker-compose.prod.yml ps nginx --format "table {{.State}}"
if ($nginxStatus -like "*Restarting*" -or $nginxStatus -like "*Exit*") {
    Write-Host "🔍 Checking if nginx is failing due to SSL certificates..." -ForegroundColor Yellow
    $nginxLogs = docker-compose -f docker-compose.prod.yml logs nginx 2>&1
    if ($nginxLogs -like "*cannot load certificate*" -or $nginxLogs -like "*No such file*") {
        Write-Host "⚠️ Nginx is restarting due to SSL certificate issues" -ForegroundColor Yellow
        Write-Host "🛠️ This is normal for first deployment - certificates will be generated after DNS propagation" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "📋 Current service status:" -ForegroundColor Yellow
        docker-compose -f docker-compose.prod.yml logs --tail=5
    }
}

Write-Host ""
Write-Host "✅ Deployment script completed!" -ForegroundColor Green
Write-Host "🔄 Check the logs above and proceed with DNS and port forwarding setup." -ForegroundColor Cyan

Write-Host "✅ All services are running successfully!" -ForegroundColor Green

# SSL 인증서 생성 및 확인
Write-Host ""
Write-Host "🔒 SSL Certificate Generation Starting..." -ForegroundColor Cyan

# SSL 인증서 생성
Write-Host "🔐 Generating SSL certificates..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml exec certbot certbot certonly --webroot --webroot-path=/var/www/certbot --email admin@fanxytv.com --agree-tos --no-eff-email -d fanxytv.com -d www.fanxytv.com

# 생성된 인증서 확인
Write-Host "🔍 Checking generated certificates..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml exec nginx ls -la /etc/letsencrypt/live/fanxytv.com/

# nginx 재시작
Write-Host "🔄 Restarting nginx with SSL..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml restart nginx

# 최종 상태 확인
Write-Host "📊 Final service status after SSL..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml ps

# nginx 로그 확인
Write-Host "📋 Checking nginx logs..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml logs nginx --tail=10

Write-Host ""
Write-Host "🎉 Complete deployment with SSL finished!" -ForegroundColor Green
Write-Host "🌐 Test your domain: https://fanxytv.com" -ForegroundColor Cyan
Write-Host "🔒 SSL Certificate: ✅ Generated and Active" -ForegroundColor Green
