const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const {
  updateExpenseSchema,
  handleUpdateExpense,
  handleDeleteExpense,
} = require('../controllers/expenseController');

router.use(authenticate);

router.patch('/:id', validate(updateExpenseSchema), handleUpdateExpense);
router.delete('/:id', handleDeleteExpense);

module.exports = router;
