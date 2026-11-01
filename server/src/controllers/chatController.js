const { z } = require('zod');
const Message = require('../models/Message');
const Group = require('../models/Group');
const { sendSuccess } = require('../utils/apiResponse');
const { sendGroupPushNotification } = require('../services/notificationService');

const sendTextMessageSchema = z.object({
  text: z.string().min(1, 'Message text cannot be empty').max(2000, 'Message is too long'),
});

async function handleGetMessages(req, res, next) {
  try {
    const groupId = req.params.id;
    const page = parseInt(req.query.page, 10) || 1;
    const limit = Math.min(parseInt(req.query.limit, 10) || 30, 100);
    const skip = (page - 1) * limit;

    const [messages, totalCount] = await Promise.all([
      Message.find({ group: groupId })
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit)
        .populate('sender', 'name emailOrMobile')
        .populate({
          path: 'expense',
          populate: [
            { path: 'paidBy', select: 'name emailOrMobile' },
            { path: 'excludedMembers', select: 'name emailOrMobile' },
            { path: 'participants', select: 'name emailOrMobile' },
            { path: 'shares.user', select: 'name emailOrMobile' },
          ],
        }),
      Message.countDocuments({ group: groupId }),
    ]);

    const hasMore = skip + messages.length < totalCount;

    return sendSuccess(res, {
      messages: messages.reverse(), // Send oldest to newest in chronological chunk
      pagination: {
        page,
        limit,
        totalCount,
        hasMore,
      },
    });
  } catch (error) {
    next(error);
  }
}

async function handleSendTextMessage(req, res, next) {
  try {
    const groupId = req.params.id;
    const { text } = req.body;

    const message = await Message.create({
      group: groupId,
      sender: req.user._id,
      type: 'text',
      text: text.trim(),
    });

    const populated = await Message.findById(message._id).populate('sender', 'name emailOrMobile');

    // Real-time broadcast
    if (req.app.get('io')) {
      req.app.get('io').to(`group:${groupId}`).emit('new_message', populated);
    }

    // Send push notification to group members
    const group = req.group || (await Group.findById(groupId));
    sendGroupPushNotification({
      groupId,
      title: group ? group.name : 'Chindi',
      body: `${req.user.name}: ${text.trim()}`,
      data: { type: 'chat_message', groupId: groupId.toString() },
      excludeUserId: req.user._id,
    });

    return sendSuccess(res, populated, 'Message sent', 201);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  sendTextMessageSchema,
  handleGetMessages,
  handleSendTextMessage,
};
