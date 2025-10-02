const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

// JWT Secret (실제 배포시 환경변수로 관리)
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'your-refresh-secret-key';

// Middleware
app.use(cors());
app.use(express.json());




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
      return res.status(401).json({ error: 'Authentication required', message: 'No token provided' });
    }

    const decoded = verifyToken(token);

    // 사용자 확인
    const result = await db.query('SELECT id, email, role, is_active FROM users WHERE id = $1', [decoded.userId]);
    const user = result.rows[0];

    if (!user || !user.is_active) {
      return res.status(401).json({ error: 'Invalid token', message: 'User not found or inactive' });
    }

    req.user = {
      userId: user.id,
      email: user.email,
      role: user.role
    };

    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token', message: error.message });
  }
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
      return res.status(400).json({ error: 'Missing required fields', required: ['email', 'password', 'name'] });
    }
    if (!validateEmail(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }
    const passwordValidation = validatePassword(password);
    if (!passwordValidation.isValid) {
      return res.status(400).json({ error: 'Password validation failed', errors: passwordValidation.errors });
    }

    // Check if user exists
    const existingUser = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    if (existingUser.rows.length > 0) {
      return res.status(409).json({ error: 'User already exists' });
    }

    // Create user
    const hashedPassword = await hashPassword(password);
    const query = `
      INSERT INTO users(email, password, name, phone, role, is_active, email_verified, phone_verified)
      VALUES($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING id, email, name, role;
    `;
    const values = [email, hashedPassword, name, phone, 'USER', true, false, false];
    const result = await db.query(query, values);
    const newUser = result.rows[0];

    // Generate tokens
    const accessToken = generateToken(newUser.id, newUser.email, newUser.role);
    const refreshToken = generateRefreshToken(newUser.id);

    res.status(201).json({
      message: 'User created successfully',
      user: newUser,
      accessToken,
      refreshToken
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Registration failed', message: error.message });
  }
});

// Login
app.post('/api/auth/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required' });
    }

    // Find user
    const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    const user = result.rows[0];

    if (!user) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Check password
    const isPasswordValid = await comparePassword(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Check if user is active
    if (!user.is_active) {
      return res.status(403).json({ error: 'Account is deactivated' });
    }

    // Update last login
    await db.query('UPDATE users SET last_login_at = NOW() WHERE id = $1', [user.id]);

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
        emailVerified: user.email_verified,
        phoneVerified: user.phone_verified
      },
      accessToken,
      refreshToken
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed', message: error.message });
  }
});

