const express = require('express');
const router = express.Router();
const { validate } = require('../middleware/validate');
const { authenticate } = require('../middleware/auth');
const {
  signupSchema,
  loginSchema,
  fcmTokenSchema,
  signup,
  login,
  getMe,
  handleRegisterFCMToken,
  handleRemoveFCMToken,
} = require('../controllers/authController');

router.post('/signup', validate(signupSchema), signup);
router.post('/login', validate(loginSchema), login);
router.get('/me', authenticate, getMe);

// FCM push notification device token registration
router.post('/fcm-token', authenticate, validate(fcmTokenSchema), handleRegisterFCMToken);
router.delete('/fcm-token', authenticate, validate(fcmTokenSchema), handleRemoveFCMToken);

module.exports = router;
