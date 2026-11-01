const { z } = require('zod');
const {
  createGroup,
  joinGroupByCode,
  leaveGroup,
  getGroupById,
} = require('../services/groupService');
const {
  getUserGlobalSummary,
  getGroupLiveBalances,
} = require('../services/balanceService');
const { sendSuccess, sendError } = require('../utils/apiResponse');

const createGroupSchema = z.object({
  name: z.string().min(2, 'Group name must be at least 2 characters'),
});

const joinGroupSchema = z.object({
  inviteCode: z.string().length(6, 'Invite code must be exactly 6 characters'),
});

async function handleCreateGroup(req, res, next) {
  try {
    const { name } = req.body;
    const group = await createGroup(name, req.user._id);
    return sendSuccess(res, group, 'Group created successfully', 201);
  } catch (error) {
    next(error);
  }
}

async function handleJoinGroup(req, res, next) {
  try {
    const { inviteCode } = req.body;
    const group = await joinGroupByCode(inviteCode, req.user._id);
    return sendSuccess(res, group, 'Joined group successfully');
  } catch (error) {
    next(error);
  }
}

async function handleGetGroups(req, res, next) {
  try {
    const summary = await getUserGlobalSummary(req.user._id);
    return sendSuccess(res, summary, 'Groups retrieved successfully');
  } catch (error) {
    next(error);
  }
}

async function handleGetGroupById(req, res, next) {
  try {
    const group = await getGroupById(req.params.id);
    const liveBalances = await getGroupLiveBalances(req.params.id);

    return sendSuccess(res, { group, balances: liveBalances }, 'Group details retrieved');
  } catch (error) {
    next(error);
  }
}

async function handleLeaveGroup(req, res, next) {
  try {
    const result = await leaveGroup(req.params.id, req.user._id);
    return sendSuccess(res, result, 'Left group successfully');
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createGroupSchema,
  joinGroupSchema,
  handleCreateGroup,
  handleJoinGroup,
  handleGetGroups,
  handleGetGroupById,
  handleLeaveGroup,
};
