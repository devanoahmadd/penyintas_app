# Penyintas — Progress Pengembangan Aplikasi

**Terakhir diperbarui:** 2026-05-27  
**Status keseluruhan:** Phase 6A ✅ · Phase 6B ✅ · Phase 6B-fix ✅ · Phase 6C ✅ · Phase 6C-fix ✅ · Phase 7-prep ✅ · Phase 7A ✅ · Phase 7-prep-fix ✅ · Phase 7B ✅ · Phase 7B-fix ✅ · Phase 7C ✅ · Profile/Nav polish ✅ · Phase 7C-fix ✅ · Phase 7D ✅ · Phase 7E ✅ · Phase 7F ✅ · Dashboard C1 Redesign ✅ · C1 Polish ✅ · Transactions V2 States ✅  
**Test count:** 183/183 passed · flutter analyze: 0 issues

---

## Ringkasan Cepat

| Phase | Fokus | Status | Test | Tanggal |
|-------|-------|--------|------|---------|
| **0** | Project foundation & design system | ✅ Selesai | — | 2026-05-06 |
| **1** | Firebase + infrastruktur lokal (Isar) | ✅ Selesai | 0 | 2026-05-06 |
| **2** | Core architecture, localization, routing | ✅ Selesai | 0 | 2026-05-07 |
| **3A** | Auth feature (Firebase Auth) | ✅ Selesai | 7 | 2026-05-07 |
| **3B** | Onboarding wizard 3 langkah | ✅ Selesai | 22 | 2026-05-07 |
| **4** | Dashboard + Transaction + Sync infrastructure | ✅ Selesai | 56 | 2026-05-08 |
| **Drift** | Migrasi Isar → Drift (SQLite ORM) | ✅ Selesai | 70 | 2026-05-08 |
| **5A** | Bug fix & hardening (17 item P1–P3) | ✅ Selesai | 82 | 2026-05-08 |
| **5B** | Notification feature (FCM + Cloud Functions) | ✅ Selesai | 90 | 2026-05-11 |
| **5B-fix** | Notification bug fixes (3 P1 + 5 P2) | ✅ Selesai | 90 | 2026-05-12 |
| **5C** | Report feature (chart + AI insight) | ✅ Selesai | 109 | 2026-05-12 |
| **6A** | Settings page + MilestoneToast + l10n + dead code | ✅ Selesai | 109 | 2026-05-19 |
| **6A-fix** | Bug sprint post-6A (#101/#102/#104/#106/#107) | ✅ Selesai | 109 | 2026-05-20 |
| **6B** | Cloud Functions WIB fix + Report Polish | ✅ Selesai | 109 | 2026-05-20 |
| **6B-fix** | Bug sprint post-6B (#114/#116/#117/#118) | ✅ Selesai | 109 | 2026-05-20 |
| **6C** | Technical Debt & Architecture | ✅ Selesai | 119 | 2026-05-20 |
| **6C-fix** | Bug sprint post-6C (#122–#130) | ✅ Selesai | 127 | 2026-05-20 |
| **7-prep** | CurrencyConfig + formatCurrency() + formatRupiah() shim | ✅ Selesai | 143 | 2026-05-20 |
| **7A** | Schema v4: Goals table, goalId di Transactions, survivalModeActivatedAt | ✅ Selesai | 143 | 2026-05-20 |
| **7-prep-fix** | Fix #131 props, #132 compact regression, #133+#137 Goals DateTimeColumn+updatedAt, #139 test name | ✅ Selesai | 143 | 2026-05-21 |
| **7B** | Survival Mode AI: entity, usecase, bloc, datasource, SurvivalTipsPage, Cloud Function | ✅ Selesai | 153 | 2026-05-21 |
| **7B-fix** | Bug sprint: #144 cast guard, #145 await, #146 Crashlytics, #147 sentinel, #148 formatCurrency, #149 l10n (8 key), #150 empty state, #151 loading preserve | ✅ Selesai | 153 | 2026-05-21 |
| **7C** | Goal Saving: GoalEntity (computed savedAmount), GoalBloc, GoalListPage, GoalCard, AddGoalSheet, link transaksi ke goal, MilestoneToast integration | ✅ Selesai | 175 | 2026-05-21 |
| **Profile/Nav** | SayaPage hub (tab "Saya"), `_BudgetComingSoonPage`, navbar tabs `/budget` dan `/profile` wired, 17 l10n key baru | ✅ Selesai | 175 | 2026-05-21 |
| **7C-fix** | Bug sprint: #162 GoalPicker caller fix, #163 AddGoalSheet BlocListener, #164 GoalDetailPage live data, #165 GoalBloc singleton + milestone trigger, #166 UnlinkTransactionUseCase, #168 l10n 8 keys | ✅ Selesai | 175 | 2026-05-21 |
| **7D** | Android Home Screen Widget: penyintas_widget.xml, PenyintasWidgetProvider.kt, DashboardBloc push, home_widget ^0.9.1 | ✅ Selesai | 175 | 2026-05-21 |
| **7E** | Share Report (RepaintBoundary + share_plus screenshot) + CSV Export (Settings → share_plus) | ✅ Selesai | 180 | 2026-05-21 |
| **7F** | Tech debt: #20 RemoteConfig splash, #134 compact negative, #135 NumberFormat cache, #136 fromCode case-insensitive, #138 PRAGMA foreign_keys, #140/#141 tests | ✅ Selesai | 180 | 2026-05-21 |
| **C1** | Dashboard redesign: BentoGrid, RingWidget (donut), TipCard, SaldoCard eye-toggle, token baru (cardLight, lg2) | ✅ Selesai | 180 | 2026-05-26 |
| **C1-polish** | l10n 100% dashboard (37 key baru, DateFormat locale-aware) · spacing sm2/md2 · text style audit (8 fix) | ✅ Selesai | 180 | 2026-05-26 |
| **Tx V2 States** | Transaction screen: 5 UI states (skeleton, empty, detail sheet, filter sheet, search) + BLoC filter extension (`FilterSheetApplied`, `categoryFilter`/`minAmount`/`maxAmount`) | ✅ Selesai | 183 | 2026-05-27 |

---

## Phase 0 — Project Foundation

**Status: ✅ Selesai**  
**Tanggal:** 2026-05-06

### Yang dibangun

- Struktur folder Clean Architecture lengkap: `lib/core/`, `lib/features/` (8 fitur), `lib/widgets/common/`, `test/`, `functions/`
- **Design system terpusat:**
  - `lib/core/theme/app_colors.dart` — semua color token (brand, light, dark, functional)
  - `lib/core/theme/app_text_styles.dart` — type scale lengkap (Display→Caption + Numeric)
  - `lib/core/theme/app_spacing.dart` — AppSpacing (xs–huge) + AppRadius (sm–pill)
  - `lib/core/theme/app_theme.dart` — ThemeData light & dark
- `lib/main.dart` + `lib/app.dart` — skeleton dengan MaterialApp.router
- `assets/translations/id.json` + `en.json` — 43 key string UI bilingual
- Firebase project terhubung: `penyintas-app` (Android: `com.onaved.penyintas`)
- `.gitignore` dikonfigurasi: exclude `google-services.json`, `firebase_options.dart`, `.env`

### Catatan teknis

- Font dimuat via `google_fonts` package (Plus Jakarta Sans, Inter Tight, JetBrains Mono)
- Local storage awal: **Isar** (akan digantikan Drift di migration step)
- Firebase App Check: `firebase_app_check: ^0.4.x` — API berubah dari v0.3.x (breaking change `providerAndroid:` bukan `androidProvider:`)

---

## Phase 1 — Firebase & Infrastruktur

**Status: ✅ Selesai**  
**Tanggal:** 2026-05-06

### Yang dibangun

- **Firebase services aktif:** Auth, Firestore, Storage, App Check, Analytics, Crashlytics, Performance, Remote Config, Cloud Functions, FCM
- **Firestore security rules** — isolasi per user (`/users/{userId}/...`)
- **Firestore indexes** — query transaksi by date + category/createdAt
- **Isar models** (3 collection):
  - `AppSettingsIsarModel` — user preferences + budget settings (singleton id=1)
  - `SyncQueueIsarModel` — offline queue untuk sync ke Firestore
  - `TransactionIsarModel` — catatan transaksi lokal
- **Core utilities:**
  - `currency_formatter.dart` — `formatRupiah(int)` → `"Rp 1.245.000"`
  - `date_helper.dart` — `remainingDaysInCycle()`, `formatDateShort()`, `isSameDay()`
  - `analytics_service.dart` — wrapper `FirebaseAnalytics`
  - `network_info.dart` — `NetworkInfoImpl` dengan HTTP HEAD check ke `dns.google`
- **GetIt DI** — semua Firebase services + Isar + NetworkInfo + AnalyticsService terdaftar
- `main.dart` — Firebase init + AppCheck + Crashlytics global error handler + Isar.open()

### Masalah yang ditemukan & diperbaiki di phase berikutnya

| # | Masalah | Diselesaikan di |
|---|---------|-----------------|
| P1 | `Isar.open()` tanpa error handling | Phase 4 → Drift migration (obsolete) |
| P2 | `isConnected` cek adapter, bukan internet | Phase 5A (fix #4) |
| P3 | Firebase debug provider hardcoded tanpa `kReleaseMode` guard | Phase 4 (fix #16) |
| P4 | `AppSettingsIsarModel` melanggar SRP | Phase 6 (planned) |

---

## Phase 2 — Core Architecture & Localization

**Status: ✅ Selesai**  
**Tanggal:** 2026-05-07

### Yang dibangun

**Core error handling:**
- `failures.dart` — abstract `Failure` + 6 sub-class (ServerFailure, CacheFailure, AuthFailure, NetworkFailure, ValidationFailure, UnknownFailure)
- `exceptions.dart` — 5 exception type yang match

**Base use cases:**
- `usecase.dart` — `UseCase<Output, Params>`, `StreamUseCase<Output, Params>`, `NoParams`
  - *Catatan:* pakai `Output` bukan `Type` — `Type` clash dengan Dart built-in

**Localization:**
- `app_localizations.dart` — manual JSON loader via `rootBundle` (bukan ARB/code-gen), typed getters per key, `shouldReload` reaktif
- `app.dart` — 4 localization delegates, `supportedLocales: [Locale('id'), Locale('en')]`

**Settings feature (minimal):**
- `AppSettingsEntity` — `themeMode`, `locale`, `copyWith()`
- `SettingsBloc` — `ChangeTheme`, `ChangeLanguage` events; persist ke Isar (id=1 singleton)
- `app.dart` — `BlocBuilder<SettingsBloc>` wrapping `MaterialApp.router` untuk theme/locale reaktif

**Routing:**
- `app_router.dart` — go_router dengan redirect async: belum login → `/login`, belum onboarding → `/onboarding`, sudah → `/dashboard`
- Routes: `/splash`, `/login`, `/register`, `/onboarding`, `/dashboard`, `/transactions`, `/report`, `/settings`

**Common widgets:**
- `PenyintasLogo` — `SvgPicture.asset` dengan 3 mode (light / dark / reversed). Logo selalu dari `assets/images/logo-m7.svg`
- `PrimaryButton` — min 48dp, `isLoading`/`isEnabled`, `AnimatedSwitcher`
- `AppTextField` — label di atas, `helperText: ' '` untuk stable height, `isPassword` toggle internal, `isValid` checkmark hijau

---

## Phase 3 — Auth & Onboarding

**Status: ✅ Selesai**  
**Test count: 22/22**  
**Tanggal:** 2026-05-07

### Phase 3A — Auth Feature

**Clean Architecture:**
- Domain: `UserEntity`, 5 use cases (SignIn, SignUp, SignOut, GetCurrentUser, WatchAuthState)
- Data: `UserModel` (fromFirestore/toFirestore), `AuthRemoteDataSourceImpl`, `AuthRepositoryImpl`
- Presentation: `AuthBloc` dengan 5 events / 5 states

**Pages:**
- `SplashPage` — fade animation 900ms, delay navigasi minimum 2500ms (branding), fallback ke `/login` jika auth belum resolve
- `LoginPage` — form email+password, validasi client-side, error snackbar, link ke register
- `RegisterPage` — 4 field (nama, email, password, konfirmasi), live validation email (checkmark hijau), konfirmasi match real-time

**Bug fixes (3A):**
- Fix #1: double dispatch `AuthCheckRequested` di splash dihapus
- Fix #2: `Future.wait` unawaited → `Future.delayed(2500ms)` + fallback auth check
- Fix #3: `asyncMap` + Firestore blocking auth stream → `.map()` sinkron dari Firebase User

### Phase 3B — Onboarding Feature

**Fitur:**
- Wizard 3 langkah via `PageController` + `NeverScrollableScrollPhysics` (navigasi dikendalikan BLoC)
- Step 1: Input pendapatan + tanggal kiriman + `_DatePickerSheet` (grid 1–31)
- Step 2: Input pengeluaran tetap per kategori (kos, listrik, air, internet, telepon) + total otomatis
- Step 3: Slider dana darurat 5–25%, kalkulasi real-time, preview anggaran harian
- `OnboardingProgressDots` — dots animasi 3 langkah

**Arsitektur penting:**
- `remainingDays` dihitung sekali di `_onStep2` BLoC, disimpan ke `OnboardingStep3` state (bukan di widget — hindari race condition tengah malam)
- `OnboardingRepositoryImpl` — local-first: tulis Isar dulu, sync Firestore jika online; masuk `SyncQueue` jika offline/Firestore gagal
- `CalculateDailyBudgetUseCase` — pure computation, tanpa repository dependency

**Test (7 usecase + 8 BLoC + 7 auth = 22):**
- `calculate_daily_budget_test.dart` — 7 scenarios (edge case income=0, fixedExpenses>income, dll)
- `onboarding_bloc_test.dart` — 8 scenarios (step transitions, error retry, data accumulation)
- `auth_bloc_test.dart` — 7 scenarios (sign in/up success, wrong password, user-not-found)

---

## Phase 4 — Dashboard, Transaction & Sync

**Status: ✅ Selesai**  
**Test count: 56/56**  
**Tanggal:** 2026-05-08

### Phase 4A — Dashboard Domain

- `DashboardEntity` — 11 fields + `BudgetStatus` enum (safe/caution/danger)
- `CalculateDaysToLiveUseCase` — pure calc, avgDailySpend → DTL days
- `GetDashboardUseCase` — wraps `DashboardRepository` stream
- Test: 5 scenarios `calculate_days_to_live_test.dart`

### Phase 4B — Dashboard Data + Presentation

**`DashboardRepositoryImpl._compute()`:**
- `async*` stream: watches `watchTodayTransactions()`, per event fetch budget settings + last-7-days transactions
- Formula: `safeMonthly = income - fixedExpenses - emergencyFund`, `dailyBudget = safeMonthly / effectiveDays`
- `avgDailySpend` dari transaksi 7 hari terakhir, fallback ke `dailyBudget` jika belum ada data
- `BudgetStatus`: safe > 30%, caution 15–30%, danger < 15% dari `totalRemaining / totalMonthlyBudget`

**`DashboardBloc`:**
- `LoadDashboard` + `DashboardRefreshed` events, `emit.forEach` stream
- Test: 4 scenarios `dashboard_bloc_test.dart` (menggunakan `makeEntity()` helper karena Equatable dedup)

**`DashboardPage`:**
- `CustomScrollView` + `SliverAppBar` floating
- FAB buka `AddTransactionSheet`
- Show `SurvivalModeBanner` jika `BudgetStatus.danger`, else `_BudgetHeaderCard`

**Common widgets:**
- `DaysToLiveCard` — warna adaptif: hijau >14 hari, kunyit 7–14 hari, terakota <7 hari
- `BudgetBar` — `TweenAnimationBuilder` dengan 3 warna adaptif (safe/caution/warn)
- `SurvivalModeBanner` — background warn, copy hangat "Lentur dulu. Kita lewati minggu ini bersama."

**Auth & Onboarding fixes (4B):**
- `fromFirestore()` unsafe cast → `(data['field'] as num?)?.toInt() ?? 0`
- `OnboardingError` sekarang punya retry via `OnboardingRetryRequested` event
- `getBudgetSettings()` remote fallback jika Isar kosong
- `AppLocalizations.shouldReload` → reaktif (ganti bahasa real-time)
- `Firebase debug providers` → guard `kReleaseMode`

### Phase 4C — Sync Infrastructure + Test Coverage

**`SyncDispatcher`:**
- Generic Firestore dispatcher via `collectionPath` sebagai doc path
- `SyncOperation.create` → `set()`, `.update` → `set(merge: true)`, `.delete` → `delete()`
- Positional params: `dispatch(SyncQueueData, FirebaseFirestore)` (bukan named)

**`SyncService`:**
- Singleton; subscribe ke `NetworkInfo.onConnectivityChanged` + `FirebaseAuth.authStateChanges`
- Mutex `_processing` agar tidak double-process
- Injectable `dispatchFn` param untuk testability (default `SyncDispatcher.dispatch`)
- Started di `main.dart` setelah DI init

**`AppSettingsIsarModel.onboardingCreatedAt`** — field nullable `DateTime?`, set sekali saat onboarding, tidak pernah di-overwrite

**Tests baru:**
- `sync_service_test.dart` — 7 scenarios (online/offline/partial fail/dispatch mock)
- `onboarding_repository_impl_test.dart` — 8 scenarios (offline/online-success/online-fail/CacheException)

**Transaction feature:**
- `TransactionEntity` + `TransactionModel` (fromDrift/toDriftCompanion)
- `TransactionRepositoryImpl` — CRUD + watch stream
- `AddTransactionBloc` — amount input via numpad, category selection, date picker
- `AddTransactionSheet` — bottom sheet dengan numpad kustom
- `TransactionItem` — swipe-to-delete, ikon per kategori, format Rupiah tabular-nums
- `TransactionListPage` — group by date, filter chips, pull-to-refresh

---

## Drift Migration (Isar → Drift)

**Status: ✅ Selesai**  
**Test count: 70/70**  
**Tanggal:** 2026-05-08

### Motivasi

`isar_generator ^3.x` memerlukan `analyzer <7`, sedangkan `bloc_test ^10` memerlukan `analyzer >=8`. Konflik permanen — tidak bisa berjalan bersamaan tanpa swap pubspec manual.

### Perubahan

**File baru (Drift):**
- `lib/core/database/app_database.dart` — `@DriftDatabase`, 3 tabel: `AppSettings`, `SyncQueue`, `Transactions`; `SyncOperationConverter` TypeConverter; `MigrationStrategy`
- `lib/core/database/app_database.g.dart` — generated (jangan edit manual)

**File dihapus (Isar):**
- `lib/core/local/app_settings_isar_model.dart` + `.g.dart`
- `lib/core/local/sync_queue_isar_model.dart` + `.g.dart`
- `lib/features/transaction/data/models/transaction_isar_model.dart` + `.g.dart`

**Perubahan signifikan:**
- Semua datasource pakai `AppDatabase` bukan `Isar`
- `TransactionModel`: `fromDrift()` + `toDriftCompanion()` menggantikan `fromIsar()`/`toIsar()`
- `SyncOperation` enum dipindah ke `app_database.dart`
- `SyncService` punya injectable `dispatchFn` param
- Test pakai `NativeDatabase.memory()` (in-memory Drift, tanpa file)
- Build runner: `dart run build_runner build` langsung tanpa swap pubspec — konflik hilang permanen

**Tests baru di migration:**
- `sync_service_test.dart` — 7 tests (pakai `NativeDatabase.memory()`)
- `onboarding_local_datasource_test.dart` — 7 tests

---

## Phase 5A — Bug Fix & Hardening

**Status: ✅ Selesai**  
**Test count: 82/82** (+12 dari baseline 70)  
**Tanggal:** 2026-05-08

### P1 Kritikal (3 fix)

| # | Fix | File | Perubahan |
|---|-----|------|-----------|
| #23 | Logo crash di Dashboard | `dashboard_page.dart` | Ganti `Image.asset('logo-m7.png')` → `PenyintasLogo(size: 28)` |
| #24 | `DashboardEntity.props` missing `todayTransactions` | `dashboard_entity.dart` | Tambah `todayTransactions` ke `props`; keluarkan `lastUpdated` dari equality |
| #25 | Fixed expenses double-counting di `_compute()` | `dashboard_repository_impl.dart` | Filter transaksi `category == fixed` dari `totalSpentThisMonth` |

### P2 Penting (9 fix)

| # | Fix | Perubahan |
|---|-----|-----------|
| #4 | `onConnectivityChanged` false positive | Tambah `.asyncMap((_) => isConnected)` — stream jadi actual internet status |
| #26 | `DashboardBloc.onError` tidak log Crashlytics | `onError: (e,s) { Crashlytics.recordError(e,s); return DashboardError(...); }` |
| #27 | `SyncService.dispose()` tidak pernah dipanggil | Wire ke `WidgetsBindingObserver.dispose()` di `app.dart` |
| #28 | Sync queue tidak ada TTL | Filter item > 7 hari di `_processQueue()`; delete item expired sebelum proses |
| #29 | BudgetBar animasi dari 0 setiap rebuild | Refactor ke StatefulWidget, `_prevPct` track nilai sebelumnya via `didUpdateWidget` |
| #30 | `emergencyFundPct` hilang saat retry onboarding | Tambah field ke `OnboardingStep3` state; BLoC simpan dari event |
| #37 | Duplicate `watchDashboard()` subscription | `LoadDashboard` → `restartable()`, `DashboardRefreshed` → `droppable()` transformer |
| #38 | `effectiveDays` fallback ke 30 saat hari kiriman | Ganti ke `daysInCycle(settings.paymentDate)` — hitung siklus berikutnya |

### P3 Kualitas Kode (6 fix)

| # | Fix | Perubahan |
|---|-----|-----------|
| #15 | Global `catch (_)` tanpa Crashlytics | Ganti ke `catch (e, s) { Crashlytics.recordError(e, s); }` di seluruh codebase |
| #31 | Nol test untuk `_compute()` | 12 unit tests baru via `watchDashboard()` stream |
| #33 | `getBudgetSettings()` di-call setiap stream event | Cache `BudgetSettingsEntity? _cachedSettings` di repo, invalidate saat null |
| #34 | `DashboardRefreshed` tanpa kondisi | Return `true` dari `AddTransactionSheet` saat save; panggil refresh hanya jika `saved == true` |
| #35 | "DAYS TO LIVE" hardcoded English | Wire ke `AppLocalizations.dashboardDtlLabel` dan `dashboardDtlSubtitle` |
| #32 | Test `SyncDispatcher` | ⚠️ **Deferred** — `fake_cloud_firestore ^3` inkompatibel dengan `cloud_firestore ^6.x`; `DocumentReference` sealed class |

**Test baru:**
- `dashboard_repository_impl_test.dart` — 12 tests (`_compute()` via `watchDashboard()`)

---

## Phase 5B — Notification Feature

**Status: ✅ Selesai (kode + bug fixes)**  
**Test count: 90/90** (+8 dari 5A)  
**Tanggal:** 2026-05-11 (kode) · 2026-05-12 (5B-fix)

### Arsitektur

```
lib/features/notification/
  domain/    notification_repository.dart + 4 use cases
  data/      NotificationLocalDatasource (flutter_local_notifications)
             NotificationRemoteDatasource (FCM token ke Firestore)
             NotificationRepositoryImpl
  presentation/  NotificationBloc (6 events, 6 states)

functions/src/
  daily_reminder.js   — scheduled 20:00 WIB (cron '0 20 * * *', Asia/Jakarta)
  budget_warning.js   — Firestore trigger saat transaksi baru
  payday_reminder.js  — scheduled 07:00 WIB, H-3 sebelum paymentDate
  index.js            — export semua functions + initializeApp()
```

### Schema migration

AppSettings `schemaVersion` → 2: tambah `reminderEnabled`, `reminderHour`, `reminderMinute` (default: enabled, 20:00)

### Dependencies baru

- `timezone: ^0.11.0` + `flutter_timezone: ^3.0.0` — `zonedSchedule()` untuk scheduled local notification

### Bug yang ditemukan & diperbaiki (5B-fix)

**P1 — 3 fix:**
| # | Masalah | Fix |
|---|---------|-----|
| #71 | `initialize()` tidak pernah dipanggil → semua local notification mati | `_onInit` bloc memanggil `await _local.initialize(onTap: (p) => add(NotificationTapped(p)))` |
| #72 | `budget_warning.js` compound inequality query illegal di Firestore → crash 100% | Hapus `category != 'fixed'` dari query; filter di JS dengan `.filter()` |
| #73 | Cron `'0 13 * * *'` = 13:00 WIB bukan 20:00 WIB | Ganti ke `'0 20 * * *'` dengan `timeZone: 'Asia/Jakarta'` |

**P2 — 5 fix:**
| # | Masalah | Fix |
|---|---------|-----|
| #74 | `onMessageOpenedApp` subscription leak | Simpan ke `_openedAppSub`, cancel di `close()` |
| #75 | `onTap` callback no-op → tap notifikasi tidak navigasi | Pindah inisialisasi dari repo ke bloc; callback real |
| #76 | `reminderEnabled/Hour/Minute` tidak dibaca/ditulis ke DB | `_onInit` baca settings + reschedule; `_onSchedule` tulis ke DB |
| #77 | `payday_reminder.js` cron = 00:00 WIB bukan 07:00 WIB | Ganti ke `'0 7 * * *'` |
| #78 | `notifStatus` tidak reset awal bulan baru | Cek `storedMonth !== currentMonth` → reset ke `'safe'`; simpan `month: currentMonth` |

**Test baru:**
- `request_permission_usecase_test.dart` — 2 tests
- `notification_bloc_test.dart` — 6 tests (termasuk bonus: permission error)

---

## Phase 5C — Report Feature

**Status: ✅ Selesai**  
**Test count: 109/109** (+19 dari 5B)  
**Tanggal:** 2026-05-12

### Yang dibangun

**Domain:**
- `ReportEntity` — totalIncome, totalExpense, netBalance, categoryBreakdown, topCategory, savingRate, comparison (vs bulan sebelumnya)
- `WeeklySpendEntity` — total pengeluaran per minggu dalam bulan
- `GetMonthlyReportUseCase` + `GetAiInsightUseCase`

**Data:**
- `ReportLocalDatasourceImpl` — query Drift: kalkulasi weekly/kategori/comparison dari `NativeDatabase`
- `ReportRemoteDatasourceImpl` — 24h Firestore cache + Firebase Functions callable untuk AI insight
- `ReportRepositoryImpl` — local-first, remote untuk AI insight

**Presentation:**
- `ReportBloc` — 4 events (LoadReport, LoadAiInsight, PreviousMonth, NextMonth), 4 states
- `ReportPage` dengan 4 widget komponen:
  - `MonthSelector` — navigasi bulan (panah kiri/kanan)
  - `CategoryPieChart` — `fl_chart ^1.2.0` PieChart dengan legend
  - `WeeklyBarChart` — `fl_chart` BarChart 4–5 bar per bulan
  - `InsightCard` — tampilan AI insight dengan loading state

**Cloud Functions:**
- `functions/src/insights.js` — Vertex AI `gemini-1.5-flash` via `@google-cloud/vertexai ^1.0.0`
  - 24h Firestore cache untuk hemat quota
  - `safeParseJson()` helper untuk strip markdown fence dari response AI
  - null guard pada `candidates[]` dan `text` field
- `functions/src/index.js` — exports semua 4 functions, `initializeApp()` wajib, region `asia-southeast2` (Jakarta)

### Bug yang ditemukan & diperbaiki (5C-fix)

| # | Status | Masalah | Fix |
|---|--------|---------|-----|
| #86 | ❌ Obsolete | False positive — kode sudah benar dari awal | — |
| #87 | ✅ | `insights.js` index months 0-based vs 1-based | Pakai `transactions?.month` dari client (1-indexed Dart key) |
| #88 | ✅ | JSON response AI berisi markdown fence → parse gagal | `safeParseJson()` strip ` ```json ` sebelum parse |
| #89 | ✅ | Null crash pada `candidates` array dan `text` | Null guard + default ke insight string kosong |
| #90 | ✅ | `elapsedDays` salah untuk bulan berjalan | `elapsedDays = now.day` untuk bulan berjalan |
| #91 | ✅ | `_SummaryItem` text color hardcoded, tidak dark mode | Ganti ke `isDark ? mutedDark : mutedLight` |

**Test baru:**
- `get_monthly_report_usecase_test.dart` — 3 tests
- `report_local_datasource_test.dart` — 6 tests (NativeDatabase.memory())
- `report_repository_impl_test.dart` — 4 tests
- `report_bloc_test.dart` — 6 tests

**Routing update:** `/report` sekarang `BlocProvider<ReportBloc> + ReportPage` (bukan SnackBar placeholder)

---

## Statistik Test

| Milestone | Test Count | Delta |
|-----------|-----------|-------|
| Phase 0–2 | 0 | — |
| Phase 3 (auth + onboarding) | 22 | +22 |
| Phase 4 (dashboard + sync) | 56 | +34 |
| Drift migration | 70 | +14 |
| Phase 5A (bug fix + compute test) | 82 | +12 |
| Phase 5B (notification) | 90 | +8 |
| Phase 5C (report) | 109 | +19 |
| Phase 6 (6A+6B+6C) | 119 | +10 |
| Phase 6A-fix + 6B-fix | 119 | +0 |
| Phase 6C-fix | 127 | +8 |
| Phase 7-prep (CurrencyConfig + formatCurrency) | **143** | +16 |
| Phase 7A (schema v4) | **143** | +0 |
| Phase 7B (Survival Mode AI) | **153** | +10 |
| Phase 7B-fix (bug sprint) | **153** | +0 |
| Phase 7C (Goal Saving) | **175** | +22 |
| Phase 7C-fix (bug sprint) | **175** | +0 |
| Phase 7D + 7E + 7F | **180** | +5 |
| Dashboard C1 Redesign (UI pass) | **180** | +0 |
| Transactions V2 States (BLoC filter extension) | **183** | +3 |

**Distribusi test aktual:**

```
test/
  features/
    auth/
      auth_bloc_test.dart                                     7 tests
    onboarding/
      domain/usecases/calculate_daily_budget_test.dart        7 tests
      presentation/bloc/onboarding_bloc_test.dart             8 tests
      data/repositories/onboarding_repository_impl_test.dart  8 tests
      data/datasources/onboarding_local_datasource_test.dart  7 tests
    dashboard/
      domain/usecases/calculate_days_to_live_test.dart        5 tests
      presentation/bloc/dashboard_bloc_test.dart              4 tests
      data/repositories/dashboard_repository_impl_test.dart   12 tests
    notification/
      domain/usecases/request_permission_usecase_test.dart    2 tests
      presentation/bloc/notification_bloc_test.dart           6 tests
    report/
      domain/usecases/get_monthly_report_usecase_test.dart    3 tests
      data/datasources/report_local_datasource_test.dart      6 tests
      data/repositories/report_repository_impl_test.dart      4 tests
      presentation/bloc/report_bloc_test.dart                 6 tests
  core/
    sync/sync_service_test.dart                               7 tests
    utils/currency_formatter_test.dart                        (termasuk di baseline)
    transaction/
      transaction_list_bloc_test.dart                         (termasuk di baseline)
  core/
    utils/
      currency_config_test.dart                               5 tests
      currency_formatter_test.dart                            11 tests
    features/
      survival/
        presentation/bloc/survival_bloc_test.dart             10 tests
      goal/
        domain/entities/goal_entity_test.dart                 11 tests
        presentation/bloc/goal_bloc_test.dart                  9 tests
      transaction/
        presentation/bloc/transaction_list_bloc_test.dart      7 tests  ← +3 dari V2 States (FilterSheetApplied)
                                                    TOTAL: 183
```

---

## Issue Tracker — Status Terkini

**Total issue terdokumentasi:** 187 issue (#1–#185, #3 dan #86 obsolete)  
Detail lengkap di [`docs/issue-tracker.md`](issue-tracker.md)

| Kategori | Jumlah |
|----------|--------|
| ✅ Selesai | 145 |
| ⚠️ Sebagian | 1 (#98 pie ✅, bar 🔲) |
| 🔲 Terbuka | 39 (#17, #63, #67–#70, #83, #99–#100, #103, #105, #108–#113, #115, #122, #142, #143, #152–#154, #156–#161, #167, #169, #170, #173–#177, #179) |
| ❌ Obsolete | 2 (#3, #86) |

**#185 diperbaiki inline (Transactions V2 States session):**
- `#185` ✅ — Filter chip stale closure: `buildWhen` di filter-row `BlocBuilder` hanya watch `typeFilter`, sehingga `state` dalam `onFilterTap` closure tidak pernah diperbarui ketika `categoryFilter` berubah → chip kategori terlihat off padahal aktif; fix: baca state live via `context.read<TransactionListBloc>().state` saat tap

**#171 + #172 + #178 + #180 + #181 diperbaiki inline:**
- `#171` ✅ — `_exportCsv()` ditambah `finally { file.delete() }` (konsisten dengan `_shareReport()`)
- `#172` ✅ — `fetchAndActivate().timeout(2s)` ditambah sebelum `getInt()` di `_startSplashTimer()`
- `#178` ✅ — `android:layout_marginLeft` → `android:layout_marginStart` di `penyintas_widget.xml` (diperbaiki sekaligus dgn #181)
- `#180` ✅ — `home_widget 0.8.0+` menarik `androidx.glance:glance-appwidget:1.3.0-alpha01` (butuh AGP 9.1+/compileSdk 37+, project pakai AGP 8.11.1/compileSdk 36) → build gagal total; fix: pin `home_widget: ">=0.5.1 <0.8.0"` → resolves ke `0.7.0+1` (classic `AppWidgetProvider`, kompatibel penuh)
- `#181` ✅ — `android.view.View` base class tidak diizinkan di RemoteViews API 31+ (Android 12+) → `InflateException` tiap launcher render widget → "can't load widget" di semua perangkat API 31+; diagnosed via `adb logcat -d | grep AppWidgetHostView` (emulator API 37); fix: hapus 2 `<View>` dari `penyintas_widget.xml` — spacer diganti `android:layout_marginTop="6dp"`, divider diganti `<FrameLayout android:layout_height="1dp" android:background="#E2DCC8" />`

**Issue terbuka P3 (transaksi screen + widget localization, Phase 8):**
- `#157–#161` — Filter chips, empty state, date headers, month picker, kategori label hardcoded di transaksi screen
- `#173–#176` — Widget: background dark mode, label bahasa, warna hex hardcoded, share strings non-l10n

**Issue terbuka lainnya (P3/P4):**
- `#103` — `SettingsPage` seluruh teks hardcoded Indonesia
- `#152–#156` — Survival Mode P4 deferred (singleton reset, dead param, Semantics, blank fallback, test coverage)
- `#167`, `#169`, `#170` — Goal tech debt deferred ke Phase 8
- `#177–#179` — Widget deep link, RTL margin, share loading state

---

## Arsitektur Fitur Saat Ini

```
lib/
  features/
    auth/          ✅  Firebase Auth + BLoC + 3 pages
    onboarding/    ✅  Wizard 3 langkah + BLoC + local-first + sync queue
    dashboard/     ✅  Real-time stream + BLoC + C1 redesign (BentoGrid, RingWidget, TipCard, SaldoCard eye-toggle)
    transaction/   ✅  CRUD + AddTransactionSheet (numpad) + TransactionList V2 (timeline spine, skeleton, empty state, detail sheet, filter sheet, search)
    notification/  ✅  FCM + local notifications + Cloud Functions (3 functions)
    report/        ✅  Chart (pie + bar) + AI insight (Vertex AI Gemini)
    settings/      ✅  Settings Page UI selesai di Phase 6A
    survival/      ✅  Survival Mode AI (Phase 7B): SurvivalBloc singleton, SurvivalTipsPage, CF
    goal/          ✅  Goal Saving (Phase 7C): GoalBloc, GoalListPage, GoalDetailPage, AddGoalSheet, milestone toasts
    profile/       ✅  SayaPage hub: ProfileHeader + QuickAccess + SettingsSection + AccountSection
    budget/        ⚠️  Coming-soon page tersedia; fitur belum dimulai (Phase 8A)

  widgets/common/
    PenyintasLogo      ✅  SVG auto light/dark/reversed
    PrimaryButton      ✅
    AppTextField       ✅
    DaysToLiveCard     ✅  Padding AppSpacing.lg2, hero num 48px Plus Jakarta Sans
    BudgetBar          ✅  Animasi dari nilai sebelumnya
    SurvivalModeBanner ✅
    TransactionItem    ✅  Swipe-to-delete
    MilestoneToast     ✅  Dibangun di Phase 6A

  core/
    database/    ✅  Drift (AppSettings, SyncQueue, Transactions)
    sync/        ✅  SyncService + SyncDispatcher
    di/          ✅  GetIt DI container
    routing/     ✅  go_router + auth redirect + onboarding guard
    l10n/        ✅  AppLocalizations (200+ keys) — dashboard 100% l10n, DateFormat locale-aware timestamp
    theme/       ✅  AppColors (+ cardLight #FDFCF8), AppTextStyles, AppSpacing (+ sm2=10, md2=14, lg2=18), AppRadius
    utils/       ✅  formatRupiah (shim), CurrencyConfig (IDR), formatCurrency(), date_helper, analytics_service, network_info
```

---

## Phase 6 — Progress

### Phase 6A ✅ (2026-05-19)

Settings Page UI, MilestoneToast, l10n fixes (#59/#60), notification dead code (#79/#80). 109/109 tests.

### Phase 6A-fix ✅ (2026-05-20)

#101 (P1 onCancel Either), #102 (BlocListener SettingsPage), #104 (hintText fix), #106 (header guard), #107 (toast margin). 109/109 tests.

### Phase 6B ✅ (2026-05-20)

Cloud Functions WIB timezone (#81/#82), budget_warning running total (#85), iOS permission delay (#83 plan), Report Polish savingTip chain (#93), netBalance sign (#94), CategoryPieChart AppColors+touch (#95/#98), minor UI fixes (#96/#97), ReportEntity props (#92). 109/109 tests.

**Analisis post-6B:** 8 issue baru ditemukan (#114–#121). 4 wajib di-fix sebelum 6C: #114/#116 (P2 budget_warning WIB + fcmToken gate) · #117/#118 (P3 touchedIndex reset + Map sort).

### Phase 6B-fix ✅ (2026-05-20)

| # | Priority | Item | Status |
|---|----------|------|--------|
| `#114` | P2 | `budget_warning.js` monthKey WIB fix | ✅ |
| `#116` | P2 | Pisah cache update dari fcmToken early return | ✅ |
| `#117` | P3 | `didUpdateWidget` reset `_touchedIndex` di `CategoryPieChart` | ✅ |
| `#118` | P3 | Sort `categoryBreakdown.entries` di `ReportEntity.props` | ✅ |

### Phase 6C ✅ (2026-05-20)

Technical Debt & Architecture. 119/119 tests · 0 flutter analyze issues.

| # | Priority | Item | Status |
|---|----------|------|--------|
| `#40` | P3 | Schema v3 migration — 5 kolom expense breakdown di `AppSettings` | ✅ |
| `#32` | P3 | `toFirestoreOp()` pure function + 6 unit tests | ✅ |
| `#36` | P4 | `Future.wait` di `watchDashboard()` | ✅ |
| `#58` | P3 | AppLocalizations full adoption — `context.l10n` ext + 40+ keys + 5 pages | ✅ |
| `#21` | P4 | Widget test `OnboardingPage` (4 tests — Steps 1 & 2) | ✅ |
| `#22` | P4 | Accessibility semantics (`_QuickChip`, `_DateSegmentPicker`) | ✅ |
| `#18` | P4 | `createAppRouter()` factory injectable via GetIt | ✅ |
| `#119` | P4 | `netBalance == 0` tidak tampil `'+ Rp 0'` | ✅ |
| `#120` | P4 | `InsightCard` skeleton `AppRadius.sm` | ✅ |
| `#121` | P4 | `copyWith()` sentinel — bisa null-ify `savingTip` | ✅ |
| `#17` | P4 | ~~Split AppSettings tabel~~ | ↩ Defer → Phase 8A |
| `#19` | P4 | Cache `onboardingCompleted` | ↩ Defer → Phase 7 |
| `#20` | P4 | Splash timeout via RemoteConfig | ↩ Defer → Phase 7 |

**Analisis post-6C:** 9 issue baru ditemukan (#122–#130). 4 wajib di-fix sebelum Phase 8 (#122–#125).

### Phase 6C-fix ✅ (2026-05-20)

| # | Priority | Item |
|---|----------|------|
| `#122` | P1 | Migration v3: user existing lihat semua breakdown sebagai "Lainnya" di Settings |
| `#123` | P1 | `sync_dispatcher.dart:27` unsafe cast `(op as DeleteOp).path` |
| `#124` | P2 | Missing Semantics di `_ExpenseInputRow` (Step 2) dan `Slider` (Step 3) |
| `#125` | P2 | 10+ hardcoded string di `onboarding_page.dart` tidak tercakup #58 |
| `#126` | P3 | `_DateSegmentPicker` Semantics label tidak announce selection state |
| `#127` | P3 | Tidak ada test untuk `ReportEntity.copyWith()` sentinel pattern |
| `#128` | P3 | `_redirect` akses `sl<AppDatabase>()` tanpa runtime guard |
| `#129` | P3 | `onboarding_page_test.dart` tidak verify Semantics labels dari #22 |
| `#130` | P3 | Schema migration SQL defaults tidak dikroscek dengan definisi Dart table | ✅ Verified |

**Analisis post-6C-fix:** 13 issue baru ditemukan (#131–#143). 5 wajib di-fix sebelum Phase 7B/7C (sprint 7-prep-fix): #132/#131/#133+#137/#139.

### Phase 7-prep ✅ (2026-05-20)

CurrencyConfig + formatCurrency() + formatRupiah() shim. 143/143 tests.

| Komponen | Status |
|----------|--------|
| `lib/core/utils/currency_config.dart` (FILE BARU) — `CurrencyConfig` Equatable, IDR config, `fromCode()` | ✅ |
| Update `lib/core/utils/currency_formatter.dart` — `formatCurrency()` + `formatCurrencyCompact()` + shim | ✅ |
| `test/core/utils/currency_config_test.dart` (FILE BARU) — 5 unit tests | ✅ |
| `test/core/utils/currency_formatter_test.dart` (FILE BARU) — 11 unit tests | ✅ |
| `flutter analyze: 0 issues` | ✅ |

**Delta tests:** 127 → 143 (+16 tests baru)

### Phase 7B ✅ (2026-05-21)

Survival Mode AI — otomatis aktif saat `BudgetStatus.danger` (saldo < 15% monthly budget). 153/153 tests.

| Komponen | Status |
|----------|--------|
| `SurvivalModeEntity` + `SurvivalTip` — Equatable, `copyWith()` | ✅ |
| `GetSurvivalModeUseCase`, `GetSurvivalTipsUseCase` (`SurvivalTipsParams`) | ✅ |
| `RecordSurvivalActivatedUseCase`, `ClearSurvivalActivatedUseCase` | ✅ |
| `SurvivalLocalDatasource` — baca/tulis `survivalModeActivatedAt` di `AppSettings id=1` | ✅ |
| `SurvivalRemoteDatasource` — panggil CF `getSurvivalTips`, map ke `List<SurvivalTip>` | ✅ |
| `SurvivalRepositoryImpl` — computed `isActive`, `suggestedDailyBudget` | ✅ |
| `SurvivalBloc` — singleton via GetIt, `droppable()`, tips cached in-memory | ✅ |
| `SurvivalTipsPage` — skeleton loading (3 cards), list card per tip, error+retry | ✅ |
| `SurvivalModeBanner` — `onTap` → `/survival/tips`, chevron icon | ✅ |
| `DashboardPage` — `BlocListener<DashboardBloc>` dispatch `LoadSurvivalMode` | ✅ |
| `functions/src/survival_tips.js` — Vertex AI Gemini, Firestore cache 24h, language: id/en/ms | ✅ |
| DI: `_initSurvival()` semua class sebagai `lazySingleton` | ✅ |
| Router: `/dashboard` `MultiBlocProvider`, `/survival/tips` `BlocProvider.value` | ✅ |
| `survival_bloc_test.dart` — 10 test cases (LoadSurvivalMode + FetchSurvivalTips) | ✅ |

**Delta tests:** 143 → 153 (+10 tests baru)

**Arsitektur kunci:**
- `SurvivalBloc` adalah singleton (`registerLazySingleton`) — tips cached in-memory antar navigasi
- `activatedAt` disimpan di `AppSettings.survivalModeActivatedAt` (bukan tabel terpisah)
- `isActive` = computed dari `BudgetStatus.danger`, bukan stored di DB
- Tips bracket cache di Firestore: 50k amount bracket, 3-hari bracket → hemat quota AI

### Phase 7C ✅ (2026-05-21)

Goal Saving feature: tujuan menabung dengan progress tracking, milestone toast, dan integrasi ke AddTransactionSheet. 175/175 tests.

| Komponen | Status |
|----------|--------|
| `GoalEntity` — computed `progressPercent` (0–1 clamp), computed `isOverdue`, `copyWith()` | ✅ |
| `GoalRepository` — abstract interface: loadGoals, createGoal, linkTransaction, unlinkTransaction, completeGoal, deleteGoal | ✅ |
| 5 use cases: `LoadGoalsUseCase`, `CreateGoalUseCase`, `LinkTransactionUseCase`, `CompleteGoalUseCase`, `DeleteGoalUseCase` | ✅ |
| `GoalLocalDatasourceImpl` — JOIN query `selectOnly + amount.sum()` untuk computed `savedAmount`; `deleteGoal` unlinks transaksi dulu | ✅ |
| `GoalRepositoryImpl` — Crashlytics `catch (e, s)` di semua method | ✅ |
| `GoalBloc` — `LoadGoals` (droppable), mutating ops (sequential); milestone detection via `prevProgress` map | ✅ |
| `GoalLoaded` — opsional `milestoneGoalId` + `milestoneThreshold` untuk toast trigger | ✅ |
| `GoalListPage` — BlocListener untuk milestone toast → `MilestoneAcknowledged`; FAB → AddGoalSheet | ✅ |
| `GoalDetailPage` — auto-pop saat goal dihapus; AppBar Complete + Delete dengan konfirmasi AlertDialog | ✅ |
| `GoalCard` — `_GoalProgressBar` TweenAnimationBuilder, `_StatusChip` (Tercapai!/Melewati target) | ✅ |
| `AddGoalSheet` — TextField title + amount (digitsOnly) + date picker (firstDate = now+1, lastDate = now+5yr) | ✅ |
| `TransactionEntity` + `TransactionModel` — tambah `goalId: int?`; updateToEntity/fromDrift/toDriftCompanion | ✅ |
| `AddTransactionEvent` — tambah `GoalSelected(int? goalId)` | ✅ |
| `AddTransactionState` — `selectedGoalId` + sentinel `_kSentinel` copyWith; clear saat TypeToggled ke expense | ✅ |
| `AddTransactionBloc` — `_onGoalSelected`; `_onSubmit` meneruskan `goalId` hanya saat type=income | ✅ |
| `AddTransactionSheet` — `_GoalPicker` DropdownButton (visible saat income + activeGoals.isNotEmpty) | ✅ |
| 17 l10n key baru di id.json + en.json + app_localizations.dart | ✅ |
| DI: `_initGoal()` — 1 `registerFactory(GoalBloc)` + 5 use cases + repository + datasource | ✅ |
| Router: `/goals` (BlocProvider<GoalBloc>) + nested `/goals/:id` (`BlocProvider.value` + `state.extra as GoalEntity`) | ✅ |
| `goal_entity_test.dart` — 11 tests (progressPercent edge cases, isOverdue, copyWith, Equatable) | ✅ |
| `goal_bloc_test.dart` — 9 tests (LoadGoals 3, CreateGoal 2, LinkTransaction 2, MilestoneAcknowledged 1, DeleteGoal 1) | ✅ |

**Delta tests:** 153 → 175 (+22 tests baru)

**Arsitektur kunci (setelah 7C-fix — updated):**
- `GoalEntity.savedAmount` SELALU computed dari `SUM(transactions WHERE goalId = id AND amount > 0)` — tidak pernah disimpan di DB
- `GoalBloc` adalah `registerLazySingleton` (singleton, mirip `SurvivalBloc`) — state dan tips persistent antar navigasi
- Router `/goals` menggunakan `BlocProvider.value(value: sl<GoalBloc>())` bukan `BlocProvider(create:...)`
- Milestone detection: `_onLoad()` capture `prevGoals` sebelum emit `GoalLoading()`, bandingkan setelah reload dari caller mana pun
- `UnlinkTransactionUseCase` ada di `lib/features/goal/domain/usecases/unlink_transaction_usecase.dart`
- `MilestoneToast.show()` dipanggil dari `GoalListPage` BlocListener, bukan dari dalam Bloc

### Phase 7C-fix ✅ (2026-05-21)

Bug sprint post-7C: 6 issue Goal Saving feature diperbaiki. 175/175 tests (tidak ada test baru — existing tests tetap hijau).

| Fix | Priority | File | Detail |
|-----|----------|------|--------|
| **#162** | P1 | `dashboard_page.dart` · `transaction_list_page.dart` · `saya_page.dart` | Load `activeGoals` via `LoadGoalsUseCase` sebelum buka `AddTransactionSheet`; pass `activeGoals:` ke sheet; GoalPicker kini muncul |
| **#163** | P1 | `add_goal_sheet.dart` | Tambah `BlocListener<GoalBloc, GoalState>` — pop hanya saat `GoalLoaded`, snackbar saat `GoalError`; hapus premature `Navigator.pop()` dari `_submit()` |
| **#164** | P2 | `goal_detail_page.dart` | `context.watch<GoalBloc>()` untuk live data; ganti semua `goal.xxx` → `current.xxx` |
| **#165** | P2 | `injection_container.dart` · `app_router.dart` · `goal_bloc.dart` | `GoalBloc` → `registerLazySingleton`; router pakai `BlocProvider.value`; 3 caller trigger `sl<GoalBloc>().add(LoadGoals())` setelah save; `_onLoad()` deteksi milestone dari state sebelumnya |
| **#166** | P2 | `goal_bloc.dart` · `unlink_transaction_usecase.dart` (FILE BARU) | `UnlinkTransactionUseCase` dibuat dan di-wire; `_onUnlink()` panggil repo sebelum reload |
| **#168** | P3 | `goal_detail_page.dart` · id.json · en.json · `app_localizations.dart` | 8 l10n key baru: `goal_detail_mark_done`, `goal_detail_delete_tooltip`, `goal_detail_status_label`, `goal_detail_status_active`, `goal_detail_delete_title`, `goal_detail_delete_btn`, `goal_detail_tip`, `goal_date_picker_hint` |

**Delta tests:** 175 → 175 (tidak berubah; semua hijau)

### Profile & Navigation Polish ✅ (2026-05-21)

Tab "Profil" dan "Budget" yang sebelumnya hanya menampilkan SnackBar "Fitur ini segera hadir" kini terhubung ke halaman nyata. 175/175 tests (tidak ada test baru — UI-only change).

#### Yang dibangun

**`lib/features/profile/presentation/pages/saya_page.dart`** (FILE BARU):

| Widget | Isi |
|--------|-----|
| `_ProfileHeader` | `CircleAvatar` 56×56 dengan inisial dari `FirebaseAuth.instance.currentUser`; nama + email di bawahnya |
| `_QuickAccess` | 3 `_QuickCard` berjajar: Tujuan → `/goals`, Laporan → `/report`, Mode Hemat → `/survival/tips` |
| `_SettingsSection` | `BlocBuilder<SettingsBloc>` — baris Tampilan + Bahasa (tap → `showModalBottomSheet` dengan `outerCtx.read<SettingsBloc>().add(...)`) + baris Notifikasi (tap → `/settings`) |
| `_AccountSection` | Versi app `v0.1.0+1` (hardcoded; #109 defer — butuh `package_info_plus`); Keluar via `FirebaseAuth.instance.signOut()` + `AlertDialog` konfirmasi; logout otomatis redirect ke `/login` via `GoRouterRefreshStream` |

**`lib/core/routing/app_router.dart` — `_BudgetComingSoonPage`** (CLASS BARU, inline di router):
- Icon dompet + eyebrow "SEGERA HADIR" + judul + deskripsi
- `AppBottomNavBar(currentIndex: 3)` tanpa FAB
- Semua copy via `AppLocalizations` (3 key baru: `budgetComingSoonEyebrow`, `budgetComingSoonTitle`, `budgetComingSoonBody`)

**`lib/widgets/common/app_bottom_nav_bar.dart`:**
- `_onTap` case 3 → `context.go('/budget')` (sebelumnya: `ScaffoldMessenger.showSnackBar(...)`)
- `_onTap` case 4 → `context.go('/profile')` (sebelumnya: `ScaffoldMessenger.showSnackBar(...)`)
- `_PlaceholderPage` dihapus dari `app_router.dart`

#### l10n — 17 key baru

| File | Key baru |
|------|----------|
| `id.json` + `en.json` | `nav_profile` → `"Saya"` / `"Saya"` (brand name, tidak diterjemahkan) |
| | `saya_section_quick`, `saya_quick_goals`, `saya_quick_report`, `saya_quick_survival` |
| | `saya_section_settings`, `saya_theme_label`, `saya_language_label`, `saya_notif_label` |
| | `saya_section_account`, `saya_version_label`, `saya_logout`, `saya_logout_confirm`, `saya_logout_confirm_yes` |
| | `budget_coming_soon_eyebrow`, `budget_coming_soon_title`, `budget_coming_soon_body` |
| `AppLocalizations` | 17 getter baru (sayaSectionQuick, sayaQuickGoals, ..., budgetComingSoonBody) |

#### Pola desain penting

- **ModalBottomSheet + BLoC:** pattern `outerCtx` (di-capture sebelum `showModalBottomSheet`) untuk dispatch event dari dalam sheet tanpa kehilangan BLoC reference — identik dengan `SettingsPage` existing
- **Logout flow:** `FirebaseAuth.signOut()` → `GoRouterRefreshStream` emit → `_redirect` deteksi `user == null` → redirect ke `/login`; tidak perlu dispatch ke AuthBloc
- **`_BudgetComingSoonPage` inline di router:** keputusan disengaja — page terlalu kecil untuk file tersendiri; akan dipisah saat fitur Budget mulai dibangun di Phase 8A

### Phase 7B-fix ✅ (2026-05-21)

Bug sprint post-7B. 153/153 tests (tidak ada test baru — existing tests tetap hijau).

| Fix | File | Detail |
|-----|------|--------|
| **#144** P1 | `survival_remote_datasource.dart` + `survival_repository_impl.dart` | Guard cast `rawTips is! List` → `FormatException`; `on Exception` → `catch (e, s)` |
| **#145** P2 | `survival_bloc.dart` | Tambah `await` ke `_recordActivated()` dan `_clearActivated()` di `_onLoad` |
| **#146** P2 | `survival_repository_impl.dart` | Crashlytics `recordError(e, s, reason: '...')` di semua 4 catch handler |
| **#147** P3 | `survival_mode_entity.dart` | Sentinel `_kSentinel` → `copyWith(activatedAt: null)` berfungsi |
| **#148** P3 | `survival_tips_page.dart` + `survival_mode_banner.dart` | Ganti `formatRupiah`/`formatRupiahCompact` → `formatCurrency`/`formatCurrencyCompact(_, CurrencyConfig.idr)` |
| **#149** P3 | id.json + en.json + `app_localizations.dart` | 8 key baru: `survivalTipsPageTitle`, `survivalTipsEyebrow`, `survivalBudgetLabel`, `survivalBudgetDaysSuggested`, `survivalTipsSavingChip`, `survivalBannerBalance`, `survivalTipsLink`, `survivalTipsEmpty` |
| **#150** P3 | `survival_tips_page.dart` | Tambah `_EmptyTipsState` widget — muncul saat `entity.tips.isEmpty` setelah load |
| **#151** P3 | `survival_bloc.dart` | Refactor `_onLoad` keluar dari `fold` callback (bisa `await`); tambah `else if (state is SurvivalTipsLoading)` guard |

**Delta tests:** 153 → 153 (tidak berubah; semua hijau)

### Phase 7A ✅ (2026-05-20)

Schema v4: Goals table, goalId di Transactions, survivalModeActivatedAt di AppSettings. 143/143 tests.

| Komponen | Status |
|----------|--------|
| `Goals` table baru di `app_database.dart` (id, title, targetAmount, targetDate, isCompleted, createdAt) | ✅ |
| `goalId INTEGER NULL` ditambahkan ke tabel `Transactions` | ✅ |
| `survivalModeActivatedAt INTEGER NULL` ditambahkan ke tabel `AppSettings` | ✅ |
| `schemaVersion` naik ke `4` | ✅ |
| Migration v4 via raw `customStatement` SQL (pattern konsisten dengan v2, v3) | ✅ |
| `@DriftDatabase(tables: [..., Goals])` diupdate | ✅ |
| `dart run build_runner build` — 124 outputs, 0 error (warning flag diabaikan) | ✅ |
| Semua 143 existing tests tetap hijau | ✅ |

---

## Dashboard C1 Final MVP Redesign ✅ (2026-05-26)

UI-only redesign dashboard berdasarkan handoff bundle C1 Final MVP. 180/180 tests (tidak ada test baru — UI change).

### Perubahan layout

Section order baru:
1. Header (notif dot static)
2. DTL Card (padding `AppSpacing.lg2`, hero num 48px Plus Jakarta Sans 800)
3. Akses Cepat + BentoGrid
4. SaldoCard (eye toggle)
5. 2× RingWidget (donut chart)
6. TipCard (dashed border)
7. Transaksi terkini (TxCard card-wrapped)

### Widget baru (private, inline di `dashboard_page.dart`)

| Widget | Deskripsi |
|--------|-----------|
| `_BentoGrid` | 2-col layout: 2 featured tile + 4 quick tile. Featured: Survival Mode + Tagihan. Quick: Tujuan + Scan Struk + Bagi Tagihan + Tantangan |
| `_BentoFeatTile` | Tile besar berwarna (min 116dp), badge pill, icon |
| `_BentoQuickTile` | Tile kecil (60dp), icon container `AppRadius.sm` |
| `_RingPainter` | `CustomPainter` donut chart, arc dari -π/2, strokeCap round |
| `_RingWidget` | Card ring + nilai + delta label |
| `_DashedBorderPainter` | `CustomPainter` dashed border (dashLen=5, gapLen=4) |
| `_TipCard` | Static tip harian, dashed border, icon circle |
| `_TxCard` | Card wrapper untuk `_TxnRow` list (max 3 item) |
| `_SectionHeader` | Row judul + action link |

### Upgrade widget existing

- `_SaldoCard` → StatefulWidget, eye toggle `bool _hidden`, tap target 44×44dp
- `_DashboardHeader` → notif dot 8×8 `AppColors.warn` di pojok kanan bell
- `_TxnRow` → divider per row, padding tokenized

### Token baru

| Token | Nilai | Pakai untuk |
|-------|-------|-------------|
| `AppSpacing.lg2` | 18dp | Padding DTL card, slot desain 18dp (rename dari `xl1`) |
| `AppColors.cardLight` | `#FDFCF8` | Card surface light mode (warm off-white, kontras di atas bgLight tanpa pure white) |

### Dihapus

- `SurvivalModeBanner` dari layout dashboard (BlocListener tetap ada untuk routing)
- `_SpendingCard`, `_EmergencyCard` → diganti `_RingWidget`
- `_RecentTransactionsSection` → diganti `_TxCard`

### Compliance fixes post-implementasi

Copy `'On track'` → `'Sesuai rencana'`, padding hardcoded 14/10 → token, `BorderRadius.circular(10)` → `AppRadius.sm`, `fontFamily: 'JetBrainsMono'` dari `.copyWith()` dihapus, card background `Colors.white` → `AppColors.cardLight`.

---

## Dashboard C1 — Post-launch Polish ✅ (2026-05-26)

3 commit polish setelah C1 redesign. 180/180 tests, 0 analyze issues.

### 1 · Localization 100% (`feat(l10n)`, commit `c74572e`)

**37 key baru** ditambahkan ke `id.json`, `en.json`, dan `app_localizations.dart`:

| Grup | Key |
|------|-----|
| Greeting | `dashboard_greeting_morning/noon/afternoon/evening` |
| Ring delta | `dashboard_delta_on_track/nearing/exceeded` |
| Ring sub-label | `dashboard_pct_of_budget(pct)`, `dashboard_pct_of_total(pct)` |
| Section header | `dashboard_quick_access`, `dashboard_quick_access_action`, `dashboard_see_all_action` |
| Saldo card | `dashboard_balance_hidden`, `dashboard_balance_detail`, `dashboard_balance_as_of` |
| Bento tiles | `dashboard_bento_survival_*`, `dashboard_bento_bills_*`, `dashboard_bento_goals_sub`, `dashboard_bento_scan_*`, `dashboard_bento_split_*`, `dashboard_bento_challenge_*` |
| Umum | `common_coming_soon` |
| Tip card | `dashboard_tip_eyebrow`, `dashboard_tip_text` |
| Tx kosong | `dashboard_tx_empty` |
| Kategori | `category_health`, `category_internet` |

**Perubahan kode `dashboard_page.dart`:**
- `_timestamp()` → pakai `intl` `DateFormat('d MMMM yyyy', locale)` untuk nama bulan locale-aware (bukan array hardcoded Indonesia)
- `_greeting()` → terima `BuildContext`, return `context.l10n.dashboardGreetingXxx`
- `_categoryLabel()` → non-static, terima `AppLocalizations` param
- `_buildSpendingRing()` / `_buildEmergencyRing()` → terima `BuildContext`, semua string via l10n
- Semua bento tiles, TipCard, TxCard, SaldoCard → 100% via `context.l10n.*`

### 2 · Spacing design tokens (`fix(spacing)`, commit `dfff4a7`)

**Root cause:** Compliance pass C1 salah mengganti nilai desain 14dp → `AppSpacing.lg` (16) dan 10dp → `AppSpacing.sm` (8). AppSpacing tidak memiliki token untuk keduanya.

**Token baru di `app_spacing.dart`:**

| Token | Nilai | Posisi di skala |
|-------|-------|-----------------|
| `AppSpacing.sm2` | 10dp | Antara `sm` (8) dan `md` (12) |
| `AppSpacing.md2` | 14dp | Antara `md` (12) dan `lg` (16) |

**13 titik diperbarui di `dashboard_page.dart`:**

| Lokasi | Sebelum | Sesudah |
|--------|---------|---------|
| `_BentoFeatTile` padding | `lg` (16) | `md2` (14) |
| `_TipCard` horizontal padding | `lg` (16) | `md2` (14) |
| `_TipCard` vertical padding | `sm` (8) | `sm2` (10) |
| `_TxnRow` horizontal padding | `lg` (16) | `md2` (14) |
| Section separators (×3) | `md` (12) | `md2` (14) |
| Ring gap | `sm` (8) | `sm2` (10) |
| Bento horizontal gaps (×3) | `sm` (8) | `sm2` (10) |
| Bento vertical gaps (×2) | `sm` (8) | `sm2` (10) |

### 3 · Text style audit (`fix(text-style)`, commit `34928cc`)

Audit seluruh penggunaan `AppTextStyles` di dashboard vs CLAUDE.md type scale. **8 fix:**

| Lokasi | Sebelum | Sesudah | Alasan |
|--------|---------|---------|--------|
| Transaction name (`_TxnRow`) | `body` IT 16px | `bodySmall` IT 14px | 16px terlalu besar untuk row 60dp |
| Transaction amount (`_TxnRow`) | `label` IT + manual tabularFigures | `numericSm` JBM 14 | Angka finansial → JBM mono, tabular built-in |
| Ring value (`_RingWidget`) | `label` IT w800 + tabularFigures | `numericSm` JBM 14 | Idem; w800 tidak ada optical cut di IT |
| Section header action (`_SectionHeader`) | `label.copyWith(12px)` | `label` 14px | 12px IT off-scale, tidak ada token |
| Bento quick tile label (`_BentoQuickTile`) | `label.copyWith(12px)` | `label` 14px | Idem |
| Tip card body (`_TipCard`) | `body.copyWith(12px)` | `bodySmall` IT 14px | 12px IT off-scale; 14px lebih readable |
| "Detail →" link (`_SaldoCard`) | `label.copyWith(11px)` | `caption` JBM 12px | 11px off-scale; caption cocok dengan timestamp di baris yang sama |
| Arrow icon "Detail" | `size: 11` | `size: 12` | Match caption baseline |

---

## Transactions V2 States ✅ (2026-05-27)

6 task UI states layar transaksi + BLoC filter extension. 183/183 tests, 0 analyze issues.

| Task | Komponen | Status |
|------|----------|--------|
| Pre | `TransactionCategoryX` extension di `transaction_entity.dart` — `.label` getter (pure Dart, tanpa Flutter import, callable sebagai `category.label`) | ✅ |
| 1 | `FilterSheetApplied` event · 3 field baru di `TransactionListLoaded` (`categoryFilter`, `minAmount`, `maxAmount`) · `_applyFilters()` static · 3 test baru (total bloc: 4 → 7) | ✅ |
| 2 | `_V2Skeleton` loading skeleton dengan `AnimationController` pulse (repeat+reverse, opacity 0.4–1.0) | ✅ |
| 3 | `_V2EmptyState` dengan spine illustration (gradient fade), contextual CTA (`onAddTap`) | ✅ |
| 4 | `transaction_detail_sheet.dart` (FILE BARU) — spine-continuity header, icon card, meta rows (Waktu/Jenis/Catatan), Edit + Duplikat + Hapus actions; wired via `_V2TxRow.onTap` | ✅ |
| 5 | `transaction_filter_sheet.dart` (FILE BARU) — chip kategori, period grid (4 opsi + custom date picker), `RangeSlider` nominal 0–5 jt; dispatch `FilterSheetApplied` + conditional `LoadTransactions` | ✅ |
| 6 | Search active state — `_TransactionListView` dikonversi ke `StatefulWidget`, `_V2SearchBar` dengan `autofocus`, `_matchesSearch` (client-side, note + category) | ✅ |
| Bug | **#185** filter chip stale closure — `buildWhen` membatasi rebuild ke `typeFilter` sehingga `state` di closure tidak update saat `categoryFilter` berubah → chip kategori terlihat off padahal aktif; fix: `context.read<TransactionListBloc>().state` at tap time | ✅ |

### File baru

- `lib/features/transaction/presentation/widgets/transaction_detail_sheet.dart`
- `lib/features/transaction/presentation/widgets/transaction_filter_sheet.dart`

### Arsitektur kunci

- `TransactionCategoryX` extension di domain layer (`transaction_entity.dart`) — pure Dart, tidak ada Flutter import. Semua widget kini memanggil `category.label` tanpa perlu static helper per-widget
- `_categoryIcon` (mengembalikan `IconData`) tetap diduplikat di `TransactionItem` dan `TransactionDetailSheet` — Flutter `IconData` adalah UI concern, tidak bisa masuk domain layer
- **Equatable dedup pitfall (test):** Dispatch event yang menghasilkan state identik tidak emit apapun. Test `FilterSheetApplied(categories: null)` harus seed state dengan filter aktif agar clear menghasilkan state berbeda
- **Stale closure pattern:** `BlocBuilder` dengan `buildWhen` yang memfilter sebagian field menyebabkan `state` dalam closure tidak diperbarui untuk field yang difilter. Selalu baca state live via `context.read<Bloc>().state` saat interaksi yang bergantung pada state yang di-filter

---

## Catatan Teknis Penting

### Dependency Versions (final, per Phase 5C)

```yaml
flutter_bloc: ^9.0.0
bloc_concurrency: ^0.3.0   # ^0.2.0 konflik dengan bloc_test ^10
bloc_test: ^10.0.0
drift: ^2.21.0
drift_flutter: ^0.2.1
drift_dev: ^2.21.0
firebase_core: ^4.7.0
firebase_auth: ^6.4.0
cloud_firestore: ^6.3.0
firebase_app_check: ^0.4.3  # breaking change di v0.4 — API berbeda dari v0.3
fl_chart: ^1.2.0
flutter_local_notifications: ^21.0.0
timezone: ^0.11.0
flutter_timezone: ^3.0.0
go_router: ^17.2.3
intl: ^0.20.0
```

### Cloud Functions

```
functions/src/
  daily_reminder.js    '0 20 * * *' Asia/Jakarta — kirim notif jika belum ada transaksi hari ini
  budget_warning.js    onDocumentCreated transactions/{txId} — notif saat budget 15–30% atau <15%
  payday_reminder.js   '0 7 * * *' Asia/Jakarta — notif H-3 sebelum paymentDate
  insights.js          callable — Vertex AI gemini-1.5-flash, 24h Firestore cache
  index.js             exports + initializeApp(), region: asia-southeast2
```

### Schema Version Roadmap

```
v1  → Phase 1 (baseline Drift: AppSettings, SyncQueue, Transactions)
v2  → Phase 5B (reminder columns: reminderEnabled, reminderHour, reminderMinute)
v3  → Phase 6C (expense breakdown: rentExpense, utilitiesExpense, internetExpense, phoneExpense, otherFixedExpense)
v4  → Phase 7A (Goals table, goalId di Transactions, survivalModeActivatedAt di AppSettings)
v5  → Phase 8A (planned: AppSettings split + currency/timezone columns)
```

### Phase 7-prep & 7A — Arsitektur Baru

**`lib/core/utils/currency_config.dart`** (FILE BARU):
- `CurrencyConfig` Equatable class dengan field: code, symbol, locale, decimalDigits, compactThousand, compactMillion
- `CurrencyConfig.idr` — IDR config (Rp, id_ID, 0 decimal, rb/jt)
- `CurrencyConfig.registry` — Map placeholder (Phase 8B: expand)
- `CurrencyConfig.fromCode()` — lookup dengan IDR fallback

**`lib/core/utils/currency_formatter.dart`** (UPDATED):
- `formatCurrency(int amount, CurrencyConfig config)` — fungsi utama via `NumberFormat.currency`
- `formatCurrencyCompact(int amount, CurrencyConfig config)` — kompak: jt/rb suffix
- `formatRupiah(int)` — shim ke `formatCurrency(amount, CurrencyConfig.idr)` (JANGAN dihapus sebelum Phase 8G)
- `formatRupiahCompact(int)` — shim ke `formatCurrencyCompact(amount, CurrencyConfig.idr)`

**Schema v4 (`lib/core/database/app_database.dart`):**
- Tabel baru `Goals` (id, title, targetAmount, targetDate [Int, ms], isCompleted, createdAt [Int, ms])
- `Transactions.goalId INTEGER NULL` — link ke Goals (bukan FK formal)
- `AppSettings.survivalModeActivatedAt INTEGER NULL` — timestamp aktivasi Survival Mode
- Migration via raw `customStatement` SQL (konsisten dengan v2/v3 pattern)

### Aturan desain yang tidak boleh dilanggar

1. Semua warna dari `AppColors` — jangan hardcode hex. Card surface light → `AppColors.cardLight`; scaffold → `AppColors.bgLight`; chip/bottomsheet → `AppColors.surfaceLight`
2. Semua font dari `AppTextStyles` — Plus Jakarta Sans / Inter Tight / JetBrains Mono. Jangan `copyWith(fontFamily: '...')` untuk font yang sudah di-set via GoogleFonts. Jangan `copyWith(fontSize: X)` dengan ukuran di luar type scale
3. **Angka finansial wajib JBM** — gunakan `numericSm`/`numericMd`/`numericLg` (tabular-nums built-in). Jangan `label.copyWith(tabularFigures)` untuk saldo/nominal
4. Semua spacing dari `AppSpacing` / `AppRadius` — jangan angka arbitrary. Skala tersedia: `xs=4, sm=8, sm2=10, md=12, md2=14, lg=16, lg2=18, xl=24, xxl=32, xxxl=48, huge=64`
5. Dark mode wajib di setiap widget
6. Logo selalu dari `assets/images/logo-m7.svg` via `SvgPicture.asset()` + `PenyintasLogo`
7. Angka selalu tabular-nums — via `numericSm/Md/Lg` (built-in), atau explicit `fontFeatures: [FontFeature.tabularFigures()]` jika memakai style lain
8. Format Rupiah: `formatRupiah(int)` → `"Rp 1.245.000"`
9. Copy via `context.l10n.*` — jangan hardcode string UI. Dashboard sudah 100% l10n
10. Hit target minimum 44dp iOS / 48dp Android — semua `GestureDetector` dan tap area
