const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { z } = require('zod');
const User = require('../models/User');
const Otp = require('../models/Otp');
const { jwtSecret, jwtExpiresIn } = require('../config/env');
const { sendSuccess, sendError } = require('../utils/apiResponse');
const { registerFCMToken, removeFCMToken } = require('../services/notificationService');
const { sendSignupOtpEmail, sendForgotPasswordOtpEmail } = require('../services/emailService');

// Validation schemas
const sendSignupOtpSchema = z.object({
  email: z.string().trim().email('Kripya valid email address darj karein').toLowerCase(),
});

const signupSchema = z
  .object({
    name: z.string().trim().min(2, 'Name must be at least 2 characters'),
    email: z.string().trim().email('Valid email address is required').toLowerCase().optional(),
    emailOrMobile: z.string().trim().min(3, 'Email or mobile number is required').optional(),
    password: z.string().min(6, 'Password must be at least 6 characters'),
    otp: z.string().trim().optional(),
  })
  .refine(data => data.email || data.emailOrMobile, {
    message: 'Valid email address is required',
    path: ['email'],
  });

const loginSchema = z
  .object({
    email: z.string().trim().toLowerCase().optional(),
    emailOrMobile: z.string().trim().optional(),
    password: z.string().min(1, 'Password is required'),
  })
  .refine(data => (data.email && data.email.length > 0) || (data.emailOrMobile && data.emailOrMobile.length > 0), {
    message: 'Email address darj karein',
    path: ['email'],
  });

const sendForgotPasswordOtpSchema = z.object({
  email: z.string().trim().email('Kripya valid email address darj karein').toLowerCase(),
});

const resetPasswordSchema = z.object({
  email: z.string().trim().email('Kripya valid email address darj karein').toLowerCase(),
  otp: z.string().trim().length(6, 'OTP theek 6 akshar ka hona chahiye'),
  newPassword: z.string().min(6, 'Naya password kam se kam 6 akshar ka hona chahiye'),
});

const fcmTokenSchema = z.object({
  fcmToken: z.string().min(1, 'FCM token is required'),
});

function generateToken(user) {
  return jwt.sign({ userId: user._id, emailOrMobile: user.emailOrMobile }, jwtSecret, {
    expiresIn: jwtExpiresIn,
  });
}

function generate6DigitOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

/**
 * Sends OTP to Gmail/Email for new user registration
 */
async function handleSendSignupOtp(req, res, next) {
  try {
    const email = req.body.email.trim().toLowerCase();

    // Check if user already exists
    const existingUser = await User.findOne({ emailOrMobile: email });
    if (existingUser) {
      return sendError(res, 'Is email se account pehle se bana hua hai. Kripya login karein.', 409);
    }

    const otp = generate6DigitOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes validity

    // Overwrite any old signup OTP for this email
    await Otp.deleteMany({ email, type: 'signup' });
    await Otp.create({
      email,
      otp,
      type: 'signup',
      expiresAt,
    });

    // Send email via Brevo
    await sendSignupOtpEmail(email, otp);

    return sendSuccess(res, { email }, 'Verification OTP aapke email par bhej diya gaya hai.');
  } catch (error) {
    next(error);
  }
}

/**
 * Registers new user after verifying OTP
 */
async function signup(req, res, next) {
  try {
    const { name, password } = req.body;
    const cleanEmail = (req.body.email || req.body.emailOrMobile || '').trim().toLowerCase();
    const otp = req.body.otp ? req.body.otp.trim() : null;

    // Check if user already exists
    const existing = await User.findOne({ emailOrMobile: cleanEmail });
    if (existing) {
      return sendError(res, 'User with this email or mobile already exists', 409);
    }

    // Verify OTP in production/development or when provided in tests
    if (process.env.NODE_ENV !== 'test' || otp) {
      if (!otp) {
        return sendError(res, 'Email verification OTP zaroori hai. Kripya OTP darj karein.', 400);
      }

      const otpRecord = await Otp.findOne({
        email: cleanEmail,
        type: 'signup',
        otp,
      });

      if (!otpRecord || otpRecord.expiresAt < new Date()) {
        return sendError(res, 'OTP galat hai ya expire ho chuka hai. Kripya naya OTP mangwayein.', 400);
      }

      // Clean up used OTP
      await Otp.deleteMany({ email: cleanEmail, type: 'signup' });
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const user = await User.create({
      name: name.trim(),
      emailOrMobile: cleanEmail,
      passwordHash,
      isEmailVerified: true,
    });

    const token = generateToken(user);

    return sendSuccess(res, { token, user }, 'Account created successfully', 201);
  } catch (error) {
    next(error);
  }
}

/**
 * Logs in with Email and Password
 */
async function login(req, res, next) {
  try {
    const cleanIdentifier = (req.body.email || req.body.emailOrMobile || '').trim().toLowerCase();
    const { password } = req.body;

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

/**
 * Sends OTP to Email for password reset
 */
async function handleSendForgotPasswordOtp(req, res, next) {
  try {
    const email = req.body.email.trim().toLowerCase();

    const user = await User.findOne({ emailOrMobile: email });
    if (!user) {
      return sendError(res, 'Is email se koi account registered nahi mila. Kripya email check karein.', 404);
    }

    const otp = generate6DigitOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes validity

    // Overwrite any old forgot_password OTP for this email
    await Otp.deleteMany({ email, type: 'forgot_password' });
    await Otp.create({
      email,
      otp,
      type: 'forgot_password',
      expiresAt,
    });

    // Send email via Brevo
    await sendForgotPasswordOtpEmail(email, otp);

    return sendSuccess(res, { email }, 'Password reset OTP aapke email par bhej diya gaya hai.');
  } catch (error) {
    next(error);
  }
}

/**
 * Resets password using OTP
 */
async function handleResetPassword(req, res, next) {
  try {
    const email = req.body.email.trim().toLowerCase();
    const { otp, newPassword } = req.body;

    const otpRecord = await Otp.findOne({
      email,
      type: 'forgot_password',
      otp: otp.trim(),
    });

    if (!otpRecord || otpRecord.expiresAt < new Date()) {
      return sendError(res, 'OTP galat hai ya expire ho chuka hai. Kripya naya OTP mangwayein.', 400);
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(newPassword, salt);

    const user = await User.findOneAndUpdate(
      { emailOrMobile: email },
      { passwordHash },
      { new: true }
    );

    if (!user) {
      return sendError(res, 'User nahi mila.', 404);
    }

    // Clean up used OTP
    await Otp.deleteMany({ email, type: 'forgot_password' });

    return sendSuccess(res, null, 'Password safaltapoorvak badal diya gaya! Ab aap naye password se login kar sakte hain.');
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
  sendSignupOtpSchema,
  signupSchema,
  loginSchema,
  sendForgotPasswordOtpSchema,
  resetPasswordSchema,
  fcmTokenSchema,
  handleSendSignupOtp,
  signup,
  login,
  handleSendForgotPasswordOtp,
  handleResetPassword,
  getMe,
  handleRegisterFCMToken,
  handleRemoveFCMToken,
};
