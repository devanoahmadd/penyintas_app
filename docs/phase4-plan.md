# Phase 4 — Planning Dokumen
## Penyintas App · Dashboard, Transaction, Sync Service

> **STATUS: ✅ SELESAI — 2026-05-08**
> `flutter analyze`: 0 issues · `flutter test`: 56/56 passed (34 test baru di Phase 4)
>
> Dokumen ini disimpan sebagai referensi arsitektur dan catatan deviasi dari rencana awal.
> Untuk analisis kelemahan yang ditemukan setelah Phase 4 selesai, lihat PROMPT.md §"ANALISIS KELEMAHAN PHASE 4".

---

## Gambaran Umum Phase 4

**Tujuan:** User bisa mencatat pengeluaran harian dan melihat kondisi keuangannya secara real-time.

**Deliverables utama:**
1. **Pra-Phase 4** — perbaikan 16 kelemahan kritis dari analisis Phase 1–3 (sebelum fitur baru dibangun)
2. **Phase 4A** — Transaction feature: CRUD + offline sync
3. **Phase 4B** — Dashboard: DaysToLive, BudgetBar, SurvivalMode
4. **Phase 4C** — SyncService: processor untuk `SyncQueueIsarModel`

**Prasyarat sebelum mulai:**
- `flutter analyze` 0 issues ✅
- `flutter test` 22/22 passed ✅
- Phase 3 commit sudah masuk ke main

---

## Bagian 1 — Analisis Kelemahan & Priority Penanganan

Seluruh 22 kelemahan dari analisis Phase 1–3 dipetakan ke tindakan konkret di bawah.
Urutan dikerjakan berdasarkan **dependency** (bukan priority saja) — fondasi dulu.

---

### Tahap 0 — Fondasi (dikerjakan SEBELUM Phase 4A dimulai)

Kelemahan yang jika dibiarkan bisa merusak fitur baru yang dibangun di atasnya.

#### 0.1 — `main.dart`: Isar.open() error handling `[P1 #3]`
**File:** `lib/main.dart`
**Masalah:** Jika Isar gagal (disk penuh, permission denied), app crash tanpa pesan.
**Solusi:**
```dart
try {
  final isar = await Isar.open([...], directory: dir.path);
  await di.init(isar: isar);
  runApp(const PenyintasApp());
} catch (e, stack) {
  FirebaseCrashlytics.instance.recordError(e, stack, fatal: true);
  runApp(const _IsarErrorApp()); // Widget sederhana: "Gagal memuat data. Coba restart."
}
```

#### 0.2 — `_redirect` error handling `[P2 #8]`
**File:** `lib/core/routing/app_router.dart`
**Masalah:** Isar query di `_redirect` tanpa try-catch → go_router crash.
**Solusi:**
```dart
Future<String?> _redirect(...) async {
  try {
    // ... logika existing
  } catch (e, stack) {
    FirebaseCrashlytics.instance.recordError(e, stack);
    return '/login'; // safe fallback
  }
}
```

#### 0.3 — Firebase debug provider guard `[P3 #16]`
**File:** `lib/main.dart`
**Masalah:** `AndroidDebugProvider()` hardcoded — AppCheck bypass di production.
**Solusi:**
```dart
await FirebaseAppCheck.instance.activate(
  providerAndroid: kReleaseMode
      ? AndroidPlayIntegrityProvider()
      : AndroidDebugProvider(),
  providerApple: kReleaseMode
      ? AppleDeviceCheckProvider()
      : AppleDebugProvider(),
);
```

#### 0.4 — `SettingsBloc._persist()` error handling `[P2 #7]`
**File:** `lib/features/settings/presentation/bloc/settings_bloc.dart`
**Masalah:** Isar write gagal → silent data loss.
**Solusi:** wrap `_persist()` dengan try-catch, log ke Crashlytics.

#### 0.5 — `AppLocalizations.shouldReload` `[P3 #14]`
**File:** `lib/core/l10n/app_localizations.dart`
**Masalah:** Ganti bahasa tidak reload string.
**Solusi:**
```dart
@override
bool shouldReload(_AppLocalizationsDelegate old) => old._locale != _locale; // bukan false
```
Simpan `_locale` sebagai field di delegate.

