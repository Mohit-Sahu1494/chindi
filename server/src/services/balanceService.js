const Group = require('../models/Group');
const Cycle = require('../models/Cycle');
const Expense = require('../models/Expense');
const { calculateCycleSnapshot, checkAndAutoCloseCycle } = require('./cycleService');

/**
 * Computes live balances, day progress, and settlements for a group's current cycle.
 */
async function getGroupLiveBalances(groupId) {
  const currentCycle = await checkAndAutoCloseCycle(groupId);
  const snapshot = await calculateCycleSnapshot(groupId, currentCycle._id);

  const now = new Date();
  const start = new Date(currentCycle.startDate);
  const end = new Date(currentCycle.endDate);

  const totalDurationMs = end.getTime() - start.getTime();
  const elapsedMs = Math.max(0, now.getTime() - start.getTime());

  // Day calculations
  const oneDayMs = 24 * 60 * 60 * 1000;
  const currentDay = Math.min(30, Math.floor(elapsedMs / oneDayMs) + 1);
  const daysLeft = Math.max(0, Math.ceil((end.getTime() - now.getTime()) / oneDayMs));

  return {
    cycle: {
      _id: currentCycle._id,
      cycleNumber: currentCycle.cycleNumber || 1,
      startDate: currentCycle.startDate,
      endDate: currentCycle.endDate,
      status: currentCycle.status,
    },
    currentDay,
    daysTotal: 30,
    daysLeft,
    totalPaise: snapshot.totalPaise,
    perUser: snapshot.perUser,
    settlements: snapshot.settlements,
  };
}

/**
 * Computes global overview for a user across all groups they belong to:
 * - Kul lena baaki (total receivables)
 * - Kul dena baaki (total payables)
 * - Group summaries with user's net amount and days left
 */
async function getUserGlobalSummary(userId) {
  const groups = await Group.find({ members: userId }).populate('members', 'name emailOrMobile admin');

  let totalLenaPaise = 0;
  let totalDenaPaise = 0;

  const groupSummaries = [];

  for (const group of groups) {
    const live = await getGroupLiveBalances(group._id);
    const userBalance = live.perUser.find(u => u.user._id.toString() === userId.toString());
    const netPaise = userBalance ? userBalance.netPaise : 0;
    const paidPaise = userBalance ? userBalance.paidPaise : 0;
    const sharePaise = userBalance ? userBalance.sharePaise : 0;

    if (netPaise > 0) {
      totalLenaPaise += netPaise;
    } else if (netPaise < 0) {
      totalDenaPaise += Math.abs(netPaise);
    }

    groupSummaries.push({
      group: {
        _id: group._id,
        name: group.name,
        inviteCode: group.inviteCode,
        admin: group.admin,
        membersCount: group.members.length,
      },
      cycle: live.cycle,
      daysLeft: live.daysLeft,
      currentDay: live.currentDay,
      totalGroupSpendPaise: live.totalPaise,
      userNetPaise: netPaise,
      userPaidPaise: paidPaise,
      userSharePaise: sharePaise,
    });
  }

  return {
    kulLenaBaakiPaise: totalLenaPaise,
    kulDenaBaakiPaise: totalDenaPaise,
    netOverallPaise: totalLenaPaise - totalDenaPaise,
    groups: groupSummaries,
  };
}

module.exports = {
  getGroupLiveBalances,
  getUserGlobalSummary,
};
