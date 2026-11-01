const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../config/env');
const User = require('../models/User');
const { sendError } = require('../utils/apiResponse');

async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return sendError(res, 'Authentication token missing or invalid', 401);
    }

    const token = authHeader.split(' ')[1];
    let decoded;
    try {
      decoded = jwt.verify(token, jwtSecret);
    } catch (err) {
      return sendError(res, 'Token expired or invalid', 401);
    }

    const user = await User.findById(decoded.userId).select('-passwordHash');
    if (!user) {
      return sendError(res, 'User no longer exists', 401);
    }

    req.user = user;
    next();
  } catch (error) {
    return sendError(res, 'Authentication error', 401, error.message);
  }
}

module.exports = {
  authenticate,
};
