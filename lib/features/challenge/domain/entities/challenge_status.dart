/// Status satu minggu tantangan (spec §2 T10).
///
/// Tinggal di `domain/` dan BUKAN di `app_database.dart` (S-C): kalkulator,
/// `ChallengePhase`, dan kontrak repository semuanya membutuhkannya, dan tak
/// satu pun dari mereka boleh mengimpor Drift. Converter-lah yang mengimpor
/// enum ini — arah data→domain, arah yang memang sah.
///
/// `unknown` BUKAN status yang pernah ditulis app ini — ia jaring untuk dokumen
/// yang ditulis versi app lebih baru dan ditarik device versi lama (§3).
enum ChallengeStatus { active, achieved, missed, held, skipped, unknown }