// Refresh token
app.post('/api/auth/refresh', async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ error: 'Refresh token is required' });
    }

    const decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
    const result = await db.query('SELECT id, email, role, is_active FROM users WHERE id = $1', [decoded.userId]);
    const user = result.rows[0];

    if (!user || !user.is_active) {
      return res.status(401).json({ error: 'Invalid refresh token' });
    }

    const accessToken = generateToken(user.id, user.email, user.role);

    res.json({ accessToken });
  } catch (error) {
    res.status(401).json({ error: 'Invalid refresh token', message: error.message });
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
app.get('/api/users/profile', authenticate, async (req, res) => {
  try {
    const result = await db.query('SELECT id, email, name, phone, role, email_verified, phone_verified, created_at FROM users WHERE id = $1', [req.user.userId]);
    const user = result.rows[0];

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Failed to get user profile', message: error.message });
  }
});

// Update user profile
app.put('/api/users/profile', authenticate, async (req, res) => {
  try {
    const { name, phone } = req.body;
    let updateQuery = 'UPDATE users SET ';
    const queryParams = [];
    let paramIndex = 1;

    if (name) {
      updateQuery += `name = $${paramIndex++}, `;
      queryParams.push(name);
    }
    if (phone) {
      updateQuery += `phone = $${paramIndex++}, `;
      queryParams.push(phone);
    }

    if (queryParams.length === 0) {
      return res.status(400).json({ error: 'No update fields provided' });
    }

    updateQuery = updateQuery.slice(0, -2); // Remove trailing comma and space
    updateQuery += ` WHERE id = $${paramIndex}`;
    queryParams.push(req.user.userId);

    await db.query(updateQuery, queryParams);

    res.json({ message: 'Profile updated successfully' });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile', message: error.message });
  }
});

// ========== USER ROUTES ==========

// Get user profile
app.get('/api/users/profile', authenticate, async (req, res) => {
  try {
    const result = await db.query('SELECT id, email, name, phone, role, email_verified, phone_verified, created_at FROM users WHERE id = $1', [req.user.userId]);
    const user = result.rows[0];

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json(user);
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({ error: 'Failed to get user profile', message: error.message });
  }
});

// Update user profile
app.put('/api/users/profile', authenticate, async (req, res) => {
  try {
    const { name, phone, currentPassword, newPassword } = req.body;

    // First, get the current user data
    const userResult = await db.query('SELECT * FROM users WHERE id = $1', [req.user.userId]);
    const user = userResult.rows[0];

    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    let updateQuery = 'UPDATE users SET ';
    const queryParams = [];
    let paramIndex = 1;

    if (name) {
      updateQuery += `name = $${paramIndex++}, `;
      queryParams.push(name);
    }
    if (phone) {
      updateQuery += `phone = $${paramIndex++}, `;
      queryParams.push(phone);
    }

    // Update password if provided
    if (currentPassword && newPassword) {
      const isPasswordValid = await comparePassword(currentPassword, user.password);
      if (!isPasswordValid) {
        return res.status(401).json({ error: 'Current password is incorrect' });
      }

      const passwordValidation = validatePassword(newPassword);
      if (!passwordValidation.isValid) {
        return res.status(400).json({ error: 'New password validation failed', errors: passwordValidation.errors });
      }

      const hashedPassword = await hashPassword(newPassword);
      updateQuery += `password = $${paramIndex++}, `;
      queryParams.push(hashedPassword);
    }

    // Only proceed if there is something to update
    if (queryParams.length === 0) {
      return res.status(400).json({ error: 'No update fields provided' });
    }

    updateQuery += `updated_at = NOW() WHERE id = $${paramIndex}`;
    queryParams.push(req.user.userId);

    const result = await db.query(updateQuery, queryParams);
    const updatedUser = result.rows[0];

    res.json({
      message: 'Profile updated successfully',
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Failed to update profile', message: error.message });
  }
});

// ========== EARNINGS ROUTES (V1 Compatible) ==========

// GET all earnings
app.get('/api/v1/earnings', authenticate, async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM earnings WHERE user_id = $1 ORDER BY date DESC', [req.user.userId]);
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Get earnings error:', error);
    res.status(500).json({ success: false, error: 'Failed to get earnings', message: error.message });
  }
});

// POST new earning
app.post('/api/v1/earnings', authenticate, async (req, res) => {
  try {
    const { source, amount, description, date, type } = req.body;
    const query = `
      INSERT INTO earnings(user_id, source, amount, description, date, type)
      VALUES($1, $2, $3, $4, $5, $6)
      RETURNING *;
    `;
    const values = [req.user.userId, source || 'Unknown', parseFloat(amount) || 0, description || '', date || new Date().toISOString(), type || 'other'];
    const result = await db.query(query, values);

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Create earning error:', error);
    res.status(500).json({ success: false, error: 'Failed to create earning', message: error.message });
  }
});

// PUT update earning
app.put('/api/v1/earnings/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { source, amount, description, date, type } = req.body;

    // For a PUT request, we can update all provided fields.
    const query = `
      UPDATE earnings
      SET source = $1, amount = $2, description = $3, date = $4, type = $5
      WHERE id = $6 AND user_id = $7
      RETURNING *;
    `;
    const values = [source, parseFloat(amount), description, date, type, id, req.user.userId];
    const result = await db.query(query, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Earning not found or user not authorized' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Update earning error:', error);
    res.status(500).json({ success: false, error: 'Failed to update earning', message: error.message });
  }
});

