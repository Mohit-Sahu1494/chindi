const express = require('express');
const router = express.Router();
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const {
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
} = require('../controllers/authController');

// 1. Email Verification for Registration
router.post('/send-signup-otp', validate(sendSignupOtpSchema), handleSendSignupOtp);
router.post('/signup', validate(signupSchema), signup);

// 2. Email Login
router.post('/login', validate(loginSchema), login);

// 3. Forgot Password via Email OTP
router.post('/forgot-password/send-otp', validate(sendForgotPasswordOtpSchema), handleSendForgotPasswordOtp);
router.post('/forgot-password/reset', validate(resetPasswordSchema), handleResetPassword);

// 4. Authenticated profile
router.get('/me', authenticate, getMe);

// 5. FCM push notification device token registration
router.post('/fcm-token', authenticate, validate(fcmTokenSchema), handleRegisterFCMToken);
router.delete('/fcm-token', authenticate, validate(fcmTokenSchema), handleRemoveFCMToken);

module.exports = router;