#### 0.6 — `_redirect` infinite loop onboarding ↔ dashboard `[Bug B1 — ditemukan saat Tahap 0]`
**File:** `lib/core/routing/app_router.dart`
**Masalah:** Dua kondisi `if` terpisah bisa overlap. Saat `onboardingDone=false` dan `location='/onboarding'`:
1. Kondisi `!onboardingDone && location != '/onboarding'` → false (sudah di `/onboarding`) → tidak redirect
2. Kondisi `location == '/onboarding'` → true → redirect ke `/dashboard`
3. Di `/dashboard`, `onboardingDone` masih false → redirect balik ke `/onboarding` → loop

**Solusi:** Atomisasi kondisi `!onboardingDone`:
```dart
if (!onboardingDone) {
  return location == '/onboarding' ? null : '/onboarding';
}
// Baris berikut hanya dieksekusi jika onboardingDone = true
if (publicRoutes.contains(location) || location == '/onboarding') {
  return '/dashboard';
}
```

---

### Tahap 1 — Selama Phase 4A (Transaction)

Kelemahan yang langsung relevan dengan Transaction + Sync.

#### 1.1 — NetworkInfo reachability check `[P2 #4]`
**File:** `lib/core/network/network_info.dart`
**Masalah:** Cek adapter saja, WiFi tanpa internet dianggap "online".
**Solusi:** Setelah `checkConnectivity()` bukan `none`, lakukan HTTP HEAD cepat:
```dart
@override
Future<bool> get isConnected async {
  final results = await _connectivity.checkConnectivity();
  if (results.every((r) => r == ConnectivityResult.none)) return false;
  try {
    final response = await http.head(
      Uri.parse('https://dns.google'),
    ).timeout(const Duration(seconds: 3));
    return response.statusCode < 500;
  } catch (_) {
    return false;
  }
}
```
Tambah dependency: `http: ^1.x.x` di pubspec.yaml.

#### 1.2 — Crashlytics logging untuk semua `catch (_)` `[P3 #15]`
**Scope:** Semua file data layer dan BLoC
**Masalah:** Error asli hilang, debug production sulit.
**Pola wajib mulai Phase 4:**
```dart
} catch (e, stack) {
  FirebaseCrashlytics.instance.recordError(e, stack);
  return const Left(UnknownFailure());
}
```

#### 1.3 — `SyncOperation.create` vs `update` `[P3 #12]`
**File:** `lib/features/onboarding/data/datasources/onboarding_local_datasource.dart`
**Masalah:** Selalu pakai `create` meski data sudah ada.
**Solusi:** Cek `onboardingCompleted` sebelum tulis ke queue; gunakan `SyncOperation.update` jika flag sudah `true`.

---

### Tahap 2 — Selama Phase 4B (Dashboard)

#### 2.1 — `getBudgetSettings()` fallback Firestore `[P1 #2]`
**File:** `lib/features/onboarding/data/repositories/onboarding_repository_impl.dart`
**Masalah:** Install baru = data onboarding hilang.
**Solusi:**
```dart
@override
Future<Either<Failure, BudgetSettingsEntity?>> getBudgetSettings() async {
  try {
    final local = await localDataSource.getBudgetSettings();
    if (local != null) return Right(local);
    // Fallback ke Firestore
    if (await networkInfo.isConnected) {
      final remote = await remoteDataSource.getBudgetSettings();
      if (remote != null) await localDataSource.saveBudgetSettings(remote);
      return Right(remote);
    }
    return const Right(null);
  } on CacheException catch (e) {
    return Left(CacheFailure(e.message));
  } catch (e, stack) {
    FirebaseCrashlytics.instance.recordError(e, stack);
    return const Left(UnknownFailure());
  }
}
```

#### 2.2 — `BudgetSettingsModel.fromFirestore()` null-safe `[P2 #5]`
**File:** `lib/features/onboarding/data/models/budget_settings_model.dart`
**Masalah:** `(data['field'] as num)` crash jika field hilang.
**Solusi:** Ganti semua cast ke:
```dart
monthlyIncome: (data['monthlyIncome'] as num?)?.toInt() ?? 0,
paymentDate: (data['paymentDate'] as num?)?.toInt() ?? 1,
fixedExpenses: (data['fixedExpenses'] as num?)?.toInt() ?? 0,
emergencyFundPct: (data['emergencyFundPct'] as num?)?.toDouble() ?? 0.10,
```
**Terapkan pola ini ke semua `fromFirestore()` baru yang dibuat di Phase 4.**