// DELETE earning
app.delete('/api/v1/earnings/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query(`DELETE FROM earnings WHERE id = $1 AND user_id = $2 RETURNING id`, [id, req.user.userId]);

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, error: 'Earning not found or user not authorized' });
    }

    res.json({ success: true, message: 'Earning deleted successfully' });
  } catch (error) {
    console.error('Delete earning error:', error);
    res.status(500).json({ success: false, error: 'Failed to delete earning', message: error.message });
  }
});

// GET earnings by date range
app.get('/api/v1/earnings/range', authenticate, async (req, res) => {
  try {
    const { start, end } = req.query;
    let query = `SELECT * FROM earnings WHERE user_id = $1`;
    const values = [req.user.userId];

    if (start && end) {
      query += ` AND date >= $2 AND date <= $3`;
      values.push(start, end);
    }
    query += ` ORDER BY date DESC`;

    const result = await db.query(query, values);
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Get earnings range error:', error);
    res.status(500).json({ success: false, error: 'Failed to get earnings by range', message: error.message });
  }
});

// ========== GOALS ROUTES (V1 Compatible) ==========

// GET all goals
app.get('/api/v1/goals', authenticate, async (req, res) => {
  try {
    const result = await db.query(`SELECT * FROM goals WHERE user_id = $1 ORDER BY created_at DESC`, [req.user.userId]);
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Get goals error:', error);
    res.status(500).json({ success: false, error: 'Failed to get goals', message: error.message });
  }
});

// POST new goal
app.post('/api/v1/goals', authenticate, async (req, res) => {
  try {
    const { title, targetAmount, deadline, description } = req.body;
    const query = `
      INSERT INTO goals(user_id, title, target_amount, deadline, description)
      VALUES($1, $2, $3, $4, $5)
      RETURNING *;
    `;
    const values = [req.user.userId, title || 'New Goal', parseFloat(targetAmount) || 0, deadline || null, description || ''];
    const result = await db.query(query, values);

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Create goal error:', error);
    res.status(500).json({ success: false, error: 'Failed to create goal', message: error.message });
  }
});

// PUT update goal
app.put('/api/v1/goals/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { title, targetAmount, deadline, description, currentAmount, completed } = req.body;

    const query = `
      UPDATE goals
      SET title = $1, target_amount = $2, deadline = $3, description = $4, current_amount = $5, completed = $6, updated_at = NOW()
      WHERE id = $7 AND user_id = $8
      RETURNING *;
    `;
    const values = [title, parseFloat(targetAmount), deadline, description, parseFloat(currentAmount), completed, id, req.user.userId];
    const result = await db.query(query, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Goal not found or user not authorized' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Update goal error:', error);
    res.status(500).json({ success: false, error: 'Failed to update goal', message: error.message });
  }
});

// PUT update goal progress
app.put('/api/v1/goals/:id/progress', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { currentAmount } = req.body;

    if (currentAmount === undefined) {
      return res.status(400).json({ success: false, error: 'currentAmount is required' });
    }

    const getGoalQuery = `SELECT target_amount FROM goals WHERE id = $1 AND user_id = $2`;
    const goalResult = await db.query(getGoalQuery, [id, req.user.userId]);

    if (goalResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Goal not found or user not authorized' });
    }

    const targetAmount = goalResult.rows[0].target_amount;
    const isCompleted = parseFloat(currentAmount) >= targetAmount;

    const updateQuery = `
      UPDATE goals
      SET current_amount = $1, completed = $2, completed_at = CASE WHEN $2 = true THEN NOW() ELSE completed_at END, updated_at = NOW()
      WHERE id = $3 AND user_id = $4
      RETURNING *;
    `;
    const values = [parseFloat(currentAmount), isCompleted, id, req.user.userId];
    const result = await db.query(updateQuery, values);

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Update goal progress error:', error);
    res.status(500).json({ success: false, error: 'Failed to update goal progress', message: error.message });
  }
});

