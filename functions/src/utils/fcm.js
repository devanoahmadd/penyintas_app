// functions/src/utils/fcm.js
'use strict';

const DEAD_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-argument',
]);

/**
 * Gabungkan token subcollection (doc IDs) dengan field legacy fcmToken, dedup.
 * @param {string[]} subcollectionTokens
 * @param {string|null|undefined} legacyToken
 * @returns {{ tokens: string[], legacyToken: string|null }}
 */
function collectTokens(subcollectionTokens, legacyToken) {
  const set = new Set();
  for (const t of subcollectionTokens || []) {
    if (typeof t === 'string' && t.length > 0) set.add(t);
  }
  const legacy =
    typeof legacyToken === 'string' && legacyToken.length > 0 ? legacyToken : null;
  if (legacy) set.add(legacy);
  return { tokens: [...set], legacyToken: legacy };
}

/**
 * Token mati dari hasil sendEachForMulticast (urutan responses == urutan tokens).
 * @param {string[]} tokens
 * @param {Array<{success:boolean, error?:{code:string}}>} responses
 * @returns {string[]}
 */
function deadTokensFromResponses(tokens, responses) {
  const dead = [];
  (responses || []).forEach((r, i) => {
    if (!r.success && r.error && DEAD_CODES.has(r.error.code)) {
      dead.push(tokens[i]);
    }
  });
  return dead;
}

/** Push aktif kecuali settings.pushEnabled === false (opt-out). */
function isPushEnabled(settingsData) {
  return !(settingsData && settingsData.pushEnabled === false);
}

module.exports = { collectTokens, deadTokensFromResponses, isPushEnabled, DEAD_CODES };
