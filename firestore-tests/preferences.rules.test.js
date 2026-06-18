import { test, before, after, beforeEach } from 'node:test';
import assert from 'node:assert';
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import { setDoc, getDoc, doc, deleteDoc, serverTimestamp } from 'firebase/firestore';

let env;
const contract = JSON.parse(readFileSync('./preferences_contract.json', 'utf8'));
const valid = () => ({
  timezone: 'Europe/Moscow', baseCurrency: 'IDR', homeCurrency: 'IDR',
  language: 'id', currentCountry: 'RU', homeCountry: 'ID',
  isPerantau: true, profileCompleted: true, schemaVersion: 1,
  updatedAt: serverTimestamp(),
});
const ref = (ctx, uid = 'u1') =>
  doc(ctx.firestore(), `users/${uid}/preferences/current`);

// C1: objek valid() WAJIB punya tepat field `required` dari kontrak bersama.
// Kalau rules hasAll & kontrak berdrift, test ini gagal duluan (bukan produksi).
test('valid() sinkron dgn kontrak bersama (required)', () => {
  assert.deepStrictEqual(
    Object.keys(valid()).sort(),
    [...contract.required].sort(),
  );
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-penyintas',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearFirestore());

test('owner boleh write doc valid', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertSucceeds(setDoc(ref(ctx), valid()));
});
test('owner boleh read', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertSucceeds(getDoc(ref(ctx)));
});
test('uid lain ditolak', async () => {
  const ctx = env.authenticatedContext('u2');
  await assertFails(setDoc(ref(ctx, 'u1'), valid()));
});
test('docId != current ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(doc(ctx.firestore(), 'users/u1/preferences/other'), valid()));
});
test('field ekstra ditolak (hasOnly)', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { ...valid(), hacker: 'x' }));
});
test('field wajib hilang ditolak (hasAll)', async () => {
  const ctx = env.authenticatedContext('u1');
  const { timezone, ...rest } = valid();
  await assertFails(setDoc(ref(ctx), rest));
});
test('baseCurrency len != 3 ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { ...valid(), baseCurrency: 'RUBLE' }));
});
test('language tak dikenal ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { ...valid(), language: 'fr' }));
});
test('status tak dikenal ditolak', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { ...valid(), status: 'ceo' }));
});
test('schemaVersion != 1 ditolak (M4: dikunci ke v1)', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { ...valid(), schemaVersion: 2 }));
});
test('displayName overlong ditolak (M2: bound 80)', async () => {
  const ctx = env.authenticatedContext('u1');
  await assertFails(setDoc(ref(ctx), { ...valid(), displayName: 'x'.repeat(81) }));
});
test('delete ditolak (M3: singleton, tak ada delete client)', async () => {
  const ctx = env.authenticatedContext('u1');
  await setDoc(ref(ctx), valid()); // seed dulu
  await assertFails(deleteDoc(ref(ctx)));
});
