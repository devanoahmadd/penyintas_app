// functions/test/cycle.test.js
'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { resolveTimezone, getEffectiveCycleKey, getEffectiveMonthKey, DEFAULT_PAYMENT_DATE, _daysInMonth, _normalizePaymentDate, _safeZone } = require('../src/utils/cycle');

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

test('_safeZone: zona valid lolos, zona tak dikenal → Asia/Jakarta', () => {
  assert.equal(_safeZone('Europe/Moscow'), 'Europe/Moscow');
  assert.equal(_safeZone('Asia/Jakarta'), 'Asia/Jakarta');
  assert.equal(_safeZone('Foo/Bar'), 'Asia/Jakarta');     // ter-tamper / tak dikenal
  assert.equal(_safeZone(''), 'Asia/Jakarta');
});

test('resolveTimezone: tz tak dikenal yang lolos rules → fallback (T-1)', () => {
  assert.equal(resolveTimezone({ timezone: 'Foo/Bar' }), 'Asia/Jakarta');
});

test('getEffectiveCycleKey: tz tak dikenal tidak melempar (T-1)', () => {
  assert.doesNotThrow(() =>
    getEffectiveCycleKey({ timestampMs: Date.UTC(2026, 5, 16, 3), timezone: 'Foo/Bar', paymentDate: 25 }),
  );
  // jatuh ke WIB → cycleKey valid
  const r = getEffectiveCycleKey({ timestampMs: Date.UTC(2026, 5, 16, 3), timezone: 'Foo/Bar', paymentDate: 25 });
  assert.match(r.cycleKey, /^\d{4}-\d{2}-\d{2}$/);
});

test('getEffectiveCycleKey: clamp F-D8 pd=31 ke akhir bulan pendek', () => {
  // Feb 2026 (28 hari), hari 28 → pdThisMonth=min(31,28)=28 → 28<28 false → siklus Feb
  let r = getEffectiveCycleKey({ timestampMs: Date.UTC(2026, 1, 28, 5), timezone: 'Asia/Jakarta', paymentDate: 31 });
  assert.equal(r.cycleKey, '2026-02-28');
  // Feb 2028 kabisat, hari 29 → clamp 29
  r = getEffectiveCycleKey({ timestampMs: Date.UTC(2028, 1, 29, 5), timezone: 'Asia/Jakarta', paymentDate: 31 });
  assert.equal(r.cycleKey, '2028-02-29');
  // April (30 hari), hari 30 → clamp 30
  r = getEffectiveCycleKey({ timestampMs: Date.UTC(2026, 3, 30, 5), timezone: 'Asia/Jakarta', paymentDate: 31 });
  assert.equal(r.cycleKey, '2026-04-30');
});

test('getEffectiveCycleKey: pertengahan bulan pendek pd=31 mundur ke bulan sebelumnya', () => {
  // Feb 2026 hari 15 → pdThisMonth=28 → 15<28 → mundur ke Jan, cycleDay=min(31,31)=31
  const r = getEffectiveCycleKey({ timestampMs: Date.UTC(2026, 1, 15, 5), timezone: 'Asia/Jakarta', paymentDate: 31 });
  assert.equal(r.cycleKey, '2026-01-31');
});

test('getEffectiveCycleKey: cycleStartLocalIso format & ordering leksikografis (K-1)', () => {
  const r = getEffectiveCycleKey({ timestampMs: Date.UTC(2026, 5, 16, 3), timezone: 'Asia/Jakarta', paymentDate: 25 });
  assert.equal(r.cycleStartLocalIso, '2026-05-25T00:00:00.000');
  assert.match(r.cycleStartLocalIso, /^\d{4}-\d{2}-\d{2}T00:00:00\.000$/);
  // tx dalam siklus (16 Jun) > boundary; tx pra-siklus (24 Mei 23:59) < boundary
  assert.ok(r.cycleStartLocalIso <= '2026-06-16T10:00:00.000');
  assert.ok(r.cycleStartLocalIso > '2026-05-24T23:59:59.999');
  // batas-bawah aman lintas presisi: microsecond 6-digit tetap > boundary .000
  assert.ok('2026-05-25T00:00:00.123456' > r.cycleStartLocalIso);
});

test('getEffectiveCycleKey: cycleKey selalu valid pd[1..31] x 12 bulan (kriteria #2)', () => {
  const daysIn = (y, m) => new Date(Date.UTC(y, m, 0)).getUTCDate();
  for (let mo = 0; mo < 12; mo++) {
    for (let pd = 1; pd <= 31; pd++) {
      const r = getEffectiveCycleKey({ timestampMs: Date.UTC(2026, mo, 15, 5), timezone: 'Asia/Jakarta', paymentDate: pd });
      const [yy, mm, dd] = r.cycleKey.split('-').map(Number);
      assert.ok(dd >= 1 && dd <= daysIn(yy, mm), `cycleKey invalid: ${r.cycleKey} (pd=${pd} mo=${mo})`);
      assert.equal(r.cycleStartLocalIso, `${r.cycleKey}T00:00:00.000`);
      assert.ok(Number.isFinite(r.cycleStartMs));
    }
  }
});

test('getEffectiveMonthKey: parity WIB == monthKey legacy', () => {
  function legacyMonthKeyWib(nowMs) {
    const w = new Date(nowMs + 7 * 60 * 60 * 1000);
    return `${w.getUTCFullYear()}_${String(w.getUTCMonth() + 1).padStart(2, '0')}`;
  }
  for (const ts of [Date.UTC(2026, 5, 16, 3), Date.UTC(2026, 0, 3, 20), Date.UTC(2026, 11, 31, 17, 30)]) {
    assert.equal(getEffectiveMonthKey({ timestampMs: ts, timezone: 'Asia/Jakarta' }).monthKey, legacyMonthKeyWib(ts));
  }
});

test('getEffectiveMonthKey: boundary ISO + rollover Desember', () => {
  let m = getEffectiveMonthKey({ timestampMs: Date.UTC(2026, 5, 16, 3), timezone: 'Asia/Jakarta' });
  assert.equal(m.monthKey, '2026_06');
  assert.equal(m.monthStartLocalIso, '2026-06-01T00:00:00.000');
  assert.equal(m.nextMonthStartLocalIso, '2026-07-01T00:00:00.000');
  m = getEffectiveMonthKey({ timestampMs: Date.UTC(2026, 11, 15, 3), timezone: 'Asia/Jakarta' });
  assert.equal(m.monthKey, '2026_12');
  assert.equal(m.nextMonthStartLocalIso, '2027-01-01T00:00:00.000');
});

test('getEffectiveMonthKey: zona menggeser bulan di batas (non-WIB)', () => {
  // 2026-06-30T17:30Z == 2026-07-01T00:30 WIB → WIB sudah Juli, UTC masih Juni
  const ts = Date.UTC(2026, 5, 30, 17, 30);
  assert.equal(getEffectiveMonthKey({ timestampMs: ts, timezone: 'Asia/Jakarta' }).monthKey, '2026_07');
  assert.equal(getEffectiveMonthKey({ timestampMs: ts, timezone: 'UTC' }).monthKey, '2026_06');
});