#### 2.3 — `OnboardingError` retry `[P2 #6]`
**File:** `lib/features/onboarding/presentation/bloc/onboarding_bloc.dart`
**Masalah:** User terjebak di error state.
**Solusi:** Tambah event `OnboardingRetryRequested`, reset ke `OnboardingStep3` dengan data cached dari state sebelumnya.

#### 2.4 — `authStateChanges` createdAt `[P3 #10]`
**File:** `lib/features/auth/data/datasources/auth_remote_datasource.dart`
**Masalah:** `createdAt: DateTime.now()` setiap auth event.
**Solusi:** Setelah login berhasil, simpan `createdAt` dari Firestore user doc ke `AppSettingsIsarModel`; stream baca dari cache tersebut.

#### 2.5 — Validasi tanggal kiriman `[P3 #13]`
**File:** `lib/features/onboarding/presentation/pages/onboarding_page.dart`
**Masalah:** 29/30/31 Februari dianggap valid.
**Solusi:**
```dart
// Di _validate() Step1:
final maxDay = _daysInMonth(DateTime.now().year, DateTime.now().month);
if (date > maxDay) {
  _dateError = 'Bulan ini maksimal tanggal $maxDay.';
}
```

---

### Tahap 3 — Phase 4C (SyncService)

#### 3.1 — Sync queue processor `[P1 #1]` — PALING KRITIS
**File baru:** `lib/core/sync/sync_service.dart`
**Masalah:** `SyncQueueIsarModel` terisi tapi tidak pernah diproses.
**Desain:**
```dart
class SyncService {
  SyncService({required Isar isar, required NetworkInfo networkInfo, ...});

  StreamSubscription? _sub;

  void start() {
    _sub = networkInfo.onConnectivityChanged.listen((isOnline) {
      if (isOnline) _processQueue();
    });
  }

  Future<void> _processQueue() async {
    final items = await isar.syncQueueIsarModels
        .where().sortByCreatedAt().findAll();
    for (final item in items) {
      try {
        await _dispatch(item);
        await isar.writeTxn(() => isar.syncQueueIsarModels.delete(item.id));
      } catch (_) {
        // Biarkan di queue, coba lagi nanti
      }
    }
  }
}
```
Panggil `SyncService.start()` di `main.dart` setelah DI init.

#### 3.2 — Test coverage repository & datasource `[P2 #9]`
**Files baru:**
```
test/features/onboarding/data/repositories/onboarding_repository_impl_test.dart
test/features/onboarding/data/datasources/onboarding_local_datasource_test.dart
test/features/transaction/data/repositories/transaction_repository_impl_test.dart
```
Skenario wajib:
- Offline: tulis Isar, tulis sync queue, tidak panggil Firestore
- Online + Firestore berhasil: tulis Isar, tulis Firestore, tidak tulis queue
- Online + Firestore gagal: tulis Isar, tidak tulis Firestore, tulis queue

#### 3.3 — `getBudgetSettings()` `createdAt` `[P3 #11]`
Tambah field `onboardingCreatedAt DateTime?` ke `AppSettingsIsarModel`.
Set sekali saat onboarding pertama kali selesai (jangan overwrite jika sudah ada).

---

## Bagian 2 — Phase 4A: Transaction Feature

### Struktur File

```
lib/features/transaction/
  domain/
    entities/
      transaction_entity.dart      ← fields + TransactionCategory + TransactionType enum
    repositories/
      transaction_repository.dart  ← abstract
    usecases/
      add_transaction_usecase.dart
      get_today_transactions_usecase.dart
      get_transactions_by_date_range_usecase.dart
      update_transaction_usecase.dart
      delete_transaction_usecase.dart
      watch_today_transactions_usecase.dart  ← StreamUseCase
      sync_pending_transactions_usecase.dart
  data/
    models/
      transaction_model.dart       ← fromIsar(), fromFirestore(), toFirestore(), fromEntity()
    datasources/
      transaction_local_datasource.dart
      transaction_remote_datasource.dart
    repositories/
      transaction_repository_impl.dart  ← offline-first + sync queue
  presentation/
    bloc/
      transaction_list_bloc.dart + event + state
      add_transaction_bloc.dart + event + state
    pages/
      transaction_list_page.dart
    widgets/
      add_transaction_sheet.dart   ← modal bottom sheet
      transaction_item.dart        ← reusable list item
      transaction_group_header.dart

test/features/transaction/
  domain/usecases/add_transaction_usecase_test.dart
  data/repositories/transaction_repository_impl_test.dart
  presentation/bloc/add_transaction_bloc_test.dart
  presentation/bloc/transaction_list_bloc_test.dart
```

