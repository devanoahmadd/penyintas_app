import { test, before, after, beforeEach } from 'node:test';
import { readFileSync } from 'node:fs';
import {
  initializeTestEnvironment, assertSucceeds, assertFails,
} from '@firebase/rules-unit-testing';
import { ref, uploadBytes, getBytes, deleteObject } from 'firebase/storage';

// PENTING: pakai `getBytes` (Node-safe, kembalikan ArrayBuffer). JANGAN ganti
// ke `getBlob` — itu browser-only dan error di Node (`node --test`).
// ref/uploadBytes/deleteObject universal (browser & Node).

let env;

// Rules memvalidasi contentType dari metadata upload dan size dari byte
// aktual yang diterima emulator (bukan deklarasi client).
const IMG = { contentType: 'image/jpeg' };
// Payload kecil apa pun cukup — rules hanya cek contentType & size.
const bytes = () => Buffer.from([0xff, 0xd8, 0xff, 0xe0]);
const fileRef = (ctx, path) => ref(ctx.storage(), path);
// Seed lewat jalur bebas-rules agar test read/update/delete tidak
// bergantung pada rule create. WAJIB untuk test allow-read: `getBytes` pada
// objek tak-ada melempar `storage/object-not-found` (BUKAN sukses) → jangan
// hapus seed pada test "owner boleh baca".
const seed = (path) =>
  env.withSecurityRulesDisabled(async (ctx) => {
    await uploadBytes(ref(ctx.storage(), path), bytes(), IMG);
  });

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-penyintas',
    storage: { rules: readFileSync('../storage.rules', 'utf8') },
  });
});
after(() => env.cleanup());
beforeEach(() => env.clearStorage());

// --- Jalur sah owner (harus BOLEH) ---
test('owner boleh upload gambar <5MB (create)', async () => {
  const ctx = env.authenticatedContext('userA');
  await assertSucceeds(
    uploadBytes(fileRef(ctx, 'users/userA/receipts/a.jpg'), bytes(), IMG),
  );
});
test('owner boleh baca file miliknya', async () => {
  await seed('users/userA/receipts/a.jpg');
  const ctx = env.authenticatedContext('userA');
  await assertSucceeds(getBytes(fileRef(ctx, 'users/userA/receipts/a.jpg')));
});
test('owner boleh overwrite file miliknya dengan gambar valid (update)', async () => {
  await seed('users/userA/receipts/a.jpg');
  const ctx = env.authenticatedContext('userA');
  await assertSucceeds(
    uploadBytes(fileRef(ctx, 'users/userA/receipts/a.jpg'), bytes(), IMG),
  );
});
test('owner boleh delete file miliknya', async () => {
  await seed('users/userA/receipts/a.jpg');
  const ctx = env.authenticatedContext('userA');
  await assertSucceeds(
    deleteObject(fileRef(ctx, 'users/userA/receipts/a.jpg')),
  );
});
// Boundary bawah: gambar tepat 1 byte di bawah 5 MiB harus BOLEH — memasang
// pin sisi-bawah pelengkap test "tepat 5MB ditolak" (boundary diuji 2 sisi).
test('owner boleh upload gambar tepat di bawah 5MB (boundary bawah)', async () => {
  const ctx = env.authenticatedContext('userA');
  const almost = Buffer.alloc(5 * 1024 * 1024 - 1); // 1 byte di bawah batas
  await assertSucceeds(
    uploadBytes(fileRef(ctx, 'users/userA/receipts/near.jpg'), almost, IMG),
  );
});
// Path nested dalam: membuktikan `{allPaths=**}` rekursif (bukan satu level),
// mengantisipasi struktur folder fitur mendatang (mis. receipts/<tahun>/<bulan>).
test('owner boleh upload ke path nested dalam', async () => {
  const ctx = env.authenticatedContext('userA');
  await assertSucceeds(
    uploadBytes(
      fileRef(ctx, 'users/userA/receipts/2026/07/a.jpg'), bytes(), IMG,
    ),
  );
});

