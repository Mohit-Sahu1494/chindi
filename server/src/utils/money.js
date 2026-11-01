/**
 * Money utilities for Hisaab
 * All calculations are done in integer paise to avoid IEEE 754 floating point rounding errors.
 * 1 Rupee = 100 Paise.
 */

/**
 * Splits totalPaise equally among participantCount participants.
 * Base = floor(totalPaise / participantCount).
 * The remainder (totalPaise % participantCount) is distributed 1 paise each
 * to the first remainder participants.
 * 
 * Guarantees:
 * - Each share is an integer
 * - The sum of all shares strictly equals totalPaise
 * 
 * @param {number} totalPaise Total amount in integer paise
 * @param {number} participantCount Number of participants (> 0)
 * @returns {number[]} Array of paise shares
 */
function splitPaise(totalPaise, participantCount) {
  if (!Number.isInteger(totalPaise) || totalPaise < 0) {
    throw new Error('Total paise must be a non-negative integer');
  }
  if (!Number.isInteger(participantCount) || participantCount <= 0) {
    throw new Error('Participant count must be a positive integer');
  }

  const base = Math.floor(totalPaise / participantCount);
  const remainder = totalPaise % participantCount;

  const shares = new Array(participantCount);
  for (let i = 0; i < participantCount; i++) {
    // Distribute 1 extra paise to first 'remainder' participants
    shares[i] = base + (i < remainder ? 1 : 0);
  }

  return shares;
}

/**
 * Distributes totalPaise among participant user IDs.
 * 
 * @param {number} totalPaise Total amount in integer paise
 * @param {string[]} participantUserIds Array of user IDs participating in the split
 * @returns {{ user: string, amountPaise: number }[]}
 */
function distributeShares(totalPaise, participantUserIds) {
  if (!Array.isArray(participantUserIds) || participantUserIds.length === 0) {
    throw new Error('At least one participant is required');
  }

  const shares = splitPaise(totalPaise, participantUserIds.length);
  return participantUserIds.map((userId, index) => ({
    user: userId,
    amountPaise: shares[index],
  }));
}

/**
 * Converts rupees (number or numeric string) to integer paise.
 * E.g., 145 -> 14500, "145.50" -> 14550.
 * 
 * @param {number|string} rupees
 * @returns {number} Integer paise
 */
function rupeesToPaise(rupees) {
  const num = typeof rupees === 'string' ? parseFloat(rupees) : rupees;
  if (isNaN(num) || num < 0) {
    throw new Error('Invalid rupee amount');
  }
  return Math.round(num * 100);
}

/**
 * Converts integer paise to rupees (float representation for display).
 * 
 * @param {number} paise 
 * @returns {number}
 */
function paiseToRupees(paise) {
  if (!Number.isInteger(paise)) {
    throw new Error('Paise must be an integer');
  }
  return paise / 100;
}

/**
 * Formats integer paise into Indian currency format (e.g. ₹1,45,000.50 or ₹145.00).
 * 
 * @param {number} paise 
 * @returns {string}
 */
function formatPaise(paise) {
  const isNegative = paise < 0;
  const absPaise = Math.abs(paise);
  const rupees = Math.floor(absPaise / 100);
  const remainderPaise = absPaise % 100;

  // Indian number grouping for rupees
  const rupeesStr = rupees.toString();
  let lastThree = rupeesStr.slice(-3);
  const otherNumbers = rupeesStr.slice(0, -3);
  let formattedRupees = otherNumbers !== '' 
    ? otherNumbers.replace(/\B(?=(\d{2})+(?!\d))/g, ',') + ',' + lastThree 
    : lastThree;

  const paiseStr = remainderPaise.toString().padStart(2, '0');
  const formatted = `₹${formattedRupees}.${paiseStr}`;

  return isNegative ? `-${formatted}` : formatted;
}

module.exports = {
  splitPaise,
  distributeShares,
  rupeesToPaise,
  paiseToRupees,
  formatPaise,
};
