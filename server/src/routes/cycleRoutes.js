const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { handleGetCycleById } = require('../controllers/cycleController');

router.use(authenticate);

router.get('/:id', handleGetCycleById);

module.exports = router;