// --- Proteksi lintas-user (harus DITOLAK) ---
test('user lain ditolak baca file userB', async () => {
  await seed('users/userB/receipts/b.jpg');
  const ctx = env.authenticatedContext('userA');
  await assertFails(getBytes(fileRef(ctx, 'users/userB/receipts/b.jpg')));
});
test('user lain ditolak tulis ke folder userB', async () => {
  const ctx = env.authenticatedContext('userA');
  await assertFails(
    uploadBytes(fileRef(ctx, 'users/userB/receipts/x.jpg'), bytes(), IMG),
  );
});
test('user lain ditolak delete file userB', async () => {
  await seed('users/userB/receipts/b.jpg');
  const ctx = env.authenticatedContext('userA');
  await assertFails(
    deleteObject(fileRef(ctx, 'users/userB/receipts/b.jpg')),
  );
});

// --- Unauthenticated (harus DITOLAK) ---
test('unauthenticated ditolak baca', async () => {
  await seed('users/userA/receipts/a.jpg');
  const ctx = env.unauthenticatedContext();
  await assertFails(getBytes(fileRef(ctx, 'users/userA/receipts/a.jpg')));
});
test('unauthenticated ditolak tulis', async () => {
  const ctx = env.unauthenticatedContext();
  await assertFails(
    uploadBytes(fileRef(ctx, 'users/userA/receipts/x.jpg'), bytes(), IMG),
  );
});

// --- Validasi konten (harus DITOLAK) ---
test('upload non-gambar ditolak', async () => {
  const ctx = env.authenticatedContext('userA');
  await assertFails(
    uploadBytes(fileRef(ctx, 'users/userA/docs/nota.pdf'), bytes(), {
      contentType: 'application/pdf',
    }),
  );
});
// contentType tak dideklarasikan → SDK default 'application/octet-stream'
// (bukan image/*) → matches() gagal → deny. Mengunci perilaku defensif saat
// metadata hilang, bukan mengandalkan asumsi diam-diam.
test('upload tanpa contentType ditolak', async () => {
  const ctx = env.authenticatedContext('userA');
  await assertFails(
    uploadBytes(fileRef(ctx, 'users/userA/receipts/raw.bin'), bytes(), {}),
  );
});
test('upload gambar tepat 5MB ditolak (batas strict <5MB)', async () => {
  const ctx = env.authenticatedContext('userA');
  const big = Buffer.alloc(5 * 1024 * 1024); // tepat 5 MiB — harus ditolak
  await assertFails(
    uploadBytes(fileRef(ctx, 'users/userA/receipts/big.jpg'), big, IMG),
  );
});

// --- Perilaku diketahui: image/* mencakup SVG (allow — terdokumentasi) ---
// image/svg+xml LOLOS matches('image/.*'). AMAN selama semua file owner-only
// read (SVG tak pernah disajikan lintas-user, jadi vektor XSS tak aktif).
// Test ini SENGAJA meng-assert allow: bila kelak ada fitur sharing/publik dan
// rules diperketat ke whitelist image/(jpeg|png|webp|heic), test ini yang akan
// GAGAL — memaksa keputusan sadar, bukan regresi diam-diam. Lihat spec §Rationale.
test('owner boleh upload image/svg+xml (perilaku saat ini — lihat caveat)', async () => {
  const ctx = env.authenticatedContext('userA');
  await assertSucceeds(
    uploadBytes(fileRef(ctx, 'users/userA/receipts/a.svg'), bytes(), {
      contentType: 'image/svg+xml',
    }),
  );
});

// --- Path di luar users/ (harus DITOLAK — default deny) ---
test('tulis di path root di luar users/ ditolak', async () => {
  const ctx = env.authenticatedContext('userA');
  await assertFails(
    uploadBytes(fileRef(ctx, 'public/banner.jpg'), bytes(), IMG),
  );
});
