const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// In-memory database (Railway에서는 실제 DB 사용 권장)
let earnings = [];
let goals = [];
let settings = {
  notifications: true,
  darkMode: false,
  currency: 'KRW',
  monthlyGoal: 100000
};

// API Key 검증 미들웨어 (간단한 구현)
const authenticateAPIKey = (req, res, next) => {
  const apiKey = req.headers['x-api-key'];
  // 임시로 모든 키 허용 (실제로는 환경변수로 관리)
  if (apiKey === 'temporary-api-key' || !apiKey) {
    next();
  } else {
    next();
  }
};

// Health check
app.get('/', (req, res) => {
  res.json({
    status: 'OK',
    service: 'PayDay Backend API',
    version: '1.0.0',
    endpoints: [
      '/api/v1/earnings',
      '/api/v1/goals',
      '/api/v1/statistics',
      '/api/v1/settings'
    ]
  });
});

// ========== EARNINGS ENDPOINTS ==========

// GET all earnings
app.get('/api/v1/earnings', authenticateAPIKey, (req, res) => {
  res.json({
    success: true,
    data: earnings
  });
});

// POST new earning
app.post('/api/v1/earnings', authenticateAPIKey, (req, res) => {
  const { source, amount, description, date } = req.body;

  const newEarning = {
    id: uuidv4(),
    source: source || 'Unknown',
    amount: parseFloat(amount) || 0,
    description: description || '',
    date: date || new Date().toISOString(),
    type: req.body.type || 'other',
    createdAt: new Date().toISOString()
  };

  earnings.push(newEarning);

  res.status(201).json({
    success: true,
    data: newEarning
  });
});

// PUT update earning
app.put('/api/v1/earnings/:id', authenticateAPIKey, (req, res) => {
  const { id } = req.params;
  const index = earnings.findIndex(e => e.id === id);

  if (index === -1) {
    return res.status(404).json({ success: false, error: 'Earning not found' });
  }

  earnings[index] = {
    ...earnings[index],
    ...req.body,
    id: earnings[index].id,
    updatedAt: new Date().toISOString()
  };

  res.json({
    success: true,
    data: earnings[index]
  });
});

// DELETE earning
app.delete('/api/v1/earnings/:id', authenticateAPIKey, (req, res) => {
  const { id } = req.params;
  const index = earnings.findIndex(e => e.id === id);

  if (index === -1) {
    return res.status(404).json({ success: false, error: 'Earning not found' });
  }

  earnings.splice(index, 1);

  res.json({
    success: true,
    message: 'Earning deleted successfully'
  });
});

// GET earnings by date range
app.get('/api/v1/earnings/range', authenticateAPIKey, (req, res) => {
  const { start, end } = req.query;

  let filtered = earnings;

  if (start && end) {
    filtered = earnings.filter(e => {
      const date = new Date(e.date);
      return date >= new Date(start) && date <= new Date(end);
    });
  }

  res.json({
    success: true,
    data: filtered
  });
});

// ========== GOALS ENDPOINTS ==========

// GET all goals
app.get('/api/v1/goals', authenticateAPIKey, (req, res) => {
  res.json({
    success: true,
    data: goals
  });
});

// POST new goal
app.post('/api/v1/goals', authenticateAPIKey, (req, res) => {
  const { title, targetAmount, deadline, description } = req.body;

  const newGoal = {
    id: uuidv4(),
    title: title || 'New Goal',
    targetAmount: parseFloat(targetAmount) || 0,
    currentAmount: 0,
    deadline: deadline || null,
    description: description || '',
    createdAt: new Date().toISOString()
  };

  goals.push(newGoal);

  res.status(201).json({
    success: true,
    data: newGoal
  });
});

// PUT update goal
app.put('/api/v1/goals/:id', authenticateAPIKey, (req, res) => {
  const { id } = req.params;
  const index = goals.findIndex(g => g.id === id);

  if (index === -1) {
    return res.status(404).json({ success: false, error: 'Goal not found' });
  }

  goals[index] = {
    ...goals[index],
    ...req.body,
    id: goals[index].id,
    updatedAt: new Date().toISOString()
  };

  res.json({
    success: true,
    data: goals[index]
  });
});

// PUT update goal progress
app.put('/api/v1/goals/:id/progress', authenticateAPIKey, (req, res) => {
  const { id } = req.params;
  const { currentAmount } = req.body;
  const index = goals.findIndex(g => g.id === id);

  if (index === -1) {
    return res.status(404).json({ success: false, error: 'Goal not found' });
  }

  goals[index].currentAmount = parseFloat(currentAmount) || 0;
  goals[index].updatedAt = new Date().toISOString();

  res.json({
    success: true,
    data: goals[index]
  });
});

