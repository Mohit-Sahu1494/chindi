const { z } = require('zod');
const {
  createExpense,
  updateExpense,
  deleteExpense,
} = require('../services/expenseService');
const { sendSuccess } = require('../utils/apiResponse');

const createExpenseSchema = z.object({
  amountPaise: z.number().int('Amount must be an integer in paise').positive('Amount must be greater than zero'),
  description: z.string().min(1, 'Description is required').max(200, 'Description too long'),
  excludedMembers: z.array(z.string()).optional().default([]),
});

const updateExpenseSchema = z.object({
  amountPaise: z.number().int('Amount must be an integer in paise').positive('Amount must be greater than zero'),
  description: z.string().min(1, 'Description is required').max(200, 'Description too long'),
  excludedMembers: z.array(z.string()).optional().default([]),
});

async function handleCreateExpense(req, res, next) {
  try {
    const groupId = req.params.id;
    const { amountPaise, description, excludedMembers } = req.body;
    const io = req.app.get('io');

    const result = await createExpense(
      {
        groupId,
        paidByUserId: req.user._id,
        amountPaise,
        description,
        excludedMemberIds: excludedMembers,
      },
      io
    );

    return sendSuccess(res, result, 'Expense added successfully', 201);
  } catch (error) {
    next(error);
  }
}

async function handleUpdateExpense(req, res, next) {
  try {
    const expenseId = req.params.id;
    const { amountPaise, description, excludedMembers } = req.body;
    const io = req.app.get('io');

    const updated = await updateExpense(
      expenseId,
      req.user._id,
      { amountPaise, description, excludedMemberIds: excludedMembers },
      io
    );

    return sendSuccess(res, updated, 'Expense updated successfully');
  } catch (error) {
    next(error);
  }
}

async function handleDeleteExpense(req, res, next) {
  try {
    const expenseId = req.params.id;
    const io = req.app.get('io');

    const result = await deleteExpense(expenseId, req.user._id, io);
    return sendSuccess(res, result, 'Expense deleted successfully');
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createExpenseSchema,
  updateExpenseSchema,
  handleCreateExpense,
  handleUpdateExpense,
  handleDeleteExpense,
};
