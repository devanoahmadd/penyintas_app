import { test, before, after, beforeEach } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import { setDoc, getDoc, doc } from 'firebase/firestore';

let env;

// Bentuk dok sesuai payload Task 7 (ChallengeModel.toFirestore(), Dart):
// weekKey(int), category(string, absen bila null), targetAmount(int, absen
// bila null), baselineAmount(int, absen bila null), status(string),
// finalSpent(int, absen selama status active), timezone(string),
// createdAt(int millis), updatedAt(int millis).
// `resolvedAt` & `resultSeenAt` SENGAJA tidak ada di sini — keduanya kolom
// lokal-saja, tak pernah dikirim ke Firestore (spec §3, diverifikasi ulang
// saat Task 8 ditulis). Kalau kelak ditambahkan ke payload, rules & test ini
// perlu perubahan sendiri.
const keDayKey = (t) =>
  t.getUTCFullYear() * 10000 + (t.getUTCMonth() + 1) * 100 + t.getUTCDate();
const hariIni = () => keDayKey(new Date());
// Dipakai menguji jendela minWritableDayKey/maxWritableDayKey — tanggalnya
// relatif terhadap saat test dijalankan, jadi test tidak basi seiring waktu.
const hariLalu = (n) => keDayKey(new Date(Date.now() - n * 86400000));
const hariDepan = (n) => keDayKey(new Date(Date.now() + n * 86400000));

const valid = (weekKey = hariIni()) => ({
  weekKey,
  category: 'food',
  targetAmount: 115000,
  baselineAmount: 140000,
  status: 'active',
  timezone: 'Asia/Jakarta',
  createdAt: Date.now(),
  updatedAt: Date.now(),
});
const ref = (ctx, uid = 'u1', weekKey = hariIni()) =>
  doc(ctx.firestore(), `users/${uid}/challenges/${weekKey}`);

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-penyintas',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

// --- U36: proteksi pemilik (read) ---
test('U36 · owner boleh read dokumen sendiri', async () => {
  const ctx = env.authenticatedContext('u1');
  const r = ref(ctx);
  await setDoc(r, valid());
  await assertSucceeds(getDoc(r));
});
test('U36 · user lain ditolak read dokumen orang lain', async () => {
  const owner = env.authenticatedContext('u1');
  await setDoc(ref(owner), valid());
  const intruder = env.authenticatedContext('u2');
  await assertFails(getDoc(ref(intruder, 'u1')));
});

// --- Proteksi pemilik tambahan (write) — simetri dengan streak_marks/goals ---
test('uid lain ditolak create', async () => {
  const ctx = env.authenticatedContext('u2');
  const wk = hariIni();
  await assertFails(setDoc(ref(ctx, 'u1', wk), valid(wk)));
});
test('anonim ditolak create', async () => {
  const ctx = env.unauthenticatedContext();
  const wk = hariIni();
  await assertFails(setDoc(ref(ctx, 'u1', wk), valid(wk)));
});

// --- U37: field opsional boleh absen (baris "held" tanpa kategori) ---
test('U37 · dokumen held tanpa category/targetAmount/baselineAmount diterima', async () => {
  const ctx = env.authenticatedContext('u1');
  const wk = hariIni();
  await assertSucceeds(
    setDoc(ref(ctx, 'u1', wk), {
      weekKey: wk,
      status: 'held',
      timezone: 'Asia/Jakarta',
      createdAt: Date.now(),
      updatedAt: Date.now(),
    }),
  );
});

// --- U38: whitelist lima status sah ---
test('U38 · status di luar lima nilai ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  const wk = hariIni();
  await assertFails(
    setDoc(ref(ctx, 'u1', wk), { ...valid(wk), status: 'paused' }),
  );
});
for (const status of ['active', 'achieved', 'missed', 'held', 'skipped']) {
  test(`U38 · status '${status}' diterima`, async () => {
    const ctx = env.authenticatedContext('u1');
    const wk = hariIni();
    await assertSucceeds(
      setDoc(ref(ctx, 'u1', wk), { ...valid(wk), status }),
    );
  });
}

// --- U40: jendela weekKey (min/max writable day key) ---
test('U40 · weekKey 500 hari ke belakang ditolak (< minWritableDayKey)', async () => {
  const ctx = env.authenticatedContext('u1');
  const wk = hariLalu(500);
  await assertFails(setDoc(ref(ctx, 'u1', wk), valid(wk)));
});
test('U40 · weekKey 10 hari ke depan ditolak (> maxWritableDayKey)', async () => {
  const ctx = env.authenticatedContext('u1');
  const wk = hariDepan(10);
  await assertFails(setDoc(ref(ctx, 'u1', wk), valid(wk)));
});

// --- U41: doc-id dan field weekKey harus sinkron ---
test('U41 · doc-id dan field weekKey berselisih ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(
    setDoc(ref(ctx, 'u1', 20260907), valid(20260831)),
  );
});

// --- U42: validasi timezone ---
test('U42 · timezone hilang ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  const wk = hariIni();
  const { timezone, ...rest } = valid(wk);
  await assertFails(setDoc(ref(ctx, 'u1', wk), rest));
});
test('U42 · timezone string kosong ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  const wk = hariIni();
  await assertFails(
    setDoc(ref(ctx, 'u1', wk), { ...valid(wk), timezone: '' }),
  );
});
test('U42 · timezone 65 karakter ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  const wk = hariIni();
  await assertFails(
    setDoc(ref(ctx, 'u1', wk), { ...valid(wk), timezone: 'x'.repeat(65) }),
  );
});

// --- S-A: jendela tarikan terjauh — retensi riwayat 12 minggu (84 hari) ---
// kChallengeHistoryWeeks = 12 berarti dorongan bisa menyentuh dokumen berumur
// 84 hari, jauh di dalam jendela 400 hari minWritableDayKey(). Test ini yang
// menjaga jarak itu tetap lega, bukan aritmetika di kepala orang yang kelak
// menaikkan kChallengeHistoryWeeks.
test('S-A · weekKey Senin 12 minggu lalu (batas retensi riwayat) diterima', async () => {
  const ctx = env.authenticatedContext('u1');
  const wk = hariLalu(12 * 7);
  await assertSucceeds(setDoc(ref(ctx, 'u1', wk), valid(wk)));
});
