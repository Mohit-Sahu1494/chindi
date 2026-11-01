const mongoose = require('mongoose');
const { mongoUri } = require('./env');

let isConnected = false;

async function connectDB() {
  if (isConnected) return;

  try {
    const conn = await mongoose.connect(mongoUri, {
      autoIndex: true,
      serverSelectionTimeoutMS: 5000,
    });
    isConnected = true;
    console.log(`[MongoDB] Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error(`[MongoDB] Connection error: ${error.message}`);
    // Don't exit process in test environment
    if (process.env.NODE_ENV !== 'test') {
      console.warn('[MongoDB] Continuing without active MongoDB connection (or retry later)');
    }
  }
}

async function disconnectDB() {
  if (!isConnected) return;
  await mongoose.disconnect();
  isConnected = false;
  console.log('[MongoDB] Disconnected');
}

module.exports = {
  connectDB,
  disconnectDB,
};
