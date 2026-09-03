import { test, before, after, beforeEach } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import { setDoc, getDoc, doc, deleteDoc } from 'firebase/firestore';

let env;

// Bentuk dok sesuai StreakMarkModel.toFirestore() (Dart): dayKey(int),
// markedAt(int millis), timezone(string), updatedAt(int millis).
// `viaClockCorrection` SENGAJA tidak ada — kolom lokal, tak pernah dikirim.
const keDayKey = (t) =>
  t.getUTCFullYear() * 10000 + (t.getUTCMonth() + 1) * 100 + t.getUTCDate();
const hariIni = () => keDayKey(new Date());
// Dipakai menguji jendela minWritableDayKey/maxWritableDayKey — tanggalnya
// relatif terhadap saat test dijalankan, jadi test tidak basi seiring waktu.
const hariLalu = (n) => keDayKey(new Date(Date.now() - n * 86400000));
const valid = (dayKey = hariIni()) => ({
  dayKey,
  markedAt: Date.now(),
  timezone: 'Asia/Jakarta',
  updatedAt: Date.now(),
});
const ref = (ctx, uid = 'u1', dayKey = hariIni()) =>
  doc(ctx.firestore(), `users/${uid}/streak_marks/${dayKey}`);

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-penyintas',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

// --- Jalur sah (harus BOLEH) ---
test('owner boleh create penanda valid', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertSucceeds(setDoc(ref(ctx), valid()));
});
test('owner boleh read penanda', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertSucceeds(getDoc(ref(ctx)));
});
test('owner boleh delete penanda (jalur undo)', async () => {
  const ctx = env.authenticatedContext('u1');
  const r = ref(ctx);
  await setDoc(r, valid());
  await assertSucceeds(deleteDoc(r));
});
test('hari lampau dalam jendela pemulihan tetap boleh — penanda offline bisa '
  + 'telat terkirim', async () => {
  const ctx = env.authenticatedContext('u1');
  const d = hariLalu(60);
  await assertSucceeds(setDoc(ref(ctx, 'u1', d), valid(d)));
});

// --- Proteksi pemilik (harus DITOLAK) ---
test('uid lain ditolak', async () => {
  const ctx = env.authenticatedContext('u2');
  await assertFails(setDoc(ref(ctx, 'u1'), valid()));
});
test('anonim ditolak', async () => {
  const ctx = env.unauthenticatedContext();
  await assertFails(setDoc(ref(ctx, 'u1'), valid()));
});

// --- Validasi bentuk (harus DITOLAK) ---
test('doc-id dan field dayKey berselisih ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx, 'u1', 20260902), valid(20260903)));
});
test('hari masa depan di luar kelonggaran 2 hari ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx, 'u1', 29991231), valid(29991231)));
});
test('hari lampau di luar jendela 400 hari ditolak — klien rusak tidak boleh '
  + 'menulis puluhan ribu dokumen ke kuota pemilik app', async () => {
  const ctx = env.authenticatedContext('u1');
  const d = hariLalu(500);
  await assertFails(setDoc(ref(ctx, 'u1', d), valid(d)));
});
test('timezone kosong ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(
    setDoc(ref(ctx), { ...valid(), timezone: '' }),
  );
});
test('markedAt bukan angka ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(
    setDoc(ref(ctx), { ...valid(), markedAt: 'kemarin' }),
  );
});
