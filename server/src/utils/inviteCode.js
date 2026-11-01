const crypto = require('crypto');

/**
 * Generates a clean 6-character uppercase alphanumeric invite code.
 * Excludes easily confusable characters (0, O, 1, I).
 */
function generateInviteCode() {
  const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  let code = '';
  const bytes = crypto.randomBytes(6);
  for (let i = 0; i < 6; i++) {
    code += chars[bytes[i] % chars.length];
  }
  return code;
}

module.exports = {
  generateInviteCode,
};
