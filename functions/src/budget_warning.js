const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getEffectiveMonthKey, resolveTimezone } = require('./utils/cycle');
const { collectTokens, deadTokensFromResponses, isPushEnabled } = require('./utils/fcm');

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

    // Baca user + preferences + token subcol + toggle push paralel (0 tambahan latency)
    const [userDoc, prefsDoc, tokensSnap, pushToggleDoc] = await Promise.all([
      db.collection('users').doc(uid).get(),
      db.collection(`users/${uid}/preferences`).doc('current').get(),
      db.collection(`users/${uid}/fcmTokens`).get(),
      db.collection(`users/${uid}/settings`).doc('notifications').get(),
    ]);
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

    // monthKey timezone-aware (bulan kalender) — ganti math +7h lama.
    const timezone = resolveTimezone(prefsDoc.exists ? prefsDoc.data() : null);
    const { monthKey, monthStartLocalIso, nextMonthStartLocalIso } = getEffectiveMonthKey({
      timestampMs: Date.now(),
      timezone,
    });

    // G8: hormati toggle push (default aktif/opt-out).
    if (!isPushEnabled(pushToggleDoc.exists ? pushToggleDoc.data() : null)) return;

    // Kumpulkan token subcollection ∪ legacy; keluar sebelum query bila kosong.
    const { tokens, legacyToken } = collectTokens(
      tokensSnap.docs.map((d) => d.id),
      userData?.fcmToken,
    );
    if (tokens.length === 0) return;

    // S-2: hitung total bulan ini via query rentang (akurat terhadap edit/hapus, tanpa drift cache).
    // Range single-field `date` (auto-indexed); filter type/category di JS agar tak butuh composite index.
    // K-1: date disimpan string ISO lokal-naif → boundary string-vs-string.
    const txSnapshot = await db
      .collection(`users/${uid}/transactions`)
      .where('date', '>=', monthStartLocalIso)
      .where('date', '<', nextMonthStartLocalIso)
      .get();
    // SEAM NOMINAL — asumsi IDR-tunggal; Spec 2 inject konversi di sini.
    const totalSpent = txSnapshot.docs.reduce((sum, d) => {
      const t = d.data();
      if (t.type !== 'expense' || t.category === 'fixed') return sum;
      return sum + (t.amount ?? 0);
    }, 0);

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

    const resp = await messaging.sendEachForMulticast({
      tokens,
      notification: { title: message.title, body: message.body },
      data: message.data, // route: '/dashboard'
    });

    // Prune presisi token mati (incl. legacy bila mati).
    const dead = deadTokensFromResponses(tokens, resp.responses);
    // Prune best-effort: kegagalan hapus token mati JANGAN mencegah revert dedup.
    try {
      await Promise.all(
        dead.map((t) => db.collection(`users/${uid}/fcmTokens`).doc(t).delete()),
      );
      if (legacyToken && dead.includes(legacyToken)) {
        await db.collection('users').doc(uid).update({
          fcmToken: FieldValue.delete(),
          fcmUpdatedAt: FieldValue.delete(),
        });
      }
    } catch (e) {
      console.error('Prune token mati gagal (diabaikan agar revert dedup tetap jalan):', e);
    }

    // Revert dedup HANYA bila semua gagal (M2) — budgetWarning sebelumnya tak punya revert.
    if (resp.successCount === 0) {
      await notifRef.set(
        { budgetStatus: prevStatus, month: monthKey, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
    }
  },
);
