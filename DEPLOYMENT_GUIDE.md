# PayDay App - 배포 가이드 🚀

## 📋 목차
1. [배포 준비](#배포-준비)
2. [백엔드 배포](#백엔드-배포)
3. [모바일 앱 배포](#모바일-앱-배포)
4. [모니터링 설정](#모니터링-설정)

## 배포 준비

### 1. 환경 변수 설정
```bash
# .env.production 파일 생성
cp .env.example .env.production

# 필수 환경 변수 설정
- JWT_SECRET: 보안 키 생성
- DATABASE_URL: PostgreSQL 연결 정보
- REDIS_URL: Redis 연결 정보
- AWS 자격 증명
```

### 2. 의존성 설치
```bash
# 루트 디렉토리에서
yarn install

# 백엔드 빌드
cd apps/backend
npm run build

# 모바일 앱 빌드 준비
cd ../mobile
npm install
```

## 백엔드 배포

### Docker를 사용한 로컬 배포
```bash
# Docker Compose 실행
docker-compose up -d

# 데이터베이스 마이그레이션
docker exec payday-backend npx prisma migrate deploy

# 헬스 체크
curl http://localhost:3000/health
```

### AWS ECS 배포
```bash
# ECR 로그인
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin [YOUR_ECR_URI]

# 이미지 빌드 및 푸시
docker build -t payday-backend ./apps/backend
docker tag payday-backend:latest [YOUR_ECR_URI]/payday-backend:latest
docker push [YOUR_ECR_URI]/payday-backend:latest

# ECS 서비스 업데이트
aws ecs update-service --cluster payday-cluster --service payday-backend --force-new-deployment
```

### Kubernetes 배포
```yaml
# k8s/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payday-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: payday-backend
  template:
    metadata:
      labels:
        app: payday-backend
    spec:
      containers:
      - name: backend
        image: [YOUR_REGISTRY]/payday-backend:latest
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
```

```bash
# 배포
kubectl apply -f k8s/
```

## 모바일 앱 배포

### 1. EAS Build 설정
```bash
cd apps/mobile

# EAS CLI 설치
npm install -g eas-cli

# EAS 로그인
eas login

# 프로젝트 초기화
eas build:configure
```

### 2. Android 빌드 및 배포
```bash
# 프로덕션 APK 빌드
eas build --platform android --profile production

# Google Play Store 배포
eas submit --platform android --latest
```

### 3. iOS 빌드 및 배포
```bash
# 프로덕션 IPA 빌드
eas build --platform ios --profile production

# App Store Connect 배포
eas submit --platform ios --latest
```

### 4. 테스트 배포 (Internal Testing)
```bash
# Android 내부 테스트
eas build --platform android --profile preview

# iOS TestFlight
eas build --platform ios --profile preview
```

## 모니터링 설정

### 1. CloudWatch (AWS)
```javascript
// 백엔드에 CloudWatch 설정
import AWS from 'aws-sdk';

const cloudwatch = new AWS.CloudWatch({
  region: 'ap-northeast-2'
});

// 메트릭 전송
cloudwatch.putMetricData({
  Namespace: 'PayDay',
  MetricData: [
    {
      MetricName: 'APILatency',
      Value: responseTime,
      Unit: 'Milliseconds'
    }
  ]
}).promise();
```

### 2. Sentry 에러 트래킹
```javascript
// 백엔드
import * as Sentry from "@sentry/node";

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV
});

// 모바일
import * as Sentry from 'sentry-expo';

Sentry.init({
  dsn: 'YOUR_SENTRY_DSN',
  enableInExpoDevelopment: false,
  debug: false
});
```

### 3. Google Analytics
```javascript
// 모바일 앱 분석
import Analytics from '@react-native-firebase/analytics';

await Analytics().logEvent('task_completed', {
  task_id: taskId,
  user_id: userId,
  amount: amount
});
```

## 배포 체크리스트 ✅

### 백엔드
- [ ] 환경 변수 설정 완료
- [ ] 데이터베이스 마이그레이션 완료
- [ ] Redis 연결 확인
- [ ] SSL 인증서 설정
- [ ] 로드 밸런서 설정
- [ ] Auto-scaling 설정
- [ ] 백업 정책 설정

### 모바일
- [ ] 앱 아이콘 및 스플래시 스크린
- [ ] 앱 스토어 메타데이터 준비
- [ ] 스크린샷 및 프로모션 이미지
- [ ] 개인정보 처리방침 URL
- [ ] 이용약관 URL
- [ ] 앱 심사 가이드라인 확인

### 보안
- [ ] API 키 로테이션
- [ ] HTTPS 적용
- [ ] Rate Limiting 설정
- [ ] SQL Injection 방지
- [ ] XSS 방지
- [ ] CORS 설정

## 트러블슈팅

### 일반적인 문제 해결

1. **Docker 빌드 실패**
```bash
# 캐시 클리어 후 재빌드
docker system prune -a
docker-compose build --no-cache
```

2. **EAS 빌드 실패**
```bash
# 캐시 클리어
eas build --clear-cache --platform android
```

3. **데이터베이스 연결 실패**
```bash
# 연결 테스트
npx prisma db pull
```

## 롤백 절차

### 백엔드 롤백
```bash
# 이전 버전으로 롤백
docker pull [YOUR_REGISTRY]/payday-backend:previous-version
docker service update --image [YOUR_REGISTRY]/payday-backend:previous-version payday-backend
```

### 데이터베이스 롤백
```bash
# 마이그레이션 롤백
npx prisma migrate resolve --rolled-back
```

## 지원 및 문의

- 기술 지원: tech@payday-app.com
- 긴급 연락처: +82-10-XXXX-XXXX
- Slack: #payday-deployment
- 문서: https://docs.payday-app.com

## 라이선스

Copyright © 2024 PayDay Team. All rights reserved.