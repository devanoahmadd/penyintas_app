const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getFirestore } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

// TODO: aktifkan App Check setelah deployment ke production — sementara dimatikan
// sesuai pola fungsi lain (getSurvivalTips, generateInsight) di project ini.
exports.deleteAccount = onCall({ enforceAppCheck: false }, async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Login dulu.');
  }

  const uid = request.auth.uid;
  const db = getFirestore();
  const auth = getAuth();

  try {
    // Hapus user document dan semua subcollection (transactions, budget_settings, budget_limits, settings, insights)
    await db.recursiveDelete(db.doc(`users/${uid}`));

    // Setelah data terhapus, hapus auth user
    await auth.deleteUser(uid);

    return { success: true };
  } catch (error) {
    console.error(`Error deleting account for uid ${uid}:`, error);
    throw new HttpsError('internal', 'Gagal menghapus akun. Coba lagi.');
  }
});
