const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = process.env.PORT || 3000;

// JWT Secret (실제 배포시 환경변수로 관리)
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'your-refresh-secret-key';

// Middleware
app.use(cors());
app.use(express.json());

// ========== IN-MEMORY DATABASE ==========
let users = [];
let earnings = [];
let goals = [];
let tasks = [];
let skills = [];
let marketplace = [];
let auctions = [];
let investments = [];
let predictions = [];
let payments = [];
let settings = {
  notifications: true,
  darkMode: false,
  currency: 'KRW',
  monthlyGoal: 100000
};

// ========== HELPER FUNCTIONS ==========

// JWT 토큰 생성
const generateToken = (userId, email, role = 'USER') => {
  return jwt.sign(
    { userId, email, role },
    JWT_SECRET,
    { expiresIn: '24h' }
  );
};

// Refresh 토큰 생성
const generateRefreshToken = (userId) => {
  return jwt.sign(
    { userId, type: 'refresh' },
    JWT_REFRESH_SECRET,
    { expiresIn: '30d' }
  );
};

// JWT 토큰 검증
const verifyToken = (token) => {
  try {
    return jwt.verify(token, JWT_SECRET);
  } catch (error) {
    throw new Error('Invalid token');
  }
};

// 비밀번호 해시
const hashPassword = async (password) => {
  return await bcrypt.hash(password, 10);
};

// 비밀번호 비교
const comparePassword = async (password, hash) => {
  return await bcrypt.compare(password, hash);
};

// Email 유효성 검사
const validateEmail = (email) => {
  const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return re.test(email);
};

// Password 유효성 검사
const validatePassword = (password) => {
  const errors = [];
  if (password.length < 8) errors.push('Password must be at least 8 characters');
  if (!/[A-Z]/.test(password)) errors.push('Password must contain uppercase letter');
  if (!/[a-z]/.test(password)) errors.push('Password must contain lowercase letter');
  if (!/[0-9]/.test(password)) errors.push('Password must contain number');

  return {
    isValid: errors.length === 0,
    errors
  };
};

// ========== AUTHENTICATION MIDDLEWARE ==========

// JWT 인증 미들웨어
const authenticate = async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
      // 임시 API Key 체크 (기존 호환성 유지)
      const apiKey = req.headers['x-api-key'];
      if (apiKey === 'temporary-api-key') {
        req.user = {
          userId: 'temp-user',
          email: 'temp@payday.com',
          role: 'USER'
        };
        return next();
      }

      return res.status(401).json({
        error: 'Authentication required',
        message: 'No token provided'
      });
    }

    const decoded = verifyToken(token);

    // 사용자 확인
    const user = users.find(u => u.id === decoded.userId);
    if (!user || !user.isActive) {
      return res.status(401).json({
        error: 'Invalid token',
        message: 'User not found or inactive'
      });
    }

    req.user = {
      userId: user.id,
      email: user.email,
      role: user.role || 'USER'
    };

    next();
  } catch (error) {
    res.status(401).json({
      error: 'Invalid token',
      message: error.message
    });
  }
};

// Optional authentication (인증 선택적)
const optionalAuth = async (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];

  if (token) {
    try {
      const decoded = verifyToken(token);
      const user = users.find(u => u.id === decoded.userId);
      if (user && user.isActive) {
        req.user = {
          userId: user.id,
          email: user.email,
          role: user.role || 'USER'
        };
      }
    } catch (error) {
      // 토큰이 유효하지 않아도 계속 진행
    }
  }

  next();
};

// ========== HEALTH CHECK ==========
app.get('/', (req, res) => {
  res.json({
    status: 'OK',
    service: 'PayDay Integrated Backend API',
    version: '2.0.0',
    endpoints: {
      auth: ['/api/auth/register', '/api/auth/login', '/api/auth/refresh'],
      v1: ['/api/v1/earnings', '/api/v1/goals', '/api/v1/settings', '/api/v1/statistics'],
      users: ['/api/users/profile', '/api/users/update'],
      earnings: ['/api/earnings'],
      tasks: ['/api/tasks'],
      marketplace: ['/api/marketplace'],
      payments: ['/api/payments']
    }
  });
});

app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'payday-backend',
    version: '2.0.0'
  });
});

// ========== AUTH ROUTES ==========

