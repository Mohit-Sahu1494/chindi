const Cycle = require('../models/Cycle');
const Group = require('../models/Group');
const { getGroupLiveBalances } = require('../services/balanceService');
const { closeCycle } = require('../services/cycleService');
const { sendSuccess, sendError } = require('../utils/apiResponse');

async function handleGetCurrentCycle(req, res, next) {
  try {
    const groupId = req.params.id;
    const balances = await getGroupLiveBalances(groupId);
    return sendSuccess(res, balances, 'Current cycle balances retrieved');
  } catch (error) {
    next(error);
  }
}

async function handleGetGroupCycles(req, res, next) {
  try {
    const groupId = req.params.id;
    const pastCycles = await Cycle.find({
      group: groupId,
      status: 'closed',
    })
      .sort({ cycleNumber: -1 })
      .populate('snapshot.perUser.user', 'name emailOrMobile')
      .populate('snapshot.settlements.from', 'name emailOrMobile')
      .populate('snapshot.settlements.to', 'name emailOrMobile');

    return sendSuccess(res, pastCycles, 'Cycle history retrieved');
  } catch (error) {
    next(error);
  }
}

async function handleGetCycleById(req, res, next) {
  try {
    const cycle = await Cycle.findById(req.params.id)
      .populate('snapshot.perUser.user', 'name emailOrMobile')
      .populate('snapshot.settlements.from', 'name emailOrMobile')
      .populate('snapshot.settlements.to', 'name emailOrMobile');

    if (!cycle) {
      return sendError(res, 'Cycle not found', 404);
    }

    // Verify user is in group
    const group = await Group.findById(cycle.group);
    if (!group || !group.members.some(m => m.toString() === req.user._id.toString())) {
      return sendError(res, 'Access denied to this cycle report', 403);
    }

    return sendSuccess(res, cycle, 'Cycle details retrieved');
  } catch (error) {
    next(error);
  }
}

async function handleCloseCycle(req, res, next) {
  try {
    const groupId = req.params.id;
    const io = req.app.get('io');

    const result = await closeCycle(groupId, req.user._id, true, io);
    return sendSuccess(res, result, 'Cycle closed successfully. New cycle started.');
  } catch (error) {
    next(error);
  }
}

module.exports = {
  handleGetCurrentCycle,
  handleGetGroupCycles,
  handleGetCycleById,
  handleCloseCycle,
};