### Domain: TransactionEntity

```dart
class TransactionEntity extends Equatable {
  final String id;          // UUID v4
  final int amount;         // Rupiah, selalu positif
  final TransactionCategory category;
  final TransactionType type; // expense | income
  final String? note;
  final DateTime date;
  final bool isFixed;
  final bool isSynced;
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum TransactionCategory { food, transport, campus, data, shopping, fixed, income, other }
enum TransactionType { expense, income }
```

### Data Layer: Pola Offline-First (wajib diikuti)

```
addTransaction():
  1. Tulis Isar (SELALU — ini sumber of truth)
  2. isConnected? → coba Firestore
     - Berhasil → markSynced(id)
     - Gagal → addToSyncQueue (SyncOperation.create)
  3. Offline → addToSyncQueue (SyncOperation.create)
  4. Return Right(null) — UI tidak terblokir sync

deleteTransaction():
  1. Soft delete di Isar (tandai isDeleted = true)
  2. isConnected? → delete Firestore
     - Gagal → addToSyncQueue (SyncOperation.delete)
  3. Return Right(null)
```

### BLoC: AddTransactionBloc

```
Events:
  AmountChanged(int amount)
  CategorySelected(TransactionCategory)
  NoteChanged(String note)
  DateChanged(DateTime)
  TypeToggled()               ← expense ↔ income
  SubmitTransaction()

States:
  AddTransactionInitial
  AddTransactionInProgress    ← form state dengan semua field
  AddTransactionLoading       ← saat saving
  AddTransactionSuccess
  AddTransactionError(String message)
```

### BLoC: TransactionListBloc

```
Events:
  LoadTransactions(DateRange range)
  RefreshTransactions()
  FilterChanged(TransactionCategory? category)
  DeleteTransactionRequested(String id)

States:
  TransactionListLoading
  TransactionListLoaded(
    transactions: List<TransactionEntity>,
    totalSpent: int,
    groupedByDate: Map<DateTime, List<TransactionEntity>>,
  )
  TransactionListError(String message)
```

### UI: AddTransactionSheet

Tampil sebagai `showModalBottomSheet` dari FAB dashboard.

```
Layout dari atas ke bawah:
─── Handle bar (8dp, rounded) ─────────────────────────────────
─── Display nominal ─────────────────────────────────────────── 
   "Rp 0" — H1 JetBrains Mono, AppColors.primary, tabular-nums
   Toggle expense/income (chip kecil kanan)
─── Grid kategori 4 kolom ────────────────────────────────────── 
   Icon + label Caption, selected = border primary
─── TextField catatan (opsional) ─────────────────────────────── 
   hintText: "Catatan (opsional)"
─── Date chip ─────────────────────────────────────────────────
   "Hari ini" → tap untuk ganti
─── Numpad custom ─────────────────────────────────────────────
   [ 1 ][ 2 ][ 3 ]
   [ 4 ][ 5 ][ 6 ]
   [ 7 ][ 8 ][ 9 ]
   [000][ 0 ][Del]
─── PrimaryButton "Simpan" ────────────────────────────────────
```

**Aturan numpad:**
- Tombol `000` append 3 nol sekaligus (untuk 5rb, 10rb dengan mudah)
- Batas maksimal: 100.000.000 (Rp 100 juta)
- `Del` hapus digit terakhir
- Tidak pakai keyboard sistem — numpad custom saja

### UI: TransactionItem Widget

```dart
// Wajib sesuai CLAUDE.md
Row(
  children: [
    // Kiri: circle icon
    Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(categoryIcon, color: AppColors.primary, size: 20),
    ),
    const SizedBox(width: AppSpacing.md),
    // Tengah: keterangan + kategori
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(note ?? categoryLabel, style: AppTextStyles.body),
          Text(categoryLabel.toUpperCase(), style: AppTextStyles.caption),
        ],
      ),
    ),
    // Kanan: nominal + sync indicator
    Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${isExpense ? '−' : '+'} ${formatRupiah(amount)}',
          style: AppTextStyles.label.copyWith(
            color: isExpense ? AppColors.warn : AppColors.success,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
        if (!isSynced)
          Container(width: 6, height: 6,
            decoration: BoxDecoration(color: AppColors.caution, shape: BoxShape.circle)),
      ],
    ),
  ],
)
```

