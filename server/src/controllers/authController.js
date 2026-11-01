const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { z } = require('zod');
const User = require('../models/User');
const { jwtSecret, jwtExpiresIn } = require('../config/env');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const { registerFCMToken, removeFCMToken } = require('../services/notificationService');

// Validation schemas
const signupSchema = z.object({
  name: z.string().trim().min(2, 'Name must be at least 2 characters'),
  emailOrMobile: z.string().trim().min(3, 'Email or mobile number is required'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
});

const loginSchema = z.object({
  emailOrMobile: z.string().trim().min(3, 'Email or mobile number is required'),
  password: z.string().min(1, 'Password is required'),
});

const fcmTokenSchema = z.object({
  fcmToken: z.string().min(1, 'FCM token is required'),
});

function generateToken(user) {
  return jwt.sign({ userId: user._id, emailOrMobile: user.emailOrMobile }, jwtSecret, {
    expiresIn: jwtExpiresIn,
  });
}

async function signup(req, res, next) {
  try {
    const { name, emailOrMobile, password } = req.body;
    const cleanIdentifier = emailOrMobile.trim().toLowerCase();

    const existing = await User.findOne({ emailOrMobile: cleanIdentifier });
    if (existing) {
      return sendError(res, 'User with this email or mobile already exists', 409);
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const user = await User.create({
      name: name.trim(),
      emailOrMobile: cleanIdentifier,
      passwordHash,
    });

    const token = generateToken(user);

    return sendSuccess(res, { token, user }, 'Account created successfully', 201);
  } catch (error) {
    next(error);
  }
}

async function login(req, res, next) {
  try {
    const { emailOrMobile, password } = req.body;
    const cleanIdentifier = emailOrMobile.trim().toLowerCase();

    const user = await User.findOne({ emailOrMobile: cleanIdentifier });
    if (!user) {
      return sendError(res, 'Email not found', 404);
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      return sendError(res, 'Email and password is incorrect', 401);
    }

    const token = generateToken(user);

    return sendSuccess(res, { token, user }, 'Logged in successfully');
  } catch (error) {
    next(error);
  }
}

async function getMe(req, res, next) {
  try {
    return sendSuccess(res, { user: req.user }, 'User profile retrieved');
  } catch (error) {
    next(error);
  }
}

async function handleRegisterFCMToken(req, res, next) {
  try {
    const { fcmToken } = req.body;
    await registerFCMToken(req.user._id, fcmToken);
    return sendSuccess(res, null, 'FCM token registered successfully');
  } catch (error) {
    next(error);
  }
}

async function handleRemoveFCMToken(req, res, next) {
  try {
    const { fcmToken } = req.body;
    await removeFCMToken(req.user._id, fcmToken);
    return sendSuccess(res, null, 'FCM token removed successfully');
  } catch (error) {
    next(error);
  }
}

module.exports = {
  signupSchema,
  loginSchema,
  fcmTokenSchema,
  signup,
  login,
  getMe,
  handleRegisterFCMToken,
  handleRemoveFCMToken,
};
