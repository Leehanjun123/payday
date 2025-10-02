const { Pool } = require('pg');

// The pool will use the environment variables PGHOST, PGUSER, PGDATABASE, PGPASSWORD, PGPORT
// which are automatically set by Railway or can be set in docker-compose.
// For local development, DATABASE_URL is used.
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false,
});

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool: pool
};
