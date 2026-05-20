const { onSchedule } = require('firebase-functions/v2/scheduler');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

/**
 * Berjalan setiap hari pukul 07:00 WIB.
 * Kirim notifikasi H-3 sebelum tanggal kiriman user.
 */
exports.paydayReminder = onSchedule(
  { schedule: '0 7 * * *', timeZone: 'Asia/Jakarta' },
  async () => {
    const db = getFirestore();
    const messaging = getMessaging();

    // Compute the target date (H-3) from WIB perspective. The cron runs at
    // 07:00 WIB = 00:00 UTC, so new Date().getDate() returns the previous
    // calendar day — WIB offset must be applied before extracting the date.
    const wibOffset = 7 * 60 * 60 * 1000;
    const wibNow = new Date(Date.now() + wibOffset);
    const targetDate = new Date(
      Date.UTC(wibNow.getUTCFullYear(), wibNow.getUTCMonth(), wibNow.getUTCDate() + 3),
    ).getUTCDate();

    const usersSnap = await db
      .collection('users')
      .where('fcmToken', '!=', null)
      .get();

    const sends = usersSnap.docs.map(async (userDoc) => {
      const { fcmToken, budgetSettings } = userDoc.data();
      if (!fcmToken || !budgetSettings) return;

      const paymentDate = budgetSettings.paymentDate ?? 1;
      if (paymentDate !== targetDate) return;

      try {
        await messaging.send({
          token: fcmToken,
          notification: {
            title: '3 hari lagi kiriman tiba!',
            body: 'Bertahan sebentar lagi. Hampir sampai garis akhir.',
          },
          data: { route: '/dashboard' },
        });
      } catch (_) {
        await db
          .collection('users')
          .doc(userDoc.id)
          .update({ fcmToken: null });
      }
    });

    await Promise.allSettled(sends);
  },
);
