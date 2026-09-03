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
test('owner boleh update penanda (markedAt & updatedAt baru) — Temuan 2: '
  + 'cabang update belum pernah dilatih. SyncDispatcher memetakan create '
  + '-> .set() tanpa merge, dan Firestore membedakan create/update dari '
  + 'ADA-TIDAKnya dokumen di server, bukan dari SyncOperation yang '
  + 'dikirim — retry sah (T25) bisa mendarat sebagai update.', async () => {
  const ctx = env.authenticatedContext('u1');
  const r = ref(ctx);
  await setDoc(r, valid());
  await assertSucceeds(
    setDoc(r, { ...valid(), markedAt: Date.now() + 1000 }),
  );
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
test('uid lain ditolak read (Temuan 3) — allow read punya kondisi terpisah '
  + 'dari create/update/delete, tak pernah dilatih dari sisi non-owner',
  async () => {
    const ctx = env.authenticatedContext('u2');
    await assertFails(getDoc(ref(ctx, 'u1')));
  });
test('uid lain ditolak delete (Temuan 6)', async () => {
  const ctx = env.authenticatedContext('u2');
  await assertFails(deleteDoc(ref(ctx, 'u1')));
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
test('timezone > 64 karakter ditolak (batas atas, Temuan 5)', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(
    setDoc(ref(ctx), { ...valid(), timezone: 'x'.repeat(65) }),
  );
});
test('markedAt bukan angka ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(
    setDoc(ref(ctx), { ...valid(), markedAt: 'kemarin' }),
  );
});
test('dayKey bukan int (string) ditolak (Temuan 7)', async () => {
  const ctx = env.authenticatedContext('u1');
  const d = hariIni();
  await assertFails(
    setDoc(ref(ctx, 'u1', d), { ...valid(d), dayKey: String(d) }),
  );
});

// --- Field wajib HILANG, bukan cuma salah tipe (Temuan 4) — mengakses field
// yang tak ada berbeda dari membandingkan tipe field yang ada di bahasa rules.
test('dayKey hilang ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  const { dayKey, ...rest } = valid();
  await assertFails(setDoc(ref(ctx), rest));
});
test('markedAt hilang ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  const { markedAt, ...rest } = valid();
  await assertFails(setDoc(ref(ctx), rest));
});
test('timezone hilang ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  const { timezone, ...rest } = valid();
  await assertFails(setDoc(ref(ctx), rest));
});
test('updatedAt hilang ditolak (field inti wajib)', async () => {
  const ctx = env.authenticatedContext('u1');
  const { updatedAt, ...rest } = valid();
  await assertFails(setDoc(ref(ctx), rest));
});
