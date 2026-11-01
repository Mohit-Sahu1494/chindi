const jwt = require('jsonwebtoken');
const { jwtSecret } = require('../config/env');
const User = require('../models/User');

function initializeSocket(io) {
  // Authenticate socket connection via JWT in handshake auth or query
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.replace('Bearer ', '');
      if (!token) {
        return next(new Error('Authentication token missing'));
      }

      const decoded = jwt.verify(token, jwtSecret);
      const user = await User.findById(decoded.userId).select('-passwordHash');
      if (!user) {
        return next(new Error('User not found'));
      }

      socket.user = user;
      next();
    } catch (err) {
      next(new Error('Authentication failed: ' + err.message));
    }
  });

  io.on('connection', socket => {
    console.log(`[Socket] Client connected: ${socket.id} (User: ${socket.user.name})`);

    // Join group room
    socket.on('join_group', ({ groupId }) => {
      if (groupId) {
        const roomName = `group:${groupId}`;
        socket.join(roomName);
        console.log(`[Socket] User ${socket.user.name} joined room: ${roomName}`);
        socket.emit('joined_group', { groupId, message: `Successfully joined ${roomName}` });
      }
    });

    // Leave group room
    socket.on('leave_group', ({ groupId }) => {
      if (groupId) {
        const roomName = `group:${groupId}`;
        socket.leave(roomName);
        console.log(`[Socket] User ${socket.user.name} left room: ${roomName}`);
      }
    });

    socket.on('disconnect', reason => {
      console.log(`[Socket] Client disconnected: ${socket.id} (Reason: ${reason})`);
    });
  });
}

module.exports = {
  initializeSocket,
};
