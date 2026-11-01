const { splitPaise, distributeShares, rupeesToPaise, paiseToRupees } = require('../utils/money');
const { computeSettlements } = require('../utils/settlement');

describe('Money and Balance Logic', () => {
  describe('splitPaise', () => {
    test('splits 14500 paise (₹145) among 3 people with exact penny conservation', () => {
      // User requirement example:
      // Ramesh pays 145 for chai, Suresh and Amit are excluded, 3 people remain,
      // so each share is 48.33 (in paise: 4834, 4833, 4833 -> sum = 14500)
      const shares = splitPaise(14500, 3);
      expect(shares).toHaveLength(3);
      expect(shares).toEqual([4834, 4833, 4833]);
      const sum = shares.reduce((a, b) => a + b, 0);
      expect(sum).toBe(14500);
    });

    test('splits perfectly divisible amounts evenly', () => {
      const shares = splitPaise(30000, 3); // ₹300 among 3
      expect(shares).toEqual([10000, 10000, 10000]);
      expect(shares.reduce((a, b) => a + b, 0)).toBe(30000);
    });

    test('splits 100 paise (₹1) among 3 people without loss of paise', () => {
      const shares = splitPaise(100, 3);
      expect(shares).toEqual([34, 33, 33]);
      expect(shares.reduce((a, b) => a + b, 0)).toBe(100);
    });

    test('splits 1 paise among 3 people', () => {
      const shares = splitPaise(1, 3);
      expect(shares).toEqual([1, 0, 0]);
      expect(shares.reduce((a, b) => a + b, 0)).toBe(1);
    });

    test('throws error for invalid participant count or negative amounts', () => {
      expect(() => splitPaise(100, 0)).toThrow();
      expect(() => splitPaise(-100, 2)).toThrow();
      expect(() => splitPaise(10.5, 2)).toThrow();
    });
  });

  describe('distributeShares', () => {
    test('assigns shares to participants correctly', () => {
      const participants = ['userA', 'userB', 'userC'];
      const distributed = distributeShares(1000, participants);
      expect(distributed).toEqual([
        { user: 'userA', amountPaise: 334 },
        { user: 'userB', amountPaise: 333 },
        { user: 'userC', amountPaise: 333 },
      ]);
      const total = distributed.reduce((acc, curr) => acc + curr.amountPaise, 0);
      expect(total).toBe(1000);
    });
  });

  describe('rupeesToPaise and paiseToRupees', () => {
    test('converts rupees to paise accurately without floating point errors', () => {
      expect(rupeesToPaise(145)).toBe(14500);
      expect(rupeesToPaise(48.33)).toBe(4833);
      expect(rupeesToPaise('120.50')).toBe(12050);
      expect(rupeesToPaise('0.05')).toBe(5);
    });

    test('converts paise to rupees accurately', () => {
      expect(paiseToRupees(14500)).toBe(145);
      expect(paiseToRupees(4833)).toBe(48.33);
      expect(paiseToRupees(5)).toBe(0.05);
    });
  });

  describe('Group Balances & Zero-Sum Guarantee', () => {
    test('sum of all net balances across multiple expenses must strictly equal zero', () => {
      // Simulate 4 users: U1 (Ramesh), U2 (Suresh), U3 (Amit), U4 (Priya)
      const users = ['U1', 'U2', 'U3', 'U4'];
      const paidMap = { U1: 0, U2: 0, U3: 0, U4: 0 };
      const shareMap = { U1: 0, U2: 0, U3: 0, U4: 0 };

      // Expense 1: U1 pays ₹145 for Chai, all 4 participate
      const exp1Amount = 14500;
      paidMap.U1 += exp1Amount;
      const exp1Shares = distributeShares(exp1Amount, users);
      exp1Shares.forEach(s => { shareMap[s.user] += s.amountPaise; });

      // Expense 2: U2 pays ₹300 for Lunch, U4 is excluded (U1, U2, U3 participate)
      const exp2Amount = 30000;
      paidMap.U2 += exp2Amount;
      const exp2Shares = distributeShares(exp2Amount, ['U1', 'U2', 'U3']);
      exp2Shares.forEach(s => { shareMap[s.user] += s.amountPaise; });

      // Expense 3: U3 pays ₹50 for Auto, only U1 and U3 participate
      const exp3Amount = 5000;
      paidMap.U3 += exp3Amount;
      const exp3Shares = distributeShares(exp3Amount, ['U1', 'U3']);
      exp3Shares.forEach(s => { shareMap[s.user] += s.amountPaise; });

      // Calculate net per user: net = paid - share
      let sumOfAllNets = 0;
      const nets = {};
      users.forEach(u => {
        nets[u] = paidMap[u] - shareMap[u];
        sumOfAllNets += nets[u];
      });

      // Strict Zero-Sum rule
      expect(sumOfAllNets).toBe(0);
    });
  });

  describe('Minimum Transactions Settlement Algorithm', () => {
    test('simplifies settlements correctly and clears all debts', () => {
      // Suppose:
      // Ramesh (U1) is net +₹290 (+29000 paise)
      // Amit (U2) is net -₹200 (-20000 paise)
      // Suresh (U3) is net -₹90 (-9000 paise)
      const balances = [
        { user: 'Ramesh', netPaise: 29000 },
        { user: 'Amit', netPaise: -20000 },
        { user: 'Suresh', netPaise: -9000 },
      ];

      const settlements = computeSettlements(balances);

      expect(settlements).toHaveLength(2);
      expect(settlements).toEqual([
        { from: 'Amit', to: 'Ramesh', amountPaise: 20000 },
        { from: 'Suresh', to: 'Ramesh', amountPaise: 9000 },
      ]);

      // Total settled matches total debt
      const totalSettled = settlements.reduce((acc, s) => acc + s.amountPaise, 0);
      expect(totalSettled).toBe(29000);
    });

    test('handles empty or balanced inputs', () => {
      expect(computeSettlements([])).toEqual([]);
      expect(computeSettlements([{ user: 'A', netPaise: 0 }, { user: 'B', netPaise: 0 }])).toEqual([]);
    });

    test('handles complex multi-party circular debts with minimum transactions', () => {
      const balances = [
        { user: 'User1', netPaise: 10000 },
        { user: 'User2', netPaise: 5000 },
        { user: 'User3', netPaise: -7000 },
        { user: 'User4', netPaise: -8000 },
      ];

      const settlements = computeSettlements(balances);
      // Verify all debts are cleared
      const netAfterSettlement = { User1: 10000, User2: 5000, User3: -7000, User4: -8000 };
      settlements.forEach(s => {
        netAfterSettlement[s.from] += s.amountPaise;
        netAfterSettlement[s.to] -= s.amountPaise;
      });

      Object.values(netAfterSettlement).forEach(net => {
        expect(net).toBe(0);
      });
      expect(settlements.length).toBeLessThanOrEqual(3);
    });
  });
});
