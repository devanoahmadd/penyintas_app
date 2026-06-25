import { test, before, after, beforeEach } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import { setDoc, getDoc, doc, deleteDoc } from 'firebase/firestore';

let env;

// Bentuk dok sesuai BudgetLimitModel.toFirestore() (Dart):
// category(string), limitAmount(int), cycleType(string), isEnabled(bool),
// updatedAt(int millis). Opsi B hanya memvalidasi limitAmount & isEnabled —
// dua field yang dibaca CF budgetLimitWarning.
const valid = () => ({
  category: 'makanan',
  limitAmount: 100000,
  cycleType: 'monthly',
  isEnabled: true,
  updatedAt: Date.now(),
});
const ref = (ctx, uid = 'u1') =>
  doc(ctx.firestore(), `users/${uid}/budget_limits/makanan`);

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-penyintas',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

// --- Jalur sah (harus BOLEH) ---
test('owner boleh create limit valid', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertSucceeds(setDoc(ref(ctx), valid()));
});
test('owner boleh read limit', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertSucceeds(getDoc(ref(ctx)));
});
test('owner boleh delete limit', async () => {
  const ctx = env.authenticatedContext('u1');
  // `ctx.firestore()` hanya boleh dipanggil sekali per context sebelum op mulai;
  // ambil ref sekali lalu pakai ulang (pola sama spt preferences.rules.test.js).
  const r = ref(ctx);
  await setDoc(r, valid()); // seed dulu (create diizinkan)
  await assertSucceeds(deleteDoc(r));
});

// --- Proteksi pemilik (harus DITOLAK) ---
test('uid lain ditolak', async () => {
  const ctx = env.authenticatedContext('u2');
  await assertFails(setDoc(ref(ctx, 'u1'), valid()));
});
test('unauthenticated ditolak', async () => {
  const ctx = env.unauthenticatedContext();
  await assertFails(setDoc(ref(ctx, 'u1'), valid()));
});

// --- Validasi tipe ringan Opsi B (harus DITOLAK) ---
test('limitAmount string ditolak (B: is number)', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { ...valid(), limitAmount: '100rb' }));
});
test('limitAmount negatif ditolak (B: >= 0)', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { ...valid(), limitAmount: -50000 }));
});
test('isEnabled non-bool ditolak (B: is bool)', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { ...valid(), isEnabled: 'ya' }));
});
test('limitAmount hilang ditolak (B: field inti wajib)', async () => {
  const ctx = env.authenticatedContext('u1');
  const { limitAmount, ...rest } = valid();
  await assertFails(setDoc(ref(ctx), rest));
});
