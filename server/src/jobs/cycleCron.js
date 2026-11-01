const cron = require('node-cron');
const { autoCloseExpiredCyclesJob } = require('../services/cycleService');

function startCycleCronJobs(io) {
  // Run every midnight (00:00:00)
  // Also runs every hour in development or configurable
  const schedule = '0 0 * * *'; // Daily at midnight

  console.log('[Cron] Initializing 30-day cycle auto-close cron job (schedule: daily 00:00)');
  const job = cron.schedule(schedule, async () => {
    console.log('[Cron] Checking for expired 30-day cycles...');
    await autoCloseExpiredCyclesJob(io);
  });

  return job;
}

module.exports = {
  startCycleCronJobs,
};
