const { onSchedule } = require('firebase-functions/v2/scheduler');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

/**
 * Berjalan setiap hari pukul 20:00 WIB.
 * Kirim notifikasi ke user yang belum mencatat transaksi hari ini.
 */
exports.dailyReminder = onSchedule(
  { schedule: '0 20 * * *', timeZone: 'Asia/Jakarta' },
  async () => {
    const db = getFirestore();
    const messaging = getMessaging();

    // Compute WIB (UTC+7) midnight as a UTC timestamp so the Firestore query
    // correctly covers "today" in the user's timezone, not server UTC midnight.
    const wibOffset = 7 * 60 * 60 * 1000;
    const wibNow = new Date(Date.now() + wibOffset);
    const todayStart = new Date(
      Date.UTC(wibNow.getUTCFullYear(), wibNow.getUTCMonth(), wibNow.getUTCDate())
      - wibOffset,
    );

    const usersSnap = await db
      .collection('users')
      .where('fcmToken', '!=', null)
      .get();

    const sends = usersSnap.docs.map(async (userDoc) => {
      const { fcmToken } = userDoc.data();
      if (!fcmToken) return;

      const uid = userDoc.id;
      const txSnap = await db
        .collection(`users/${uid}/transactions`)
        .where('date', '>=', Timestamp.fromDate(todayStart))
        .limit(1)
        .get();

      if (!txSnap.empty) return; // sudah ada transaksi hari ini

      try {
        await messaging.send({
          token: fcmToken,
          notification: {
            title: 'Jangan lupa catat pengeluaran hari ini!',
            body: 'Satu catatan kecil sekarang, lebih aman sampai akhir bulan.',
          },
          data: { route: '/transactions' },
        });
      } catch (_) {
        // Token expired atau invalid — hapus dari Firestore
        await db.collection('users').doc(uid).update({ fcmToken: null });
      }
    });

    await Promise.allSettled(sends);
  },
);
