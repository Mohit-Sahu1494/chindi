const bcrypt = require('bcryptjs');
const mongoose = require('mongoose');
const { mongoUri } = require('../config/env');
const User = require('../models/User');
const Group = require('../models/Group');
const Cycle = require('../models/Cycle');
const Expense = require('../models/Expense');
const Message = require('../models/Message');
const { distributeShares } = require('../utils/money');

async function seed() {
  console.log('[Seed] Connecting to MongoDB:', mongoUri);
  await mongoose.connect(mongoUri);

  console.log('[Seed] Clearing existing collections...');
  await Promise.all([
    User.deleteMany({}),
    Group.deleteMany({}),
    Cycle.deleteMany({}),
    Expense.deleteMany({}),
    Message.deleteMany({}),
  ]);

  console.log('[Seed] Creating demo users...');
  const salt = await bcrypt.genSalt(10);
  const passwordHash = await bcrypt.hash('password123', salt);

  const [ramesh, suresh, amit, priya] = await User.create([
    {
      name: 'Ramesh Kumar',
      emailOrMobile: 'ramesh@hisaab.app',
      passwordHash,
    },
    {
      name: 'Suresh Sharma',
      emailOrMobile: 'suresh@hisaab.app',
      passwordHash,
    },
    {
      name: 'Amit Verma',
      emailOrMobile: 'amit@hisaab.app',
      passwordHash,
    },
    {
      name: 'Priya Singh',
      emailOrMobile: 'priya@hisaab.app',
      passwordHash,
    },
  ]);

  console.log('[Seed] Users created: Ramesh, Suresh, Amit, Priya (password: password123)');

  // Group 1: Flat 302 Roommates
  console.log('[Seed] Creating Group: Flat 302 Roommates...');
  const flatStartDate = new Date(Date.now() - 12 * 24 * 60 * 60 * 1000); // 12 days ago
  const flatEndDate = new Date(flatStartDate.getTime() + 30 * 24 * 60 * 60 * 1000);

  const flatGroup = await Group.create({
    name: 'Flat 302 Roommates',
    inviteCode: 'FLAT02',
    admin: ramesh._id,
    members: [ramesh._id, suresh._id, amit._id, priya._id],
  });

  const flatCycle = await Cycle.create({
    group: flatGroup._id,
    cycleNumber: 1,
    startDate: flatStartDate,
    endDate: flatEndDate,
    status: 'open',
  });

  flatGroup.currentCycle = flatCycle._id;
  await flatGroup.save();

  // Helper to add expense and message
  async function addExpense({ group, cycle, paidBy, amountPaise, description, excludedMembers, date }) {
    const allMembers = group.members.map(m => m.toString());
    const excludedSet = new Set((excludedMembers || []).map(m => m.toString()));
    const participants = allMembers.filter(m => !excludedSet.has(m));
    const shares = distributeShares(amountPaise, participants);

    const expense = await Expense.create({
      group: group._id,
      cycle: cycle._id,
      paidBy: paidBy._id,
      amountPaise,
      description,
      excludedMembers: Array.from(excludedSet),
      participants,
      shares,
      createdAt: date || new Date(),
    });

    const msg = await Message.create({
      group: group._id,
      sender: paidBy._id,
      type: 'expense',
      text: description,
      expense: expense._id,
      createdAt: date || new Date(),
    });

    return { expense, msg };
  }

  // Initial greeting message
  await Message.create({
    group: flatGroup._id,
    sender: ramesh._id,
    type: 'text',
    text: 'Namaste sabhi ko! Is group mein hum is mahine ke saare kharche track karenge.',
    createdAt: new Date(flatStartDate.getTime() + 10 * 60 * 1000),
  });

  await Message.create({
    group: flatGroup._id,
    sender: suresh._id,
    type: 'text',
    text: 'Sahi hai bhai, sab transparent rahega 👍',
    createdAt: new Date(flatStartDate.getTime() + 25 * 60 * 1000),
  });

  // Expense 1: Chai & Samosa (Ramesh pays ₹145, Suresh & Amit excluded)
  await addExpense({
    group: flatGroup,
    cycle: flatCycle,
    paidBy: ramesh,
    amountPaise: 14500, // ₹145
    description: 'Special Chai aur Samosa',
    excludedMembers: [suresh._id, amit._id],
    date: new Date(flatStartDate.getTime() + 2 * 24 * 60 * 60 * 1000),
  });

  // Expense 2: WiFi & Electricity (Suresh pays ₹800, all 4 participate)
  await addExpense({
    group: flatGroup,
    cycle: flatCycle,
    paidBy: suresh,
    amountPaise: 80000, // ₹800
    description: 'High Speed WiFi Bill',
    excludedMembers: [],
    date: new Date(flatStartDate.getTime() + 5 * 24 * 60 * 60 * 1000),
  });

  // Expense 3: Groceries & Milk (Priya pays ₹450, all 4 participate)
  await addExpense({
    group: flatGroup,
    cycle: flatCycle,
    paidBy: priya,
    amountPaise: 45000, // ₹450
    description: 'Kirana aur Doodh packet',
    excludedMembers: [],
    date: new Date(flatStartDate.getTime() + 8 * 24 * 60 * 60 * 1000),
  });

  await Message.create({
    group: flatGroup._id,
    sender: amit._id,
    type: 'text',
    text: 'Maine shaam ke snacks laaye the, par wo meri taraf se treat hai! 🍕',
    createdAt: new Date(flatStartDate.getTime() + 10 * 24 * 60 * 60 * 1000),
  });

  // Group 2: Goa Roadtrip
  console.log('[Seed] Creating Group: Goa Roadtrip...');
  const goaStartDate = new Date(Date.now() - 5 * 24 * 60 * 60 * 1000);
  const goaEndDate = new Date(goaStartDate.getTime() + 30 * 24 * 60 * 60 * 1000);

  const goaGroup = await Group.create({
    name: 'Goa Roadtrip 🏖️',
    inviteCode: 'GOATRP',
    admin: amit._id,
    members: [amit._id, ramesh._id, suresh._id],
  });

  const goaCycle = await Cycle.create({
    group: goaGroup._id,
    cycleNumber: 1,
    startDate: goaStartDate,
    endDate: goaEndDate,
    status: 'open',
  });

  goaGroup.currentCycle = goaCycle._id;
  await goaGroup.save();

  await addExpense({
    group: goaGroup,
    cycle: goaCycle,
    paidBy: amit,
    amountPaise: 250000, // ₹2,500
    description: 'Highway Petrol aur Toll Plaza',
    excludedMembers: [],
    date: new Date(goaStartDate.getTime() + 1 * 24 * 60 * 60 * 1000),
  });

  await addExpense({
    group: goaGroup,
    cycle: goaCycle,
    paidBy: suresh,
    amountPaise: 180000, // ₹1,800
    description: 'Beach Shack Dinner & Beverages',
    excludedMembers: [],
    date: new Date(goaStartDate.getTime() + 3 * 24 * 60 * 60 * 1000),
  });

  console.log('[Seed] Database seeded successfully!');
  console.log('--------------------------------------------------');
  console.log('Login credentials:');
  console.log('  Ramesh : ramesh@hisaab.app / password123');
  console.log('  Suresh : suresh@hisaab.app / password123');
  console.log('  Amit   : amit@hisaab.app   / password123');
  console.log('  Priya  : priya@hisaab.app  / password123');
  console.log('Groups:');
  console.log('  Flat 302 Roommates (Code: FLAT02)');
  console.log('  Goa Roadtrip 🏖️ (Code: GOATRP)');
  console.log('--------------------------------------------------');

  await mongoose.disconnect();
}

seed().catch(err => {
  console.error('[Seed] Error seeding database:', err);
  process.exit(1);
});