// DELETE goal
app.delete('/api/v1/goals/:id', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query(`DELETE FROM goals WHERE id = $1 AND user_id = $2 RETURNING id`, [id, req.user.userId]);

    if (result.rowCount === 0) {
      return res.status(404).json({ success: false, error: 'Goal not found or user not authorized' });
    }

    res.json({ success: true, message: 'Goal deleted successfully' });
  } catch (error) {
    console.error('Delete goal error:', error);
    res.status(500).json({ success: false, error: 'Failed to delete goal', message: error.message });
  }
});

// ========== STATISTICS ROUTE ==========

app.get('/api/v1/statistics', authenticate, async (req, res) => {
  try {
    const userId = req.user.userId;

    const earningsQuery = `
      SELECT
        COALESCE(SUM(amount), 0) AS total,
        COALESCE(SUM(CASE WHEN date >= date_trunc('month', NOW()) THEN amount ELSE 0 END), 0) AS monthly,
        COALESCE(SUM(CASE WHEN date >= date_trunc('week', NOW()) THEN amount ELSE 0 END), 0) AS weekly,
        COALESCE(SUM(CASE WHEN date >= date_trunc('day', NOW()) THEN amount ELSE 0 END), 0) AS today
      FROM earnings
      WHERE user_id = $1;
    `;

    const goalsQuery = `
      SELECT
        COUNT(*) AS total,
        COUNT(CASE WHEN completed = false THEN 1 END) AS active,
        COUNT(CASE WHEN completed = true THEN 1 END) AS completed
      FROM goals
      WHERE user_id = $1;
    `;

    const sourceQuery = `
      SELECT type, SUM(amount) as total
      FROM earnings
      WHERE user_id = $1
      GROUP BY type;
    `;

    const [earningsResult, goalsResult, sourceResult] = await Promise.all([
      db.query(earningsQuery, [userId]),
      db.query(goalsQuery, [userId]),
      db.query(sourceQuery, [userId]),
    ]);

    const earningsBySource = sourceResult.rows.reduce((acc, row) => {
      acc[row.type] = row.total;
      return acc;
    }, {});

    res.json({
      success: true,
      data: {
        totalEarnings: earningsResult.rows[0].total,
        monthlyEarnings: earningsResult.rows[0].monthly,
        weeklyEarnings: earningsResult.rows[0].weekly,
        todayEarnings: earningsResult.rows[0].today,
        earningsBySource,
        totalGoals: goalsResult.rows[0].total,
        activeGoals: goalsResult.rows[0].active,
        completedGoals: goalsResult.rows[0].completed,
      }
    });

  } catch (error) {
    console.error('Statistics error:', error);
    res.status(500).json({ success: false, error: 'Failed to get statistics', message: error.message });
  }
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

// Get all OPEN tasks (public)
app.get('/api/tasks', async (req, res) => {
  try {
    const result = await db.query(`SELECT * FROM tasks WHERE status = 'OPEN' ORDER BY created_at DESC`);
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Get open tasks error:', error);
    res.status(500).json({ success: false, error: 'Failed to get tasks', message: error.message });
  }
});

// Create task
app.post('/api/tasks', authenticate, async (req, res) => {
  try {
    const { title, description, deadline, priority, skills, reward } = req.body;
    const query = `
      INSERT INTO tasks(user_id, title, description, deadline, priority, skills, reward)
      VALUES($1, $2, $3, $4, $5, $6, $7)
      RETURNING *;
    `;
    const values = [req.user.userId, title || 'New Task', description || '', deadline || null, priority || 'MEDIUM', skills || [], parseFloat(reward) || 0];
    const result = await db.query(query, values);

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Create task error:', error);
    res.status(500).json({ success: false, error: 'Failed to create task', message: error.message });
  }
});

// Update task status
app.put('/api/tasks/:id/status', authenticate, async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status) {
      return res.status(400).json({ success: false, error: 'Status is required' });
    }

    const query = `UPDATE tasks SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *`;
    const values = [status, id];
    const result = await db.query(query, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Task not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Update task status error:', error);
    res.status(500).json({ success: false, error: 'Failed to update task status', message: error.message });
  }
});