// Register
app.post('/api/auth/register', async (req, res) => {
  try {
    const { email, password, name, phone } = req.body;

    // Validation
    if (!email || !password || !name) {
      return res.status(400).json({
        error: 'Missing required fields',
        required: ['email', 'password', 'name']
      });
    }

    if (!validateEmail(email)) {
      return res.status(400).json({
        error: 'Invalid email format'
      });
    }

    const passwordValidation = validatePassword(password);
    if (!passwordValidation.isValid) {
      return res.status(400).json({
        error: 'Password validation failed',
        errors: passwordValidation.errors
      });
    }

    // Check if user exists
    if (users.find(u => u.email === email)) {
      return res.status(409).json({
        error: 'User already exists'
      });
    }

    // Create user
    const hashedPassword = await hashPassword(password);
    const newUser = {
      id: uuidv4(),
      email,
      password: hashedPassword,
      name,
      phone,
      role: 'USER',
      isActive: true,
      emailVerified: false,
      phoneVerified: false,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    };

    users.push(newUser);

    // Generate tokens
    const accessToken = generateToken(newUser.id, newUser.email, newUser.role);
    const refreshToken = generateRefreshToken(newUser.id);

    res.status(201).json({
      message: 'User created successfully',
      user: {
        id: newUser.id,
        email: newUser.email,
        name: newUser.name,
        role: newUser.role
      },
      accessToken,
      refreshToken
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      error: 'Registration failed',
      message: error.message
    });
  }
});

// Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        error: 'Email and password are required'
      });
    }

    // Find user
    const user = users.find(u => u.email === email);
    if (!user) {
      return res.status(401).json({
        error: 'Invalid credentials'
      });
    }

    // Check password
    const isPasswordValid = await comparePassword(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        error: 'Invalid credentials'
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(403).json({
        error: 'Account is deactivated'
      });
    }

    // Update last login
    user.lastLoginAt = new Date().toISOString();

    // Generate tokens
    const accessToken = generateToken(user.id, user.email, user.role);
    const refreshToken = generateRefreshToken(user.id);

    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        emailVerified: user.emailVerified,
        phoneVerified: user.phoneVerified
      },
      accessToken,
      refreshToken
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      error: 'Login failed',
      message: error.message
    });
  }
});

// Refresh token
app.post('/api/auth/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        error: 'Refresh token is required'
      });
    }

    const decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
    const user = users.find(u => u.id === decoded.userId);

    if (!user || !user.isActive) {
      return res.status(401).json({
        error: 'Invalid refresh token'
      });
    }

    const accessToken = generateToken(user.id, user.email, user.role);

    res.json({
      accessToken
    });
  } catch (error) {
    res.status(401).json({
      error: 'Invalid refresh token',
      message: error.message
    });
  }
});

// Logout (optional - mainly for client-side token removal)
app.post('/api/auth/logout', authenticate, (req, res) => {
  res.json({
    message: 'Logout successful'
  });
});

// ========== USER ROUTES ==========

// Get user profile
app.get('/api/users/profile', authenticate, (req, res) => {
  const user = users.find(u => u.id === req.user.userId);

  if (!user) {
    return res.status(404).json({
      error: 'User not found'
    });
  }

  res.json({
    id: user.id,
    email: user.email,
    name: user.name,
    phone: user.phone,
    role: user.role,
    emailVerified: user.emailVerified,
    phoneVerified: user.phoneVerified,
    createdAt: user.createdAt
  });
});

// Update user profile
app.put('/api/users/profile', authenticate, async (req, res) => {
  const user = users.find(u => u.id === req.user.userId);

  if (!user) {
    return res.status(404).json({
      error: 'User not found'
    });
  }

  const { name, phone, currentPassword, newPassword } = req.body;

  // Update basic info
  if (name) user.name = name;
  if (phone) user.phone = phone;

  // Update password if provided
  if (currentPassword && newPassword) {
    const isPasswordValid = await comparePassword(currentPassword, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({
        error: 'Current password is incorrect'
      });
    }

    const passwordValidation = validatePassword(newPassword);
    if (!passwordValidation.isValid) {
      return res.status(400).json({
        error: 'New password validation failed',
        errors: passwordValidation.errors
      });
    }

    user.password = await hashPassword(newPassword);
  }

  user.updatedAt = new Date().toISOString();

  res.json({
    message: 'Profile updated successfully',
    user: {
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      role: user.role
    }
  });
});

// ========== EARNINGS ROUTES (V1 Compatible) ==========

// GET all earnings
app.get('/api/v1/earnings', authenticate, (req, res) => {
  const userEarnings = earnings.filter(e =>
    e.userId === req.user.userId || e.userId === 'temp-user'
  );

  res.json({
    success: true,
    data: userEarnings
  });
});

