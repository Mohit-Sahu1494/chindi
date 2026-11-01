const Group = require('../models/Group');
const { sendError } = require('../utils/apiResponse');

/**
 * Middleware to verify that the authenticated user is an active member of the group.
 * Attaches req.group to the request object.
 */
async function requireGroupMember(req, res, next) {
  try {
    const groupId = req.params.groupId || req.params.id || req.body.groupId;
    if (!groupId) {
      return sendError(res, 'Group ID is required', 400);
    }

    const group = await Group.findById(groupId).populate('members', 'name emailOrMobile');
    if (!group) {
      return sendError(res, 'Group not found', 404);
    }

    const isMember = group.members.some(
      member => member._id.toString() === req.user._id.toString()
    );

    if (!isMember) {
      return sendError(res, 'Aap is group ke member nahi hain (Access denied)', 403);
    }

    req.group = group;
    next();
  } catch (error) {
    return sendError(res, 'Failed to verify group membership', 500, error.message);
  }
}

module.exports = {
  requireGroupMember,
};