---

## Bagian 3 — Phase 4B: Dashboard Feature

### Struktur File

```
lib/features/dashboard/
  domain/
    entities/
      dashboard_entity.dart    ← DashboardEntity + BudgetStatus enum
    usecases/
      get_dashboard_usecase.dart  ← StreamUseCase<DashboardEntity, NoParams>
      calculate_days_to_live_usecase.dart  ← pure computation
  data/
    repositories/
      dashboard_repository_impl.dart  ← compose dari transaction + budget
  presentation/
    bloc/
      dashboard_bloc.dart + event + state
    pages/
      dashboard_page.dart
    widgets/
      (sudah ada di lib/widgets/common/ — dibuat di Phase 4B)

lib/widgets/common/
  days_to_live_card.dart      ← DTL number card
  budget_bar.dart             ← animated progress bar
  survival_mode_banner.dart   ← warning banner
  milestone_toast.dart        ← celebration overlay

test/features/dashboard/
  domain/usecases/calculate_days_to_live_test.dart
  presentation/bloc/dashboard_bloc_test.dart
```

### Domain: DashboardEntity

```dart
class DashboardEntity extends Equatable {
  final int dailyBudget;        // dari BudgetSettings
  final int spentToday;         // sum transaksi hari ini
  final int remainingToday;     // dailyBudget - spentToday (bisa negatif)
  final int totalMonthlyBudget; // income - fixedExpenses - emergencyFund
  final int totalSpentThisMonth;
  final int totalRemaining;     // totalMonthlyBudget - totalSpentThisMonth
  final int daysToLive;         // totalRemaining / avgDailySpend (floor)
  final int remainingDays;      // hari sampai kiriman berikutnya
  final double avgDailySpend;   // rata-rata 7 hari terakhir
  final BudgetStatus status;
  final DateTime lastUpdated;
}

enum BudgetStatus { safe, caution, danger }
// safe    → totalRemaining / totalMonthlyBudget > 0.30
// caution → 0.15 – 0.30
// danger  → < 0.15
```

### Kalkulasi DaysToLive

```dart
int calculateDaysToLive({
  required int totalRemaining,
  required double avgDailySpend,
  required int remainingDays,
}) {
  if (avgDailySpend <= 0) return remainingDays; // belum ada data spend
  final dtl = (totalRemaining / avgDailySpend).floor();
  return dtl < 0 ? 0 : dtl;
}

// avgDailySpend: rata-rata pengeluaran 7 hari terakhir
// Jika kurang dari 7 hari data → gunakan data yang ada
// Jika nol hari data → gunakan dailyBudget dari settings sebagai baseline
```

### BLoC: DashboardBloc

```
Events:
  LoadDashboard
  DashboardRefreshed           ← pull-to-refresh
  _TransactionStreamUpdated    ← internal, dari watchLazy stream

States:
  DashboardInitial
  DashboardLoading
  DashboardLoaded(DashboardEntity entity)
  DashboardError(String message)

Arsitektur stream:
  - initState: subscribe ke WatchTodayTransactionsUseCase stream
  - Setiap emit dari stream → dispatch _TransactionStreamUpdated
  - _onTransactionUpdated: recalculate, emit DashboardLoaded baru
  - close(): cancel subscription
```

### UI: DashboardPage Layout

```
Scaffold
└── CustomScrollView
    ├── SliverAppBar (pinned: false, floating: true)
    │   ├── Leading: PenyintasLogo(size: 28)
    │   ├── Title: Text('Penyintas', style: AppTextStyles.h3)
    │   └── Actions: CircleAvatar (avatar user)
    │
    └── SliverList
        ├── [status == danger] SurvivalModeBanner
        │   atau
        │   [status != danger] _BudgetHeaderCard
        │       Caption: "ANGGARAN HARI INI"
        │       H1 JetBrains Mono: formatRupiah(remainingToday)
        │       BodySmall: "dari ${formatRupiah(dailyBudget)} · sisa $remainingDays hari"
        │
        ├── SizedBox(height: AppSpacing.lg)
        │
        ├── DaysToLiveCard(daysToLive: entity.daysToLive)
        │
        ├── SizedBox(height: AppSpacing.lg)
        │
        ├── BudgetBar(
        │     spent: entity.totalSpentThisMonth,
        │     total: entity.totalMonthlyBudget,
        │   )
        │
        ├── SizedBox(height: AppSpacing.xl)
        │
        └── _TodaySection
            ├── Row: H3 "Hari ini" + TextButton "Lihat semua →"
            └── ListView (max 3 item) atau EmptyState
```

