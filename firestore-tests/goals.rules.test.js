import { test, before, after, beforeEach } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import { setDoc, getDoc, doc, deleteDoc } from 'firebase/firestore';

let env;

// Bentuk dok sesuai GoalModel.toFirestore() (Dart): title(string),
// targetAmount(int), targetDate(int millis), isCompleted(bool),
// createdAt(int millis), updatedAt(int millis). Validasi tipe ringan
// pola budget_limits — TANPA hasOnly (hindari drift-trap permission-denied).
const valid = () => ({
  title: 'Pulang kampung',
  targetAmount: 1500000,
  targetDate: 1798675200000,
  isCompleted: false,
  createdAt: Date.now(),
  updatedAt: Date.now(),
});
const ref = (ctx, uid = 'u1') =>
  doc(ctx.firestore(), `users/${uid}/goals/goal-uuid-1`);

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-penyintas',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

// --- Jalur sah (harus BOLEH) ---
test('owner boleh create goal valid', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertSucceeds(setDoc(ref(ctx), valid()));
});
test('owner boleh read goal', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertSucceeds(getDoc(ref(ctx)));
});
test('owner boleh update goal (complete)', async () => {
  const ctx = env.authenticatedContext('u1');
  const r = ref(ctx);
  await setDoc(r, valid());
  await assertSucceeds(setDoc(r, { ...valid(), isCompleted: true }));
});
test('owner boleh delete goal', async () => {
  const ctx = env.authenticatedContext('u1');
  // `ctx.firestore()` sekali per context sebelum op mulai — ambil ref sekali
  // lalu pakai ulang (pola budget_limits.rules.test.js).
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
test('uid lain ditolak read', async () => {
  const ctx = env.authenticatedContext('u2');
  await assertFails(getDoc(ref(ctx, 'u1')));
});

// --- Validasi tipe ringan (harus DITOLAK) ---
test('title kosong ditolak (size > 0)', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { ...valid(), title: '' }));
});
test('title bukan string ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { ...valid(), title: 123 }));
});
test('title > 100 karakter ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { ...valid(), title: 'x'.repeat(101) }));
});
test('targetAmount string ditolak (is number)', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { ...valid(), targetAmount: '1jt' }));
});
test('targetAmount 0 ditolak (harus positif)', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { ...valid(), targetAmount: 0 }));
});
test('isCompleted non-bool ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { ...valid(), isCompleted: 'ya' }));
});
test('updatedAt hilang ditolak (field inti wajib)', async () => {
  const ctx = env.authenticatedContext('u1');
  const { updatedAt, ...rest } = valid();
  await assertFails(setDoc(ref(ctx), rest));
});
