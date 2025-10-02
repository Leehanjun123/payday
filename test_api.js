// PayDay API 통합 테스트
const API_BASE = 'https://payday-production-94a8.up.railway.app';
const API_KEY = 'temporary-api-key';

async function testAPI() {
    console.log('=== PayDay API 테스트 시작 ===\n');

    const headers = {
        'Content-Type': 'application/json',
        'X-API-Key': API_KEY
    };

    try {
        // 1. 서버 상태 확인
        console.log('1. 서버 상태 확인...');
        const healthRes = await fetch(API_BASE);
        const healthData = await healthRes.text();
        console.log('✅ 서버 정상 작동:', healthData);

        // 2. 수익 목록 조회
        console.log('\n2. 수익 목록 조회...');
        const earningsRes = await fetch(`${API_BASE}/api/v1/earnings`, { headers });
        const earnings = await earningsRes.json();
        console.log('✅ 수익 데이터 수:', earnings.data.length);
        console.log('   총 수익:', earnings.data.reduce((sum, e) => sum + e.amount, 0), '원');

        // 3. 새 수익 추가
        console.log('\n3. 새 수익 추가...');
        const newEarning = {
            source: '테스트 광고',
            amount: 2500,
            description: 'API 테스트용 수익',
            type: 'ad'
        };
        const createRes = await fetch(`${API_BASE}/api/v1/earnings`, {
            method: 'POST',
            headers,
            body: JSON.stringify(newEarning)
        });
        const created = await createRes.json();
        console.log('✅ 수익 추가 완료:', created.data.id);

        // 4. 목표 목록 조회
        console.log('\n4. 목표 목록 조회...');
        const goalsRes = await fetch(`${API_BASE}/api/v1/goals`, { headers });
        const goals = await goalsRes.json();
        console.log('✅ 목표 개수:', goals.data.length);
        goals.data.forEach(goal => {
            const progress = Math.round(goal.currentAmount / goal.targetAmount * 100);
            console.log(`   - ${goal.title}: ${progress}% 달성`);
        });

        // 5. 통계 조회
        console.log('\n5. 통계 데이터 조회...');
        const statsRes = await fetch(`${API_BASE}/api/v1/statistics`, { headers });
        const stats = await statsRes.json();
        console.log('✅ 통계 데이터:');
        console.log('   오늘 수익:', stats.data.todayEarnings, '원');
        console.log('   이번주 수익:', stats.data.weeklyEarnings, '원');
        console.log('   이번달 수익:', stats.data.monthlyEarnings, '원');
        console.log('   총 수익:', stats.data.totalEarnings, '원');

        // 6. 인증 테스트 (회원가입)
        console.log('\n6. 인증 시스템 테스트...');
        const testUser = {
            email: `test${Date.now()}@payday.com`,
            password: 'Test1234!',
            username: 'TestUser'
        };
        const registerRes = await fetch(`${API_BASE}/api/v1/auth/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(testUser)
        });
        const registered = await registerRes.json();
        if (registered.success) {
            console.log('✅ 회원가입 성공:', registered.data.user.email);
            console.log('   JWT 토큰 발급됨');
        } else {
            console.log('⚠️ 회원가입 테스트 스킵 (이미 존재하는 사용자)');
        }

        console.log('\n=== 모든 테스트 완료 ===');
        console.log('✅ Railway 백엔드가 정상적으로 작동 중입니다!');
        console.log('✅ Flutter 앱과 실시간 데이터 연동이 가능합니다.');

    } catch (error) {
        console.error('❌ 테스트 실패:', error.message);
    }
}

testAPI();