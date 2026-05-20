const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

/**
 * Dipicu saat transaksi baru disimpan ke Firestore.
 * Kirim notifikasi kuning/merah jika saldo mendekati/melewati ambang batas.
 *
 * Threshold:
 *   - 15–30% remaining  → peringatan kuning (caution)
 *   - < 15% remaining   → Survival Mode aktif (danger)
 */
exports.budgetWarning = onDocumentCreated(
  'users/{uid}/transactions/{txId}',
  async (event) => {
    const txData = event.data?.data();
    // Only track non-fixed expense transactions; exit early to avoid extra reads
    if (!txData || txData.type !== 'expense' || txData.category === 'fixed') return;

    const uid = event.params.uid;
    const db = getFirestore();
    const messaging = getMessaging();

    const userDoc = await db.collection('users').doc(uid).get();
    const userData = userDoc.data();

    const settings = userData?.budgetSettings;
    if (!settings) return;

    const { monthlyIncome = 0, fixedExpenses = 0, emergencyFundPct = 0.1 } =
      settings;
    const emergencyFund = Math.round(monthlyIncome * emergencyFundPct);
    const monthlyBudget = Math.max(
      monthlyIncome - fixedExpenses - emergencyFund,
      0,
    );
    if (monthlyBudget === 0) return;

    // #114: gunakan WIB (UTC+7) agar monthKey tidak meleset di tengah malam
    const wibNow = new Date(Date.now() + 7 * 60 * 60 * 1000);
    const monthKey = `${wibNow.getUTCFullYear()}_${String(wibNow.getUTCMonth() + 1).padStart(2, '0')}`;

    // #116: cache increment selalu dijalankan — tidak bergantung pada fcmToken
    // agar running total tetap akurat meski user belum punya token notifikasi
    const cacheRef = db.doc(`users/${uid}/meta/budgetCache`);
    await cacheRef.set(
      { [`spent_${monthKey}`]: FieldValue.increment(txData.amount ?? 0) },
      { merge: true },
    );

    // Keluar setelah cache update jika tidak ada fcmToken — tidak ada notif yang bisa dikirim
    if (!userData?.fcmToken) return;

    // Single read instead of scanning all transactions
    const cache = await cacheRef.get();
    const totalSpent = cache.data()?.[`spent_${monthKey}`] ?? 0;

    const remaining = monthlyBudget - totalSpent;
    const ratio = remaining / monthlyBudget;

    // Ambil status notifikasi sebelumnya untuk hindari double-notif
    const notifRef = db.doc(`users/${uid}/meta/notifStatus`);
    const notifDoc = await notifRef.get();
    const notifData = notifDoc.data() ?? {};

    // Reset status di awal bulan baru agar notifikasi bisa terkirim lagi
    const storedMonth = notifData.month ?? null;
    const prevStatus =
      storedMonth !== monthKey ? 'safe' : (notifData.budgetStatus ?? 'safe');

    let newStatus = 'safe';
    let message = null;

    if (ratio < 0.15 && prevStatus !== 'danger') {
      newStatus = 'danger';
      message = {
        title: 'Survival Mode aktif',
        body: 'Saldo tersisa < 15%. Lentur dulu. Kita lewati minggu ini bersama.',
        data: { route: '/dashboard' },
      };
    } else if (ratio < 0.30 && ratio >= 0.15 && prevStatus === 'safe') {
      newStatus = 'caution';
      message = {
        title: 'Anggaran mulai menipis',
        body: `Saldo tersisa ${Math.round(ratio * 100)}% dari anggaran bulan ini.`,
        data: { route: '/dashboard' },
      };
    }

    if (!message) return;

    await notifRef.set(
      {
        budgetStatus: newStatus,
        month: monthKey,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    try {
      await messaging.send({
        token: userData.fcmToken,
        notification: { title: message.title, body: message.body },
        data: message.data,
      });
    } catch (_) {
      await db.collection('users').doc(uid).update({ fcmToken: null });
    }
  },
);
