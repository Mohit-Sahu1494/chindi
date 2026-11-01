const http = require('http');
const { Server } = require('socket.io');
const app = require('./app');
const { port, corsOrigin } = require('./config/env');
const { connectDB } = require('./config/db');
const { initializeSocket } = require('./sockets/socketHandler');
const { startCycleCronJobs } = require('./jobs/cycleCron');

async function startServer() {
  // Connect to Database
  await connectDB();

  // Create HTTP server
  const server = http.createServer(app);

  // Initialize Socket.io
  const io = new Server(server, {
    cors: {
      origin: corsOrigin === '*' ? '*' : corsOrigin,
      methods: ['GET', 'POST'],
      credentials: true,
    },
  });

  // Attach io instance to express app so controllers can emit events
  app.set('io', io);

  // Initialize Socket event handlers and auth
  initializeSocket(io);

  // Start Cron Jobs
  startCycleCronJobs(io);

  // Start listening
  server.listen(port, () => {
    console.log(`===============================================`);
    console.log(`  Chindi Server running on port ${port}`);
    console.log(`  Health check: http://localhost:${port}/api/health`);
    console.log(`===============================================`);
  });

  // Graceful shutdown
  const shutdown = () => {
    console.log('\n[Server] Shutting down gracefully...');
    server.close(() => {
      console.log('[Server] HTTP and Socket server closed.');
      process.exit(0);
    });
  };

  process.on('SIGTERM', shutdown);
  process.on('SIGINT', shutdown);
}

startServer().catch(err => {
  console.error('[Fatal] Server failed to start:', err);
  process.exit(1);
});
