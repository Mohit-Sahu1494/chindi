const mongoose = require('mongoose');
const { sendError } = require('../utils/apiResponse');
const { connectDB } = require('../config/db');

/**
 * Middleware that verifies MongoDB is active and connected before executing any database operation.
 * Prevents queries (like User.findOne) from hanging in Mongoose buffer and timing out.
 */
async function checkDbConnection(req, res, next) {
  // Allow health check to bypass DB check
  if (req.path === '/health' || req.path === '/api/health') {
    return next();
  }

  // Bypass in test environment if mocked
  if (process.env.NODE_ENV === 'test') {
    return next();
  }

  // 1. If already connected (readyState 1), proceed immediately
  if (mongoose.connection.readyState === 1) {
    return next();
  }

  // 2. If currently connecting (readyState 2), wait briefly for completion
  if (mongoose.connection.readyState === 2) {
    try {
      await new Promise((resolve, reject) => {
        const timer = setTimeout(() => reject(new Error('Connection timeout')), 3500);
        mongoose.connection.once('connected', () => {
          clearTimeout(timer);
          resolve();
        });
        mongoose.connection.once('error', (err) => {
          clearTimeout(timer);
          reject(err);
        });
      });
      if (mongoose.connection.readyState === 1) {
        return next();
      }
    } catch (_) {}
  }

  // 3. If disconnected (readyState 0), attempt single reconnect
  if (mongoose.connection.readyState === 0) {
    try {
      await connectDB(1);
      if (mongoose.connection.readyState === 1) {
        return next();
      }
    } catch (_) {}
  }

  // 4. Return clean, user-facing 503 error instead of 10s buffer timeout
  return sendError(
    res,
    'Database connection sthapit nahi ho saka. Kripya internet check karein ya kuch second baad punah koshish karein.',
    503
  );
}

module.exports = {
  checkDbConnection,
};
