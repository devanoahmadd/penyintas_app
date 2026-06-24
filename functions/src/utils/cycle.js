// functions/src/utils/cycle.js
'use strict';

const DEFAULT_TZ = 'Asia/Jakarta';

/** Kembalikan tz bila zona IANA valid; selainnya DEFAULT_TZ (cegah RangeError Intl). */
function _safeZone(tz) {
  try {
    new Intl.DateTimeFormat('en-US', { timeZone: tz });
    return tz;
  } catch {
    return DEFAULT_TZ;
  }
}

/** prefs.timezone bila string non-kosong, selainnya Asia/Jakarta. */
function resolveTimezone(prefs) {
  const tz = prefs && typeof prefs.timezone === 'string' ? prefs.timezone.trim() : '';
  return _safeZone(tz.length > 0 ? tz : DEFAULT_TZ);
}

/** Wall-clock parts sebuah instant di zona IANA tertentu. */
function _zonedParts(timestampMs, timeZone) {
  const dtf = new Intl.DateTimeFormat('en-US', {
    timeZone,
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit',
    hourCycle: 'h23',
  });
  const out = {};
  for (const p of dtf.formatToParts(new Date(timestampMs))) {
    if (p.type !== 'literal') out[p.type] = Number(p.value);
  }
  return out; // { year, month, day, hour, minute, second }
}

/** Offset zona (ms) pada sebuah instant = (wallclock-as-UTC) − UTC-asli. */
function _offsetMs(timestampMs, timeZone) {
  const p = _zonedParts(timestampMs, timeZone);
  const asUtc = Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second);
  return asUtc - timestampMs;
}

/** UTC ms dari tengah-malam lokal (00:00:00) y-m-d di timeZone (DST-aware). */
function _localMidnightUtcMs(year, month, day, timeZone) {
  const guess = Date.UTC(year, month - 1, day, 0, 0, 0);
  const offset = _offsetMs(guess, timeZone); // koreksi sekali — aman utk tengah malam
  return guess - offset;
}

function _pad2(n) {
  return String(n).padStart(2, '0');
}

const DEFAULT_PAYMENT_DATE = 25;

/** Jumlah hari dalam bulan (month 1-based). Tz-independent. */
function _daysInMonth(year, month) {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

/** paymentDate kanonik: integer [1..31]; default 25 bila invalid/<1; clamp 31. */
function _normalizePaymentDate(paymentDate) {
  const n = Number(paymentDate);
  if (!Number.isFinite(n) || n < 1) return DEFAULT_PAYMENT_DATE;
  if (n > 31) return 31;
  return Math.floor(n);
}

/**
 * Cycle boundary IANA-aware untuk siklus anggaran berbasis paymentDate.
 * Pengganti DST-/non-jam-bulat-benar dari math `+7h WIB` mentah
 * (budget_limit_warning.js:52,64). Dirancang menerima `cycleType` belakangan
 * tanpa breaking (W6/A3).
 * @param {{ timestampMs:number, timezone:string, paymentDate:number }} args
 * @returns {{ cycleKey:string, cycleStartMs:number, cycleStartLocalIso:string }}
 */
function getEffectiveCycleKey({ timestampMs, timezone, paymentDate }) {
  const tz = _safeZone((typeof timezone === 'string' && timezone.trim()) ? timezone.trim() : DEFAULT_TZ);
  const pd = _normalizePaymentDate(paymentDate);
  const now = _zonedParts(timestampMs, tz);
  let cycleYear = now.year;
  let cycleMonth = now.month;
  // F-D8: clamp pd ke panjang bulan agar tak ada tanggal invalid/overflow.
  const pdThisMonth = Math.min(pd, _daysInMonth(now.year, now.month));
  if (now.day < pdThisMonth) {
    if (cycleMonth === 1) { cycleYear -= 1; cycleMonth = 12; }
    else { cycleMonth -= 1; }
  }
  const cycleDay = Math.min(pd, _daysInMonth(cycleYear, cycleMonth));
  const cycleKey = `${cycleYear}-${_pad2(cycleMonth)}-${_pad2(cycleDay)}`;
  const cycleStartMs = _localMidnightUtcMs(cycleYear, cycleMonth, cycleDay, tz);
  // K-1: boundary string lokal-naif untuk query string-vs-string (date disimpan ISO string).
  const cycleStartLocalIso = `${cycleYear}-${_pad2(cycleMonth)}-${_pad2(cycleDay)}T00:00:00.000`;
  return { cycleKey, cycleStartMs, cycleStartLocalIso };
}

/**
 * Month-key & boundary kalender IANA-aware untuk Survival-Mode (bulan kalender).
 * @param {{ timestampMs:number, timezone:string }} args
 * @returns {{ monthKey:string, monthStartLocalIso:string, nextMonthStartLocalIso:string }}
 */
function getEffectiveMonthKey({ timestampMs, timezone }) {
  const tz = _safeZone((typeof timezone === 'string' && timezone.trim()) ? timezone.trim() : DEFAULT_TZ);
  const now = _zonedParts(timestampMs, tz);
  const monthKey = `${now.year}_${_pad2(now.month)}`;
  const monthStartLocalIso = `${now.year}-${_pad2(now.month)}-01T00:00:00.000`;
  let ny = now.year;
  let nm = now.month + 1;
  if (nm === 13) { ny += 1; nm = 1; }
  const nextMonthStartLocalIso = `${ny}-${_pad2(nm)}-01T00:00:00.000`;
  return { monthKey, monthStartLocalIso, nextMonthStartLocalIso };
}

module.exports = {
  resolveTimezone,
  getEffectiveCycleKey,
  getEffectiveMonthKey,
  DEFAULT_TZ,
  DEFAULT_PAYMENT_DATE,
  _daysInMonth,
  _normalizePaymentDate,
  _safeZone,
};