// DELETE goal
app.delete('/api/v1/goals/:id', authenticateAPIKey, (req, res) => {
  const { id } = req.params;
  const index = goals.findIndex(g => g.id === id);

  if (index === -1) {
    return res.status(404).json({ success: false, error: 'Goal not found' });
  }

  goals.splice(index, 1);

  res.json({
    success: true,
    message: 'Goal deleted successfully'
  });
});

// ========== STATISTICS ENDPOINT ==========

app.get('/api/v1/statistics', authenticateAPIKey, (req, res) => {
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - now.getDay());
  const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  const totalEarnings = earnings.reduce((sum, e) => sum + e.amount, 0);

  const monthlyEarnings = earnings
    .filter(e => new Date(e.date) >= startOfMonth)
    .reduce((sum, e) => sum + e.amount, 0);

  const weeklyEarnings = earnings
    .filter(e => new Date(e.date) >= startOfWeek)
    .reduce((sum, e) => sum + e.amount, 0);

  const todayEarnings = earnings
    .filter(e => new Date(e.date) >= startOfDay)
    .reduce((sum, e) => sum + e.amount, 0);

  // 소스별 수익 계산
  const earningsBySource = {};
  earnings.forEach(e => {
    const type = e.type || 'other';
    earningsBySource[type] = (earningsBySource[type] || 0) + e.amount;
  });

  res.json({
    success: true,
    data: {
      totalEarnings,
      monthlyEarnings,
      weeklyEarnings,
      todayEarnings,
      earningsBySource,
      totalGoals: goals.length,
      activeGoals: goals.filter(g => !g.completed).length
    }
  });
});

// ========== SETTINGS ENDPOINTS ==========

app.get('/api/v1/settings', authenticateAPIKey, (req, res) => {
  res.json({
    success: true,
    data: settings
  });
});

app.put('/api/v1/settings', authenticateAPIKey, (req, res) => {
  settings = {
    ...settings,
    ...req.body
  };

  res.json({
    success: true,
    data: settings
  });
});

// ========== SAMPLE DATA INITIALIZATION ==========
function initializeSampleData() {
  // 샘플 수익 데이터
  earnings = [
    {
      id: uuidv4(),
      source: 'Google AdMob',
      amount: 25000,
      description: '광고 수익',
      date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
      type: 'ad',
      createdAt: new Date().toISOString()
    },
    {
      id: uuidv4(),
      source: 'Survey Time',
      amount: 8500,
      description: '설문조사 10개 완료',
      date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
      type: 'survey',
      createdAt: new Date().toISOString()
    },
    {
      id: uuidv4(),
      source: 'Coupang Partners',
      amount: 15000,
      description: '제휴 마케팅 수익',
      date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
      type: 'affiliate',
      createdAt: new Date().toISOString()
    },
    {
      id: uuidv4(),
      source: 'Unity Ads',
      amount: 12000,
      description: '동영상 광고 수익',
      date: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000).toISOString(),
      type: 'ad',
      createdAt: new Date().toISOString()
    },
    {
      id: uuidv4(),
      source: '네이버 쇼핑',
      amount: 7500,
      description: '제휴 링크 클릭',
      date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
      type: 'affiliate',
      createdAt: new Date().toISOString()
    }
  ];

  // 샘플 목표 데이터
  goals = [
    {
      id: uuidv4(),
      title: '이번달 10만원 달성',
      targetAmount: 100000,
      currentAmount: 68000,
      deadline: new Date(Date.now() + 20 * 24 * 60 * 60 * 1000).toISOString(),
      description: '월 목표 수익 달성하기',
      createdAt: new Date().toISOString()
    },
    {
      id: uuidv4(),
      title: '아이패드 구매 자금',
      targetAmount: 1000000,
      currentAmount: 250000,
      deadline: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
      description: '아이패드 프로 구매를 위한 저축',
      createdAt: new Date().toISOString()
    },
    {
      id: uuidv4(),
      title: '여행 자금 모으기',
      targetAmount: 500000,
      currentAmount: 120000,
      deadline: new Date(Date.now() + 60 * 24 * 60 * 60 * 1000).toISOString(),
      description: '제주도 여행 경비',
      createdAt: new Date().toISOString()
    }
  ];
}

// 서버 시작 시 샘플 데이터 초기화
initializeSampleData();

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Something went wrong!'
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`PayDay Backend API running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`API Endpoints available at http://localhost:${PORT}/api/v1/`);
});