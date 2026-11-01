const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { requireGroupMember } = require('../middleware/groupMember');
const { validate } = require('../middleware/validate');
const {
  createGroupSchema,
  joinGroupSchema,
  handleCreateGroup,
  handleJoinGroup,
  handleGetGroups,
  handleGetGroupById,
  handleLeaveGroup,
} = require('../controllers/groupController');
const {
  sendTextMessageSchema,
  handleGetMessages,
  handleSendTextMessage,
} = require('../controllers/chatController');
const {
  createExpenseSchema,
  handleCreateExpense,
} = require('../controllers/expenseController');
const {
  handleGetCurrentCycle,
  handleGetGroupCycles,
  handleCloseCycle,
} = require('../controllers/cycleController');

// All group routes require authentication
router.use(authenticate);

// Groups collection routes
router.post('/', validate(createGroupSchema), handleCreateGroup);
router.post('/join', validate(joinGroupSchema), handleJoinGroup);
router.get('/', handleGetGroups);

// Single group member-guarded routes
router.get('/:id', requireGroupMember, handleGetGroupById);
router.post('/:id/leave', requireGroupMember, handleLeaveGroup);

// Messages routes inside group
router.get('/:id/messages', requireGroupMember, handleGetMessages);
router.post('/:id/messages', requireGroupMember, validate(sendTextMessageSchema), handleSendTextMessage);

// Expenses inside group
router.post('/:id/expenses', requireGroupMember, validate(createExpenseSchema), handleCreateExpense);

// Cycle routes inside group
router.get('/:id/cycle/current', requireGroupMember, handleGetCurrentCycle);
router.get('/:id/cycles', requireGroupMember, handleGetGroupCycles);
router.post('/:id/cycle/close', requireGroupMember, handleCloseCycle);

module.exports = router;
