const express = require('express');
const router = express.Router();
const { getLatestAppVersion, updateAppVersion } = require('../controllers/versionController');
const { authenticate } = require('../middleware/auth');

// Public route for mobile app to check for updates
router.get('/', getLatestAppVersion);

// Protected route for admin to push a new version update
router.post('/', authenticate, updateAppVersion);

module.exports = router;
