const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

const db = getFirestore();

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

    // Ambil paymentDate user
    const settingsDoc = await db
      .collection(`users/${uid}/budget_settings`)
      .doc('current')
      .get();
    const paymentDate = settingsDoc.exists ? (settingsDoc.data()?.paymentDate ?? 25) : 25;

    // Hitung cycleKey = tanggal awal siklus berjalan (YYYY-MM-DD)
    const now = new Date();
    const year = now.getFullYear();
    const month = now.getMonth() + 1;
    const day = now.getDate();
    let cycleYear = year;
    let cycleMonth = month;
    if (day < paymentDate) {
      if (month === 1) { cycleYear--; cycleMonth = 12; }
      else { cycleMonth--; }
    }
    const cycleKey = `${cycleYear}-${String(cycleMonth).padStart(2, '0')}-${String(paymentDate).padStart(2, '0')}`;
    const cycleStart = new Date(cycleYear, cycleMonth - 1, paymentDate);

    // Sum semua expense kategori ini sejak cycleStart
    const txSnapshot = await db
      .collection(`users/${uid}/transactions`)
      .where('category', '==', category)
      .where('type', '==', 'expense')
      .where('date', '>=', cycleStart.getTime())
      .get();

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

    // Ambil FCM token
    const userDoc = await db.collection('users').doc(uid).get();
    const fcmToken = userDoc.exists ? userDoc.data()?.fcmToken : null;
    if (!fcmToken) return;

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

    // Update dedup sebelum kirim — kurangi window race condition
    await statusRef.set({ cycleKey, threshold: newThreshold });

    try {
      await getMessaging().send({
        token: fcmToken,
        notification: { title: notifTitle, body: notifBody },
        android: { priority: 'high' },
        apns: { payload: { aps: { badge: 1 } } },
      });
    } catch (_) {
      // Token stale/invalid — hapus agar tidak mengirim ke device yang salah
      await db.collection('users').doc(uid).update({ fcmToken: null });
    }
  }
);
