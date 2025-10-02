# PayDay 앱 구조 정리

## 📱 앱 개요
실제 현금(원화)을 벌 수 있는 한국형 부수익 앱

## 💰 수익 시스템 (실제 원화)

### 기본 수익
- **걷기**: 100보당 1원
- **일일 출석**: 10원 (연속 출석시 최대 100원)
- **광고 시청**: 20-100원

### 잠금화면 광고
- **1배**: 월 3,000원
- **2배**: 월 6,000원
- **3배**: 월 9,000원
- **5배**: 월 15,000원

### 미션 보상
- **일일 미션**: 10-50원
- **주간 미션**: 500원

### 설문조사
- **일반 설문**: 100-500원
- **전문 설문**: 500-1000원

## 🏗 핵심 파일 구조

### 메인 화면 (lib/screens/)
```
✅ 사용 중인 화면
- main_screen.dart           # 하단 탭 네비게이션
- enhanced_home_screen.dart  # 홈 화면
- income_platforms_screen.dart # 부수익 플랫폼 선택
- wallet_screen.dart         # 지갑/잔액
- charts_screen.dart         # 통계/차트
- settings_screen.dart       # 설정

✅ 기능 화면
- auth_screen.dart           # 로그인/회원가입
- walking_reward_screen.dart # 걷기 보상
- survey_list_screen.dart    # 설문조사 목록
- mission_screen.dart        # 미션 화면
- lockscreen_ad_settings_screen.dart # 잠금화면 광고 설정
```

### 핵심 서비스 (lib/services/)
```
✅ 사용 중인 서비스
- cash_service.dart          # 💵 캐시(원화) 관리 - 핵심!
- lockscreen_ad_service.dart # 잠금화면 광고
- mission_service.dart       # 미션 시스템
- survey_service.dart        # 설문조사
- pedometer_service.dart     # 걷기 측정
- firebase_auth_service.dart # 사용자 인증
- data_service.dart          # 로컬 데이터 저장
- api_service.dart           # API 통신
- admob_service.dart         # AdMob 광고
- analytics_service.dart     # 애널리틱스

❌ 삭제됨
- point_service.dart         # CashService로 대체
```

## 📊 데이터 흐름

```
사용자 활동
    ↓
CashService (원화 적립)
    ↓
DataService (로컬 저장)
    ↓
UI 업데이트
```

## 💵 출금 시스템
- **최소 출금액**: 5,000원
- **출금 수수료**: 3%
- **출금 방법**: 계좌이체, 상품권 (예정)

## 🎯 일일 수익 목표
- **소극적 사용**: 500-1,000원
- **적극적 사용**: 1,500-2,000원
- **월 예상**: 30,000-60,000원

## 🔧 기술 스택
- Flutter 3.0+
- Firebase (Auth, Analytics, Messaging)
- Google AdMob
- SharedPreferences (로컬 저장)

## 📝 TODO
1. ✅ 포인트 → 원화 시스템 변경 완료
2. ⏳ 실제 DB 연결 (Supabase/Railway)
3. ⏳ 실제 출금 시스템 구현
4. ⏳ 친구 초대 시스템
5. ⏳ 쿠팡 파트너스 연동