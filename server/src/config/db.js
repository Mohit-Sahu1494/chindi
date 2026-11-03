const mongoose = require('mongoose');
const { mongoUri } = require('./env');

// Event listeners for connection monitoring
mongoose.connection.on('connected', () => {
  console.log('[MongoDB] Connection established successfully');
});

mongoose.connection.on('error', (err) => {
  console.error(`[MongoDB] Connection error event: ${err.message}`);
});

mongoose.connection.on('disconnected', () => {
  console.warn('[MongoDB] Connection disconnected');
});

/**
 * Connects to MongoDB Atlas with retry mechanism.
 * Uses 15s serverSelectionTimeoutMS to prevent premature timeouts during TLS negotiation.
 */
async function connectDB(retries = 3, delayMs = 2000) {
  if (mongoose.connection.readyState === 1) return mongoose.connection;

  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      console.log(`[MongoDB] Connecting to Atlas (Attempt ${attempt}/${retries})...`);
      const conn = await mongoose.connect(mongoUri, {
        autoIndex: true,
        serverSelectionTimeoutMS: 15000,
        maxPoolSize: 10,
      });
      console.log(`[MongoDB] Connected: ${conn.connection.host}`);
      return conn;
    } catch (error) {
      console.error(`[MongoDB] Connection attempt ${attempt} failed: ${error.message}`);
      if (attempt < retries) {
        console.log(`[MongoDB] Retrying in ${delayMs / 1000}s...`);
        await new Promise((res) => setTimeout(res, delayMs));
      } else {
        if (process.env.NODE_ENV === 'test') return null;
        console.error('[MongoDB] All connection attempts failed. Check internet connection and MongoDB Atlas IP access.');
        throw error;
      }
    }
  }
}

/**
 * Checks if the database is actively connected.
 */
function isDbConnected() {
  return mongoose.connection.readyState === 1;
}

/**
 * Disconnects from MongoDB.
 */
async function disconnectDB() {
  if (mongoose.connection.readyState !== 0) {
    await mongoose.disconnect();
    console.log('[MongoDB] Disconnected cleanly');
  }
}

module.exports = {
  connectDB,
  isDbConnected,
  disconnectDB,
};