// POST new earning
app.post('/api/v1/earnings', authenticate, (req, res) => {
  const { source, amount, description, date, type } = req.body;

  const newEarning = {
    id: uuidv4(),
    userId: req.user.userId,
    source: source || 'Unknown',
    amount: parseFloat(amount) || 0,
    description: description || '',
    date: date || new Date().toISOString(),
    type: type || 'other',
    createdAt: new Date().toISOString()
  };

  earnings.push(newEarning);

  res.status(201).json({
    success: true,
    data: newEarning
  });
});

// PUT update earning
app.put('/api/v1/earnings/:id', authenticate, (req, res) => {
  const { id } = req.params;
  const index = earnings.findIndex(e =>
    e.id === id && (e.userId === req.user.userId || e.userId === 'temp-user')
  );

  if (index === -1) {
    return res.status(404).json({
      success: false,
      error: 'Earning not found'
    });
  }

  earnings[index] = {
    ...earnings[index],
    ...req.body,
    id: earnings[index].id,
    userId: earnings[index].userId,
    updatedAt: new Date().toISOString()
  };

  res.json({
    success: true,
    data: earnings[index]
  });
});

// DELETE earning
app.delete('/api/v1/earnings/:id', authenticate, (req, res) => {
  const { id } = req.params;
  const index = earnings.findIndex(e =>
    e.id === id && (e.userId === req.user.userId || e.userId === 'temp-user')
  );

  if (index === -1) {
    return res.status(404).json({
      success: false,
      error: 'Earning not found'
    });
  }

  earnings.splice(index, 1);

  res.json({
    success: true,
    message: 'Earning deleted successfully'
  });
});

// GET earnings by date range
app.get('/api/v1/earnings/range', authenticate, (req, res) => {
  const { start, end } = req.query;

  let userEarnings = earnings.filter(e =>
    e.userId === req.user.userId || e.userId === 'temp-user'
  );

  if (start && end) {
    userEarnings = userEarnings.filter(e => {
      const date = new Date(e.date);
      return date >= new Date(start) && date <= new Date(end);
    });
  }

  res.json({
    success: true,
    data: userEarnings
  });
});

// ========== GOALS ROUTES (V1 Compatible) ==========

// GET all goals
app.get('/api/v1/goals', authenticate, (req, res) => {
  const userGoals = goals.filter(g =>
    g.userId === req.user.userId || g.userId === 'temp-user'
  );

  res.json({
    success: true,
    data: userGoals
  });
});

// POST new goal
app.post('/api/v1/goals', authenticate, (req, res) => {
  const { title, targetAmount, deadline, description } = req.body;

  const newGoal = {
    id: uuidv4(),
    userId: req.user.userId,
    title: title || 'New Goal',
    targetAmount: parseFloat(targetAmount) || 0,
    currentAmount: 0,
    deadline: deadline || null,
    description: description || '',
    completed: false,
    createdAt: new Date().toISOString()
  };

  goals.push(newGoal);

  res.status(201).json({
    success: true,
    data: newGoal
  });
});

// PUT update goal
app.put('/api/v1/goals/:id', authenticate, (req, res) => {
  const { id } = req.params;
  const index = goals.findIndex(g =>
    g.id === id && (g.userId === req.user.userId || g.userId === 'temp-user')
  );

  if (index === -1) {
    return res.status(404).json({
      success: false,
      error: 'Goal not found'
    });
  }

  goals[index] = {
    ...goals[index],
    ...req.body,
    id: goals[index].id,
    userId: goals[index].userId,
    updatedAt: new Date().toISOString()
  };

  res.json({
    success: true,
    data: goals[index]
  });
});

// PUT update goal progress
app.put('/api/v1/goals/:id/progress', authenticate, (req, res) => {
  const { id } = req.params;
  const { currentAmount } = req.body;
  const index = goals.findIndex(g =>
    g.id === id && (g.userId === req.user.userId || g.userId === 'temp-user')
  );

  if (index === -1) {
    return res.status(404).json({
      success: false,
      error: 'Goal not found'
    });
  }

  goals[index].currentAmount = parseFloat(currentAmount) || 0;
  goals[index].updatedAt = new Date().toISOString();

  // Check if goal is completed
  if (goals[index].currentAmount >= goals[index].targetAmount) {
    goals[index].completed = true;
    goals[index].completedAt = new Date().toISOString();
  }

  res.json({
    success: true,
    data: goals[index]
  });
});

