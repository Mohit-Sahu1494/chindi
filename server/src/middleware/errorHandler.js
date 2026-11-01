const { sendError } = require('../utils/apiResponse');

function errorHandler(err, req, res, next) {
  console.error(`[Error Handler] ${req.method} ${req.url}:`, err);

  // Mongoose duplicate key error (E11000)
  if (err.code === 11000) {
    const field = Object.keys(err.keyValue || {})[0] || 'field';
    const message = field === 'emailOrMobile'
      ? 'This email or mobile number is already registered'
      : `${field} already exists. Please use a unique value.`;
    return sendError(res, message, 409);
  }

  // Mongoose CastError (invalid ObjectId)
  if (err.name === 'CastError') {
    return sendError(res, `Invalid ID format for ${err.path}`, 400);
  }

  // Mongoose ValidationError
  if (err.name === 'ValidationError') {
    const errors = Object.values(err.errors).map(e => ({
      field: e.path,
      message: e.message,
    }));
    const message = errors.map(e => e.message).join('. ');
    return sendError(res, message || 'Validation error', 400, errors);
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    return sendError(res, 'Invalid or expired token', 401);
  }

  // Default server error
  const statusCode = err.statusCode || 500;
  const message = err.message || 'Internal Server Error';
  return sendError(res, message, statusCode, process.env.NODE_ENV === 'development' ? err.stack : null);
}

module.exports = {
  errorHandler,
};
