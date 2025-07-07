# SSL 인증서 생성 스크립트
Write-Host "🔒 SSL Certificate Generation Starting..." -ForegroundColor Cyan

# 1. 현재 서비스 상태 확인
Write-Host "📋 Checking current service status..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml ps

# 2. certbot 컨테이너로 SSL 인증서 생성
Write-Host "🔐 Generating SSL certificates..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml exec certbot certbot certonly --webroot --webroot-path=/var/www/certbot --email admin@fanxytv.com --agree-tos --no-eff-email -d fanxytv.com -d www.fanxytv.com

# 3. 생성된 인증서 확인
Write-Host "🔍 Checking generated certificates..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml exec nginx ls -la /etc/letsencrypt/live/fanxytv.com/

# 4. nginx 재시작
Write-Host "🔄 Restarting nginx..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml restart nginx

# 5. 최종 상태 확인
Write-Host "📊 Final service status..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml ps

# 6. nginx 로그 확인
Write-Host "📋 Checking nginx logs..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml logs nginx --tail=10

Write-Host "✅ SSL Certificate generation completed!" -ForegroundColor Green
Write-Host "🌐 Test your domain: https://fanxytv.com" -ForegroundColor Cyan 