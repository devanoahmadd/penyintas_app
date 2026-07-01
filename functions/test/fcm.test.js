'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { collectTokens, deadTokensFromResponses, isPushEnabled } = require('../src/utils/fcm');

test('collectTokens: union subcollection + legacy, dedup', () => {
  const r = collectTokens(['a', 'b'], 'b'); // 'b' duplikat
  assert.deepEqual(r.tokens.sort(), ['a', 'b']);
  assert.equal(r.legacyToken, 'b');
});

test('collectTokens: legacy null/invalid diabaikan', () => {
  assert.deepEqual(collectTokens(['a'], null), { tokens: ['a'], legacyToken: null });
  assert.deepEqual(collectTokens(['a'], ''), { tokens: ['a'], legacyToken: null });
  assert.deepEqual(collectTokens([], undefined), { tokens: [], legacyToken: null });
});

test('collectTokens: legacy unik ditambahkan', () => {
  const r = collectTokens(['a'], 'z');
  assert.deepEqual(r.tokens.sort(), ['a', 'z']);
  assert.equal(r.legacyToken, 'z');
});

test('deadTokensFromResponses: prune hanya code mati', () => {
  const tokens = ['a', 'b', 'c'];
  const responses = [
    { success: true },
    { success: false, error: { code: 'messaging/registration-token-not-registered' } },
    { success: false, error: { code: 'messaging/internal-error' } }, // bukan mati → jangan prune
  ];
  assert.deepEqual(deadTokensFromResponses(tokens, responses), ['b']);
});

test('deadTokensFromResponses: invalid-argument ikut di-prune', () => {
  assert.deepEqual(
    deadTokensFromResponses(['x'], [{ success: false, error: { code: 'messaging/invalid-argument' } }]),
    ['x'],
  );
});

test('isPushEnabled: default true (opt-out)', () => {
  assert.equal(isPushEnabled(null), true);
  assert.equal(isPushEnabled({}), true);
  assert.equal(isPushEnabled({ pushEnabled: true }), true);
  assert.equal(isPushEnabled({ pushEnabled: false }), false);
});
