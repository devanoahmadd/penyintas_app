/// Tujuan feedback pengguna (#111). Alamat publik developer — bukan secret.
const feedbackEmail = 'devanoahmadd@gmail.com';

/// Fungsi murni — testable tanpa platform channel url_launcher.
/// `query` manual (bukan `queryParameters`) agar spasi ter-encode %20,
/// bukan '+' yang salah ditafsirkan sebagian aplikasi email.
/// [versionLine] opsional → body email diisi info versi (triage feedback);
/// user tetap menulis pesannya di atas baris ini.
Uri buildFeedbackMailto({String? versionLine}) {
  final query = StringBuffer(
    'subject=${Uri.encodeComponent('Feedback Penyintas')}',
  );
  if (versionLine != null) {
    query.write('&body=${Uri.encodeComponent('\n\n—\n$versionLine')}');
  }
  return Uri(scheme: 'mailto', path: feedbackEmail, query: '$query');
}
