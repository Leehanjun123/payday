-- PayDay App - Railway Postgres Schema
-- 실제 캐시 적립 시스템을 위한 데이터베이스 설계

-- 사용자 테이블
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20) UNIQUE,
    device_id VARCHAR(255) UNIQUE NOT NULL,
    firebase_uid VARCHAR(255) UNIQUE,

    -- 프로필 정보
    nickname VARCHAR(50),
    profile_image_url TEXT,

    -- 계정 정보
    cash_balance DECIMAL(10,2) DEFAULT 0.00,
    total_earned DECIMAL(10,2) DEFAULT 0.00,
    withdrawal_available BOOLEAN DEFAULT true,

    -- 출금 계좌 정보 (암호화됨)
    bank_name VARCHAR(50),
    account_number_encrypted TEXT,
    account_holder_name VARCHAR(100),

    -- 보안 정보
    pin_hash VARCHAR(255), -- 출금 시 확인용 PIN
    last_login_at TIMESTAMP WITH TIME ZONE,
    last_device_check TIMESTAMP WITH TIME ZONE,

    -- 추천인 시스템
    referral_code VARCHAR(10) UNIQUE NOT NULL,
    referred_by_code VARCHAR(10),

    -- 계정 상태
    status VARCHAR(20) DEFAULT 'active', -- active, suspended, banned
    verification_status VARCHAR(20) DEFAULT 'pending', -- pending, verified, rejected

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 거래 내역 테이블 (모든 수익/출금 기록)
CREATE TABLE transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 거래 정보
    type VARCHAR(20) NOT NULL, -- earn, withdraw, bonus, penalty
    earning_method VARCHAR(50), -- ad_view, walking, survey, referral, etc.
    amount DECIMAL(10,2) NOT NULL,

    -- 상세 정보
    description TEXT,
    metadata JSONB, -- 추가 메타데이터 (광고 ID, 단계별 정보 등)

    -- 검증 정보
    verification_status VARCHAR(20) DEFAULT 'pending', -- pending, verified, rejected
    verified_at TIMESTAMP WITH TIME ZONE,
    verified_by VARCHAR(50), -- 'system', 'admin', 'admob'

    -- AdMob 연동 정보
    ad_unit_id VARCHAR(100),
    ad_impression_id VARCHAR(100),
    ad_revenue_usd DECIMAL(8,4), -- 실제 AdMob 수익 (USD)
    ad_revenue_krw DECIMAL(10,2), -- 원화 변환 수익

    -- 잔액 정보
    balance_before DECIMAL(10,2),
    balance_after DECIMAL(10,2),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 일일 제한 테이블
CREATE TABLE daily_limits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    earning_method VARCHAR(50) NOT NULL,
    date DATE NOT NULL,
    count INTEGER DEFAULT 0,
    last_earned_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(user_id, earning_method, date)
);

-- 출석 체크 테이블
CREATE TABLE attendance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    streak_count INTEGER DEFAULT 1,
    bonus_earned DECIMAL(10,2),

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

    UNIQUE(user_id, date)
);

-- 출금 요청 테이블
CREATE TABLE withdrawal_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 출금 정보
    amount DECIMAL(10,2) NOT NULL,
    fee DECIMAL(10,2) DEFAULT 0.00,
    net_amount DECIMAL(10,2) NOT NULL, -- amount - fee

    -- 계좌 정보 (요청 시점의 스냅샷)
    bank_name VARCHAR(50) NOT NULL,
    account_number_encrypted TEXT NOT NULL,
    account_holder_name VARCHAR(100) NOT NULL,

    -- 상태 관리
    status VARCHAR(20) DEFAULT 'pending', -- pending, processing, completed, failed, cancelled
    admin_notes TEXT,

    -- 처리 정보
    processed_at TIMESTAMP WITH TIME ZONE,
    processed_by VARCHAR(100),
    transaction_id VARCHAR(100), -- 은행 거래 ID

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 추천인 보상 테이블
CREATE TABLE referral_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    referred_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 보상 정보
    reward_type VARCHAR(20) NOT NULL, -- signup, first_earning, milestone
    amount DECIMAL(10,2) NOT NULL,
    milestone_target DECIMAL(10,2), -- 추천인이 달성해야 할 목표 금액

    -- 상태
    status VARCHAR(20) DEFAULT 'pending', -- pending, paid, expired
    paid_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- AdMob 수익 동기화 테이블