// DELETE goal
app.delete('/api/v1/goals/:id', authenticate, (req, res) => {
  const { id } = req.params;
  const index = goals.findIndex(g =>
    g.id === id && (g.userId === req.user.userId || g.userId === 'temp-user')
  );

  if (index === -1) {
    return res.status(404).json({
      success: false,
      error: 'Goal not found'
    });
  }

  goals.splice(index, 1);

  res.json({
    success: true,
    message: 'Goal deleted successfully'
  });
});

// ========== STATISTICS ROUTE ==========

app.get('/api/v1/statistics', authenticate, (req, res) => {
  const userEarnings = earnings.filter(e =>
    e.userId === req.user.userId || e.userId === 'temp-user'
  );
  const userGoals = goals.filter(g =>
    g.userId === req.user.userId || g.userId === 'temp-user'
  );

  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
  const startOfWeek = new Date(now);
  startOfWeek.setDate(now.getDate() - now.getDay());
  const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());

  const totalEarnings = userEarnings.reduce((sum, e) => sum + e.amount, 0);

  const monthlyEarnings = userEarnings
    .filter(e => new Date(e.date) >= startOfMonth)
    .reduce((sum, e) => sum + e.amount, 0);

  const weeklyEarnings = userEarnings
    .filter(e => new Date(e.date) >= startOfWeek)
    .reduce((sum, e) => sum + e.amount, 0);

  const todayEarnings = userEarnings
    .filter(e => new Date(e.date) >= startOfDay)
    .reduce((sum, e) => sum + e.amount, 0);

  // 소스별 수익 계산
  const earningsBySource = {};
  userEarnings.forEach(e => {
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
      totalGoals: userGoals.length,
      activeGoals: userGoals.filter(g => !g.completed).length,
      completedGoals: userGoals.filter(g => g.completed).length
    }
  });
});

// ========== SETTINGS ROUTES ==========

app.get('/api/v1/settings', authenticate, (req, res) => {
  // In real app, settings would be per user
  res.json({
    success: true,
    data: settings
  });
});

app.put('/api/v1/settings', authenticate, (req, res) => {
  settings = {
    ...settings,
    ...req.body
  };

  res.json({
    success: true,
    data: settings
  });
});

// ========== TASKS ROUTES ==========

// Get all tasks for user
app.get('/api/tasks', authenticate, (req, res) => {
  const userTasks = tasks.filter(t =>
    t.userId === req.user.userId || t.assignedTo === req.user.userId
  );

  res.json({
    success: true,
    data: userTasks
  });
});

// Create task
app.post('/api/tasks', authenticate, (req, res) => {
  const { title, description, deadline, priority, skills, reward } = req.body;

  const newTask = {
    id: uuidv4(),
    userId: req.user.userId,
    title: title || 'New Task',
    description: description || '',
    deadline: deadline || null,
    priority: priority || 'MEDIUM',
    skills: skills || [],
    reward: parseFloat(reward) || 0,
    status: 'OPEN',
    createdAt: new Date().toISOString()
  };

  tasks.push(newTask);

  res.status(201).json({
    success: true,
    data: newTask
  });
});

// Update task status
app.put('/api/tasks/:id/status', authenticate, (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  const task = tasks.find(t => t.id === id);

  if (!task) {
    return res.status(404).json({
      success: false,
      error: 'Task not found'
    });
  }

  task.status = status;
  task.updatedAt = new Date().toISOString();

  res.json({
    success: true,
    data: task
  });
});

// ========== MARKETPLACE ROUTES ==========

// Get marketplace items
app.get('/api/marketplace', optionalAuth, (req, res) => {
  const { category, minPrice, maxPrice } = req.query;

  let items = marketplace;

  if (category) {
    items = items.filter(i => i.category === category);
  }

  if (minPrice) {
    items = items.filter(i => i.price >= parseFloat(minPrice));
  }

  if (maxPrice) {
    items = items.filter(i => i.price <= parseFloat(maxPrice));
  }

  res.json({
    success: true,
    data: items
  });
});

// Create marketplace listing
app.post('/api/marketplace', authenticate, (req, res) => {
  const { title, description, price, category, images } = req.body;

  const newListing = {
    id: uuidv4(),
    sellerId: req.user.userId,
    title: title || 'New Item',
    description: description || '',
    price: parseFloat(price) || 0,
    category: category || 'other',
    images: images || [],
    status: 'ACTIVE',
    views: 0,
    likes: 0,
    createdAt: new Date().toISOString()
  };

  marketplace.push(newListing);

  res.status(201).json({
    success: true,
    data: newListing
  });
});

