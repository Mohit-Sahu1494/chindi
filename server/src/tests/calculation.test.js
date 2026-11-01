const { splitPaise, distributeShares, rupeesToPaise, paiseToRupees, formatPaise } = require('../utils/money');
const { computeSettlements } = require('../utils/settlement');

describe('Full Calculation Engine Verification (All Phases & Scenarios)', () => {
  describe('Phase 1: Basic Splitting & Precision Conservation', () => {
    test('Exact division produces identical integer shares', () => {
      const shares = splitPaise(30000, 3);
      expect(shares).toEqual([10000, 10000, 10000]);
      expect(shares.reduce((a, b) => a + b, 0)).toBe(30000);
    });

    test('Indivisible amounts conserve every single paisa without loss', () => {
      // 14500 paise (₹145) among 3 people: 14500 = 3 * 4833 + 1
      const shares = splitPaise(14500, 3);
      expect(shares).toEqual([4834, 4833, 4833]);
      expect(shares.reduce((a, b) => a + b, 0)).toBe(14500);
    });

    test('Smallest denomination (1 paisa) is never lost or duplicated', () => {
      const shares = splitPaise(1, 4);
      expect(shares).toEqual([1, 0, 0, 0]);
      expect(shares.reduce((a, b) => a + b, 0)).toBe(1);
    });

    test('Zero amount produces all zeroes', () => {
      const shares = splitPaise(0, 5);
      expect(shares).toEqual([0, 0, 0, 0, 0]);
      expect(shares.reduce((a, b) => a + b, 0)).toBe(0);
    });

    test('Throws on invalid inputs', () => {
      expect(() => splitPaise(-100, 3)).toThrow();
      expect(() => splitPaise(100.5, 3)).toThrow();
      expect(() => splitPaise(100, 0)).toThrow();
      expect(() => splitPaise(100, -1)).toThrow();
    });
  });

  describe('Phase 2: Share Distribution with Excluded Members', () => {
    test('Correctly maps shares to active participants only', () => {
      const allMembers = ['Ramesh', 'Suresh', 'Amit', 'Priya'];
      const excluded = ['Suresh', 'Amit'];
      const active = allMembers.filter(m => !excluded.includes(m)); // Ramesh, Priya

      const shares = distributeShares(5000, active);
      expect(shares).toEqual([
        { user: 'Ramesh', amountPaise: 2500 },
        { user: 'Priya', amountPaise: 2500 },
      ]);
      expect(shares.reduce((sum, s) => sum + s.amountPaise, 0)).toBe(5000);
    });

    test('Indivisible amount with 3 active members out of 5', () => {
      const active = ['user1', 'user2', 'user3'];
      const shares = distributeShares(1000, active); // 1000 / 3 = 333 remainder 1
      expect(shares).toEqual([
        { user: 'user1', amountPaise: 334 },
        { user: 'user2', amountPaise: 333 },
        { user: 'user3', amountPaise: 333 },
      ]);
      expect(shares.reduce((sum, s) => sum + s.amountPaise, 0)).toBe(1000);
    });
  });

  describe('Phase 3: Multi-Expense Cycle Balance & Zero-Sum Guarantee', () => {
    test('Simulates complex multi-expense group cycle with 100% zero-sum balance', () => {
      const users = ['Alice', 'Bob', 'Charlie', 'Dave'];
      const balances = {
        Alice: { paid: 0, share: 0 },
        Bob: { paid: 0, share: 0 },
        Charlie: { paid: 0, share: 0 },
        Dave: { paid: 0, share: 0 },
      };

      // Expense 1: Alice pays ₹1200 (120000 paise) for all 4
      const exp1Shares = distributeShares(120000, users);
      balances.Alice.paid += 120000;
      exp1Shares.forEach(s => { balances[s.user].share += s.amountPaise; });

      // Expense 2: Bob pays ₹650 (65000 paise) for Alice, Bob, Charlie (Dave excluded)
      const exp2Participants = ['Alice', 'Bob', 'Charlie'];
      const exp2Shares = distributeShares(65000, exp2Participants);
      balances.Bob.paid += 65000;
      exp2Shares.forEach(s => { balances[s.user].share += s.amountPaise; });

      // Expense 3: Dave pays ₹400 (40000 paise) for Charlie and Dave (Alice & Bob excluded)
      const exp3Participants = ['Charlie', 'Dave'];
      const exp3Shares = distributeShares(40000, exp3Participants);
      balances.Dave.paid += 40000;
      exp3Shares.forEach(s => { balances[s.user].share += s.amountPaise; });

      // Expense 4: Charlie pays ₹145 (14500 paise) for all 4
      const exp4Shares = distributeShares(14500, users);
      balances.Charlie.paid += 14500;
      exp4Shares.forEach(s => { balances[s.user].share += s.amountPaise; });

      // Compute net
      const netBalances = users.map(u => ({
        user: u,
        paidPaise: balances[u].paid,
        sharePaise: balances[u].share,
        netPaise: balances[u].paid - balances[u].share,
      }));

      // Total group spend
      const totalGroupSpend = 120000 + 65000 + 40000 + 14500;
      const totalPaid = netBalances.reduce((acc, b) => acc + b.paidPaise, 0);
      const totalShares = netBalances.reduce((acc, b) => acc + b.sharePaise, 0);
      const netSum = netBalances.reduce((acc, b) => acc + b.netPaise, 0);

      expect(totalPaid).toBe(totalGroupSpend);
      expect(totalShares).toBe(totalGroupSpend);
      // Zero-sum guarantee
      expect(netSum).toBe(0);

      // Verify settlements completely clear all debts
      const settlements = computeSettlements(netBalances);
      expect(settlements.length).toBeGreaterThan(0);

      // Apply settlements
      const afterSettlement = { ...balances };
      settlements.forEach(s => {
        expect(s.amountPaise).toBeGreaterThan(0);
      });

      // Total debtor amount == total creditor amount == total settlement transfer amount
      const totalDebts = netBalances.filter(b => b.netPaise < 0).reduce((sum, b) => sum + Math.abs(b.netPaise), 0);
      const totalCredits = netBalances.filter(b => b.netPaise > 0).reduce((sum, b) => sum + b.netPaise, 0);
      const totalSettled = settlements.reduce((sum, s) => sum + s.amountPaise, 0);

      expect(totalDebts).toBe(totalCredits);
      expect(totalSettled).toBe(totalDebts);
    });
  });

  describe('Phase 4: Indian Currency Formatting', () => {
    test('formats paise to Indian Rupee strings with correct lakhs and thousands grouping', () => {
      expect(formatPaise(14500)).toBe('₹145.00');
      expect(formatPaise(10000000)).toBe('₹1,00,000.00'); // ₹1 Lakh
      expect(formatPaise(100000000)).toBe('₹10,00,000.00'); // ₹10 Lakhs
      expect(formatPaise(4833)).toBe('₹48.33');
      expect(formatPaise(-25050)).toBe('-₹250.50');
      expect(formatPaise(0)).toBe('₹0.00');
    });

    test('rupeesToPaise and paiseToRupees handles standard and decimal values', () => {
      expect(rupeesToPaise(145)).toBe(14500);
      expect(rupeesToPaise('145.50')).toBe(14550);
      expect(rupeesToPaise('0.99')).toBe(99);
      expect(paiseToRupees(14550)).toBe(145.5);
    });
  });
});
