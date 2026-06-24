// functions/test/cycle.test.js
'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { resolveTimezone, getEffectiveCycleKey, DEFAULT_PAYMENT_DATE, _daysInMonth, _normalizePaymentDate } = require('../src/utils/cycle');

// Replikasi math lama (budget_limit_warning.js:52-64) — basis regresi drop-in.
function legacyWib(nowMs, paymentDate) {
  const wibNow = new Date(nowMs + 7 * 60 * 60 * 1000);
  const year = wibNow.getUTCFullYear();
  const month = wibNow.getUTCMonth() + 1;
  const day = wibNow.getUTCDate();
  let cycleYear = year, cycleMonth = month;
  if (day < paymentDate) {
    if (month === 1) { cycleYear--; cycleMonth = 12; } else { cycleMonth--; }
  }
  const cycleKey = `${cycleYear}-${String(cycleMonth).padStart(2, '0')}-${String(paymentDate).padStart(2, '0')}`;
  const cycleStartMs = Date.UTC(cycleYear, cycleMonth - 1, paymentDate) - 7 * 60 * 60 * 1000;
  return { cycleKey, cycleStartMs };
}

test('resolveTimezone: baca prefs.timezone', () => {
  assert.equal(resolveTimezone({ timezone: 'Europe/Moscow' }), 'Europe/Moscow');
});

test('resolveTimezone: fallback Asia/Jakarta saat absen/kosong/null', () => {
  assert.equal(resolveTimezone(null), 'Asia/Jakarta');
  assert.equal(resolveTimezone({}), 'Asia/Jakarta');
  assert.equal(resolveTimezone({ timezone: '' }), 'Asia/Jakarta');
});

test('getEffectiveCycleKey: Europe/Moscow (GMT+3) boundary benar', () => {
  // 2026-06-16T10:00:00Z → Moscow 13:00, 16 Jun; day 16 < pd 25 → siklus mundur ke 25 Mei
  const ts = Date.UTC(2026, 5, 16, 10, 0, 0);
  const r = getEffectiveCycleKey({ timestampMs: ts, timezone: 'Europe/Moscow', paymentDate: 25 });
  assert.equal(r.cycleKey, '2026-05-25');
  // midnight 25 Mei di Moscow (+3) = UTC 24 Mei 21:00
  assert.equal(r.cycleStartMs, Date.UTC(2026, 4, 25, 0, 0, 0) - 3 * 60 * 60 * 1000);
});

test('regresi: WIB (Asia/Jakarta) == math +7h lama (drop-in aman)', () => {
  const samples = [
    Date.UTC(2026, 5, 16, 3, 0, 0),
    Date.UTC(2026, 0, 3, 20, 0, 0),   // dekat batas tahun setelah +7h
    Date.UTC(2026, 11, 31, 17, 30, 0), // lintas tahun setelah +7h
  ];
  for (const ts of samples) {
    for (const pd of [1, 25, 31]) {
      const got = getEffectiveCycleKey({ timestampMs: ts, timezone: 'Asia/Jakarta', paymentDate: pd });
      const want = legacyWib(ts, pd);
      assert.equal(got.cycleKey, want.cycleKey, `cycleKey ts=${ts} pd=${pd}`);
      assert.equal(got.cycleStartMs, want.cycleStartMs, `cycleStartMs ts=${ts} pd=${pd}`);
    }
  }
});

test('_daysInMonth: panjang bulan termasuk kabisat', () => {
  assert.equal(_daysInMonth(2026, 1), 31);  // Januari
  assert.equal(_daysInMonth(2026, 2), 28);  // Februari non-kabisat
  assert.equal(_daysInMonth(2028, 2), 29);  // Februari kabisat
  assert.equal(_daysInMonth(2026, 4), 30);  // April
  assert.equal(_daysInMonth(2026, 12), 31); // Desember
});

test('_normalizePaymentDate: default 25 saat invalid, clamp [1..31]', () => {
  assert.equal(_normalizePaymentDate(25), 25);
  assert.equal(_normalizePaymentDate(1), 1);
  assert.equal(_normalizePaymentDate(31), 31);
  assert.equal(_normalizePaymentDate(0), DEFAULT_PAYMENT_DATE);         // pd=0 jebakan lama
  assert.equal(_normalizePaymentDate(undefined), DEFAULT_PAYMENT_DATE); // absen
  assert.equal(_normalizePaymentDate(null), DEFAULT_PAYMENT_DATE);
  assert.equal(_normalizePaymentDate(40), 31);                          // di atas batas → clamp
  assert.equal(_normalizePaymentDate(25.9), 25);                        // floor
});
