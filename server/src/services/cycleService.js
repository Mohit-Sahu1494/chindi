const Cycle = require('../models/Cycle');
const Group = require('../models/Group');
const Expense = require('../models/Expense');
const { computeSettlements } = require('../utils/settlement');

/**
 * Calculates the full financial snapshot for a given cycle.
 */
async function calculateCycleSnapshot(groupId, cycleId) {
  const group = await Group.findById(groupId).populate('members', 'name emailOrMobile');
  if (!group) throw new Error('Group not found');

  const expenses = await Expense.find({
    group: groupId,
    cycle: cycleId,
    isDeleted: false,
  });

  const memberMap = new Map();
  group.members.forEach(member => {
    memberMap.set(member._id.toString(), {
      user: member,
      paidPaise: 0,
      sharePaise: 0,
      netPaise: 0,
    });
  });

  let totalPaise = 0;

  for (const exp of expenses) {
    totalPaise += exp.amountPaise;

    // Paid by
    const payerId = exp.paidBy.toString();
    if (memberMap.has(payerId)) {
      memberMap.get(payerId).paidPaise += exp.amountPaise;
    }

    // Shares
    for (const share of exp.shares) {
      const participantId = share.user.toString();
      if (memberMap.has(participantId)) {
        memberMap.get(participantId).sharePaise += share.amountPaise;
      }
    }
  }

  // Calculate net per user: paid - share
  const perUser = [];
  memberMap.forEach(data => {
    data.netPaise = data.paidPaise - data.sharePaise;
    perUser.push(data);
  });

  // Calculate simplified settlements
  const settlementInput = perUser.map(item => ({
    user: item.user._id,
    netPaise: item.netPaise,
  }));
  const rawSettlements = computeSettlements(settlementInput);

  // Populate settlements with user objects
  const settlements = rawSettlements.map(s => {
    const fromMember = group.members.find(m => m._id.toString() === s.from.toString());
    const toMember = group.members.find(m => m._id.toString() === s.to.toString());
    return {
      from: fromMember || s.from,
      to: toMember || s.to,
      amountPaise: s.amountPaise,
    };
  });

  return {
    totalPaise,
    perUser,
    settlements,
  };
}

/**
 * Ensures a group has an active open cycle.
 * If currentCycle is missing or invalid, initializes a new 30-day cycle.
 */
async function getOrCreateCurrentCycle(groupId) {
  let cycle = await Cycle.findOne({ group: groupId, status: 'open' }).sort({ createdAt: -1 });

  if (!cycle) {
    const startDate = new Date();
    const endDate = new Date(startDate.getTime() + 30 * 24 * 60 * 60 * 1000); // +30 days

    const lastCycle = await Cycle.findOne({ group: groupId }).sort({ cycleNumber: -1 });
    const nextNumber = lastCycle ? (lastCycle.cycleNumber || 1) + 1 : 1;

    cycle = await Cycle.create({
      group: groupId,
      cycleNumber: nextNumber,
      startDate,
      endDate,
      status: 'open',
    });

    await Group.findByIdAndUpdate(groupId, { currentCycle: cycle._id });
  }

  return cycle;
}

/**
 * Checks if the current cycle has expired (past endDate) and closes it if so.
 * Used for lazy-checking on API requests.
 */
async function checkAndAutoCloseCycle(groupId, io = null) {
  const cycle = await Cycle.findOne({ group: groupId, status: 'open' });
  if (!cycle) {
    return await getOrCreateCurrentCycle(groupId);
  }

  const now = new Date();
  if (now >= new Date(cycle.endDate)) {
    return await closeCycle(groupId, null, false, io);
  }

  return cycle;
}

/**
 * Closes an open cycle, saves the financial snapshot, and opens the next 30-day cycle.
 */
async function closeCycle(groupId, requestingUserId = null, isManual = false, io = null) {
  const group = await Group.findById(groupId);
  if (!group) throw new Error('Group not found');

  if (isManual && requestingUserId) {
    if (group.admin.toString() !== requestingUserId.toString()) {
      throw new Error('Only the group admin can close a cycle early');
    }
  }

  const currentCycle = await Cycle.findOne({ group: groupId, status: 'open' });
  if (!currentCycle) {
    return await getOrCreateCurrentCycle(groupId);
  }

  // Calculate final snapshot
  const snapshot = await calculateCycleSnapshot(groupId, currentCycle._id);

  // Close current cycle
  currentCycle.status = 'closed';
  currentCycle.closedAt = new Date();
  currentCycle.snapshot = {
    totalPaise: snapshot.totalPaise,
    perUser: snapshot.perUser.map(item => ({
      user: item.user._id,
      paidPaise: item.paidPaise,
      sharePaise: item.sharePaise,
      netPaise: item.netPaise,
    })),
    settlements: snapshot.settlements.map(s => ({
      from: s.from._id || s.from,
      to: s.to._id || s.to,
      amountPaise: s.amountPaise,
    })),
  };
  await currentCycle.save();

  // Open brand new 30-day cycle with zero balances
  const nextStartDate = new Date();
  const nextEndDate = new Date(nextStartDate.getTime() + 30 * 24 * 60 * 60 * 1000);
  const nextCycle = await Cycle.create({
    group: groupId,
    cycleNumber: (currentCycle.cycleNumber || 1) + 1,
    startDate: nextStartDate,
    endDate: nextEndDate,
    status: 'open',
  });

  group.currentCycle = nextCycle._id;
  await group.save();

  // Emit real-time event if socket.io is provided
  if (io) {
    io.to(`group:${groupId}`).emit('cycle_closed', {
      closedCycleId: currentCycle._id,
      newCycleId: nextCycle._id,
      snapshot,
    });
  }

  return { closedCycle: currentCycle, newCycle: nextCycle, snapshot };
}

/**
 * Background cron job: finds all open cycles past their endDate and closes them.
 */
async function autoCloseExpiredCyclesJob(io = null) {
  try {
    const now = new Date();
    const expiredCycles = await Cycle.find({
      status: 'open',
      endDate: { $lte: now },
    });

    for (const cycle of expiredCycles) {
      console.log(`[Cron] Auto-closing expired cycle ${cycle._id} for group ${cycle.group}`);
      try {
        await closeCycle(cycle.group, null, false, io);
      } catch (err) {
        console.error(`[Cron] Error closing cycle ${cycle._id}:`, err.message);
      }
    }
  } catch (error) {
    console.error('[Cron] Error running autoCloseExpiredCyclesJob:', error.message);
  }
}

module.exports = {
  calculateCycleSnapshot,
  getOrCreateCurrentCycle,
  checkAndAutoCloseCycle,
  closeCycle,
  autoCloseExpiredCyclesJob,
};