// Assign task to self
app.patch('/api/tasks/:id/assign', authenticate, async (req, res) => {
  try {
    const { id } = req.params; // Task ID
    const applicantId = req.user.userId; // User ID from token

    // Atomically update the task if it is still OPEN
    const query = `
      UPDATE tasks
      SET assigned_to = $1, status = 'IN_PROGRESS', updated_at = NOW()
      WHERE id = $2 AND status = 'OPEN'
      RETURNING *;
    `;
    const values = [applicantId, id];
    const result = await db.query(query, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Task not found or is already taken' });
    }

    res.json({ success: true, message: 'Task assigned successfully', data: result.rows[0] });
  } catch (error) {
    console.error('Assign task error:', error);
    res.status(500).json({ success: false, error: 'Failed to assign task', message: error.message });
  }
});


// ========== MARKETPLACE ROUTES ==========

// Get marketplace items
app.get('/api/marketplace', async (req, res) => {
  try {
    const { category, minPrice, maxPrice } = req.query;
    let query = `SELECT * FROM marketplace WHERE status = 'ACTIVE'`;
    const values = [];
    let valueIndex = 1;

    if (category) {
      query += ` AND category = $${valueIndex++}`;
      values.push(category);
    }
    if (minPrice) {
      query += ` AND price >= $${valueIndex++}`;
      values.push(parseFloat(minPrice));
    }
    if (maxPrice) {
      query += ` AND price <= $${valueIndex++}`;
      values.push(parseFloat(maxPrice));
    }

    query += ` ORDER BY created_at DESC`;

    const result = await db.query(query, values);
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Get marketplace error:', error);
    res.status(500).json({ success: false, error: 'Failed to get marketplace items', message: error.message });
  }
});

