import { test, before, after, beforeEach } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import { setDoc, getDoc, doc, deleteDoc } from 'firebase/firestore';

let env;

// Bentuk dok minimal yang divalidasi rules: token(string) + platform enum.
const valid = () => ({ token: 'tok-abc', platform: 'android' });
const ref = (ctx, uid = 'u1', token = 'tok-abc') =>
  doc(ctx.firestore(), `users/${uid}/fcmTokens/${token}`);

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-penyintas',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

// --- Jalur sah ---
test('owner boleh create token valid', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertSucceeds(setDoc(ref(ctx), valid()));
});
test('owner boleh read token', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertSucceeds(getDoc(ref(ctx)));
});
test('owner boleh delete token', async () => {
  const ctx = env.authenticatedContext('u1');
  const r = ref(ctx);
  await setDoc(r, valid());
  await assertSucceeds(deleteDoc(r));
});
test('platform ios diterima', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertSucceeds(setDoc(ref(ctx), { token: 'tok-abc', platform: 'ios' }));
});

// --- Proteksi pemilik ---
test('uid lain ditolak', async () => {
  const ctx = env.authenticatedContext('u2');
  await assertFails(setDoc(ref(ctx, 'u1'), valid()));
});
test('unauthenticated ditolak', async () => {
  const ctx = env.unauthenticatedContext();
  await assertFails(setDoc(ref(ctx, 'u1'), valid()));
});

// --- Validasi tipe ringan ---
test('platform invalid (web) ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { token: 'tok-abc', platform: 'web' }));
});
test('token non-string ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { token: 123, platform: 'android' }));
});
