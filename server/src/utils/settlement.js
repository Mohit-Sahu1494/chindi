/**
 * Minimum Transactions Settlement Algorithm for Hisaab
 * 
 * Given a list of user balances where netPaise = paidPaise - sharePaise:
 * - netPaise > 0 means the user is owed money (creditor)
 * - netPaise < 0 means the user owes money (debtor)
 * - Sum of netPaise for all group members strictly equals 0.
 * 
 * Computes a simplified list of transactions:
 * [ { from: userId, to: userId, amountPaise: number } ]
 */

/**
 * Computes simplified settlements from user net balances.
 * 
 * @param {Array<{ user: string|object, netPaise: number }>} balances
 * @returns {Array<{ from: string|object, to: string|object, amountPaise: number }>}
 */
function computeSettlements(balances) {
  if (!Array.isArray(balances) || balances.length === 0) {
    return [];
  }

  // Deep copy / extract debtors and creditors
  const debtors = [];
  const creditors = [];

  for (const b of balances) {
    const net = b.netPaise || 0;
    if (net < 0) {
      debtors.push({ user: b.user, amount: Math.abs(net) });
    } else if (net > 0) {
      creditors.push({ user: b.user, amount: net });
    }
  }

  // Sort descending by amount to minimize total transaction count greedily
  debtors.sort((a, b) => b.amount - a.amount);
  creditors.sort((a, b) => b.amount - a.amount);

  const settlements = [];

  let dIdx = 0;
  let cIdx = 0;

  while (dIdx < debtors.length && cIdx < creditors.length) {
    const debtor = debtors[dIdx];
    const creditor = creditors[cIdx];

    const amountToSettle = Math.min(debtor.amount, creditor.amount);

    if (amountToSettle > 0) {
      settlements.push({
        from: debtor.user,
        to: creditor.user,
        amountPaise: amountToSettle,
      });

      debtor.amount -= amountToSettle;
      creditor.amount -= amountToSettle;
    }

    if (debtor.amount === 0) {
      dIdx++;
    }
    if (creditor.amount === 0) {
      cIdx++;
    }
  }

  return settlements;
}

module.exports = {
  computeSettlements,
};
