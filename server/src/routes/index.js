const express = require('express');
const router = express.Router();
const authRoutes = require('./authRoutes');
const groupRoutes = require('./groupRoutes');
const expenseRoutes = require('./expenseRoutes');
const cycleRoutes = require('./cycleRoutes');
const versionRoutes = require('./versionRoutes');

router.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    app: 'Chindi API',
    time: new Date().toISOString(),
  });
});

router.use('/auth', authRoutes);
router.use('/groups', groupRoutes);
router.use('/expenses', expenseRoutes);
router.use('/cycles', cycleRoutes);
router.use('/version', versionRoutes);

module.exports = router;