### Widget: DaysToLiveCard

```dart
// Sesuai CLAUDE.md spesifikasi
Container(
  width: double.infinity,
  padding: const EdgeInsets.all(AppSpacing.xl),
  decoration: BoxDecoration(
    color: isDark ? AppColors.surfaceDark : AppColors.primary,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: isDark ? Border.all(color: AppColors.shoot, width: 1.5) : null,
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('DAYS TO LIVE', style: AppTextStyles.caption.copyWith(
        color: isDark ? AppColors.shoot : Colors.white.withAlpha(180),
      )),
      const SizedBox(height: AppSpacing.xs),
      Text(
        '$daysToLive',
        style: AppTextStyles.h1.copyWith(
          fontFamily: 'JetBrainsMono',
          fontSize: 64,
          fontWeight: FontWeight.w700,
          color: _dtlColor(daysToLive, isDark),   // putih >14, caution 7-14, warn <7
          fontFeatures: [const FontFeature.tabularFigures()],
        ),
      ),
      Text(
        'Prediksi berdasarkan pola belanjamu',
        style: AppTextStyles.bodySmall.copyWith(
          color: isDark ? AppColors.textSoftDark : Colors.white.withAlpha(200),
        ),
      ),
    ],
  ),
)
```

### Widget: BudgetBar

```dart
// warna adaptif sesuai CLAUDE.md
Color _barColor(double pct) {
  if (pct <= 0.50) return AppColors.primary;
  if (pct <= 0.80) return AppColors.caution;
  return AppColors.warn;
}

// Animasi dengan TweenAnimationBuilder saat nilai berubah
TweenAnimationBuilder<double>(
  duration: const Duration(milliseconds: 600),
  curve: Curves.easeOut,
  tween: Tween(begin: 0, end: spentPct),
  builder: (_, value, __) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.pill),
    child: LinearProgressIndicator(
      value: value,
      backgroundColor: borderColor,
      valueColor: AlwaysStoppedAnimation(_barColor(value)),
      minHeight: 8,
    ),
  ),
)
```

### Widget: SurvivalModeBanner

```dart
// Wajib: nada hangat, tidak menakuti
Container(
  padding: const EdgeInsets.all(AppSpacing.lg),
  decoration: BoxDecoration(
    color: AppColors.warn,
    borderRadius: BorderRadius.circular(AppRadius.lg),
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(children: [
        Icon(Icons.shield_outlined, color: Colors.white, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text('Mode Hemat Aktif', style: AppTextStyles.label.copyWith(color: Colors.white)),
      ]),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Lentur dulu. Kita lewati minggu ini bersama.',
        style: AppTextStyles.body.copyWith(color: Colors.white),
      ),
      Text(
        'Sisa ${formatRupiah(totalRemaining)} untuk $remainingDays hari. Kamu bisa.',
        style: AppTextStyles.bodySmall.copyWith(color: Colors.white.withAlpha(220)),
      ),
    ],
  ),
)
```

---

## Bagian 4 — Phase 4C: SyncService

### Struktur File

```
lib/core/sync/
  sync_service.dart          ← processor utama
  sync_dispatcher.dart       ← routing item → datasource yang tepat
```

### Desain SyncService

```dart
class SyncService {
  SyncService({
    required this.isar,
    required this.networkInfo,
    required this.auth,
    required this.firestore,
  });

  StreamSubscription<bool>? _connectivitySub;

  void start() {
    // Proses saat startup jika online
    networkInfo.isConnected.then((online) {
      if (online) _processQueue();
    });
    // Proses setiap kali koneksi kembali
    _connectivitySub = networkInfo.onConnectivityChanged.listen((online) {
      if (online) _processQueue();
    });
  }

  void dispose() => _connectivitySub?.cancel();

  Future<void> _processQueue() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) return;

    final items = await isar.syncQueueIsarModels
        .where().sortByCreatedAt().findAll();

    for (final item in items) {
      try {
        await SyncDispatcher.dispatch(item, uid: uid, firestore: firestore);
        await isar.writeTxn(() => isar.syncQueueIsarModels.delete(item.id));
      } catch (_) {
        // Biarkan di queue, retry saat koneksi berikutnya
      }
    }
  }
}
```

