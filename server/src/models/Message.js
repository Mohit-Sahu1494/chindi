const mongoose = require('mongoose');

const messageSchema = new mongoose.Schema(
  {
    group: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Group',
      required: true,
      index: true,
    },
    sender: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    type: {
      type: String,
      enum: ['text', 'expense'],
      default: 'text',
      required: true,
    },
    text: {
      type: String,
      trim: true,
    },
    expense: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Expense',
    },
  },
  {
    timestamps: true,
  }
);

// Compound index for fast paginated chat query
messageSchema.index({ group: 1, createdAt: -1 });

module.exports = mongoose.model('Message', messageSchema);
