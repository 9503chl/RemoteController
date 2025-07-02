Write-Host "🚀 FanxyTV Windows 배포 시작..." -ForegroundColor Green

# 현재 공인 IP 확인
Write-Host "🌐 공인 IP 확인 중..." -ForegroundColor Yellow
try {
    $publicIP = Invoke-RestMethod -Uri "https://ipinfo.io/ip" -TimeoutSec 10
    Write-Host "📍 현재 공인 IP: $publicIP" -ForegroundColor Cyan
} catch {
    Write-Host "⚠️ 공인 IP 확인 실패. 수동으로 확인하세요: https://whatismyipaddress.com/" -ForegroundColor Red
    $publicIP = "IP_확인_필요"
}

# Docker 상태 확인
Write-Host "🐳 Docker 상태 확인 중..." -ForegroundColor Yellow
try {
    docker version | Out-Null
    Write-Host "✅ Docker 정상 작동" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker가 실행되지 않습니다. Docker Desktop을 시작하세요." -ForegroundColor Red
    exit 1
}

# 기존 컨테이너 정리
Write-Host "📦 기존 컨테이너 정리 중..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml down

# 필요한 디렉토리 생성
Write-Host "📁 디렉토리 생성 중..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "certbot\conf" | Out-Null
New-Item -ItemType Directory -Force -Path "certbot\www" | Out-Null

# 이미지 빌드
Write-Host "🔨 Docker 이미지 빌드 중..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml build

# 서비스 시작
Write-Host "▶️ 서비스 시작 중..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml up -d

# 서비스 상태 확인
Write-Host "🔍 서비스 상태 확인 중..." -ForegroundColor Yellow
Start-Sleep -Seconds 10
$services = docker-compose -f docker-compose.prod.yml ps
Write-Host $services

# 포트 확인
Write-Host "🔌 포트 사용 확인 중..." -ForegroundColor Yellow
$port80 = netstat -an | Select-String ":80 "
$port443 = netstat -an | Select-String ":443 "

if ($port80) {
    Write-Host "✅ 포트 80 사용 중" -ForegroundColor Green
} else {
    Write-Host "⚠️ 포트 80이 사용되지 않습니다." -ForegroundColor Red
}

if ($port443) {
    Write-Host "✅ 포트 443 사용 중" -ForegroundColor Green
} else {
    Write-Host "⚠️ 포트 443이 사용되지 않습니다." -ForegroundColor Red
}

# 방화벽 규칙 확인/추가
Write-Host "🔥 방화벽 규칙 확인 중..." -ForegroundColor Yellow
try {
    $httpRule = Get-NetFirewallRule -DisplayName "FanxyTV-HTTP" -ErrorAction SilentlyContinue
    if (-not $httpRule) {
        New-NetFirewallRule -DisplayName "FanxyTV-HTTP" -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow | Out-Null
        Write-Host "✅ HTTP 방화벽 규칙 추가됨" -ForegroundColor Green
    }
    
    $httpsRule = Get-NetFirewallRule -DisplayName "FanxyTV-HTTPS" -ErrorAction SilentlyContinue
    if (-not $httpsRule) {
        New-NetFirewallRule -DisplayName "FanxyTV-HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow | Out-Null
        Write-Host "✅ HTTPS 방화벽 규칙 추가됨" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️ 방화벽 규칙 추가 실패. 관리자 권한으로 실행하세요." -ForegroundColor Red
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "✅ 배포 완료!" -ForegroundColor Green
Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host ""

# 결과 및 다음 단계 안내
Write-Host "📋 다음 단계를 진행하세요:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1️⃣ 가비아 DNS 설정:" -ForegroundColor Cyan
Write-Host "   - A 레코드: fanxytv.com → $publicIP" -ForegroundColor White
Write-Host "   - A 레코드: www.fanxytv.com → $publicIP" -ForegroundColor White
Write-Host ""
Write-Host "2️⃣ 공유기 포트포워딩 설정:" -ForegroundColor Cyan
Write-Host "   - 80포트: 외부 → 내부 PC IP:80" -ForegroundColor White
Write-Host "   - 443포트: 외부 → 내부 PC IP:443" -ForegroundColor White
Write-Host ""
Write-Host "3️⃣ 로컬 테스트:" -ForegroundColor Cyan
Write-Host "   - http://localhost:3000" -ForegroundColor White
Write-Host ""
Write-Host "4️⃣ 도메인 테스트 (DNS 전파 후):" -ForegroundColor Cyan
Write-Host "   - https://fanxytv.com" -ForegroundColor White
Write-Host ""

# 내부 IP 확인
$internalIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notmatch "Loopback" -and $_.IPAddress -notmatch "169.254"}).IPAddress | Select-Object -First 1
Write-Host "💻 내부 IP: $internalIP" -ForegroundColor Magenta
Write-Host "🌐 공인 IP: $publicIP" -ForegroundColor Magenta
Write-Host ""

Write-Host "🔧 유용한 명령어:" -ForegroundColor Yellow
Write-Host "   - 서비스 중지: docker-compose -f docker-compose.prod.yml down" -ForegroundColor Gray
Write-Host "   - 서비스 시작: docker-compose -f docker-compose.prod.yml up -d" -ForegroundColor Gray
Write-Host "   - 로그 확인: docker-compose -f docker-compose.prod.yml logs -f" -ForegroundColor Gray
Write-Host ""

Write-Host "🎉 Windows PC에서 도메인 연결 준비 완료!" -ForegroundColor Green 