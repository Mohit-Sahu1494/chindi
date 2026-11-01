const mongoose = require('mongoose');

const perUserSnapshotSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    paidPaise: {
      type: Number,
      required: true,
      default: 0,
    },
    sharePaise: {
      type: Number,
      required: true,
      default: 0,
    },
    netPaise: {
      type: Number,
      required: true,
      default: 0,
    },
  },
  { _id: false }
);

const settlementSnapshotSchema = new mongoose.Schema(
  {
    from: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    to: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    amountPaise: {
      type: Number,
      required: true,
    },
  },
  { _id: false }
);

const cycleSchema = new mongoose.Schema(
  {
    group: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Group',
      required: true,
      index: true,
    },
    cycleNumber: {
      type: Number,
      default: 1,
    },
    startDate: {
      type: Date,
      required: true,
    },
    endDate: {
      type: Date,
      required: true,
    },
    status: {
      type: String,
      enum: ['open', 'closed'],
      default: 'open',
      index: true,
    },
    closedAt: {
      type: Date,
    },
    snapshot: {
      totalPaise: {
        type: Number,
        default: 0,
      },
      perUser: [perUserSnapshotSchema],
      settlements: [settlementSnapshotSchema],
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Cycle', cycleSchema);
