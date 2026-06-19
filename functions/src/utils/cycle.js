// functions/src/utils/cycle.js
'use strict';

const DEFAULT_TZ = 'Asia/Jakarta';

/** prefs.timezone bila string non-kosong, selainnya Asia/Jakarta. */
function resolveTimezone(prefs) {
  const tz = prefs && typeof prefs.timezone === 'string' ? prefs.timezone.trim() : '';
  return tz.length > 0 ? tz : DEFAULT_TZ;
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

/**
 * Cycle boundary IANA-aware untuk siklus anggaran berbasis paymentDate.
 * Pengganti DST-/non-jam-bulat-benar dari math `+7h WIB` mentah
 * (budget_limit_warning.js:52,64). Dirancang menerima `cycleType` belakangan
 * tanpa breaking (W6/A3).
 * @param {{ timestampMs:number, timezone:string, paymentDate:number }} args
 * @returns {{ cycleKey:string, cycleStartMs:number }}
 */
function getEffectiveCycleKey({ timestampMs, timezone, paymentDate }) {
  const tz = (typeof timezone === 'string' && timezone.trim()) ? timezone.trim() : DEFAULT_TZ;
  const pd = Number(paymentDate) || 1;
  const now = _zonedParts(timestampMs, tz);
  let cycleYear = now.year;
  let cycleMonth = now.month;
  if (now.day < pd) {
    if (cycleMonth === 1) { cycleYear -= 1; cycleMonth = 12; }
    else { cycleMonth -= 1; }
  }
  const cycleKey = `${cycleYear}-${_pad2(cycleMonth)}-${_pad2(pd)}`;
  const cycleStartMs = _localMidnightUtcMs(cycleYear, cycleMonth, pd, tz);
  return { cycleKey, cycleStartMs };
}

module.exports = { resolveTimezone, getEffectiveCycleKey, DEFAULT_TZ };
