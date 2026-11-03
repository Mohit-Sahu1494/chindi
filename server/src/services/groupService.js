const Group = require('../models/Group');
const User = require('../models/User');
const { generateInviteCode } = require('../utils/inviteCode');
const { getOrCreateCurrentCycle } = require('./cycleService');

/**
 * Creates a new group, generates unique invite code, assigns creator as admin,
 * and sets up Cycle 1.
 */
async function createGroup(name, creatorUserId) {
  let inviteCode;
  let isUnique = false;

  // Generate unique 6-character invite code
  while (!isUnique) {
    inviteCode = generateInviteCode();
    const existing = await Group.findOne({ inviteCode });
    if (!existing) isUnique = true;
  }

  const group = await Group.create({
    name: name.trim(),
    inviteCode,
    admin: creatorUserId,
    members: [creatorUserId],
  });

  // Initialize initial 30-day cycle
  const cycle = await getOrCreateCurrentCycle(group._id);
  group.currentCycle = cycle._id;
  await group.save();

  const populatedGroup = await Group.findById(group._id)
    .populate('admin', 'name emailOrMobile')
    .populate('members', 'name emailOrMobile');

  return populatedGroup;
}

/**
 * Joins a group using a 6-character invite code.
 */
async function joinGroupByCode(inviteCode, userId) {
  const code = inviteCode.trim().toUpperCase();
  const group = await Group.findOne({ inviteCode: code });

  if (!group) {
    throw new Error('Invalid invite code. Group not found.');
  }

  const isAlreadyMember = group.members.some(
    m => m.toString() === userId.toString()
  );

  let isNewMember = false;
  if (!isAlreadyMember) {
    group.members.push(userId);
    await group.save();
    isNewMember = true;
  }

  const populated = await Group.findById(group._id)
    .populate('admin', 'name emailOrMobile')
    .populate('members', 'name emailOrMobile');

  return { group: populated, isNewMember };
}

/**
 * Adds a member directly to a group by email or mobile.
 */
async function addMemberToGroup(groupId, emailOrMobile) {
  const user = await User.findOne({
    emailOrMobile: emailOrMobile.trim().toLowerCase(),
  });

  if (!user) {
    throw new Error('Is email ya mobile number ka koi user nahi mila.');
  }

  const group = await Group.findById(groupId);
  if (!group) throw new Error('Group nahi mila');

  const isMember = group.members.some(m => m.toString() === user._id.toString());
  if (isMember) {
    throw new Error('Ye user pehle se hi is group ke member hain.');
  }

  group.members.push(user._id);
  await group.save();

  const populatedGroup = await Group.findById(group._id)
    .populate('admin', 'name emailOrMobile')
    .populate('members', 'name emailOrMobile');

  return { group: populatedGroup, addedUser: user };
}

/**
 * Leaves a group.
 */
async function leaveGroup(groupId, userId) {
  const group = await Group.findById(groupId);
  if (!group) throw new Error('Group not found');

  const isMember = group.members.some(m => m.toString() === userId.toString());
  if (!isMember) throw new Error('Aap is group ke member nahi hain');

  // If user is admin and there are other members, pass admin to next member
  if (group.admin.toString() === userId.toString()) {
    const remaining = group.members.filter(m => m.toString() !== userId.toString());
    if (remaining.length > 0) {
      group.admin = remaining[0];
    }
  }

  group.members = group.members.filter(m => m.toString() !== userId.toString());
  await group.save();

  return { message: 'Group successfully left' };
}

/**
 * Retrieves group details with members.
 */
async function getGroupById(groupId) {
  const group = await Group.findById(groupId)
    .populate('admin', 'name emailOrMobile')
    .populate('members', 'name emailOrMobile');
  return group;
}

/**
 * Retrieves all groups for a user.
 */
async function getUserGroups(userId) {
  const groups = await Group.find({ members: userId })
    .populate('admin', 'name emailOrMobile')
    .populate('members', 'name emailOrMobile')
    .sort({ updatedAt: -1 });
  return groups;
}

module.exports = {
  createGroup,
  joinGroupByCode,
  addMemberToGroup,
  leaveGroup,
  getGroupById,
  getUserGroups,
};
