# PayDay App 배포 가이드

## 🚀 GitHub 설정

### 1. GitHub Repository 생성
1. GitHub (https://github.com) 에 로그인
2. 우측 상단 + 버튼 → "New repository" 클릭
3. Repository 정보 입력:
   - Repository name: `payday-app`
   - Description: "PayDay - AI-powered personal finance management app"
   - Public 또는 Private 선택
   - "Create repository" 클릭

### 2. 로컬 Git 연결 및 푸시
```bash
# GitHub repository와 연결
git remote add origin https://github.com/[your-username]/payday-app.git

# 코드 푸시
git push -u origin main
```

### 3. GitHub Secrets 설정
1. GitHub repository → Settings → Secrets and variables → Actions
2. "New repository secret" 클릭
3. 다음 secrets 추가:
   - `RAILWAY_TOKEN`: Railway에서 발급받은 토큰

## 🚂 Railway 설정

### 1. Railway 프로젝트 생성
1. Railway (https://railway.app) 에 로그인
2. "New Project" 클릭
3. "Deploy from GitHub repo" 선택
4. `payday-app` repository 선택

### 2. Railway 서비스 설정
Railway 대시보드에서:

#### Backend 서비스
1. "New" → "GitHub Repo" → `payday-app` 선택
2. Service 이름: `backend`
3. Root Directory: `/apps/backend`
4. Environment Variables 설정:
   ```
   NODE_ENV=production
   JWT_SECRET=[32자 이상의 랜덤 문자열]
   DATABASE_URL=[Railway가 자동으로 제공하는 PostgreSQL URL]
   ```

#### PostgreSQL 데이터베이스
1. "New" → "Database" → "Add PostgreSQL"
2. Railway가 자동으로 DATABASE_URL을 backend 서비스에 연결

### 3. Railway Token 발급
1. Railway 대시보드 → Account Settings
2. "Tokens" 섹션
3. "Create Token" 클릭
4. Token 복사 → GitHub Secrets에 추가

## 📱 Flutter 앱 설정

### 1. Production 환경 변수 업데이트
`/apps/payday_flutter/.env.production` 파일 수정:
```env
# Railway 배포 후 실제 URL로 변경
API_URL=https://[your-backend-service].up.railway.app
API_VERSION=v1
APP_ENV=production
```

### 2. 변경사항 커밋 및 푸시
```bash
git add .
git commit -m "🔧 Update production API URL"
git push
```

## 🔄 자동 배포 워크플로우

GitHub Actions가 자동으로:
1. `main` 브랜치에 push 시 자동 배포 시작
2. Backend TypeScript 빌드 및 테스트
3. Flutter 코드 분석 및 포맷 체크
4. Backend를 Railway에 배포
5. Flutter 웹 버전을 GitHub Pages에 배포

## ✅ 배포 확인

### Backend 상태 확인
```bash
# Railway CLI 설치 (선택사항)
npm install -g @railway/cli

# Railway 프로젝트 상태 확인
railway status
```

### 배포된 서비스 접속
- Backend API: `https://[your-backend-service].up.railway.app`
- Flutter Web: `https://[your-username].github.io/payday-app`

## 🔧 트러블슈팅

### Railway 배포 실패
1. Railway 대시보드에서 로그 확인
2. 환경 변수가 모두 설정되었는지 확인
3. `railway.json` 파일의 build/deploy 명령어 확인

### GitHub Actions 실패
1. Actions 탭에서 실패한 워크플로우 확인
2. 로그에서 에러 메시지 확인
3. RAILWAY_TOKEN이 올바르게 설정되었는지 확인

### Database 연결 실패
1. DATABASE_URL이 Railway에서 제공되었는지 확인
2. Prisma schema와 마이그레이션 확인
3. Railway 대시보드에서 PostgreSQL 서비스 상태 확인

## 📝 환경 변수 체크리스트

### Backend (Railway)
- [ ] NODE_ENV=production
- [ ] DATABASE_URL (Railway가 자동 제공)
- [ ] JWT_SECRET
- [ ] PORT (Railway가 자동 제공)

### Flutter
- [ ] API_URL (Railway backend URL)
- [ ] API_VERSION
- [ ] APP_ENV=production

### GitHub Secrets
- [ ] RAILWAY_TOKEN

## 🎯 다음 단계

1. **모니터링 설정**
   - Railway 대시보드에서 메트릭 확인
   - 에러 로그 모니터링

2. **도메인 연결** (선택사항)
   - Railway에서 커스텀 도메인 설정
   - SSL 자동 적용

3. **스케일링**
   - Railway에서 인스턴스 수 조정
   - 리소스 한계 설정

## 💡 유용한 명령어

```bash
# Git 상태 확인
git status

# 변경사항 푸시
git add .
git commit -m "커밋 메시지"
git push

# Railway CLI 로그인
railway login

# Railway 로그 확인
railway logs

# Flutter 웹 빌드
cd apps/payday_flutter
flutter build web --release
```

## 📚 참고 자료

- [Railway 문서](https://docs.railway.app)
- [GitHub Actions 문서](https://docs.github.com/en/actions)
- [Flutter 배포 가이드](https://flutter.dev/docs/deployment/web)