// ========== PAYMENTS ROUTES ==========

// Get payment history
app.get('/api/payments', authenticate, (req, res) => {
  const userPayments = payments.filter(p =>
    p.userId === req.user.userId ||
    p.recipientId === req.user.userId
  );

  res.json({
    success: true,
    data: userPayments
  });
});

// Create payment/withdrawal request
app.post('/api/payments/withdraw', authenticate, (req, res) => {
  const { amount, method, accountInfo } = req.body;

  const withdrawalRequest = {
    id: uuidv4(),
    userId: req.user.userId,
    type: 'WITHDRAWAL',
    amount: parseFloat(amount) || 0,
    method: method || 'bank_transfer',
    accountInfo: accountInfo || {},
    status: 'PENDING',
    createdAt: new Date().toISOString()
  };

  payments.push(withdrawalRequest);

  res.status(201).json({
    success: true,
    data: withdrawalRequest,
    message: 'Withdrawal request created successfully'
  });
});

// ========== INITIAL SAMPLE DATA ==========

function initializeSampleData() {
  // Sample users
  const sampleUser = {
    id: 'sample-user-1',
    email: 'test@payday.com',
    password: '$2b$10$YourHashedPasswordHere', // Password: Test1234!
    name: 'Test User',
    role: 'USER',
    isActive: true,
    emailVerified: true,
    phoneVerified: false,
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString()
  };
  users.push(sampleUser);

  // Sample earnings
  earnings = [
    {
      id: uuidv4(),
      userId: 'temp-user',
      source: 'Google AdMob',
      amount: 25000,
      description: '광고 수익',
      date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
      type: 'ad',
      createdAt: new Date().toISOString()
    },
    {
      id: uuidv4(),
      userId: 'temp-user',
      source: 'Survey Time',
      amount: 8500,
      description: '설문조사 10개 완료',
      date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
      type: 'survey',
      createdAt: new Date().toISOString()
    },
    {
      id: uuidv4(),
      userId: 'temp-user',
      source: 'Coupang Partners',
      amount: 15000,
      description: '제휴 마케팅 수익',
      date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
      type: 'affiliate',
      createdAt: new Date().toISOString()
    }
  ];

  // Sample goals
  goals = [
    {
      id: uuidv4(),
      userId: 'temp-user',
      title: '이번달 10만원 달성',
      targetAmount: 100000,
      currentAmount: 48500,
      deadline: new Date(Date.now() + 20 * 24 * 60 * 60 * 1000).toISOString(),
      description: '월 목표 수익 달성하기',
      completed: false,
      createdAt: new Date().toISOString()
    },
    {
      id: uuidv4(),
      userId: 'temp-user',
      title: '아이패드 구매 자금',
      targetAmount: 1000000,
      currentAmount: 250000,
      deadline: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString(),
      description: '아이패드 프로 구매를 위한 저축',
      completed: false,
      createdAt: new Date().toISOString()
    }
  ];

  // Sample tasks
  tasks = [
    {
      id: uuidv4(),
      userId: 'temp-user',
      title: '앱 리뷰 작성',
      description: '지정된 앱 5개에 대한 상세 리뷰 작성',
      deadline: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000).toISOString(),
      priority: 'HIGH',
      skills: ['writing', 'review'],
      reward: 5000,
      status: 'OPEN',
      createdAt: new Date().toISOString()
    }
  ];

  // Sample marketplace items
  marketplace = [
    {
      id: uuidv4(),
      sellerId: 'sample-user-1',
      title: '중고 아이폰 12',
      description: '상태 좋은 아이폰 12 판매합니다',
      price: 500000,
      category: 'electronics',
      images: [],
      status: 'ACTIVE',
      views: 45,
      likes: 12,
      createdAt: new Date().toISOString()
    }
  ];
}

// Initialize sample data on server start
initializeSampleData();

// ========== ERROR HANDLING ==========

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    error: 'Something went wrong!',
    message: err.message
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    error: 'Endpoint not found',
    path: req.path
  });
});

// ========== START SERVER ==========

app.listen(PORT, () => {
  console.log(`PayDay Integrated Backend API running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
  console.log(`API Base URL: http://localhost:${PORT}`);
  console.log('');
  console.log('Authentication Methods:');
  console.log('1. JWT Token: Authorization: Bearer <token>');
  console.log('2. API Key (legacy): X-API-Key: temporary-api-key');
  console.log('');
  console.log('Test Credentials:');
  console.log('Email: test@payday.com');
  console.log('Password: Test1234!');
});

module.exports = app;