### Registrasi di DI + main.dart

```dart
// injection_container.dart
sl.registerLazySingleton(() => SyncService(
  isar: sl(), networkInfo: sl(), auth: sl(), firestore: sl(),
));

// main.dart — setelah di.init()
sl<SyncService>().start();
```

---

## Bagian 5 — Testing Strategy Phase 4

### Target per sub-phase

| Sub-phase | Test yang wajib ada sebelum lanjut |
|-----------|-----------------------------------|
| Tahap 0 (fixes) | Existing 22 test tetap pass; analyze 0 issues |
| Phase 4A | `add_transaction_bloc_test`, `transaction_repository_impl_test` (3 skenario: offline/online/fail) |
| Phase 4B | `dashboard_bloc_test` (safe/caution/danger/stream update), `calculate_days_to_live_test` |
| Phase 4C | `sync_service_test` (queue process, retry on fail, skip jika offline) |

### Skenario test wajib untuk TransactionRepositoryImpl

```dart
group('addTransaction', () {
  test('should write Isar first regardless of connectivity', ...);
  test('should write Firestore and markSynced when online and succeeds', ...);
  test('should write syncQueue when online but Firestore throws', ...);
  test('should write syncQueue and NOT call Firestore when offline', ...);
});
```

### Skenario test wajib untuk DashboardBloc

```dart
group('LoadDashboard', () {
  test('should emit DashboardLoaded with safe status when remaining > 30%', ...);
  test('should emit DashboardLoaded with caution status when remaining 15–30%', ...);
  test('should emit DashboardLoaded with danger status when remaining < 15%', ...);
  test('should recalculate when transaction stream emits', ...);
  test('should calculate daysToLive = 0 when totalRemaining is negative', ...);
});
```

---

## Bagian 6 — Urutan Kerja (Sequence)

> **Catatan aktual:** Tahap 0, Tahap 1 (parsial), Tahap 2, dan Tahap 3 dikerjakan dalam sesi yang
> digabung — bukan 6 sesi terpisah seperti rencana. Urutan dependency tetap diikuti.

```
Sesi 1 — Tahap 0: Bug fixes fondasi
  ├── 0.1 Isar error handling di main.dart
  ├── 0.2 _redirect error handling
  ├── 0.3 Firebase debug provider guard
  ├── 0.4 SettingsBloc error handling
  ├── 0.5 AppLocalizations.shouldReload
  └── flutter analyze + flutter test → harus 22/22

Sesi 2 — Phase 4A bagian 1: Transaction domain + data
  ├── TransactionEntity + enums
  ├── TransactionRepository abstract
  ├── 5 use cases domain
  ├── TransactionIsarModel sudah ada (Phase 1) — tambah field isSynced jika belum
  ├── TransactionModel (fromIsar, fromFirestore, toFirestore, fromEntity)
  ├── TransactionLocalDataSource
  ├── TransactionRemoteDataSource
  ├── TransactionRepositoryImpl (offline-first + sync queue)
  ├── 1.2 Crashlytics logging di semua catch baru
  ├── 1.3 SyncOperation fix di onboarding
  └── Tulis transaction_repository_impl_test.dart

Sesi 3 — Phase 4A bagian 2: Transaction BLoC + UI
  ├── AddTransactionBloc + event + state
  ├── TransactionListBloc + event + state
  ├── AddTransactionSheet (bottom sheet + numpad custom)
  ├── TransactionItem widget
  ├── TransactionListPage
  ├── Daftarkan di DI + routing (/transactions, /transactions/add)
  └── Tulis bloc tests

Sesi 4 — Phase 4B bagian 1: Dashboard domain + data + fixes
  ├── 2.1 getBudgetSettings Firestore fallback
  ├── 2.2 BudgetSettingsModel null-safe cast
  ├── 2.3 OnboardingError retry
  ├── 2.4 authStateChanges createdAt fix
  ├── 2.5 Validasi tanggal kiriman
  ├── DashboardEntity + BudgetStatus
  ├── CalculateDaysToLiveUseCase (pure — tulis test dulu)
  └── GetDashboardUseCase (StreamUseCase)

Sesi 5 — Phase 4B bagian 2: Dashboard BLoC + UI
  ├── DashboardBloc + stream subscription
  ├── DaysToLiveCard widget
  ├── BudgetBar widget
  ├── SurvivalModeBanner widget
  ├── MilestoneToast widget
  ├── DashboardPage (full layout)
  ├── Daftarkan di DI + routing (/dashboard)
  └── Tulis bloc tests

Sesi 6 — Phase 4C: SyncService + test coverage
  ├── SyncService + SyncDispatcher
  ├── Daftarkan di DI, start() di main.dart
  ├── 3.3 onboardingCreatedAt field
  ├── 1.1 NetworkInfo reachability check
  ├── Tulis sync_service_test.dart
  ├── Tulis onboarding_repository_impl_test.dart (sesuai P2 #9)
  └── flutter analyze + flutter test → semua pass
```

