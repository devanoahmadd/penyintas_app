const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { getEffectiveCycleKey, resolveTimezone } = require('./utils/cycle');
const { collectTokens, deadTokensFromResponses, isPushEnabled } = require('./utils/fcm');

/**
 * Trigger per transaksi baru. Cek apakah kategori transaksi punya limit
 * dan apakah spending sudah mendekati/melewati limit tersebut.
 * Deduplication via budgetLimitNotifStatus/{category} per siklus.
 *
 * Race condition note: dua transaksi bersamaan bisa kirim dua notifikasi
 * sebelum dedup-doc terupdate. Frekuensinya sangat rendah — acceptable.
 */
exports.budgetLimitWarning = onDocumentCreated(
  {
    document: 'users/{uid}/transactions/{txId}',
    region: 'asia-southeast2',
  },
  async (event) => {
    const db = getFirestore();
    const uid = event.params.uid;
    const txData = event.data?.data();
    if (!txData) return;

    // Hanya proses expense
    if (txData.type !== 'expense') return;

    const category = txData.category; // slug string
    if (!category || category === 'fixed' || category === 'income') return;

    // Cek apakah ada limit untuk kategori ini
    const limitDoc = await db
      .collection(`users/${uid}/budget_limits`)
      .doc(category)
      .get();
    if (!limitDoc.exists) return;

    const limitData = limitDoc.data();
    if (!limitData.isEnabled) return;

    const limitAmount = limitData.limitAmount;
    if (!limitAmount || limitAmount <= 0) return;

    // Baca settings + prefs + token + toggle push + user(legacy) paralel.
    const [settingsDoc, prefsDoc, tokensSnap, notifDoc, userDoc] =
      await Promise.all([
        db.collection(`users/${uid}/budget_settings`).doc('current').get(),
        db.collection(`users/${uid}/preferences`).doc('current').get(),
        db.collection(`users/${uid}/fcmTokens`).get(),
        db.collection(`users/${uid}/settings`).doc('notifications').get(),
        db.collection('users').doc(uid).get(),
      ]);
    const paymentDate = settingsDoc.exists ? settingsDoc.data()?.paymentDate : undefined;
    const timezone = resolveTimezone(prefsDoc.exists ? prefsDoc.data() : null);

    // G8: hormati toggle push (default aktif/opt-out).
    if (!isPushEnabled(notifDoc.exists ? notifDoc.data() : null)) return;

    // Kumpulkan token subcollection ∪ legacy.
    const { tokens, legacyToken } = collectTokens(
      tokensSnap.docs.map((d) => d.id),
      userDoc.exists ? userDoc.data()?.fcmToken : null,
    );
    if (tokens.length === 0) return;

    // Cycle boundary timezone-aware (DST-aware, clamp F-D8) — ganti math +7h lama.
    const { cycleKey, cycleStartLocalIso } = getEffectiveCycleKey({
      timestampMs: Date.now(),
      timezone,
      paymentDate,
    });

    // Sum semua expense kategori ini sejak awal siklus.
    // K-1: date disimpan string ISO lokal-naif → bandingkan string-vs-string.
    const txSnapshot = await db
      .collection(`users/${uid}/transactions`)
      .where('category', '==', category)
      .where('type', '==', 'expense')
      .where('date', '>=', cycleStartLocalIso)
      .get();

    // SEAM NOMINAL — asumsi IDR-tunggal; Spec 2 inject konversi di sini.
    const totalSpent = txSnapshot.docs.reduce((sum, d) => sum + (d.data().amount ?? 0), 0);
    const pct = totalSpent / limitAmount;

    // Cek deduplication status
    const statusRef = db
      .collection(`users/${uid}/budgetLimitNotifStatus`)
      .doc(category);
    const statusDoc = await statusRef.get();
    const prevStatus = statusDoc.exists ? statusDoc.data() : {};
    const prevCycleKey = prevStatus.cycleKey ?? '';
    const prevThreshold = prevCycleKey === cycleKey ? (prevStatus.threshold ?? 'none') : 'none';

    let notifTitle = null;
    let notifBody = null;
    let newThreshold = prevThreshold;

    const remaining = Math.max(0, limitAmount - totalSpent);
    const pctFmt = Math.round(pct * 100);

    if (pct >= 1.0 && prevThreshold !== 'exceeded') {
      notifTitle = `Batas ${category} terlewati`;
      notifBody = `Pengeluaran ${category} sudah melewati limit bulan ini.`;
      newThreshold = 'exceeded';
    } else if (pct >= 0.8 && prevThreshold === 'none') {
      notifTitle = `Pengeluaran ${category} hampir di batas`;
      notifBody = `Sudah ${pctFmt}% — sisa Rp ${remaining.toLocaleString('id-ID')}.`;
      newThreshold = 'warn';
    }

    if (!notifTitle) return;

    // Update dedup SEBELUM kirim — kurangi window race condition.
    await statusRef.set({ cycleKey, threshold: newThreshold });

    const resp = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: notifTitle, body: notifBody },
      android: { priority: 'high' },
      apns: { payload: { aps: { badge: 1 } } },
      data: { route: '/budget' }, // G7
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

    // Revert dedup HANYA bila semua gagal (M2).
    if (resp.successCount === 0) {
      await statusRef.set({ cycleKey, threshold: prevThreshold });
    }
  }
);
