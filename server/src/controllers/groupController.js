const { z } = require('zod');
const {
  createGroup,
  joinGroupByCode,
  addMemberToGroup,
  leaveGroup,
  getGroupById,
} = require('../services/groupService');
const {
  getUserGlobalSummary,
  getGroupLiveBalances,
} = require('../services/balanceService');
const { sendGroupPushNotification, sendUserPushNotification } = require('../services/notificationService');
const { sendSuccess, sendError } = require('../utils/apiResponse');

const createGroupSchema = z.object({
  name: z.string().min(2, 'Group name must be at least 2 characters'),
});

const joinGroupSchema = z.object({
  inviteCode: z.string().length(6, 'Invite code must be exactly 6 characters'),
});

const addMemberSchema = z.object({
  emailOrMobile: z.string().min(3, 'Email ya phone number darj karein'),
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
    const result = await joinGroupByCode(inviteCode, req.user._id);
    const group = result.group || result;
    const isNewMember = result.isNewMember ?? true;

    if (isNewMember) {
      // 1. Send push notification to all existing group members
      sendGroupPushNotification({
        groupId: group._id,
        title: group.name,
        body: `${req.user.name} ne group join kiya hai! 🎉`,
        data: {
          type: 'member_joined',
          groupId: group._id.toString(),
          userId: req.user._id.toString(),
        },
        excludeUserId: req.user._id,
      });

      // 2. Real-time WebSocket broadcast to active app users
      if (req.app.get('io')) {
        req.app.get('io').to(`group:${group._id}`).emit('member_joined', {
          group,
          user: { _id: req.user._id, name: req.user.name },
        });
      }
    }

    return sendSuccess(res, group, 'Joined group successfully');
  } catch (error) {
    next(error);
  }
}

async function handleAddMember(req, res, next) {
  try {
    const groupId = req.params.id;
    const { emailOrMobile } = req.body;
    const { group, addedUser } = await addMemberToGroup(groupId, emailOrMobile);

    // 1. Send push notification to the newly added member
    sendUserPushNotification({
      userId: addedUser._id,
      title: 'Chindi',
      body: `Aapko "${group.name}" group mein shamil kiya gaya hai! 🎉`,
      data: {
        type: 'added_to_group',
        groupId: group._id.toString(),
      },
    });

    // 2. Send push notification to other members
    sendGroupPushNotification({
      groupId: group._id,
      title: group.name,
      body: `${addedUser.name} ko ${req.user.name} ne group mein add kiya`,
      data: {
        type: 'member_added',
        groupId: group._id.toString(),
        userId: addedUser._id.toString(),
      },
      excludeUserId: addedUser._id,
    });

    // 3. Real-time WebSocket broadcast
    if (req.app.get('io')) {
      req.app.get('io').to(`group:${group._id}`).emit('member_joined', {
        group,
        user: { _id: addedUser._id, name: addedUser.name },
      });
    }

    return sendSuccess(res, group, `${addedUser.name} ko group mein shamil kar diya gaya.`);
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
  addMemberSchema,
  handleCreateGroup,
  handleJoinGroup,
  handleAddMember,
  handleGetGroups,
  handleGetGroupById,
  handleLeaveGroup,
};
