# penyintas_app

Penyintas — Aplikasi manajemen keuangan untuk mahasiswa & pekerja perantau Indonesia.

## Status

| Phase | Status | Keterangan |
|-------|--------|------------|
| Phase 1 | ✅ Selesai | Firebase, DI, core utilities — local storage awalnya Isar |
| Phase 2 | ✅ Selesai | Error layer, localization, SettingsBloc, routing, common widgets |
| Phase 3 | ✅ Selesai | Auth bug fixes, Onboarding feature (wizard 3 langkah, BLoC, sync queue) |
| Phase 4 | ✅ Selesai | Transaction CRUD, Dashboard real-time, SyncService, 16 bug fixes dari Phase 1–3 |
| Drift Migration | ✅ Selesai | Migrasi Isar → Drift (SQLite); 70/70 tests; eliminasi konflik build_runner permanen |
| Phase 5 | 🔲 Planned | Notification & Report; perbaikan kelemahan dari analisis Phase 4 |

## Fitur yang sudah berjalan

- **Auth** — Register, Login, Logout (Firebase Auth + Firestore user doc)
- **Onboarding** — Wizard 3 langkah: income, pengeluaran tetap, emergency fund
- **Transaction** — Tambah, lihat, hapus transaksi; offline-first via Drift/SQLite; sync Firestore via queue
- **Dashboard** — Anggaran hari ini, Days-to-Live, BudgetBar, Survival Mode Banner; real-time stream
- **Settings** — Toggle tema (light/dark/system) dan bahasa (ID/EN)
- **Sync** — SyncService proses queue saat online/login; SyncDispatcher generic via Firestore doc path

## Menjalankan Proyek

```bash
flutter pub get      # install dependencies
flutter analyze      # lint & static analysis (target: 0 issues)
flutter test         # run all tests (70 tests)
flutter run          # jalankan di device/emulator
```

## Regenerasi Drift Schema

Setelah mengubah tabel di `lib/core/database/app_database.dart`:

```bash
dart run build_runner build
```

Tidak ada swap pubspec — `drift_dev ^2.x` kompatibel langsung dengan `bloc_test ^10`.

## Dokumentasi

- [PROMPT.md](PROMPT.md) — Master prompt per phase (konteks + rencana + hasil implementasi)
- [docs/phase4-plan.md](docs/phase4-plan.md) — Rencana dan hasil implementasi Phase 4
- [docs/drift-migration-plan.md](docs/drift-migration-plan.md) — Rencana dan hasil migrasi Isar → Drift
