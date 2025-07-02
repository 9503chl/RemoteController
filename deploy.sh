#!/bin/bash

echo "🚀 FanxyTV 도메인 배포 시작..."

# 필요한 디렉토리 생성
mkdir -p certbot/conf
mkdir -p certbot/www

# 기존 컨테이너 중지 및 제거
echo "📦 기존 컨테이너 정리 중..."
docker-compose -f docker-compose.prod.yml down

# 이미지 빌드
echo "🔨 Docker 이미지 빌드 중..."
docker-compose -f docker-compose.prod.yml build

# 임시 Nginx 설정 (SSL 인증서 발급용)
cat > nginx-temp.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream frontend {
        server frontend:3000;
    }
    
    upstream backend {
        server backend:8000;
    }

    server {
        listen 80;
        server_name fanxytv.com www.fanxytv.com;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            proxy_pass http://frontend;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }

        location /api/ {
            proxy_pass http://backend/;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF

# 임시 설정으로 시작
echo "🔧 임시 Nginx 설정으로 서비스 시작..."
cp nginx-temp.conf nginx.conf
docker-compose -f docker-compose.prod.yml up -d frontend backend nginx

# SSL 인증서 발급
echo "🔐 SSL 인증서 발급 중..."
echo "이메일 주소를 입력하세요:"
read EMAIL
sed -i "s/your-email@example.com/$EMAIL/g" docker-compose.prod.yml

docker-compose -f docker-compose.prod.yml run --rm certbot

# 원래 Nginx 설정으로 교체
echo "🔄 SSL 설정으로 Nginx 재시작..."
cat > nginx.conf << EOF
events {
    worker_connections 1024;
}

http {
    upstream frontend {
        server frontend:3000;
    }
    
    upstream backend {
        server backend:8000;
    }

    # HTTP to HTTPS redirect
    server {
        listen 80;
        server_name fanxytv.com www.fanxytv.com;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            return 301 https://\$server_name\$request_uri;
        }
    }

    # HTTPS server
    server {
        listen 443 ssl http2;
        server_name fanxytv.com www.fanxytv.com;

        ssl_certificate /etc/letsencrypt/live/fanxytv.com/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/fanxytv.com/privkey.pem;
        
        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
        ssl_prefer_server_ciphers off;

        location / {
            proxy_pass http://frontend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_cache_bypass \$http_upgrade;
        }

        location /api/ {
            proxy_pass http://backend/;
            proxy_http_version 1.1;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
EOF

# 전체 서비스 재시작
docker-compose -f docker-compose.prod.yml down
docker-compose -f docker-compose.prod.yml up -d

# 정리
rm nginx-temp.conf

echo "✅ 배포 완료!"
echo "🌐 https://fanxytv.com 에서 확인하세요!"
echo "📱 SSL 인증서 자동 갱신을 위해 cron job 설정을 권장합니다:"
echo "0 12 * * * cd $(pwd) && docker-compose -f docker-compose.prod.yml run --rm certbot renew && docker-compose -f docker-compose.prod.yml exec nginx nginx -s reload" 