CREATE TABLE admob_revenue_sync (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- AdMob 정보
    ad_unit_id VARCHAR(100) NOT NULL,
    impression_id VARCHAR(100) UNIQUE NOT NULL,

    -- 수익 정보
    revenue_usd DECIMAL(8,4) NOT NULL,
    revenue_krw DECIMAL(10,2) NOT NULL,
    exchange_rate DECIMAL(8,4) NOT NULL,

    -- 분배 정보
    platform_share DECIMAL(8,4) NOT NULL, -- 플랫폼 수수료 (예: 50%)
    user_share DECIMAL(8,4) NOT NULL, -- 사용자 분배금

    -- 사용자 정보
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    transaction_id UUID REFERENCES transactions(id) ON DELETE SET NULL,

    -- 처리 상태
    status VARCHAR(20) DEFAULT 'pending', -- pending, distributed, failed
    distributed_at TIMESTAMP WITH TIME ZONE,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 시스템 설정 테이블
CREATE TABLE system_settings (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 인덱스 생성
CREATE INDEX idx_users_device_id ON users(device_id);
CREATE INDEX idx_users_referral_code ON users(referral_code);
CREATE INDEX idx_users_referred_by ON users(referred_by_code);

CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_type ON transactions(type);
CREATE INDEX idx_transactions_earning_method ON transactions(earning_method);
CREATE INDEX idx_transactions_created_at ON transactions(created_at);
CREATE INDEX idx_transactions_verification_status ON transactions(verification_status);

CREATE INDEX idx_daily_limits_user_method_date ON daily_limits(user_id, earning_method, date);
CREATE INDEX idx_attendance_user_date ON attendance(user_id, date);
CREATE INDEX idx_withdrawal_requests_user_id ON withdrawal_requests(user_id);
CREATE INDEX idx_withdrawal_requests_status ON withdrawal_requests(status);

CREATE INDEX idx_admob_sync_impression_id ON admob_revenue_sync(impression_id);
CREATE INDEX idx_admob_sync_user_id ON admob_revenue_sync(user_id);
CREATE INDEX idx_admob_sync_status ON admob_revenue_sync(status);

-- 시스템 설정 초기값
INSERT INTO system_settings (key, value, description) VALUES
('earning_rates', '{
    "ad_view": 100,
    "walking": 1,
    "survey": 500,
    "daily_login": 10,
    "referral": 1000,
    "app_review": 100,
    "social_share": 30,
    "video_watch": 10,
    "news_read": 20,
    "quiz_correct": 50,
    "water_drink": 10,
    "exercise_log": 100,
    "sleep_record": 50,
    "qr_scan": 15,
    "location_checkin": 25
}', '수익 방법별 보상 금액 (원)'),

('daily_limits', '{
    "ad_view": 20,
    "walking": 50,
    "survey": 5,
    "daily_login": 1,
    "referral": 10,
    "app_review": 3,
    "social_share": 10,
    "video_watch": 60,
    "news_read": 20,
    "quiz_correct": 15,
    "water_drink": 8,
    "exercise_log": 3,
    "sleep_record": 1,
    "qr_scan": 20,
    "location_checkin": 10
}', '수익 방법별 일일 제한'),

('withdrawal_settings', '{
    "minimum_amount": 10000,
    "maximum_amount": 1000000,
    "fee_percentage": 0.03,
    "processing_days": 3
}', '출금 관련 설정'),

('admob_settings', '{
    "revenue_share_percentage": 0.5,
    "minimum_revenue_usd": 0.01
}', 'AdMob 수익 분배 설정');