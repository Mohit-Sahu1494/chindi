const Expense = require('../models/Expense');
const Message = require('../models/Message');
const Group = require('../models/Group');
const Cycle = require('../models/Cycle');
const { distributeShares, formatPaise } = require('../utils/money');
const { checkAndAutoCloseCycle } = require('./cycleService');
const { sendGroupPushNotification } = require('./notificationService');

/**
 * Creates an expense inside a group and automatically posts a corresponding chat message.
 */
async function createExpense({ groupId, paidByUserId, amountPaise, description, excludedMemberIds = [] }, io = null) {
  // Check cycle
  const currentCycle = await checkAndAutoCloseCycle(groupId, io);
  if (currentCycle.status !== 'open') {
    throw new Error('Active cycle is closed. Cannot add expense.');
  }

  const group = await Group.findById(groupId);
  if (!group) throw new Error('Group not found');

  const memberIdStrings = group.members.map(m => m.toString());

  // Determine participants (all group members minus excluded)
  const excludedSet = new Set((excludedMemberIds || []).map(id => id.toString()));
  const participantIds = memberIdStrings.filter(id => !excludedSet.has(id));

  if (participantIds.length === 0) {
    throw new Error('At least one group member must be included in the expense');
  }

  // Calculate integer paise shares
  const shares = distributeShares(amountPaise, participantIds);

  const expense = await Expense.create({
    group: groupId,
    cycle: currentCycle._id,
    paidBy: paidByUserId,
    amountPaise,
    description: description.trim(),
    excludedMembers: Array.from(excludedSet),
    participants: participantIds,
    shares,
    isDeleted: false,
  });

  // Create corresponding chat message
  const message = await Message.create({
    group: groupId,
    sender: paidByUserId,
    type: 'expense',
    text: description.trim(),
    expense: expense._id,
  });

  // Populate references for clean client display
  const populatedExpense = await Expense.findById(expense._id)
    .populate('paidBy', 'name emailOrMobile')
    .populate('excludedMembers', 'name emailOrMobile')
    .populate('participants', 'name emailOrMobile')
    .populate('shares.user', 'name emailOrMobile');

  const populatedMessage = await Message.findById(message._id)
    .populate('sender', 'name emailOrMobile')
    .populate({
      path: 'expense',
      populate: [
        { path: 'paidBy', select: 'name emailOrMobile' },
        { path: 'excludedMembers', select: 'name emailOrMobile' },
        { path: 'participants', select: 'name emailOrMobile' },
        { path: 'shares.user', select: 'name emailOrMobile' },
      ],
    });

  // Real-time broadcast
  if (io) {
    io.to(`group:${groupId}`).emit('new_message', populatedMessage);
    io.to(`group:${groupId}`).emit('expense_added', {
      expense: populatedExpense,
      cycleId: currentCycle._id,
    });
  }

  // Push notification to other members
  sendGroupPushNotification({
    groupId,
    title: group.name,
    body: `${populatedExpense.paidBy.name} ne ${formatPaise(amountPaise)} ka kharcha joda: ${description.trim()}`,
    data: {
      type: 'expense_added',
      groupId: groupId.toString(),
      expenseId: expense._id.toString(),
    },
    excludeUserId: paidByUserId,
  });

  return { expense: populatedExpense, message: populatedMessage };
}

/**
 * Updates an expense. Allowed only by creator and while cycle is open.
 */
async function updateExpense(expenseId, userId, { amountPaise, description, excludedMemberIds }, io = null) {
  const expense = await Expense.findById(expenseId);
  if (!expense || expense.isDeleted) {
    throw new Error('Expense not found or already deleted');
  }

  if (expense.paidBy.toString() !== userId.toString()) {
    throw new Error('Only the member who added this expense can edit it');
  }

  // Verify cycle is open
  const cycle = await Cycle.findById(expense.cycle);
  if (!cycle || cycle.status !== 'open') {
    throw new Error('Cannot edit expense in a closed cycle');
  }

  const group = await Group.findById(expense.group);
  const memberIdStrings = group.members.map(m => m.toString());

  const excludedSet = new Set((excludedMemberIds || []).map(id => id.toString()));
  const participantIds = memberIdStrings.filter(id => !excludedSet.has(id));

  if (participantIds.length === 0) {
    throw new Error('At least one group member must participate');
  }

  const newShares = distributeShares(amountPaise, participantIds);

  expense.amountPaise = amountPaise;
  expense.description = description.trim();
  expense.excludedMembers = Array.from(excludedSet);
  expense.participants = participantIds;
  expense.shares = newShares;
  await expense.save();

  // Update linked chat message text
  await Message.findOneAndUpdate(
    { expense: expense._id },
    { text: description.trim() }
  );

  const populatedExpense = await Expense.findById(expense._id)
    .populate('paidBy', 'name emailOrMobile')
    .populate('excludedMembers', 'name emailOrMobile')
    .populate('participants', 'name emailOrMobile')
    .populate('shares.user', 'name emailOrMobile');

  if (io) {
    io.to(`group:${expense.group}`).emit('expense_updated', {
      expense: populatedExpense,
      cycleId: cycle._id,
    });
  }

  return populatedExpense;
}

/**
 * Soft deletes an expense. Allowed only by creator and while cycle is open.
 */
async function deleteExpense(expenseId, userId, io = null) {
  const expense = await Expense.findById(expenseId);
  if (!expense || expense.isDeleted) {
    throw new Error('Expense not found or already deleted');
  }

  if (expense.paidBy.toString() !== userId.toString()) {
    throw new Error('Only the member who added this expense can delete it');
  }

  const cycle = await Cycle.findById(expense.cycle);
  if (!cycle || cycle.status !== 'open') {
    throw new Error('Cannot delete expense in a closed cycle');
  }

  expense.isDeleted = true;
  expense.deletedAt = new Date();
  await expense.save();

  // Update or delete associated message
  await Message.findOneAndDelete({ expense: expense._id });

  if (io) {
    io.to(`group:${expense.group}`).emit('expense_updated', {
      deletedExpenseId: expense._id,
      cycleId: cycle._id,
    });
  }

  return { message: 'Expense deleted successfully' };
}

module.exports = {
  createExpense,
  updateExpense,
  deleteExpense,
};
