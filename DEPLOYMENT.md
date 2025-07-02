# 🌐 FanxyTV 도메인 배포 가이드

## 📋 준비사항

1. **VPS/클라우드 서버** (AWS EC2, DigitalOcean, Vultr 등)
   - Ubuntu 20.04+ 권장
   - 최소 2GB RAM, 20GB 디스크
   - 80, 443 포트 오픈

2. **도메인 설정** (가비아)
   - A 레코드: `fanxytv.com` → 서버 IP
   - A 레코드: `www.fanxytv.com` → 서버 IP

## 🚀 배포 단계

### 1. 서버 준비
```bash
# 서버에 접속 후 Docker 설치
sudo apt update
sudo apt install -y docker.io docker-compose git
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker $USER
```

### 2. 프로젝트 복사
```bash
# 프로젝트를 서버로 업로드 (SCP, Git 등 사용)
scp -r /f:/Backend/RemoteController user@your-server-ip:/home/user/
```

### 3. 가비아 DNS 설정
가비아 관리 페이지에서:
- **A 레코드 추가**: `fanxytv.com` → `서버 IP 주소`
- **A 레코드 추가**: `www.fanxytv.com` → `서버 IP 주소`
- **TTL**: 300초 (5분)

### 4. 서버에서 배포 실행
```bash
cd /home/user/RemoteController
chmod +x deploy.sh
./deploy.sh
```

배포 스크립트가 자동으로:
- Docker 이미지 빌드
- SSL 인증서 발급 (Let's Encrypt)
- Nginx 리버스 프록시 설정
- 서비스 시작

## 🔧 수동 배포 (고급)

### 1. 프로덕션 환경 시작
```bash
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d
```

### 2. SSL 인증서 발급
```bash
# 이메일 주소 수정
nano docker-compose.prod.yml

# 인증서 발급
docker-compose -f docker-compose.prod.yml run --rm certbot
```

### 3. Nginx 재시작
```bash
docker-compose -f docker-compose.prod.yml restart nginx
```

## 📱 확인 사항

배포 완료 후 확인:
- ✅ `http://fanxytv.com` → `https://fanxytv.com` 리다이렉트
- ✅ `https://fanxytv.com` 정상 접속
- ✅ 웹캠 기능 테스트
- ✅ API 엔드포인트 동작 확인

## 🔄 SSL 인증서 자동 갱신

Cron job 설정:
```bash
sudo crontab -e

# 매일 정오에 인증서 갱신 체크
0 12 * * * cd /home/user/RemoteController && docker-compose -f docker-compose.prod.yml run --rm certbot renew && docker-compose -f docker-compose.prod.yml exec nginx nginx -s reload
```

## 🐛 트러블슈팅

### 도메인이 연결되지 않을 때
1. DNS 전파 확인: `nslookup fanxytv.com`
2. 방화벽 확인: `sudo ufw status`
3. 포트 확인: `netstat -tlnp | grep :80`

### SSL 인증서 발급 실패
1. 도메인 DNS 설정 재확인
2. 80포트 접근 가능 여부 확인
3. Certbot 로그 확인: `docker-compose -f docker-compose.prod.yml logs certbot`

### 서비스 재시작
```bash
# 전체 재시작
docker-compose -f docker-compose.prod.yml restart

# 개별 서비스 재시작
docker-compose -f docker-compose.prod.yml restart nginx
docker-compose -f docker-compose.prod.yml restart frontend
docker-compose -f docker-compose.prod.yml restart backend
```

## 📊 모니터링

### 로그 확인
```bash
# 전체 로그
docker-compose -f docker-compose.prod.yml logs -f

# 특정 서비스 로그
docker-compose -f docker-compose.prod.yml logs -f nginx
docker-compose -f docker-compose.prod.yml logs -f frontend
docker-compose -f docker-compose.prod.yml logs -f backend
```

### 서비스 상태 확인
```bash
docker-compose -f docker-compose.prod.yml ps
```

---

🎉 **배포 완료 후 `https://fanxytv.com`에서 서비스를 이용하세요!** 