---

## Bagian 7 — Kriteria Phase 4 Selesai

Semua item berikut harus terpenuhi sebelum commit Phase 4:

**Fungsional:**
- [x] User bisa tambah transaksi dari dashboard (bottom sheet)
- [x] Dashboard menampilkan sisa anggaran hari ini, DTL, dan budget bar
- [x] Survival Mode Banner muncul saat sisa < 15%
- [x] Transaksi tersimpan ke Isar saat offline
- [x] Transaksi tersync ke Firestore saat kembali online
- [x] Data budget tidak hilang saat reinstall (Firestore fallback)

**Teknis:**
- [x] `flutter analyze` 0 issues
- [x] `flutter test` semua pass — 56/56 (melampaui target ≥ 40)
- [x] Semua `fromFirestore()` model menggunakan null-safe cast
- [ ] ~~Semua `catch` block mencatat ke Crashlytics~~ — **TIDAK SEPENUHNYA**: `DashboardBloc.emit.forEach.onError` tidak log (issue #26); perbaikan di Phase 5
- [x] Firebase App Check menggunakan provider yang sesuai mode (debug/release)
- [x] Tidak ada hardcoded warna hex, angka spacing, atau string UI

**Design:**
- [x] Dark mode berfungsi di semua widget baru
- [x] Semua angka menggunakan `tabular-nums`
- [x] Format Rupiah konsisten (`Rp 1.245.000`)
- [x] Hit target minimum 44dp/48dp di semua elemen interaktif

**Deviasi & Item yang Tidak Selesai (dipindah ke Phase 5):**
- ⚠️ **1.1 NetworkInfo reachability check** — tidak diimplementasikan; tetap pakai cek adapter (issue #4 lama)
- ⚠️ **`sync_service_test.dart`** — tidak ditulis; Isar in-memory butuh setup khusus (issue #32)
- ⚠️ **`onboarding_local_datasource_test.dart`** — tidak ditulis (sama) (issue #32)
- ⚠️ **`MilestoneToast` widget** — tidak dibuat; belum ada trigger logic
- ⚠️ **Logo dashboard** — `Image.asset('logo-m7.png')` bukan SVG via `PenyintasLogo` (issue #23, blocking)

---

## Catatan Tambahan

### Dependency baru yang perlu ditambahkan

```yaml
dependencies:
  http: ^1.2.0        # untuk NetworkInfo reachability check
  uuid: ^4.5.0        # untuk generate transaction ID (mungkin sudah ada)
```

### Isar model yang perlu diupdate

`AppSettingsIsarModel` — tambah field:
```dart
DateTime? onboardingCreatedAt;  // set sekali saat onboarding selesai
```
Perlu regenerasi `.g.dart` (ikuti prosedur konflik analyzer di PROMPT.md).

`TransactionIsarModel` — cek apakah field `isSynced` sudah ada dari Phase 1.
Jika belum, tambah dan regenerasi.

### Konvensi baru yang berlaku mulai Phase 4

1. **Setiap `catch` blok** wajib log ke Crashlytics: `FirebaseCrashlytics.instance.recordError(e, stack)`
2. **Setiap `fromFirestore()`** wajib null-safe cast: `(data['key'] as Type?)?.value ?? default`
3. **SyncService** yang menulis ke queue wajib tentukan operation type dengan benar (create/update/delete)
4. **Setiap BLoC baru** wajib punya minimal 3 test: loading state, success state, error state
