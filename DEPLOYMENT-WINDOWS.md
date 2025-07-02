# 🖥️ Windows PC에서 FanxyTV 도메인 연결

## 📋 준비사항

1. **Windows PC 요구사항**
   - Windows 10/11 (Docker Desktop 지원)
   - 최소 8GB RAM 권장
   - Docker Desktop 설치됨
   - 고정 IP 또는 DDNS 설정

2. **네트워크 설정**
   - 공유기 포트포워딩: 80, 443포트
   - Windows 방화벽 설정
   - 고정 IP 또는 동적 DNS

## 🚀 Windows 배포 방법

### 방법 1: Docker Desktop + 포트포워딩 (추천)

#### 1단계: 포트포워딩 설정
공유기 관리 페이지에서:
- **80포트**: 외부 → 내부 PC IP:80
- **443포트**: 외부 → 내부 PC IP:443

#### 2단계: Windows 방화벽 설정
```powershell
# PowerShell 관리자 권한으로 실행
New-NetFirewallRule -DisplayName "HTTP" -Direction Inbound -Protocol TCP -LocalPort 80
New-NetFirewallRule -DisplayName "HTTPS" -Direction Inbound -Protocol TCP -LocalPort 443
```

#### 3단계: 현재 프로젝트 실행
```powershell
# 현재 디렉토리에서
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
```

#### 4단계: 가비아 DNS 설정
- **A 레코드**: `fanxytv.com` → **공인 IP 주소**
- **A 레코드**: `www.fanxytv.com` → **공인 IP 주소**

### 방법 2: WSL2 + Ubuntu (Linux 환경)

#### 1단계: WSL2 설치
```powershell
# PowerShell 관리자 권한으로 실행
wsl --install -d Ubuntu
```

#### 2단계: Ubuntu에서 Docker 설치
```bash
# WSL2 Ubuntu 터미널에서
sudo apt update
sudo apt install -y docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
```

#### 3단계: 프로젝트 복사 및 실행
```bash
# Windows 파일을 WSL로 복사
cp -r /mnt/f/Backend/RemoteController ~/
cd ~/RemoteController
chmod +x deploy.sh
./deploy.sh
```

## 🌐 공인 IP 확인 방법

### 현재 공인 IP 확인:
```powershell
# PowerShell에서
Invoke-RestMethod -Uri "https://ipinfo.io/ip"
```

또는 웹사이트에서: https://whatismyipaddress.com/

## 🔧 동적 DNS 설정 (IP가 자주 바뀌는 경우)

### 1. 무료 DDNS 서비스 이용
- **DuckDNS**: https://duckdns.org/
- **No-IP**: https://noip.com/
- **FreeDNS**: https://freedns.afraid.org/

### 2. 가비아에서 CNAME 설정
```
fanxytv.com → your-ddns-domain.duckdns.org
```

## 📱 SSL 인증서 (Let's Encrypt)

### Windows PowerShell로 SSL 설정:
```powershell
# Certbot 설치 (Chocolatey 사용)
choco install certbot

# 인증서 발급
certbot certonly --standalone -d fanxytv.com -d www.fanxytv.com
```

## 🐛 Windows 특화 트러블슈팅

### Docker Desktop 이슈
```powershell
# Docker Desktop 재시작
Restart-Service -Name "com.docker.service"
```

### 포트 충돌 확인
```powershell
# 포트 사용 확인
netstat -an | findstr :80
netstat -an | findstr :443
```

### 방화벽 문제
```powershell
# 방화벽 상태 확인
Get-NetFirewallProfile
```

## 🚀 Windows 전용 배포 스크립트

### `deploy-windows.ps1` 생성:
```powershell
Write-Host "🚀 FanxyTV Windows 배포 시작..." -ForegroundColor Green

# Docker 컨테이너 정리
Write-Host "📦 기존 컨테이너 정리 중..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml down

# 이미지 빌드
Write-Host "🔨 Docker 이미지 빌드 중..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml build

# 서비스 시작
Write-Host "▶️ 서비스 시작 중..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml up -d

Write-Host "✅ 배포 완료!" -ForegroundColor Green
Write-Host "🌐 https://fanxytv.com 에서 확인하세요!" -ForegroundColor Cyan

# 공인 IP 표시
$publicIP = Invoke-RestMethod -Uri "https://ipinfo.io/ip"
Write-Host "📍 현재 공인 IP: $publicIP" -ForegroundColor Magenta
Write-Host "⚠️ 가비아 DNS에서 A 레코드를 $publicIP 로 설정하세요!" -ForegroundColor Red
```

## 💡 권장사항

1. **고정 IP 서비스** 신청 (통신사)
2. **UPS** 사용 (정전 대비)
3. **원격 접속** 설정 (TeamViewer, 크롬 원격 데스크톱)
4. **자동 시작** 설정 (Windows 부팅 시 Docker 자동 실행)

---

🎉 **Windows PC에서도 완벽하게 도메인 연결 가능합니다!** 