// Create marketplace listing
app.post('/api/marketplace', authenticate, async (req, res) => {
  try {
    const { title, description, price, category, images } = req.body;
    const query = `
      INSERT INTO marketplace(seller_id, title, description, price, category, images)
      VALUES($1, $2, $3, $4, $5, $6)
      RETURNING *;
    `;
    const values = [req.user.userId, title || 'New Item', description || '', parseFloat(price) || 0, category || 'other', images || []];
    const result = await db.query(query, values);

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (error) {
    console.error('Create marketplace listing error:', error);
    res.status(500).json({ success: false, error: 'Failed to create marketplace listing', message: error.message });
  }
});

// ========== PAYDAY CASH SYSTEM ROUTES ==========

// Device-based authentication (for guest users)
app.post('/auth/login', async (req, res) => {
  try {
    const { deviceId, email, phone, firebaseUid } = req.body;

    if (!deviceId) {
      return res.status(400).json({ error: 'Device ID is required' });
    }

    // Check if user exists by device ID
    let userQuery = 'SELECT * FROM users WHERE device_id = $1';
    let userResult = await db.query(userQuery, [deviceId]);

    if (userResult.rows.length === 0) {
      // Create new user with device ID
      const referralCode = Math.random().toString(36).substring(2, 8).toUpperCase();
      const insertQuery = `
        INSERT INTO users(device_id, email, phone, firebase_uid, referral_code, cash_balance, total_earned)
        VALUES($1, $2, $3, $4, $5, 0.00, 0.00)
        RETURNING *
      `;
      userResult = await db.query(insertQuery, [deviceId, email, phone, firebaseUid, referralCode]);
    } else if (email || phone || firebaseUid) {
      // Update existing user with new auth info
      const updateQuery = `
        UPDATE users SET email = COALESCE($2, email), phone = COALESCE($3, phone),
                        firebase_uid = COALESCE($4, firebase_uid), last_login_at = NOW()
        WHERE device_id = $1
        RETURNING *
      `;
      userResult = await db.query(updateQuery, [deviceId, email, phone, firebaseUid]);
    }

    const user = userResult.rows[0];
    const token = generateToken(user.id, user.email || 'guest');

    res.json({
      user: {
        id: user.id,
        device_id: user.device_id,
        email: user.email,
        referral_code: user.referral_code,
        created_at: user.created_at
      },
      auth_token: token
    });
  } catch (error) {
    console.error('PayDay auth error:', error);
    res.status(500).json({ error: 'Authentication failed', message: error.message });
  }
});

// Get user balance
app.get('/users/:userId/balance', authenticate, async (req, res) => {
  try {
    const { userId } = req.params;
    const result = await db.query('SELECT cash_balance FROM users WHERE id = $1', [userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({ balance: result.rows[0].cash_balance });
  } catch (error) {
    console.error('Get balance error:', error);
    res.status(500).json({ error: 'Failed to get balance', message: error.message });
  }
});

// Record transaction/earning
app.post('/transactions', authenticate, async (req, res) => {
  try {
    const { user_id, type, earning_method, amount, description, metadata, ad_unit_id, ad_impression_id } = req.body;

    // Insert transaction
    const transactionQuery = `
      INSERT INTO transactions(user_id, type, earning_method, amount, description, metadata, ad_unit_id, ad_impression_id)
      VALUES($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *
    `;
    const transactionResult = await db.query(transactionQuery, [
      user_id, type, earning_method, amount, description,
      JSON.stringify(metadata || {}), ad_unit_id, ad_impression_id
    ]);

    // Update user balance if earning
    if (type === 'earn') {
      await db.query(
        'UPDATE users SET cash_balance = cash_balance + $1, total_earned = total_earned + $1 WHERE id = $2',
        [amount, user_id]
      );
    }

    res.status(201).json({
      success: true,
      transaction: transactionResult.rows[0],
      message: 'Transaction recorded successfully'
    });
  } catch (error) {
    console.error('Record transaction error:', error);
    res.status(500).json({ error: 'Failed to record transaction', message: error.message });
  }
});

// AdMob revenue verification
app.post('/admob/verify', authenticate, async (req, res) => {
  try {
    const { user_id, ad_unit_id, impression_id, revenue_usd } = req.body;

    // Mock verification - in real app, verify with AdMob API
    const exchangeRate = 1300; // USD to KRW
    const userSharePercentage = 0.5;
    const revenueKrw = revenue_usd * exchangeRate;
    const userRewardKrw = revenueKrw * userSharePercentage;

    // Record AdMob sync
    const syncQuery = `
      INSERT INTO admob_revenue_sync(ad_unit_id, impression_id, revenue_usd, revenue_krw, exchange_rate, user_share, user_id)
      VALUES($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `;
    await db.query(syncQuery, [ad_unit_id, impression_id, revenue_usd, revenueKrw, exchangeRate, userRewardKrw, user_id]);

    res.json({
      verified: true,
      user_reward_krw: userRewardKrw,
      exchange_rate: exchangeRate,
      revenue_usd: revenue_usd
    });
  } catch (error) {
    console.error('AdMob verification error:', error);
    res.status(500).json({ error: 'Verification failed', message: error.message });
  }
});

// Check daily limits
app.get('/users/:userId/daily-limits/:earningMethod', authenticate, async (req, res) => {
  try {
    const { userId, earningMethod } = req.params;
    const today = new Date().toISOString().split('T')[0];

    const result = await db.query(
      'SELECT count FROM daily_limits WHERE user_id = $1 AND earning_method = $2 AND date = $3',
      [userId, earningMethod, today]
    );

    // Default limits
    const defaultLimits = {
      'ad_view': 20,
      'walking': 50,
      'daily_login': 1
    };

    const currentCount = result.rows.length > 0 ? result.rows[0].count : 0;
    const limit = defaultLimits[earningMethod] || 10;

    res.json({ can_earn: currentCount < limit, current: currentCount, limit });
  } catch (error) {
    console.error('Daily limit check error:', error);
    res.status(500).json({ error: 'Failed to check daily limit', message: error.message });
  }
});

// Get withdrawal requests
app.get('/users/:userId/withdrawals', authenticate, async (req, res) => {
  try {
    const { userId } = req.params;
    const result = await db.query(
      'SELECT * FROM withdrawal_requests WHERE user_id = $1 ORDER BY created_at DESC',
      [userId]
    );
    res.json({ withdrawals: result.rows });
  } catch (error) {
    console.error('Get withdrawals error:', error);
    res.status(500).json({ error: 'Failed to get withdrawals', message: error.message });
  }
});

// Create withdrawal request
app.post('/withdrawals', authenticate, async (req, res) => {
  try {
    const { user_id, amount, bank_name, account_number, account_holder_name, pin } = req.body;

    // Basic validation
    if (amount < 10000) {
      return res.status(400).json({ error: 'Minimum withdrawal amount is 10,000 KRW' });
    }

    // Check user balance
    const balanceResult = await db.query('SELECT cash_balance FROM users WHERE id = $1', [user_id]);
    if (balanceResult.rows.length === 0 || balanceResult.rows[0].cash_balance < amount) {
      return res.status(400).json({ error: 'Insufficient balance' });
    }

    // Calculate fee (3%)
    const fee = amount * 0.03;
    const netAmount = amount - fee;

    // Create withdrawal request
    const withdrawalQuery = `
      INSERT INTO withdrawal_requests(user_id, amount, fee, net_amount, bank_name, account_number_encrypted, account_holder_name)
      VALUES($1, $2, $3, $4, $5, $6, $7)
      RETURNING *
    `;
    const result = await db.query(withdrawalQuery, [
      user_id, amount, fee, netAmount, bank_name, account_number, account_holder_name
    ]);

    // Deduct from user balance (pending withdrawal)
    await db.query('UPDATE users SET cash_balance = cash_balance - $1 WHERE id = $2', [amount, user_id]);

    res.status(201).json({
      withdrawal_request: result.rows[0],
      message: 'Withdrawal request created successfully'
    });
  } catch (error) {
    console.error('Create withdrawal error:', error);
    res.status(500).json({ error: 'Failed to create withdrawal request', message: error.message });
  }
});

// Get system settings
app.get('/system/settings', async (req, res) => {
  try {
    const result = await db.query('SELECT key, value FROM system_settings');
    const settings = {};
    result.rows.forEach(row => {
      settings[row.key] = row.value;
    });
    res.json({ settings });
  } catch (error) {
    console.error('Get system settings error:', error);
    res.status(500).json({ error: 'Failed to get system settings', message: error.message });
  }
});

// ========== LEGACY PAYMENTS ROUTES ==========

// Get payment history
app.get('/api/payments', authenticate, async (req, res) => {
  try {
    const result = await db.query(`SELECT * FROM payments WHERE user_id = $1 ORDER BY created_at DESC`, [req.user.userId]);
    res.json({ success: true, data: result.rows });
  } catch (error) {
    console.error('Get payments error:', error);
    res.status(500).json({ success: false, error: 'Failed to get payments', message: error.message });
  }
});

// Create payment/withdrawal request
app.post('/api/payments/withdraw', authenticate, async (req, res) => {
  try {
    const { amount, method, accountInfo } = req.body;
    const query = `
      INSERT INTO payments(user_id, type, amount, method, account_info)
      VALUES($1, $2, $3, $4, $5)
      RETURNING *;
    `;
    const values = [req.user.userId, 'WITHDRAWAL', parseFloat(amount) || 0, method || 'bank_transfer', accountInfo || {}];
    const result = await db.query(query, values);

    res.status(201).json({ success: true, data: result.rows[0], message: 'Withdrawal request created successfully' });
  } catch (error) {
    console.error('Create withdrawal error:', error);
    res.status(500).json({ success: false, error: 'Failed to create withdrawal request', message: error.message });
  }
});





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