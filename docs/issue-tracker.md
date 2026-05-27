# Penyintas — Issue Tracker

Dokumen ini merangkum semua bug, error, kelemahan, dan kekurangan yang ditemukan dari analisis kode aktual Phase 1–4 + Drift Migration + analisis lokalisasi.

**Terakhir diperbarui:** 2026-05-27 (Hotfix dashboard stuck loading · 1 issue baru #186 ditemukan dan langsung diperbaiki · root cause: `DashboardBloc` `registerFactory` → `registerLazySingleton` · fix pendukung: `state.pageKey` di `NoTransitionPage`, guard `initState()`)  
**Sebelumnya:** 2026-05-27 (Transactions V2 States · 1 issue baru #185 ditemukan dan langsung diperbaiki · filter chip stale closure via `buildWhen` filter + stale state in closure)  
**Test baseline:** 70/70 passed · flutter analyze: 0 issues  
**Setelah Phase 5A:** 82/82 passed · flutter analyze: 0 issues  
**Setelah Step 2 redesign:** flutter analyze: 0 issues · +7 issue baru (#39–#45)  
**Setelah analisis Step 1 & 3:** +10 issue baru (#46–#55)  
**Setelah analisis lokalisasi:** +4 issue baru (#56–#59)  
**Setelah dashboard redesign:** 82/82 passed · flutter analyze: 0 issues · +11 issue baru (#60–#70)  
**Setelah Phase 5B onboarding polish:** 82/82 passed · flutter analyze: 0 issues · 17 item selesai  
**Setelah Phase 5B dashboard quick wins:** 82/82 passed · flutter analyze: 0 issues · 6 item selesai  
**Setelah Phase 5B notification feature:** 90/90 passed · flutter analyze: 0 issues · analisis: +15 issue baru (#71–#85)  
**Setelah Phase 5B-fix:** 90/90 passed · flutter analyze: 0 issues · #71–#78 selesai (3 P1 + 5 P2)  
**Setelah Phase 5C report feature:** 109/109 passed · flutter analyze: 0 issues · analisis: +15 issue baru (#86–#100)
**Setelah Phase 5C-fix:** 109/109 passed · flutter analyze: 0 issues · #86 obsolete · #87–#91 selesai (5 fixed)
**Setelah Phase 6A:** 109/109 passed · flutter analyze: 0 issues · #59/#60/#79/#80 selesai · analisis: +13 issue baru (#101–#113)
**Setelah Phase 6A-fix:** 109/109 passed · flutter analyze: 0 issues · #101/#102/#104/#106/#107 selesai
**Setelah Phase 6B:** 109/109 passed · flutter analyze: 0 issues · #81/#82/#84–#85/#92–#97 selesai · analisis: +8 issue baru (#114–#121)
**Setelah Phase 6B-fix:** 109/109 passed · flutter analyze: 0 issues · #114/#116/#117/#118 selesai
**Setelah Phase 6C:** 119/119 passed · flutter analyze: 0 issues · #40/#32/#36/#58/#21/#22/#18/#119/#120/#121 selesai · analisis: +9 issue baru (#122–#130)
**Setelah Phase 6C-fix:** 127/127 passed · flutter analyze: 0 issues · #123/#124/#125/#126/#127/#129 selesai · #122 deferred (UI not yet built) · #128 N/A (existing try-catch guards it) · #130 verified (SQL defaults match Dart)
**Setelah Phase 7-prep & 7A:** 143/143 passed · flutter analyze: 0 issues · analisis: +13 issue baru (#131–#143) ditemukan
**Setelah Phase 7-prep-fix:** 143/143 passed · flutter analyze: 0 issues · #131/#132/#133/#137/#139 selesai
**Setelah Phase 7B:** 153/153 passed · flutter analyze: 0 issues · analisis: +13 issue baru (#144–#156) ditemukan
**Setelah Phase 7B-fix:** 153/153 passed · flutter analyze: 0 issues · #144–#151 selesai · #152–#156 defer ke Phase 8
**Setelah Phase 7C:** 175/175 passed · flutter analyze: 0 issues · analisis transaksi screen: +5 issue baru (#157–#161) ditemukan
**Setelah Phase 7C analisis Goal feature:** 175/175 passed · flutter analyze: 0 issues · analisis Goal feature: +9 issue baru (#162–#170) ditemukan
**Setelah Phase 7C-fix:** 175/175 passed · flutter analyze: 0 issues · #162/#163/#164/#165/#166/#168 selesai · #167/#169/#170 defer ke Phase 8
**Setelah Phase 7D/7E/7F:** 180/180 passed · flutter analyze: 0 issues · #19/#20/#134–#136/#138/#140/#141 selesai · #167/#169/#170 defer ke Phase 8 · analisis: +9 issue baru (#171–#179) · build error: +1 issue baru (#180 — home_widget Glance, ✅ fixed inline) · runtime bug widget: +1 issue baru (#181 — android.view.View dilarang RemoteViews API 31+, ✅ fixed inline · sekaligus fix #178)
**Setelah Transactions V2 States:** 183/183 passed · flutter analyze: 0 issues · #185 ditemukan dan langsung diperbaiki (filter chip stale closure)

---

## Legend

| Simbol | Arti |
|--------|------|
| ✅ | Selesai |
| 🔲 | Belum dikerjakan |
| ⚠️ | Selesai sebagian |
| ❌ | Tidak akan dikerjakan / obsolete |

**Prioritas:**
- **P1** — Kritikal: bug aktif / data corruption / aturan wajib dilanggar
- **P2** — Penting: user-facing / memory leak / potential data loss
- **P3** — Kualitas kode: maintainability, testability
- **P4** — Polish & optimisasi: performa, aksesibilitas, edge case

---

## Ringkasan Status

| Status | Jumlah | Catatan |
|--------|--------|---------|
| ✅ Selesai | 146 | +1 dari Hotfix 2026-05-27: #186 (DashboardBloc factory → lazySingleton · dashboard stuck loading) · sebelumnya: #185 (filter chip stale closure) · #182–#184 (ListTile fix, GoalBloc context.read, DashboardBloc singleton closed) · #155 (SurvivalTipsPage blank screen) |
| ⚠️ Sebagian | 1 | #98 (pie chart done, bar chart masih 🔲) |
| 🔲 Terbuka | 39 | #17, #63, #67–#70, #83, #99, #100, #103, #105, #108–#113, #115, #122, #142, #143, #152–#154, #156, #157–#161, #167, #169, #170, #173–#177, #179 |
| ❌ Obsolete | 2 | #3, #86 |
| **Total** | **188** | Hotfix 2026-05-27: 1 issue baru #186, langsung diperbaiki · Transactions V2 States: #185 · Phase 7 SELESAI · hotfix 2026-05-26: #182–#184 semuanya langsung diperbaiki · deferred #155 sekaligus fix |

---

## P1 — Kritikal

| # | Status | File | Kelemahan | Dampak | Diselesaikan di |
|---|--------|------|-----------|--------|-----------------|
| 1 | ✅ | `sync_service.dart` | **Sync queue tidak punya processor** — `addToSyncQueue()` menulis ke DB tapi tidak ada worker yang membaca dan mengirim ke Firestore | Data tidak pernah tersync ke cloud walau koneksi kembali | Phase 4C |
| 2 | ✅ | `onboarding_local_datasource.dart` | **`getBudgetSettings()` tidak fetch Firestore** — hanya baca lokal. Install baru atau ganti device: data onboarding hilang | Data loss di multi-device / reinstall | Phase 4B |
| 3 | ❌ | ~~`main.dart`~~ | **`Isar.open()` tanpa error handling** — disk penuh atau korupsi DB → app crash | App tidak bisa dibuka jika DB gagal | Diselesaikan di Phase 4 (0.1); lalu Isar dihapus di Drift migration — obsolete |
| 23 | ✅ | `dashboard_page.dart` | **Logo menggunakan `Image.asset('logo-m7.png')` bukan SVG** — melanggar aturan CLAUDE.md; file PNG tidak ada di assets | App crash saat dashboard dimuat; tidak ada dark mode color switch | Phase 5A |
| 24 | ✅ | `dashboard_entity.dart` | **`DashboardEntity.props` tidak menyertakan `todayTransactions`** — dua entity dengan transaksi berbeda tapi field lain sama dianggap equal. Diselamatkan sementara oleh `lastUpdated: DateTime.now()` yang selalu berbeda — tapi jika `_compute()` dipanggil dua kali dalam millisecond yang sama, state tidak di-emit | BLoC bisa drop update UI; `todayTransactions` di widget tidak terupdate | Phase 5A |
| 25 | ✅ | `dashboard_repository_impl.dart` | **Fixed expenses double-counting di `_compute()`** — `totalMonthlyBudget` sudah dikurangi `settings.fixedExpenses`, tapi `totalSpentThisMonth` sum SEMUA expense termasuk kategori `fixed`. Jika user catat kos sebagai transaksi (perilaku normal), biaya itu terhitung dua kali | Days-to-Live dan sisa anggaran jauh lebih kecil dari realitas | Phase 5A |
| 71 | ✅ | `notification_local_datasource.dart` · `notification_bloc.dart` | **`initialize()` tidak pernah dipanggil** — `NotificationLocalDatasourceImpl.initialize()` yang meng-init timezone library (`tz_data.initializeTimeZones()`, `tz.setLocalLocation()`) dan plugin Flutter Local Notifications tidak dipanggil dari mana pun. `_onInit` di bloc hanya subscribe ke FCM stream. Akibat: `tz.local` tidak ter-set, plugin belum di-init → setiap panggilan `scheduleDailyReminder()` throw exception timezone/plugin tidak terinisialisasi | **Semua fitur local notification mati total**; `zonedSchedule()` crash at runtime; tidak ada daily reminder yang bisa dijadwalkan | Phase 5B-fix |
| 72 | ✅ | `budget_warning.js` | **Compound Firestore query inequality pada dua field berbeda** — query memiliki `.where('category', '!=', 'fixed')` DAN `.where('date', '>=', monthStart)` sekaligus. Firestore melarang inequality filter (`<`, `<=`, `>`, `>=`, `!=`, `not-in`) pada lebih dari satu field dalam satu compound query → `INVALID_ARGUMENT` exception setiap kali transaksi baru ditulis | **`budgetWarning` Cloud Function crash 100% dari setiap trigger**; budget warning notification tidak pernah terkirim sama sekali | Phase 5B-fix |
| 73 | ✅ | `daily_reminder.js` | **Cron schedule salah karena kombinasi `'0 13 * * *'` + `timeZone: 'Asia/Jakarta'`** — dengan timezone Jakarta, ekspresi cron ini diinterpretasi sebagai 13:00 WIB (= 06:00 UTC), bukan 20:00 WIB seperti yang dikomen ("Berjalan setiap hari pukul 20:00 WIB (13:00 UTC)"). Untuk 20:00 WIB harus pakai `'0 20 * * *'` + timezone, atau `'0 13 * * *'` tanpa timezone (UTC raw) | Reminder harian muncul pukul 13:00 WIB (siang hari); relevansi notifikasi sangat rendah; bertentangan dengan spec | Phase 5B-fix |
| 86 | ❌ | ~~`functions/src/insights.js`~~ | **Request data field names mismatch** — analisis awal menyebut Dart mengirim `'reportData'`/`'settingsData'` tapi `insights.js` expect `'transactions'`/`'budgetSettings'`. Ternyata kode aktual `report_remote_datasource.dart` sudah mengirim `{'transactions': reportData, 'budgetSettings': settingsData}` — keys sudah match. Analisis adalah false positive | Tidak ada bug nyata — kode sudah benar sejak awal | Obsolete — false positive |
| 184 | ✅ | `app_router.dart:61–73` | **`/dashboard` route pakai `BlocProvider(create: (_) => sl<DashboardBloc>())` — `create` memanggil `close()` pada lazySingleton saat route di-replace via `context.go()`** — ketika user navigasi ke `/survival/tips` via `context.go()`, seluruh stack diganti dan `/dashboard` di-teardown. `BlocProvider(create:...)` memanggil `close()` pada singleton `DashboardBloc`. Singleton sekarang permanen closed. Kembali ke dashboard: `sl<DashboardBloc>()` return instance yang sudah closed → `DashboardPage.initState()` memanggil `add(LoadDashboard())` → `StateError: Cannot add event after calling close` → force close | **Force close saat kembali ke dashboard setelah membuka Survival Tips** — satu navigasi ke survival tips page cukup untuk merusak seluruh session dashboard | Hotfix 2026-05-26 |
| 183 | ✅ | `app_router.dart:109–116` | **Sub-route `/goals/:id` builder memanggil `context.read<GoalBloc>()` pada GoRouter routing context** — GoRouter sub-route `builder` menerima routing context, bukan widget context dari parent `pageBuilder`. `BlocProvider.value(value: sl<GoalBloc>())` yang dibuat di `/goals` `pageBuilder` tidak ada di scope builder `/goals/:id`. `context.read<GoalBloc>()` throw `ProviderNotFoundException` saat user tap item goal | **Tap goal item tidak respond dan throw error** — `GoalDetailPage` tidak pernah terbuka; seluruh navigasi ke detail goal mati total | Hotfix 2026-05-26 |
| 162 | ✅ | `add_transaction_sheet.dart` · `dashboard_page.dart` · `transaction_list_page.dart` · `saya_page.dart` | **GoalPicker tidak pernah muncul — `activeGoals` tidak diteruskan ke `AddTransactionSheet`** — semua 3 pemanggil menggunakan `const AddTransactionSheet()` tanpa argumen `activeGoals`. Default `activeGoals = const []` → kondisi `if (widget.activeGoals.isNotEmpty)` selalu false. GoalPicker tidak dirender → `selectedGoalId` selalu null saat submit → semua transaksi tersimpan dengan `goalId: null` → `savedAmount` semua goal selalu 0 → milestone tidak pernah berjalan | **Seluruh fitur Goal Saving Phase 7C tidak berfungsi** — linking, progress, milestone semuanya mati total | Phase 7C-fix |
| 163 | ✅ | `add_goal_sheet.dart` | **`AddGoalSheet._submit()` langsung pop sebelum tunggu hasil `CreateGoal`** — `Navigator.of(context).pop()` dipanggil langsung setelah `add(CreateGoal(...))`, tanpa menunggu state `GoalLoaded` maupun `GoalError`. Tidak ada `BlocListener` di sheet. Jika DB gagal menyimpan goal, sheet sudah hilang dan user tidak mendapat feedback apapun | Goal gagal tersimpan secara silent; user mengira goal berhasil dibuat padahal tidak ada di DB | Phase 7C-fix |
| 101 | ✅ | `notification_bloc.dart` | **`_onCancel()` mengabaikan result `Either` dan tidak emit state apapun** — `await _cancelDailyReminder()` tidak mengecek hasil; `Left(failure)` dibuang diam-diam. DB langsung ditulis `reminderEnabled: false` tanpa validasi apakah plugin berhasil membatalkan alarm. Tidak ada `emit()` — listener tidak bisa bereaksi. Jika OS/plugin gagal cancel, notifikasi tetap terjadwal tapi DB mengatakan disabled; session berikutnya tidak reschedule tapi alarm OS masih aktif | State DB dan plugin tidak konsisten; notification masih muncul walau user disable; tidak ada error feedback ke UI | Phase 6A-fix |
| 87 | ✅ | `functions/src/insights.js` · `report_remote_datasource.dart` | **Cache key format tidak konsisten** — Dart client menggunakan `'${year}-${month.toString().padLeft(2, '0')}'` (1-indexed, zero-padded, contoh: `'2026-05'`), tapi Cloud Function menggunakan `` `${now.getFullYear()}-${now.getMonth()}` `` (JavaScript `getMonth()` 0-indexed, tanpa padding, contoh: `'2026-4'`). Dokumen Firestore yang dibuat Cloud Function dan yang dibaca client adalah path yang berbeda selamanya | **Cache 24 jam tidak pernah berfungsi** — client selalu mendapat cache miss, setiap buka halaman Report memanggil Cloud Function → Vertex AI fresh. Cost Vertex AI ~$0.002/request × semua user = biaya production yang meningkat linear | Phase 5C-fix |
| 186 | ✅ | `injection_container.dart:232` · `app_router.dart` · `dashboard_page.dart` | **`DashboardBloc` terdaftar sebagai `registerFactory` bukan `registerLazySingleton` — setiap `sl<DashboardBloc>()` membuat instance baru dengan state `DashboardInitial`** — GoRouter memanggil `pageBuilder` `/dashboard` ulang saat `context.push('/survival/tips')`. `BlocProvider.value(value: sl<DashboardBloc>())` mendapat instance baru (DashboardInitial) alih-alih singleton yang sudah DashboardLoaded. `BlocBuilder` di `DashboardPage` langsung tampil loading indicator. Tiga fix pendukung: (1) `context.go()` → `context.push()` agar stack navigasi tetap ada — sudah difix di #184, (2) `key: state.pageKey` di semua `NoTransitionPage pageBuilder` agar Navigator tidak needlessly recreate route (`app_router.dart`), (3) guard `initState()` agar `LoadDashboard` tidak di-dispatch ulang jika bloc sudah `DashboardLoaded` (`dashboard_page.dart`) | **Dashboard stuck loading indefinitely setiap kali kembali dari survival tips atau route pushed lainnya** — user harus pindah navbar dulu baru dashboard kembali normal | Hotfix 2026-05-27 |

**Fix yang diterapkan (Hotfix 2026-05-27):**
- `#186` → di `injection_container.dart`: ubah `sl.registerFactory(() => DashboardBloc(...))` → `sl.registerLazySingleton(() => DashboardBloc(...))`; di `app_router.dart`: tambah `key: state.pageKey` ke semua 5 `NoTransitionPage` di `pageBuilder` (dashboard, transactions, goals, report, profile); di `dashboard_page.dart`: guard `initState()` — hanya dispatch `LoadDashboard` jika `bloc.state is DashboardInitial || bloc.state is DashboardError`

**Fix yang direkomendasikan:**
- `#23` → ganti dengan `PenyintasLogo(size: 28)` di `SliverAppBar.leading`
- `#24` → tambah `todayTransactions` ke `props`; keluarkan `lastUpdated` dari `props` (tetap ada untuk UI tapi bukan equality signal)
- `#25` → filter `totalSpentThisMonth` agar tidak menghitung transaksi kategori `fixed`, atau redesign: hapus `fixedExpenses` dari deduksi awal dan biarkan user track via transaksi biasa
- `#71` → panggil `_local.initialize(onTap: (payload) => add(NotificationTapped(payload)))` di dalam `_onInit`; atau buat `InitializeNotificationUseCase` yang di-call dari `_onInit`
- `#72` → hapus `.where('category', '!=', 'fixed')` dari Firestore query; filter di JS setelah fetch: `const filteredDocs = txSnap.docs.filter(doc => doc.data().category !== 'fixed');`
- `#73` → ubah menjadi `{ schedule: '0 20 * * *', timeZone: 'Asia/Jakarta' }` (20:00 WIB) atau `{ schedule: '0 13 * * *' }` tanpa timeZone (13:00 UTC = 20:00 WIB)
- `#86` → di `report_remote_datasource.dart`, ubah `callable.call({'reportData': reportData, 'settingsData': settingsData})` menjadi `callable.call({'transactions': reportData, 'budgetSettings': settingsData})`; atau sebaliknya, ganti destructuring di `insights.js` menjadi `const { reportData, settingsData } = request.data;` dan update penggunaan di prompt
- `#87` → seragamkan format cache key: gunakan 1-indexed month di JS dengan `now.getMonth() + 1` dan format sama dengan Dart (`${year.toString().padStart(4,'0')}-${(month).toString().padStart(2,'0')}`); atau di Dart ubah format ke `'${year}-${month-1}'` supaya cocok dengan JS (opsi pertama lebih mudah dibaca)
- `#101` → di `_onCancel()`, periksa result: `final result = await _cancelDailyReminder(); await result.fold((failure) async { FirebaseCrashlytics.instance.recordError(failure, null); emit(NotificationError(failure.message)); }, (_) async { await (_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(const AppSettingsCompanion(reminderEnabled: Value(false))); emit(const NotificationCancelled()); });`

---

## P2 — Penting

| # | Status | File | Kelemahan | Dampak | Diselesaikan di |
|---|--------|------|-----------|--------|-----------------|
| 4 | ✅ | `network_info.dart` | **`isConnected` sudah punya HTTP HEAD ke `dns.google` ✅ — tapi `onConnectivityChanged` stream masih cek adapter saja.** SyncService subscribe ke stream ini → bisa trigger queue processing saat adapter connect tapi internet belum ada | False positive di stream; `isConnected` sudah benar | Phase 5A |
| 5 | ✅ | `budget_settings_model.dart` | **`fromFirestore()` unsafe cast** — `(data['field'] as num)` tanpa null check → crash jika field hilang atau tipe berbeda | App crash saat baca data dari Firestore | Phase 4B |
| 6 | ✅ | `onboarding_bloc.dart` | **`OnboardingError` tidak bisa retry** — user terjebak di error state tanpa path keluar selain restart app | UX sangat buruk; data yang diisi hilang | Phase 4B |
| 7 | ✅ | `settings_bloc.dart` | **`_persist()` tanpa error handling** — Drift write gagal, error ditelan diam-diam; state UI berubah tapi disk tidak | Silent data loss untuk pengaturan tema/bahasa | Phase 4 (0.4) |
| 8 | ✅ | `app_router.dart` | **`_redirect` tanpa error handling** — jika DB query gagal, `Future<String?>` throw, go_router crash tanpa recovery | App crash saat navigasi jika DB bermasalah | Phase 4 (0.2) |
| 9 | ✅ | `onboarding_repository_impl.dart` | **Nol unit test untuk `OnboardingRepositoryImpl`** — logika sync queue dan local-first write tidak tercover | Bug di logika sync tidak terdeteksi | Phase 4C (8 tests) |
| 26 | ✅ | `dashboard_bloc.dart` | **`emit.forEach.onError` tidak log ke Crashlytics** — `onError: (e, s) => const DashboardError('...')` menelan error original tanpa logging | Bug production di dashboard stream tidak bisa di-debug | Phase 5A |
| 27 | ✅ | `sync_service.dart` | **`SyncService.dispose()` tidak pernah dipanggil** — `_connectivitySub` dan `_authSub` di-cancel di `dispose()` yang terdefinisi tapi tidak di-wire dari mana pun (tidak dari `main.dart`, tidak dari DI) | Memory leak; subscription aktif terus selama lifecycle app | Phase 5A |
| 28 | ✅ | `sync_dispatcher.dart` | **Tidak ada max retry count / TTL untuk item yang selalu gagal** — item yang ditolak Firestore rules atau berisi data invalid tetap di queue selamanya dan di-retry setiap kali online | Sync queue bloat; item valid di-delay karena item invalid terus diproses duluan | Phase 5A |
| 29 | ✅ | `budget_bar.dart` | **Animasi selalu dari 0% pada setiap rebuild** — `TweenAnimationBuilder(begin: 0, end: pct)` hardcode `begin: 0`; setiap stream update men-trigger animasi dari nol | Bar terasa "reset" setiap ada perubahan; UX jarring | Phase 5A |
| 30 | ✅ | `onboarding_bloc.dart` | **`_lastStep3` tidak menyimpan `emergencyFundPct` untuk retry** — `OnboardingStep3` state tidak punya field ini; saat retry slider kembali ke posisi default | Data yang sudah diisi user (`emergencyFundPct`) hilang saat retry | Phase 5A |

| 185 | ✅ | `transaction_list_page.dart` | **Filter chip kategori terlihat off/unselected saat filter aktif dan sheet dibuka ulang — stale closure via `buildWhen`** — `_V2FilterRow`'s `BlocBuilder` menggunakan `buildWhen: (p, c) => p.typeFilter != c.typeFilter`, sehingga widget hanya rebuild saat `typeFilter` berubah. `onFilterTap` closure di dalam builder ini capture `state` saat build pertama; ketika `categoryFilter` berubah (setelah `FilterSheetApplied`), `buildWhen` mencegah rebuild, sehingga `state` di closure tetap nilai lama. Saat `_openFilterSheet(state)` dipanggil, `currentState.categoryFilter` selalu null — sheet terbuka dengan semua chip unselected padahal filter sedang aktif | User yang sudah memilih filter "Makan" → tutup sheet → buka kembali filter → chip "Makan" terlihat tidak aktif. Membingungkan dan membuat user berpikir filter mereset sendiri | Transactions V2 States 2026-05-27 |
| 182 | ✅ | `settings_page.dart` · `saya_page.dart` | **`ListTile` dibungkus `Container(decoration: BoxDecoration(color: ...))` tanpa `Material` ancestor** — Flutter `ListTile.onTap` memerlukan `Material` ancestor agar ink splash berjalan. `Container` dengan `color` di `BoxDecoration` tidak menyediakan ink canvas. `_CardContainer` di `settings_page.dart` dan 2 card section di `saya_page.dart` (Settings + Account) menggunakan `Container` langsung. Di debug mode throw assertion `RenderInkFeatures`; di release mode tap terlihat tidak responsif (tidak ada visual feedback ripple) | Assertion error di debug mode; tidak ada ink splash pada semua `ListTile` yang dibungkus — logout button, versi tile, settings link semuanya tidak memberikan feedback visual saat di-tap | Hotfix 2026-05-26 |
| 164 | ✅ | `goal_detail_page.dart` · `app_router.dart:109` | **`GoalDetailPage` menampilkan stale data setelah aksi** — halaman menerima `GoalEntity goal` via `state.extra as GoalEntity` saat navigasi (snapshot saat push, tidak pernah di-update). `BlocListener` di detail page hanya handle delete (pop jika goal gone). Setelah `CompleteGoal` berhasil: tombol "Tandai tercapai" masih muncul, chip "Selesai" tidak muncul, `isCompleted` tetap false. Setelah transaksi baru linked: `savedAmount`, progress bar, persentase tetap nilai lama | User melihat data usang setelah setiap aksi; tidak ada konfirmasi visual bahwa aksi berhasil | Phase 7C-fix |
| 165 | ✅ | `goal_bloc.dart` · `add_transaction_bloc.dart` | **Milestone detection tidak pernah trigger dari flow `AddTransactionSheet`** — milestone hanya terdeteksi di `GoalBloc._onLink()`. Saat user menambah transaksi income dengan `goalId` selected via `AddTransactionBloc → AddTransactionUseCase → DB`, `GoalBloc` tidak dinotifikasi (instance terpisah, tidak ada komunikasi antar-bloc). `MilestoneToast` tidak pernah muncul via flow normal, bahkan setelah fix #162 | Fitur milestone celebration 25/50/75/100% tidak pernah berjalan via flow menambah transaksi | Phase 7C-fix |
| 166 | ✅ | `goal_bloc.dart:123-135` | **`GoalBloc._onUnlink()` tidak memanggil repository — silent no-op** — handler hanya reload goals tanpa memanggil `_local.unlinkTransaction()` atau repository apapun. Komentar menyatakan "unlinking sudah dilakukan via add_transaction_sheet" — salah kaprah. Jika event `UnlinkTransaction` dipanggil dari UI, DB tidak berubah namun UI reload seolah berhasil | Ketika UI unlink goal diimplementasi, DB tidak berubah tanpa siapapun menyadari | Phase 7C-fix |
| 56 | ✅ | `assets/translations/id.json` | **`dashboard_days_to_live` belum diterjemahkan ke bahasa Indonesia** — nilainya masih `"Days to Live"` (Inggris) di `id.json`. `DaysToLiveCard` membaca key ini via `AppLocalizations` sejak Phase 5A; user Indonesia melihat teks Inggris di dalam kartu DTL | Label bahasa Inggris muncul di UI Indonesian locale — inkonsisten dengan tone bahasa app | Phase 5B |
| 61 | ✅ | `dashboard_page.dart` | **`todayTransactions` dipakai sebagai "Transaksi terkini"** — section header "Transaksi terkini" memberi kesan beberapa hari terakhir, tapi data yang ditampilkan hanya hari ini. Jika tidak ada transaksi hari ini, section tampil kosong walau kemarin ada banyak riwayat | Empty state muncul padahal user memiliki data; kesan app tidak berguna / kosong | Phase 5B |
| 39 | ✅ | `onboarding_page.dart` | **`_Step2WidgetState` tidak pakai `AutomaticKeepAliveClientMixin`** — `PageView` tidak preserve state off-screen; semua angka yang sudah diisi user di Step 2 hilang saat kembali dari Step 3 | User harus isi ulang Step 2 dari nol setelah back dari Step 3; pengalaman frustrasi dan data terbuang | Phase 5B |
| 46 | ✅ | `onboarding_page.dart` | **`_validate()` Step 1 menolak `paymentDate` 29–31 berdasarkan `maxDay` bulan berjalan** — validasi `if (date > maxDay)` memakai `DateTime.now()` untuk mengecek tanggal recurring. User yang gajian tanggal 30 akan ditolak di bulan Februari (maxDay=28) padahal sistem sudah punya `_clampedDate()` untuk menangani overflow ini dengan benar. | `paymentDate` 29–31 tidak bisa dipilih oleh sebagian user walau valid untuk siklus mereka; blok validasi merusak flow onboarding | Phase 5B |
| 47 | ✅ | `onboarding_page.dart` | **DTL preview card di Step 3 menampilkan `remainingDays` berlabel "ESTIMASI DAYS-TO-LIVE"** — `widget.remainingDays` adalah sisa hari dalam siklus bulan ini, bukan prediksi DTL. DTL sejati bergantung pada `avgDailySpend` historis yang belum ada saat onboarding. Label "hari aman" menyiratkan model spending yang belum tentu valid | Ekspektasi user terbentuk dari angka yang tidak representatif; bisa overestimate rasa aman | Phase 5B |
| 48 | ✅ | `onboarding_page.dart` | **CTA "Mulai Bertahan" di Step 3 tidak di-pin ke bawah layar** — tombol ada di dalam `SingleChildScrollView`, bukan di luar seperti Step 1 & 2. Di layar kecil (< 5 inci) tombol bisa tersembunyi di bawah scroll area; user tidak tahu harus scroll dulu | Inkonsistensi pola navigasi; tombol submit tidak terlihat tanpa scroll pada device kecil | Phase 5B |
| 49 | ✅ | `onboarding_page.dart` | **Step 3 tidak menampilkan warning saat `fixedExpenses >= income`** — `_available = max(income - fixedExpenses, 0)` meng-clamp ke 0, semua nilai di kalkulasi card (installment, remaining, daily budget) menjadi 0. Tidak ada pesan penjelasan — user melihat semua Rp 0 tanpa konteks | User bingung mengapa semua angka nol; bisa mengira ada bug; tidak ada panduan untuk kembali memperbaiki Step 2 | Phase 5B |
| 74 | ✅ | `notification_bloc.dart` | **`onMessageOpenedApp.listen()` subscription tidak disimpan** — listener `FirebaseMessaging.onMessageOpenedApp.listen(...)` di `_onInit` tidak di-assign ke variable manapun; tidak bisa di-cancel di `close()`. `_tokenRefreshSub` dan `_foregroundSub` di-cancel dengan benar, tapi subscription ketiga dibiarkan hidup selamanya | Memory leak; bloc bisa menerima event setelah di-dispose; bisa menyebabkan `emit()` setelah stream closed exception | Phase 5B-fix |
| 75 | ✅ | `notification_repository_impl.dart` | **`onTap` callback yang di-pass ke `initialize()` adalah no-op `(_) {}`** — bahkan jika `initialize()` pernah dipanggil, tap pada local notification tidak akan memicu navigasi karena callback `onTap` discard semua payload. Wiring antara `NotificationLocalDatasource.onTap` → `bloc.add(NotificationTapped(...))` tidak pernah terhubung | Ketuk notifikasi lokal tidak membuka halaman yang benar; local notification tap handling non-functional | Phase 5B-fix |
| 76 | ✅ | `notification_bloc.dart` · `app_database.dart` | **Schema columns `reminderEnabled/Hour/Minute` tidak pernah dibaca atau ditulis** — tiga kolom baru di schema v2 tersedia tapi `NotificationBloc` tidak membaca defaults saat `InitNotification`, tidak menyimpan perubahan saat `ScheduleDailyReminder`, dan tidak me-reschedule reminder saat app restart. Di Android, OS bisa membatalkan alarm saat device restart | Reminder tidak bertahan setelah restart; 3 kolom schema orphaned; user preference reminder time tidak pernah tersimpan | Phase 5B-fix |
| 77 | ✅ | `payday_reminder.js` | **Cron `'0 0 * * *'` + `timeZone: 'Asia/Jakarta'` berjalan 00:00 WIB, bukan 07:00 WIB** — komentar menyebut "pukul 07:00 WIB (00:00 UTC)" namun kombinasi ini menghasilkan eksekusi di 00:00 WIB (= 17:00 UTC hari sebelumnya). Intent dan actual behavior berbeda 7 jam | Notifikasi H-3 kiriman muncul tengah malam (00:00 WIB) bukan pagi hari; mengganggu tidur user; mismatch dengan spec | Phase 5B-fix |
| 78 | ✅ | `budget_warning.js` | **`notifStatus` tidak di-reset pada awal bulan baru** — `budgetStatus` dari bulan lalu persist di Firestore. Jika bulan lalu berakhir dengan `danger`, bulan baru mulai dengan `prevStatus = 'danger'` → user tidak mendapat notifikasi `caution` (karena kondisi `prevStatus === 'safe'` gagal) sampai bulan baru juga mencapai < 15%. Budget warning tidak relevan untuk sebagian besar bulan baru | Notifikasi `caution` tidak muncul di bulan baru jika sebelumnya dalam `danger` state; silent degradation fitur | Phase 5B-fix |

**Fix yang diterapkan:**
- `#185` → di `BlocBuilder` untuk filter row, ganti closure `onFilterTap: () { _openFilterSheet(state); }` (stale) dengan `onFilterTap: () { final s = context.read<TransactionListBloc>().state; if (s is TransactionListLoaded) _openFilterSheet(s); }` — baca state live saat interaksi, bukan dari closure yang di-capture saat build

**Fix yang direkomendasikan (Phase 7C-fix — goal feature):**
- `#162` → di `dashboard_page.dart._openAddSheet()`: load goals aktif sebelum buka sheet — bisa via `context.read<GoalBloc>().state` (jika GoalBloc tersedia di scope) atau query `sl<LoadGoalsUseCase>()` langsung; pass `activeGoals: goals.where((g) => !g.isCompleted).toList()` ke `AddTransactionSheet()`; terapkan pola sama di `transaction_list_page.dart` dan `saya_page.dart`; alternatif lebih clean: provide `GoalBloc` singleton di level router dan baca dari context
- `#163` → tambah `BlocListener<GoalBloc, GoalState>` di dalam `AddGoalSheet.build()`: listen `GoalLoaded` → `Navigator.of(context).pop()` (sukses), `GoalError` → tampilkan snackbar + reset `_isSubmitting = false`; hapus `Navigator.of(context).pop()` dari `_submit()` sehingga sheet hanya menutup diri setelah state sukses dikonfirmasi
- `#164` → di `GoalDetailPage`: ganti prop `goal` yang stale dengan `BlocBuilder<GoalBloc, GoalState>` yang membaca goal terkini dari list (`state.goals.firstWhere((g) => g.id == goalId, orElse: ...)`); atau tambah `BlocListener` yang update state lokal `_goal` saat `GoalLoaded` emit; simpan `goalId` saja di constructor dan baca entity live dari bloc
- `#165` → setelah `AddTransactionSheet` ditutup dengan `result == true` (saved), caller (dashboard/transaction list) perlu juga reload `GoalBloc`; di `dashboard_page.dart._openAddSheet()` tambah `context.read<GoalBloc>().add(const LoadGoals())` di `then()` saat `saved == true`; di `GoalListPage` pastikan reload dipicu saat kembali dari addsheet; ini juga membenahi milestone karena `_onLoad` di GoalBloc mendeteksi crossing dari prevProgress
- `#166` → tambah 1 baris di `GoalBloc._onUnlink()` sebelum reload: `await _local.unlinkTransaction(event.txId);` — atau lebih tepat via repository: buat `UnlinkTransactionUseCase` yang wraps `_repository.unlinkTransaction()`; update `_onUnlink` untuk memanggilnya

**Fix yang direkomendasikan:**
- `#56` → di `assets/translations/id.json`, ubah `"dashboard_days_to_live": "Days to Live"` → `"dashboard_days_to_live": "Hari Aman"` (atau string Indonesian yang sesuai konteks DaysToLiveCard)
- `#4` → tambah reachability check via HTTP HEAD ke `dns.google` setelah `checkConnectivity()` return bukan `none`
- `#26` → `onError: (e, s) { FirebaseCrashlytics.instance.recordError(e, s); return const DashboardError('Terjadi kesalahan.'); }`
- `#27` → wire `dispose()` dari `WidgetsBindingObserver.didChangeAppLifecycleState` saat `AppLifecycleState.detached`, atau dari `app.dart` State `dispose()`
- `#28` → tambah kolom `retryCount` di tabel `SyncQueue` Drift; setelah N kali gagal hapus item dan log ke Crashlytics; atau hapus item dengan `createdAt` > X hari (TTL field sudah ada)
- `#29` → jadikan `StatefulWidget` dengan `_prevPct` di-track via `didUpdateWidget`; animasi dari `_prevPct` → `pct`
- `#30` → tambah field `emergencyFundPct` ke `OnboardingStep3` state; set dari nilai slider sebelum submit; emit ulang dengan nilai tersimpan saat retry
- `#39` → tambah `with AutomaticKeepAliveClientMixin` pada `_Step2WidgetState`; override `wantKeepAlive => true`; panggil `super.build(context)` di awal `build()`
- `#61` → ganti `todayTransactions` dengan query "transaksi 3 terbaru" (`getTransactions(last N)` tanpa filter tanggal); atau tetap pakai today tapi tambahkan fallback: jika kosong tampilkan 3 transaksi terakhir dari `getTransactions(last 7 days)`; update label section dan DashboardEntity field name untuk konsistensi
- `#46` → hapus blok `if (date > maxDay)` dari `_validate()`; tambah validasi sederhana `1 ≤ date ≤ 31`; tambah catatan di UI "Untuk bulan yang lebih pendek, kami sesuaikan otomatis"
- `#47` → ganti konten DTL preview card: label "SISA HARI SIKLUS INI", hapus klaim "aman"; tambah subtitle "Estimasi DTL akan muncul setelah ada riwayat belanja"
- `#48` → pindahkan `PrimaryButton` ke luar `SingleChildScrollView`; wrap body dengan `Column(children: [Expanded(child: SingleChildScrollView(...)), PrimaryButton(...)])`
- `#49` → di Step 3, tambah conditional banner di atas kalkulasi card saat `_available == 0`: "Pengeluaran tetap melebihi pemasukanmu. Kembali ke langkah sebelumnya dan sesuaikan."
- `#74` → simpan subscription: `_openedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(...)`; tambahkan `StreamSubscription<RemoteMessage>? _openedAppSub`; cancel di `close()`
- `#75` → hapus `onTap: (_) {}` dari `NotificationRepositoryImpl.initialize()`; panggil `_local.initialize()` langsung di `_onInit` dengan callback yang dispatch ke bloc: `onTap: (payload) => add(NotificationTapped(payload))`
- `#76` → di `_onInit`: baca `AppSettings` dari Drift via repository; jika `reminderEnabled == true`, panggil `ScheduleDailyReminder(hour: reminderHour, minute: reminderMinute)`. Di `_onSchedule`: simpan `reminderEnabled=true`, `reminderHour`, `reminderMinute` ke DB. Di `_onCancel`: set `reminderEnabled=false` di DB
- `#77` → ubah ke `{ schedule: '0 7 * * *', timeZone: 'Asia/Jakarta' }` (07:00 WIB) atau `{ schedule: '0 0 * * *' }` tanpa timeZone (00:00 UTC = 07:00 WIB)
- `#78` → tambah Cloud Function terjadwal bulanan (cron `'0 0 1 * *'`) yang clear field `budgetStatus` di semua dokumen `users/{uid}/meta/notifStatus`; atau reset `budgetStatus` ke `'safe'` di dalam `budgetWarning` saat `monthStart` berbeda dari `updatedAt.month`

---

## P3 — Kualitas Kode

| # | Status | File | Kelemahan | Dampak | Diselesaikan di |
|---|--------|------|-----------|--------|-----------------|
| 10 | ✅ | `auth_remote_datasource.dart` | **`authStateChanges` stream: `createdAt: DateTime.now()`** — setiap auth event, `createdAt` di-reset ke waktu sekarang | Data user tidak akurat untuk fitur history | Phase 4B |
| 11 | ✅ | `onboarding_local_datasource.dart` | **`getBudgetSettings()`: `createdAt: DateTime.now()`** — waktu onboarding tidak pernah tersimpan permanen | Histori kapan onboarding dilakukan hilang | Phase 4C |
| 12 | ✅ | `onboarding_local_datasource.dart` | **`SyncOperation.create` selalu dipakai** — jika user re-trigger onboarding, queue punya `create` duplikat | Data duplikat atau inkonsisten di Firestore | Drift migration |
| 13 | ✅ | `onboarding_page.dart` | **Validasi tanggal kiriman hanya cek range 1–31** — tanggal 29/30/31 di bulan pendek valid; `remainingDaysInCycle` bisa salah | Kalkulasi anggaran harian tidak akurat di akhir bulan | Phase 4B |
| 14 | ✅ | `app_localizations.dart` | **`shouldReload = false`** — ganti bahasa tidak me-reload string; butuh restart app | UX ganti bahasa tidak bekerja real-time | Phase 4 (0.5) |
| 15 | ✅ | Seluruh codebase | **`catch (_)` kehilangan stack trace** — banyak tempat pakai `catch (_)` tanpa Crashlytics logging; debug production sangat sulit | Bug production tidak bisa di-debug | Phase 5A |
| 16 | ✅ | `main.dart` | **Firebase debug providers hardcoded tanpa `kReleaseMode` guard** — `AndroidDebugProvider()` masuk ke production build | AppCheck bypass di production | Phase 4 (0.3) |
| 31 | ✅ | `dashboard_repository_impl.dart` | **Nol unit test untuk `_compute()`** — logika DTL, avgDailySpend, BudgetStatus threshold, edge case negatif, dan double counting tidak tercover | Bug kalkulasi tidak terdeteksi otomatis; regresi saat refactor | Phase 5A (12 tests) |
| 32 | ✅ | `sync_dispatcher.dart` | **Nol unit test untuk `SyncDispatcher`** — logika dispatch create/update/delete ke Firestore tidak tercover secara langsung. `SyncService` sudah tercover via injected `fakeDispatch` (7 tests), tapi perilaku dispatcher asli (path routing, SetOptions merge) tidak ditest. `fake_cloud_firestore ^3` inkompatibel dengan `cloud_firestore ^6.x` | Perubahan di SyncDispatcher tidak terdeteksi | Phase 6C (`toFirestoreOp()` pure fn + 6 tests) |
| 33 | ✅ | `dashboard_repository_impl.dart` | **`getBudgetSettings()` di-call setiap stream event** — budget settings jarang berubah tapi di-fetch ulang setiap kali `watchDashboard()` emit | Overhead DB reads pada frequent transaction updates | Phase 5A |
| 34 | ✅ | `dashboard_page.dart` | **`DashboardRefreshed` dipanggil unconditional saat sheet tutup** — stream restart bahkan jika user cancel tanpa simpan | Unnecessary stream restart; minor performa overhead | Phase 5A |
| 35 | ✅ | `days_to_live_card.dart` | **"DAYS TO LIVE" hardcoded English** — label tidak diterjemahkan; inconsistent dengan tone bahasa Indonesia CLAUDE.md | Tone inconsistency; familiar bagi user berbahasa Indonesia | Phase 5A |

| 60 | ✅ | `dashboard_page.dart` · `days_to_live_card.dart` | **`emergencyFundMonthly` di-label "CICILAN DARURAT" padahal bukan saldo tersimpan** — `emergencyFundMonthly` adalah rencana cicilan bulanan (income × pct), bukan jumlah dana darurat yang sudah terkumpul. Progress bar menghitung rasio cicilan vs total budget, bukan kemajuan menuju target. Label dan angka membingungkan user yang berharap melihat saldo aktual | User tidak bisa mengetahui berapa dana darurat yang sudah terkumpul; card terasa tidak informatif tanpa konteks cicilan | Phase 6A (label fix: "ALOKASI DARURAT") |
| 62 | ✅ | `days_to_live_card.dart` | **`_safeUntilDate()` bisa melampaui tanggal kiriman berikutnya** — "Saldo aman sampai X" dihitung `DateTime.now() + daysToLive`. Jika `daysToLive > remainingDays`, tanggal yang ditampilkan melewati tanggal kiriman berikutnya — secara teknis salah karena siklus baru akan mulai saat itu | User bisa salah interpretasi kapan perlu mulai lebih hemat; "aman sampai 20 Juni" padahal kiriman masuk 1 Juni | Phase 5B |
| 64 | ✅ | `dashboard_page.dart` | **Bottom nav tab tengah ("Budget") tidak memiliki label teks** — semua tab lain (`_NavItem`) punya label di bawah ikon; center FAB hanya punya ikon `+` tanpa teks "Budget". Fungsi tombol tidak jelas (apakah untuk budget overview, tambah transaksi, atau menu?) | Inkonsistensi visual; user bisa kebingungan tentang fungsi tombol tengah | Phase 5B |
| 65 | ✅ | `dashboard_page.dart` | **"Lihat semua →" bypass `_onNavTap` — bottom nav tidak update** — `context.push('/transactions')` dipanggil langsung tanpa `setState(() => _navIndex = 1)`. Tab "Transaksi" tidak aktif walaupun halaman transaksi sedang tampil; tab "Beranda" tetap highlighted | Inkonsistensi state antara route aktif dan tab highlighted; muncul saat user kembali dari transactions |
| 66 | ✅ | `dashboard_page.dart` | **`_TxnRow` tidak menampilkan sync indicator** — `TransactionItem` lama punya dot kuning saat `!transaction.isSynced`; `_TxnRow` pengganti di dashboard tidak punya penanda ini. User tidak tahu transaksi mana yang belum tersync ke cloud | Silent data integrity concern; user kehilangan context sync status di tampilan utama | Phase 5B |
| 57 | ✅ | `add_transaction_sheet.dart` · `transaction_item.dart` · `transaction_list_page.dart` | **`TransactionCategory.income` tidak punya key lokalisasi** — label "Pemasukan" dan "Masuk" untuk kategori income di-hardcode di tiga tempat terpisah (`_CategoryChip._label()`, `TransactionItem._categoryLabel()`, `_FilterChips`) dengan string berbeda-beda. `assets/translations/en.json` dan `id.json` tidak punya key `category_income`, `AppLocalizations` tidak punya getter untuk ini | Category label income inconsistent antar widget; tidak bisa diterjemahkan ke English; jika ada perubahan nama harus ubah di 3 tempat | Phase 5B |
| 58 | ✅ | Seluruh codebase (6 pages + 3 widgets) | **Infrastruktur lokalisasi ada tapi hampir tidak digunakan** — `AppLocalizations` punya 30+ getter; `en.json` + `id.json` punya 43 key; namun hanya `DaysToLiveCard` yang memanggil `AppLocalizations.of(context)`. Enam halaman (`splash`, `login`, `register`, `onboarding`, `dashboard`, `transaction_list`) dan tiga widget (`SurvivalModeBanner`, `AddTransactionSheet`, `TransactionItem`) semuanya hardcode string bahasa Indonesia. 30+ key JSON terdefinisi tapi tidak dipanggil dari mana pun | App tidak bisa mendukung bahasa Inggris tanpa refactor besar; key yang terdefinisi di JSON (termasuk onboarding keys) tidak memberi manfaat | Phase 6C (`context.l10n` ext + 40+ keys + 5 pages) |
| 40 | ✅ | `onboarding_page.dart` + `onboarding_bloc.dart` | **`Step2Submitted` hanya kirim total, bukan breakdown per kategori** — data rent/utilities/internet/phone/other dibuang sebelum submit. Stated goal Step 2 tidak terpenuhi: "aplikasi punya data terstruktur untuk future feature (budget tracking per kategori)" | Tidak bisa build budget-tracking per kategori (kos, listrik, dll.) di fitur berikutnya tanpa breaking change pada schema | Phase 6C (schema v3 + 5 kolom breakdown) |
| 41 | ✅ | `onboarding_page.dart` | **`_submitError` tidak di-clear saat user mulai mengetik** — error "Isi paling tidak satu pengeluaran tetap." tetap tampil setelah user mulai mengisi, sampai submit berikutnya terjadi | Error stale terlihat membingungkan; user tidak tahu apakah pesannya masih valid | Phase 5B |
| 50 | ✅ | `onboarding_page.dart` | **Preview card Step 1 hardcode `_dailyIncome = income / 30`** — `_dailyIncome` di-compute dengan pembagi 30 tetap, sedangkan logika aktual di `dashboard_repository_impl.dart` menggunakan `daysInCycle(paymentDate)`. User melihat preview yang berbeda dari anggaran harian sebenarnya | Inkonsistensi antara preview onboarding dan nilai di dashboard; user bisa surprise saat melihat angka berbeda | Phase 5B |
| 51 | ✅ | `onboarding_page.dart` | **`_incomeError` dan `_dateError` di Step 1 tidak di-clear saat user berinteraksi** — error hanya di-reset di awal `_validate()`. `onChanged` income field hanya memanggil `setState(() {})` tanpa reset error; `onClear` juga tidak reset `_incomeError`. Error tetap tampil walau user sudah memperbaiki input | Sama dengan #41 untuk Step 2; error stale membingungkan; pattern yang sama seharusnya difix seragam | Phase 5B |
| 52 | ✅ | `onboarding_page.dart` | **`_targetController` di Step 3 menggunakan `FilteringTextInputFormatter.digitsOnly` tanpa formatter ribuan** — field "Target dana darurat" menampilkan digit mentah (contoh: "5000000") tanpa pemisah titik. Step 1 pakai `_RupiahInputFormatter`, Step 2 pakai `_DotFormatter` — Step 3 adalah satu-satunya yang tidak konsisten | Angka besar sulit dibaca (7–9 digit tanpa separator); inkonsistensi visual di tiga step wizard yang berurutan | Phase 5B |
| 53 | ✅ | `onboarding_page.dart` | **`_DatePickerSheet` menampilkan tanggal 29–31 tanpa indikasi clamping** — grid 1–31 menampilkan semua tanggal identik. Jika user memilih tanggal 31 dan bulan berjalan hanya 30 hari, konfirmasi menampilkan "Gunakan tanggal 31", padahal `_clampedDate()` akan menggunakan tanggal 30. User tidak tahu tanggal mereka akan di-adjust | Ekspektasi user tidak terpenuhi — mereka memilih 31 tapi sistem menggunakan 30 tanpa notifikasi; bisa menyebabkan miskalikulasi yang tidak diketahui | Phase 5B |
| 102 | ✅ | `settings_page.dart` | **`SettingsPage` tidak punya `BlocListener` untuk `NotificationBloc`** — `_onToggleReminder()` dispatch event ke `NotificationBloc` tapi tidak ada listener untuk state balik. Jika `ScheduleDailyReminder` gagal (permission denied mid-session, plugin error), switch tetap tampil "enabled" tapi notifikasi tidak terjadwal. Tidak ada error snackbar, tidak ada rollback `_reminderEnabled` | User mendapat false sense of security — switch hijau tapi reminder tidak berjalan; tidak ada error feedback sama sekali | Phase 6A-fix |
| 103 | 🔲 | `settings_page.dart` | **Seluruh teks `SettingsPage` hardcoded dalam bahasa Indonesia — tidak berubah saat user ganti bahasa ke English** — L10n keys tersedia di JSON (`settings_theme`, `settings_theme_light`, `settings_theme_dark`, `settings_theme_system`, `settings_language`) dan `AppLocalizations` punya getter-nya, tapi `settings_page.dart` tidak import `AppLocalizations` sama sekali. Section headers, tile labels, subtitle semuanya hardcode Indonesian | Settings page tidak fungsional untuk user yang memilih English; melanggar prinsip i18n yang sedang dibangun; menjadi ironi — user ganti bahasa via Settings yang tidak bisa diterjemahkan | Phase 6B |
| 104 | ✅ | `onboarding_page.dart` | **`onboardingIncomeHint` l10n key dipetakan ke `label:` (floating label), bukan `hintText:`** — setelah Fix #59, kode menjadi `AppTextField(label: l10n.onboardingIncomeHint, ...)`. Nilai key di `id.json`: `"Masukkan nominal dalam Rupiah"` — ini instruksi input, bukan form label. Floating label yang terlalu panjang terlihat aneh; field yang seharusnya berlabel `"Nominal"` kini berlabel kalimat panjang | UX visual terganggu; floating label terlalu panjang tidak sesuai desain; mapping semantik antara key name dan penggunaannya salah | Phase 6A-fix |
| 105 | 🔲 | `settings_page.dart` | **`_loadReminder()` query DB langsung dari widget — violates Clean Architecture** — `sl<AppDatabase>().select(sl<AppDatabase>().appSettings)` dipanggil dari `State.initState()`. Root cause: `NotificationState` tidak punya state yang mengekspos konfigurasi reminder saat ini. Fix butuh tambah `NotificationReminderLoaded` state atau query via repository | Violasi Clean Architecture; widget bergantung langsung ke infrastructure layer; sulit di-test; potensi desync jika `NotificationBloc` update DB di luar widget lifecycle | Phase 6C |
| 106 | ✅ | `settings_page.dart` | **`_reminderLoaded` flag tidak melindungi "NOTIFIKASI" section header** — `_reminderLoaded` hanya melindungi `AnimatedOpacity` di sekeliling switch dan time picker card, tapi section header "NOTIFIKASI" selalu dirender tanpa guard. Header muncul sesaat sebelum konten di bawahnya ter-load — visual flash inkonsisten | Minor UX flash; inkonsistensi guard: sebagian widget dilindungi, sebagian tidak; header bisa tampil tanpa konten | Phase 6A-fix |
| 107 | ✅ | `milestone_toast.dart` | **`MilestoneToast` tidak punya `margin` pada `SnackBar`** — `SnackBarBehavior.floating` tanpa `margin` menggunakan jarak default Flutter yang tidak memperhitungkan bottom navigation bar (tinggi ~60dp). Toast tertutup sebagian atau sepenuhnya oleh bottom nav saat muncul | Toast celebration tidak terlihat; fitur milestone terasa tidak berfungsi; core feature delivery terhalang oleh margin default yang salah | Phase 6A-fix |
| 108 | 🔲 | `assets/translations/id.json` | **Copy onboarding di `id.json` kehilangan tone percakapan original** — setelah Fix #59, nilai di `id.json` menggunakan kalimat yang berbeda dari original hardcode: `"onboarding_income_title"` → `"Berapa kiriman bulananmu?"` (vs original `"Berapa kamu terima\ntiap bulan?"`), `"onboarding_fixed_title"` → `"Pengeluaran tetap tiap bulan"` (vs `"Apa yang pasti kamu\nbayar tiap bulan?"`). Kehilangan line break intentional dan sapaan langsung "kamu" | Copy baru lebih kaku; menyimpang dari tone santai-formal app; kehilangan emphasis dari newline yang disengaja di judul step | Phase 6B |
| 109 | 🔲 | `settings_page.dart` | **String versi `'v0.1.0+1'` hardcoded di widget** — `_VersionTile` di `SettingsPage` menggunakan literal string versi yang tidak akan pernah berubah secara otomatis saat `pubspec.yaml` di-bump. Developer harus ingat update dua tempat setiap rilis | Versi di Settings bisa mismatch dengan versi aktual binary; developer prone-to-forget; best practice Flutter pakai `package_info_plus` | Phase 6B |
| 79 | ✅ | `notification_local_datasource.dart` | **`showNotification()` adalah dead code** — method didefinisikan di abstract class dan impl, tapi tidak ada use case, bloc event, atau repo method yang memanggilnya. Tidak ada path dari UI ke `showNotification()`. Method ini tidak digunakan oleh siapapun | Dead code menambah cognitive load; membuat interface lebih besar dari yang diperlukan; bisa menyesatkan developer yang mengira sudah ada immediate notification feature | Phase 6A |
| 80 | ✅ | `notification_repository.dart` | **`getFcmToken()` dan `initialize()` di domain interface tidak memiliki use case** — keduanya terdaftar di domain interface tapi tidak ada `GetFcmTokenUseCase` atau `InitializeNotificationUseCase`. Jika dipanggil, harus melewati repository impl secara langsung (bypass clean architecture). Domain layer notification tidak konsisten dengan pola di fitur lain | Inconsistency di layer architecture; `getFcmToken()` tidak bisa dimock/di-test via domain boundary; coupling domain impl ke infra | Phase 6A |
| 81 | ✅ | `daily_reminder.js` | **`todayStart.setHours(0, 0, 0, 0)` adalah UTC midnight, bukan WIB midnight** — "hari ini" dari perspektif WIB (UTC+7) dimulai pukul 17:00 UTC hari sebelumnya. `setHours(0,0,0,0)` meng-set waktu ke 00:00 UTC = 07:00 WIB. User yang mencatat transaksi antara 00:00–06:59 WIB (= sebelum 00:00 UTC) tidak terdeteksi sebagai "sudah catat hari ini" | False positive reminder: user yang catat transaksi pagi WIB (sebelum 07:00) tetap menerima notifikasi pengingat yang tidak relevan | — |
| 92 | ✅ | `report_entity.dart` | **`Map<TransactionCategory, int>` di Equatable `props` menggunakan reference equality** — Dart `Map.==` adalah reference equality, bukan value equality. Equatable membandingkan `props` element per element menggunakan `==`; dua map instance berbeda dengan isi identik menghasilkan entity yang "tidak sama" padahal seharusnya sama. Setiap kali `getMonthlyReport()` return entity baru (object baru), BLoC akan selalu emit `ReportLoaded` baru meski data tidak berubah (navigasi bulan yang sama dua kali) | Unnecessary rebuild setiap navigasi; potential duplicate state emissions; bila `droppable()` diubah ke `restartable()`, bisa menyebabkan infinite loop | — |
| 93 | ✅ | `report_remote_datasource.dart` · `functions/src/insights.js` | **`savingTip` dari Cloud Function dibuang** — `insights.js` menghitung, menyimpan ke cache, dan mengembalikan `savingTip: "..."` (satu kalimat tip hemat); `report_remote_datasource.dart` hanya mengambil `result.data['insights']` dan mengabaikan `savingTip`. Konten cache Firestore juga menyimpan field ini tapi tidak pernah dibaca | Tips hemat yang dihasilkan AI (berpotensi berguna) tidak pernah ditampilkan; extra compute dan storage Firestore untuk field yang terbuang; `InsightCard` bisa menampilkan tip ini sebagai baris tambahan | — |
| 94 | ✅ | `report_page.dart` | **`netBalance.abs()` ditampilkan tanpa tanda negatif** — "SALDO BERSIH" selalu menampilkan nilai absolut; sign negatif (overspent) hanya dikomunikasikan via warna `AppColors.warn`. User yang color-blind atau tidak paham konvensi warna tidak bisa membedakan saldo positif Rp 50.000 dari defisit Rp 50.000 tanpa membaca warna | Aksesibilitas rendah; informasi kritikal (surplus vs defisit) hilang jika warna tidak tersampaikan; menyiratkan app color-dependent untuk pemahaman data keuangan | — |
| 95 | ✅ | `category_pie_chart.dart` | **`_categoryColors` menggunakan Material Design colors hardcoded di luar `AppColors`** — palet `Color(0xFF4CAF50)`, `Color(0xFF2196F3)`, dll. tidak ada di `AppColors` dan tidak switch berdasarkan tema. CLAUDE.md: "Selalu mulai dari token. Warna → `AppColors`. Jangan hardcode hex atau angka arbitrary." Pie chart terlihat kontras dengan identitas visual brand (hijau Penyintas vs hijau Material) | Melanggar design system; chart warna berbeda dari brand palette; tidak responsif dark mode (warna bisa clash dengan background gelap); inkonsistensi visual yang terlihat oleh user | — |
| 82 | ✅ | `payday_reminder.js` | **`today.getDate()` mengembalikan UTC date, bukan WIB date** — saat cron berjalan 00:00 WIB = 17:00 UTC hari sebelumnya, `new Date().getDate()` menghasilkan tanggal kemarin (UTC). `targetDate = (kemarin + 3).getDate()` → secara efektif H-3 dihitung dari kemarin WIB, membuat notifikasi tiba satu hari setelah yang diharapkan | Notifikasi H-3 secara efektif menjadi H-2 dari perspektif user WIB; timing off by one day | — |
| 88 | ✅ | `functions/src/insights.js` | **`JSON.parse(text)` tidak dilindungi try-catch** — LLM diinstruksikan `"Return JSON persis (tanpa markdown, tanpa kode block)"`, tapi model sering menambahkan markdown fence `` ```json ... ``` `` atau karakter lain. `JSON.parse()` akan throw `SyntaxError` yang tidak tertangkap → Cloud Function return HTTP 500 ke client. Tidak ada fallback atau sanitasi response sebelum parsing | Semua request AI insight bisa gagal dengan error 500 saat Gemini tidak patuh instruksi format; tidak bisa di-predict reliabilitasnya; user melihat `InsightCard` error state | Phase 5C-fix |
| 89 | ✅ | `functions/src/insights.js` | **Unsafe access `result.response.candidates[0].content.parts[0].text`** — jika Vertex AI mengembalikan response kosong (safety filter triggered, rate limit, atau quota exceeded), `candidates` bisa array kosong atau `undefined`. Akses `candidates[0]` langsung throw `TypeError: Cannot read properties of undefined` tanpa error handling | Cloud Function crash dengan 500 saat safety filter aktif atau quota habis; tidak ada graceful degradation; `InsightCard` menampilkan error state tanpa pesan yang informatif ke user | Phase 5C-fix |
| 90 | ✅ | `report_local_datasource.dart` | **`dailyAverageSpend = totalSpent / daysInMonth` menggunakan total hari dalam bulan, bukan hari yang sudah berjalan** — untuk bulan berjalan (contoh: buka laporan tanggal 10 Mei), pembagi adalah 31 (total hari Mei), bukan 10 (hari yang sudah berjalan). Rata-rata harian tampak 3× lebih kecil dari kenyataan: user yang sudah keluar Rp 300.000 dalam 10 hari melihat "Rp 9.677/hari" padahal pola belanjanya Rp 30.000/hari | Metrik "rata-rata per hari" menyesatkan untuk bulan berjalan; user yang punya batas harian (dari DTL) tidak bisa mengevaluasi apakah mereka over atau under budget | Phase 5C-fix |
| 91 | ✅ | `report_page.dart` | **`_SummaryItem` selalu menggunakan `AppColors.mutedLight` untuk teks label tanpa mempertimbangkan mode tema** — baris `style: AppTextStyles.caption.copyWith(color: AppColors.mutedLight)` di `_SummaryItem.build()` mengabaikan `textColor` parameter yang di-pass dan mengabaikan `isDark`. `AppColors.mutedLight` (#6B7264) di atas `AppColors.surfaceDark` (#15301F) memiliki contrast ratio yang rendah | Teks label ("PENGELUARAN", "PEMASUKAN", "SALDO BERSIH") sulit dibaca di dark mode; melanggar CLAUDE.md aturan dark mode wajib dari hari pertama | Phase 5C-fix |
| 167 | 🔲 | `goal_card.dart:155` | **`_GoalProgressBar` `TweenAnimationBuilder` selalu restart dari 0 setiap rebuild** — `Tween(begin: 0, end: percent)` hardcode `begin: 0`. Setiap kali `GoalCard` di-rebuild (scroll list, `GoalActionLoading` → `GoalLoaded` transition), animasi progress bar mulai dari nol ke nilai akhir | Goal 90% terlihat "mundur dari nol" setiap interaksi; terutama jarring saat `GoalActionLoading` state transition | Phase 7F |
| 168 | ✅ | `goal_detail_page.dart:60,141,146,160-163,198` | **7+ string hardcoded non-l10n di `GoalDetailPage`** — `'Tandai tercapai'`, `'Hapus tujuan'`, `'Status'`, `'Sedang berjalan'`, `'Hapus Tujuan'`, `'Hapus'`, `'Cara menabung untuk tujuan ini...'` semuanya literal Indonesian string tidak lewat `AppLocalizations`. Inkonsisten dengan Phase 6C fix #58 yang sudah wire l10n ke 5 page lain | UI `GoalDetailPage` tidak berubah saat ganti bahasa ke English; pola sama dengan #149 yang sudah difix di 7B-fix | Phase 7C-fix |
| 169 | 🔲 | `goal_local_datasource.dart:28-50` | **`loadGoals()` menggunakan N+1 query pattern** — 1 query `select(goals)` + 1 query `SUM` per goal via `Future.wait`. N goals = N+1 DB round-trips concurrent; 20 goals = 21 queries | Overhead DB meningkat linear dengan jumlah goal; lebih optimal dengan single `LEFT JOIN + GROUP BY goalId` | Phase 7F |
| 157 | 🔲 | `transaction_list_page.dart` | **Filter chip labels `'Semua'`/`'Masuk'`/`'Keluar'` hardcoded — tidak berubah saat ganti bahasa ke English** — `_FilterRow` (line 128–136) menggunakan string literal untuk ketiga label filter type. Tidak ada l10n key untuk label ini di `en.json`/`id.json` maupun getter di `AppLocalizations`. Fix #58 (Phase 6C) mewire l10n ke page title (`navTransactions`) tapi melewatkan filter chip labels | User English melihat "Semua"/"Masuk"/"Keluar" alih-alih "All"/"In"/"Out"; inkonsisten dengan judul halaman yang sudah terl10n-kan | — |
| 158 | 🔲 | `transaction_list_page.dart` | **Empty state text hardcoded Indonesia padahal key `emptyStateTransactions` sudah ada di `AppLocalizations`** — `_LoadedBody` (line 389–390) menampilkan `'Belum ada catatan bulan ini.\nMulai dari satu pengeluaran kecil hari ini.'` via literal. Key `empty_state_transactions` terdaftar di `en.json`/`id.json` dan getter `emptyStateTransactions` tersedia; copy sedikit berbeda (versi page tambah "bulan ini") tapi base key sudah ada | Fix satu baris; tampilan English menampilkan teks Indonesia | — |
| 159 | 🔲 | `transaction_list_page.dart` | **Date group headers `'HARI INI'` dan `'KEMARIN'` hardcoded — tidak ada l10n key** — `_dateHeader()` method (line 462–472) mengembalikan `'HARI INI · ...'` dan `'KEMARIN · ...'` sebagai string literal. Tidak ada key di `en.json`/`id.json` untuk label "today" dan "yesterday" ini | User English melihat "HARI INI" dan "KEMARIN" di header tanggal bersamaan dengan konten list yang sudah English | — |
| 160 | 🔲 | `transaction_list_page.dart` | **`_MonthPickerSheet` menggunakan singkatan bulan Indonesia hardcoded dan locale `id_ID` dikodekan keras di dua tempat** — (1) array `monthNames` (line 276–278) berisi `'Mei'`, `'Ags'`, `'Okt'`, `'Des'` yang hanya valid di Indonesia tanpa l10n key; (2) `_DateChip.build()` (line 198) memanggil `DateFormat('MMMM', 'id_ID')` dengan locale string hardcoded — di mode English bulan tampil nama Indonesia | Month picker dan date chip tetap Indonesia saat bahasa app diubah ke English; dua lokasi perlu difix bersamaan | — |
| 161 | 🔲 | `transaction_item.dart` · `add_transaction_sheet.dart` | **Semua label kategori transaksi hardcoded Indonesia di dua widget — keys l10n sudah ada tapi tidak digunakan** — `TransactionItem._categoryLabel()` (line 156–170) dan helper serupa di `add_transaction_sheet.dart` (line 699–713) keduanya mengembalikan string literal (`'Makan'`, `'Transport'`, `'Belanja'`, `'Kesehatan'`, `'Internet'`, `'Kos'`, `'Lainnya'`, `'Pemasukan'`). Keys `category_food`, `category_transport`, `category_shopping`, `category_campus`, `category_data`, `category_fixed`, `category_other`, `category_income` sudah terdaftar di `en.json`/`id.json` dan `AppLocalizations` sejak fix #57 (Phase 5B), tapi dua helper function tidak pernah di-refactor untuk menggunakannya. `TransactionItem` digunakan di `DashboardPage._TxnRow` dan `TransactionListPage` — dua screen utama terimbas | Label kategori tampil Indonesia di semua transaction item saat mode English; pola sama dengan #57 (sudah difix untuk `category_income`) tapi 7 kategori lain terlewat; keys tersedia, fix hanya butuh refactor dua helper function | — |

**Fix yang direkomendasikan:**
- `#57` → tambah key `"category_income"` ke `en.json` (`"Income"`) dan `id.json` (`"Pemasukan"`); tambah getter `categoryIncome` di `AppLocalizations`; refactor `_CategoryChip._label()`, `TransactionItem._categoryLabel()`, dan `_FilterChips` agar baca dari `l10n.categoryIncome` (atau lookup map berbasis `AppLocalizations`)
- `#58` → Phase 6: buat helper `l10n` extension; wire AppLocalizations ke 6 pages dan 3 widgets satu per satu; hapus key JSON yang tidak punya callee setelah semua terhubung
- `#15` → global search `catch (_)` dan `catch (e)` tanpa logging; ganti ke `catch (e, s) { FirebaseCrashlytics.instance.recordError(e, s); ... }`
- `#31` → `test/features/dashboard/data/repositories/dashboard_repository_impl_test.dart`; scenario: income < fixedExpenses, DTL zero avgDailySpend, BudgetStatus threshold, double-counting fix
- `#32` → `test/core/sync/sync_dispatcher_test.dart`; mock `FirebaseFirestore` via `FakeFirebaseFirestore` (package `fake_cloud_firestore`) atau test integration sederhana
- `#33` → cache `BudgetSettingsEntity?` sebagai field private; invalidate saat `onboarding_completed` event; re-fetch hanya saat null
- `#34` → pakai `result` dari `showModalBottomSheet` — return `true` dari sheet saat transaksi disimpan; panggil `DashboardRefreshed` hanya jika `result == true`
- `#35` → buat key `dashboard_dtl_label` di `id.json` dan `en.json`; gunakan `AppLocalizations.of(context).dashboard_dtl_label`
- `#40` → tambah field breakdown ke `Step2Submitted` event dan `OnboardingStep3` state; simpan ke `BudgetSettingsEntity` sebagai `Map<String, int>` atau field terpisah; naikkan schema version Drift
- `#41` → panggil `setState(() => _submitError = null)` di dalam setiap `onChanged` callback pada `_ExpenseInputRow`
- `#50` → ganti `_dailyIncome = income / 30` dengan `income / daysInCycle(_selectedDatePreset ?? 1)`; hanya compute setelah tanggal dipilih; import `date_helper.dart`
- `#51` → di `onChanged` income field: `setState(() { _incomeError = null; })`; di `onClear`: tambah `_incomeError = null`; di `_selectDate`: sudah ada `_dateError = null` ✅ — hanya income dan clear yang perlu fix
- `#52` → ganti `FilteringTextInputFormatter.digitsOnly` dengan `_DotFormatter()` yang sudah ada di file yang sama; tambah prefix "Rp " atau pakai `_RupiahInputFormatter`
- `#53` → di `_DatePickerSheet`, tandai tanggal 29–31 dengan warna `mutedColor` dan asterisk; di konfirmasi button tampilkan "Gunakan sekitar tanggal $selected*"; atau tampilkan tooltip/footnote "Bulan tertentu mungkin disesuaikan otomatis"
- `#79` → hapus `showNotification()` dari abstract interface dan impl; jika dibutuhkan di masa depan, tambahkan kembali dengan use case yang proper ✅ Phase 6A
- `#80` → buat `InitializeNotificationUseCase` wrapping `_repo.initialize()`; hapus `getFcmToken()` dari domain interface karena hanya digunakan secara internal di bloc; atau biarkan bloc mengakses `messaging.getToken()` langsung (sudah dilakukan, domain abstraction tidak menambah nilai di sini) ✅ Phase 6A
- `#102` → tambah `BlocListener<NotificationBloc, NotificationState>` wrapping `Scaffold` di `SettingsPage.build()`; react ke `NotificationError` dengan `ScaffoldMessenger.showSnackBar`; rollback `_reminderEnabled` ke nilai sebelumnya saat error; bisa inject `_prevReminderEnabled` sebelum dispatch toggle
- `#103` → tambah `import 'package:penyintas_app/core/l10n/app_localizations.dart'`; `final l10n = AppLocalizations.of(context)` di `build()`; ganti: `'TAMPILAN'→l10n.settingsTheme.toUpperCase()`, `'BAHASA'→l10n.settingsLanguage.toUpperCase()`, `'Terang'→l10n.settingsThemeLight`, `'Gelap'→l10n.settingsThemeDark`, `'Ikut sistem'→l10n.settingsThemeSystem`; buat key baru untuk string yang belum ada (lihat #112)
- `#104` → ganti `label: l10n.onboardingIncomeHint` dengan `label: l10n.onboardingIncomeLabel` (key baru, nilai pendek: id=`"Nominal per bulan"`, en=`"Monthly amount"`); pindahkan `l10n.onboardingIncomeHint` ke `hintText:` field atau hapus jika sudah ada `hintText: 'Rp 0'`; tambah key baru ke id.json + en.json + AppLocalizations
- `#105` → tambah `NotificationReminderLoaded({required bool enabled, required int hour, required int minute})` state ke `NotificationState`; dispatch `LoadReminderSettings` event di `_onInit` setelah baca DB; `SettingsPage` gunakan `BlocBuilder<NotificationBloc>` untuk reminder state, hapus `_loadReminder()` direct DB call
- `#106` → pindahkan `_SectionHeader('NOTIFIKASI')` ke dalam blok `AnimatedOpacity` yang sudah ada, atau bungkus dalam `Visibility(visible: _reminderLoaded, maintainState: true, ...)` untuk konsistensi guard dengan switch card di bawahnya
- `#107` → tambah `margin: const EdgeInsets.only(bottom: kBottomNavigationBarHeight + AppSpacing.sm)` ke `SnackBar` di `MilestoneToast.show()`; atau gunakan `MediaQuery.of(context).viewPadding.bottom + 72` untuk device dengan gesture navigation; pastikan nilai cukup untuk cover bottom nav
- `#108` → revisi nilai di `id.json`: `"onboarding_income_title"` → `"Berapa kamu terima\ntiap bulan?"`, `"onboarding_fixed_title"` → `"Apa yang pasti kamu\nbayar tiap bulan?"`; catatan: Dart `Text()` tidak interpret `\n` dari JSON secara otomatis — perlu `Text(l10n.onboardingIncomeTitle.replaceAll(r'\n', '\n'))` atau `Text.rich` dengan manual split, atau pisahkan ke dua getter `onboardingIncomeLine1`/`Line2`
- `#109` → tambah `package_info_plus: ^8.0.0` ke `pubspec.yaml`; di `_VersionTile`, load via `FutureBuilder<PackageInfo>` dengan `PackageInfo.fromPlatform()`; tampilkan `'v\${info.version}+\${info.buildNumber}'`; cache hasilnya di State untuk menghindari async rebuild
- `#92` → gunakan `DeepCollectionEquality` dari package `collection` di `props`: import `package:collection/collection.dart`; override `operator ==` dan `hashCode` secara manual; atau gunakan `MapEquality().equals(categoryBreakdown, other.categoryBreakdown)` dalam custom `==`; alternatif: convert `Map` ke sorted `List<MapEntry>` di `props`
- `#93` → di `report_remote_datasource.dart`, tambah return type wrapper `({List<String> insights, String? savingTip})`; atau return `Map<String, dynamic>` dari datasource dan biarkan repository split; di `ReportEntity` tambah field `savingTip`; tampilkan di `InsightCard` sebagai baris terakhir dengan styling berbeda
- `#94` → tampilkan tanda prefix: `final netSign = report.netBalance < 0 ? '−' : '+'`; gunakan `'$netSign${formatRupiah(report.netBalance.abs())}'`; atau tampilkan dua baris (nilai dan label "Surplus"/"Defisit") agar tidak bergantung warna semata
- `#95` → buat `_categoryColors` sebagai `Map<TransactionCategory, Color>` yang menggunakan `AppColors` tokens; map ke token yang semantically closest: `food → AppColors.primary`, `transport → AppColors.primaryBright`, `campus → AppColors.shoot`, `data → AppColors.caution`, `shopping → AppColors.warn`, `fixed → AppColors.mutedLight/Dark`, `other → AppColors.borderLight/Dark`; tambah dark-mode variant
- `#81` → ganti `todayStart.setHours(0, 0, 0, 0)` dengan penghitungan WIB midnight: `const jakartaOffsetMs = 7 * 60 * 60 * 1000; const nowMs = Date.now(); const todayWibMs = nowMs - ((nowMs + jakartaOffsetMs) % 86400000) + (0 * 86400000 % 86400000); const todayStart = new Date(todayWibMs - jakartaOffsetMs);`; atau gunakan library `date-fns-tz`
- `#82` → setelah apply fix #77 (cron jadi 07:00 WIB), hitung WIB date secara eksplisit: `const jakartaOffset = 7 * 60 * 60 * 1000; const nowWib = new Date(Date.now() + jakartaOffset); const today = { getDate: () => nowWib.getUTCDate() };` lalu pakai `today.getDate()` dan `targetDay.setUTCDate(...)` untuk konsistensi
- `#88` → tambahkan try-catch di sekitar `JSON.parse(text)` dan sanitasi response: `const jsonText = text.replace(/^```json\n?/, '').replace(/\n?```$/, '').trim(); const parsed = JSON.parse(jsonText);`; wrap dalam `try { ... } catch (e) { throw new HttpsError('internal', 'Gagal memproses respons AI.'); }`
- `#89` → tambah guard: `const candidates = result?.response?.candidates; if (!candidates || candidates.length === 0) { throw new HttpsError('internal', 'Respons AI kosong.'); } const text = candidates[0]?.content?.parts?.[0]?.text;`; throw HttpsError jika `text` falsy
- `#90` → untuk bulan berjalan (bulan dan tahun sama dengan `DateTime.now()`), gunakan `min(DateTime.now().day, daysInMonth)` sebagai denominator; untuk bulan lalu gunakan `daysInMonth` penuh: `final elapsedDays = (month.year == DateTime.now().year && month.month == DateTime.now().month) ? DateTime.now().day : daysInMonth;`
- `#91` → di `_SummaryItem.build()`, ganti `color: AppColors.mutedLight` dengan `color: isDark ? AppColors.mutedDark : AppColors.mutedLight`; inject `isDark` via constructor parameter atau akses via `Theme.of(context).brightness`
- `#157` → tambah 3 key baru ke `id.json` (`"tx_filter_all": "Semua"`, `"tx_filter_income": "Masuk"`, `"tx_filter_expense": "Keluar"`) dan `en.json` (`"All"`, `"In"`, `"Out"`); tambah getter `txFilterAll`, `txFilterIncome`, `txFilterExpense` ke `AppLocalizations`; ganti string literal di `_FilterRow._TypeChip` dengan getter tersebut
- `#158` → ganti literal `'Belum ada catatan bulan ini.\nMulai dari satu pengeluaran kecil hari ini.'` di `_LoadedBody` dengan `l10n.emptyStateTransactions`; pertimbangkan update copy key `empty_state_transactions` di `id.json` agar menyertakan konteks "bulan ini": `"Belum ada catatan bulan ini. Mulai dari satu pengeluaran kecil hari ini."`
- `#159` → tambah 2 key baru ke `id.json` (`"tx_date_today": "HARI INI"`, `"tx_date_yesterday": "KEMARIN"`) dan `en.json` (`"TODAY"`, `"YESTERDAY"`); tambah getter `txDateToday`, `txDateYesterday` ke `AppLocalizations`; ganti literal di `_dateHeader()` dengan getter tersebut
- `#160` → (1) ganti array `monthNames` hardcoded dengan `List.generate(12, (i) => DateFormat('MMM', Localizations.localeOf(context).languageCode).format(DateTime(2000, i + 1)))` agar mengikuti locale aktif; atau tambah 12 key `"month_jan"` dst. ke JSON; (2) ganti `DateFormat('MMMM', 'id_ID')` di `_DateChip` dengan `DateFormat('MMMM', Localizations.localeOf(context).languageCode)` — inject context lewat constructor `_DateChip`
- `#161` → refactor dua helper function menjadi satu shared top-level helper `_categoryLabel(AppLocalizations l10n, TransactionCategory cat)` yang menggunakan getter l10n yang sudah ada; mapping: `food→l10n.categoryFood`, `transport→l10n.categoryTransport`, `shopping→l10n.categoryShopping`, `campus→l10n.categoryCampus`, `data→l10n.categoryData`, `fixed→l10n.categoryFixed`, `other→l10n.categoryOther`, `income→l10n.categoryIncome`; untuk enum value `health` yang tidak punya key, tambah `"category_health": "Kesehatan"` / `"Health"` ke JSON dan getter ke `AppLocalizations`

---

## P4 — Polish & Optimisasi

| # | Status | File | Kelemahan | Dampak | Diselesaikan di |
|---|--------|------|-----------|--------|-----------------|
| 17 | 🔲 | `app_database.dart` | **`AppSettings` table melanggar SRP** — gabungkan user preferences (locale, theme) + budget settings (income, paymentDate, fixedExpenses) dalam satu tabel. Schema change di satu memaksa migrate keduanya | Coupling tinggi; migration complexity meningkat di Phase 5+ | Phase 6 |
| 18 | ✅ | `app_router.dart` | **`appRouter` sebagai global mutable state** — `GoRouterRefreshStream` di top-level; sulit di-test, berpotensi stale reference | Testability rendah; potential memory leak | Phase 6C (`createAppRouter()` factory via GetIt) |
| 19 | ✅ | `app_router.dart` | **`_redirect` query DB setiap navigasi** — tidak ada caching `onboardingCompleted`; setiap route change trigger Drift select | Performa pada slow storage devices | Phase 7D |
| 20 | ✅ | `splash_page.dart` | **Splash timeout 1500ms hardcoded** — device sangat lambat atau koneksi buruk: auth stream belum emit, fallback `/login` terpicu, redirect bounce | Edge case UX rusak di perangkat lama | Phase 7F (#172 — `fetchAndActivate().timeout(2s)`) |
| 21 | ✅ | `onboarding_page.dart` | **Widget test `OnboardingPage` belum ada** — hanya BLoC test; UI rendering, form validation, animasi wizard tidak tercover | Bug UI tidak terdeteksi | Phase 6C (4 tests: Steps 1 & 2) |
| 22 | ✅ | `onboarding_page.dart` | **Tidak ada accessibility semantics** — slider, tombol, input tidak punya label untuk screen reader | Tidak accessible untuk pengguna disabilitas | Phase 6C (`_QuickChip`, `_DateSegmentPicker`) |
| 36 | ✅ | `dashboard_repository_impl.dart` | **`watchDashboard()` — 3 async calls serial per stream event** — setiap transaksi baru trigger `getBudgetSettings()` + `getTransactions(monthRange)` + `getTransactions(last7)` secara serial | Dashboard terasa lambat saat banyak transaksi | Phase 6C (`Future.wait`) |
| 37 | ✅ | `dashboard_bloc.dart` | **Duplicate `watchDashboard()` subscription** — `LoadDashboard` dan `DashboardRefreshed` keduanya membuat stream baru via `emit.forEach`; jika concurrent, dua stream aktif bersamaan | Doubled queries; race condition antar state emissions | Phase 5A |
| 38 | ✅ | `dashboard_repository_impl.dart` | **`effectiveDays` fallback ke 30 saat `remainingDays = 0`** — di hari kiriman, `remainingDays = 0` → fallback ke 30; `dailyBudget` terlalu kecil karena dibagi 30 padahal siklus berikutnya belum tentu 30 hari | Kalkulasi anggaran harian tidak akurat di hari kiriman | Phase 5A |

| 42 | ✅ | `onboarding_page.dart` | **Keyboard "Next" di `_ExpenseInputRow` tidak pindah fokus otomatis** — `textInputAction: TextInputAction.next` terpasang tapi tidak ada `FocusNode` chain; Flutter memindahkan fokus ke elemen focusable berikutnya secara arbitrer, bukan ke field Rupiah berikutnya | Input antar kategori tidak smooth; user harus tap manual untuk pindah field — melambat pengisian pada pengguna mobile |
| 43 | ✅ | `onboarding_page.dart` | **Tidak ada auto-focus pada field pertama (Kos/Sewa) di Step 2** — keyboard tidak muncul otomatis saat PageView sliding ke Step 2; spec menyatakan "auto-focus input pertama" | Tambahan satu tap sebelum bisa mulai mengisi; minor friction tapi terasa di UX wizard |
| 44 | ✅ | `onboarding_page.dart` | **Summary card tidak menonjol di dark mode** — gradient menggunakan `AppColors.textLight` (#0B1F14) dan `AppColors.textSoftLight` (#1F3328) di kedua mode; di dark mode background sudah gelap (#0B1F14) sehingga card menyatu dengan layar | Informasi total yang penting (angka terbesar di halaman) tidak terbaca dengan baik di dark mode |
| 45 | ✅ | `onboarding_page.dart` | **Hint "0" di `_ExpenseInputRow` ambigu antara empty state dan nilai nol** — placeholder "0" terlihat seperti angka sudah diisi, bukan field kosong; user bisa mengira semua field sudah punya value default | Minor confusion; berpotensi user skip field yang memang harus diisi (misal Kos/Sewa) karena dikira sudah ada nilainya |
| 59 | ✅ | `onboarding_page.dart` | **Key lokalisasi onboarding terdefinisi di JSON tapi halaman tidak memanggil `AppLocalizations`** — `en.json` dan `id.json` punya `onboarding_income_title`, `onboarding_income_hint`, `onboarding_fixed_title`, `onboarding_fixed_hint`, `onboarding_date_title`; nilainya sama persis dengan string yang di-hardcode di `onboarding_page.dart`. Page tidak import `AppLocalizations`; 5 key JSON tidak memiliki callee | Redundant dead code di JSON files; refactor mudah (< 30 menit) yang akan mengurangi drift antara JSON dan UI copy | Phase 6A |
| 54 | ✅ | `onboarding_page.dart` | **Label "Cicilan dana darurat" di `_CalcRow` Step 3 menggunakan istilah yang miskonsepsi** — "cicilan" berkonotasi hutang/angsuran. Dana darurat adalah alokasi tabungan. Bagi user awam, label ini bisa diinterpretasikan sebagai kewajiban finansial baru | Potensi user salah memahami konsep dana darurat sebagai tagihan; bisa memengaruhi keputusan mengatur slider |
| 55 | ✅ | `onboarding_page.dart` | **`_dailyBudget = 0` saat `remainingDays == 0` tanpa fallback teks di Step 3** — ketika `remainingDays = 0` (hari kiriman), subtext di kalkulasi card menampilkan "≈ Rp 0 / hari" yang membingungkan; seharusnya ada teks seperti "Siklus baru dimulai hari ini" | Edge case minor tapi user yang onboarding tepat di hari kiriman mendapat tampilan tidak informatif |

**Fix yang direkomendasikan:**
- `#59` → Phase 6: di `onboarding_page.dart`, import `AppLocalizations`; ganti 5 string hardcode dengan getter yang sudah ada (`l10n.onboardingIncomeTitle`, `l10n.onboardingIncomeHint`, `l10n.onboardingFixedTitle`, `l10n.onboardingFixedHint`, `l10n.onboardingDateTitle`)
- `#17` → pisah menjadi `UserPreferences` table dan `BudgetSettings` table saat ada migration window; naikkan `schemaVersion` + tambah `onUpgrade` di `MigrationStrategy`
- `#18` → inject router via `GetIt` atau factory function yang di-dispose saat app lifecycle `detached`
- `#19` → cache `bool? _onboardingDone` sebagai in-memory field di `_redirect` closure; invalidate saat event onboarding selesai
- `#20` → expose timeout via `FirebaseRemoteConfig` dengan default 1500ms; atau tambah `AuthLoaded` state yang bisa di-listen sebelum fallback
- `#36` → batch queries: `Future.wait([getBudgetSettings(), getTransactions(month), getTransactions(last7)])`; cache budget settings seperti #33
- `#37` → tambah `transformer: droppable()` ke handler `LoadDashboard`; jadikan `DashboardRefreshed` hanya signal re-compute tanpa membuat stream baru
- `#38` → jika `remainingDays == 0`, hitung `remainingDaysInCycle` untuk siklus berikutnya; atau gunakan `totalDaysInCycle` sebagai denominator tetap
- `#42` → tambah list `_focusNodes` (5 node); pass ke setiap `_ExpenseInputRow` sebagai `focusNode` + `nextFocusNode`; pada `onSubmitted` panggil `nextFocusNode.requestFocus()` atau `FocusScope.of(context).unfocus()` untuk node terakhir
- `#43` → tambah `FocusNode _firstFieldFocus`; di `initState()` post-frame: `WidgetsBinding.instance.addPostFrameCallback((_) => _firstFieldFocus.requestFocus())`
- `#44` → di dark mode, tambahkan `border: Border.all(color: AppColors.borderDark)` pada summary card; atau ubah gradient dark menjadi `[AppColors.surfaceDark, AppColors.borderDark]` agar kontras dengan background
- `#45` → ganti `hintText: '0'` ke `hintText: '—'`; atau tampilkan teks "Kosong (tidak berlaku)" sebagai subtitle saat field masih 0 dan tidak fokus
- `#54` → ganti label "Cicilan dana darurat" → "Alokasi dana darurat" di `_CalcRow`; update copy subtitle slider dari "Cicilan ke dana darurat" → "Dana darurat per bulan"
- `#55` → di `_buildSubtext()`, jika `_dailyBudget == 0` dan `widget.remainingDays == 0`: return `'Siklus baru dimulai hari ini'` sebagai fallback string; jika `_dailyBudget == 0` karena income nol: kembalikan string kosong
- `#60` → Phase 6: tambah `emergencyFundSaved: int` ke `DashboardEntity` (butuh feature tracking tabungan darurat via transaksi bertipe `income` kategori emergency); untuk interim, ubah label card menjadi "ALOKASI DARURAT" + subtitle "per bulan" agar tidak menyiratkan akumulasi
- `#62` → clamp `_safeUntilDate()`: `final safeDays = daysToLive.clamp(0, remainingDays); final date = DateTime.now().add(Duration(days: safeDays));`; tambah suffix "(est.)" jika `daysToLive > remainingDays`
- `#64` → tambah `Text(l10n.navBudget, ...)` di bawah FAB dalam `_BottomNavBar`; atau relabel fungsi FAB sebagai "Catat" agar lebih jelas
- `#65` → di `_RecentTransactionsSection`, ganti `context.push('/transactions')` dengan `widget.onSeeAllTap()` yang di-pass dari parent; parent memanggil `_onNavTap(1)` sehingga index terupdate sebelum navigate
- `#66` → tambah dot indicator `Container(6×6, shape: circle, color: AppColors.caution)` di sudut kanan bawah icon container `_TxnRow` saat `!transaction.isSynced`; identik dengan pola di `TransactionItem`

| 63 | 🔲 | `dashboard_page.dart` | **Bottom nav `_navIndex` tidak sync dengan GoRouter state** — `_navIndex` adalah local state di `_DashboardPageState`; push route via `context.push('/transactions')` tidak memanggil `setState(() => _navIndex = 1)` pada semua path navigasi (termasuk deep link dan "Lihat semua →"). Saat user kembali, index bisa tidak sesuai | Tab indicator tidak mencerminkan posisi aktual user; minor tapi visible di setiap sesi |
| 67 | 🔲 | `days_to_live_card.dart` | **Semantik progress bar DTL card bisa membingungkan** — bar menggunakan rasio `daysToLive / remainingDays`. Bar penuh = uang cukup untuk siklus. Bar pendek = hampir habis. Tanpa label atau tooltip, user yang tidak familiar bisa mengira bar menunjukkan "berapa sudah terpakai" (idiom umum loading/progress) | Potensi misinterpretasi kondisi keuangan; terutama untuk user pertama kali |
| 68 | 🔲 | `dashboard_page.dart` | **`_EmergencyCard` progress bar selalu tampil hampir kosong** — pct = `emergencyFundMonthly / (totalMonthlyBudget + emergencyFundMonthly)`. Untuk alokasi darurat 10% dari income, hasilnya ~9%. Bar selalu kecil walau alokasi sudah sesuai rekomendasi keuangan | Card terkesan "buruk" / meresahkan secara visual walau alokasi sudah tepat |
| 69 | 🔲 | `dashboard_page.dart` | **Pull-to-refresh selesai tanpa feedback visual** — `RefreshIndicator` hilang setelah selesai tanpa snackbar atau konfirmasi apapun. User tidak tahu apakah refresh berhasil, gagal, atau sedang pending | Minor UX: user mungkin pull berulang karena tidak yakin data sudah diperbarui |
| 70 | 🔲 | `dashboard_page.dart` | **Avatar header tidak support foto profil Firebase dan warna tidak adaptif** — `_DashboardHeader` hanya menampilkan inisial dengan background primer. Jika user upload foto via Firebase Auth (`user.photoURL != null`), foto tidak ditampilkan. Warna avatar selalu sama untuk semua user | App terasa kurang personal; foto profil yang sudah diupload user diabaikan sepenuhnya |
| 83 | 🔲 | `onboarding_page.dart` | **`RequestPermission` dispatch dan `context.go('/dashboard')` terjadi berurutan di frame yang sama** — setelah `OnboardingSuccess`, listener dispatch `RequestPermission` lalu langsung `context.go('/dashboard')`. Pada iOS, FCM permission system dialog muncul tapi navigasi sudah terjadi sebelum user merespons. Response user terhadap dialog bisa diproses dalam konteks yang berbeda | Minor UX race: response dialog iOS bisa kehilangan context atau bloc sudah dalam state yang berbeda; permission bisa ter-grant tapi token save tidak dipicu | — |
| 84 | ✅ | `notification_bloc.dart` | **`ScheduleDailyReminder` event tidak pernah di-dispatch dari manapun di app** — event, use case, dan bloc handler tersedia, tapi tidak ada UI (settings page, notifikasi preferences) yang memungkinkan user mengaktifkan atau mengubah waktu reminder. Local daily reminder tidak pernah aktif untuk pengguna nyata | Fitur "Local daily reminder" non-functional dari perspektif user; 3 schema columns orphaned; fitur ada di backend tapi tidak bisa diakses | — |
| 85 | ✅ | `budget_warning.js` | **Full month transaction scan pada setiap transaksi baru** — setiap kali ada transaksi baru, Cloud Function membaca seluruh koleksi transaksi bulan berjalan untuk menghitung total spending. Untuk user aktif dengan 100+ transaksi/bulan, setiap transaksi baru memicu 100+ Firestore document reads | Biaya Firestore meningkat O(n) per transaksi; latency bertambah seiring dengan jumlah transaksi; potensi timeout di akun dengan banyak transaksi | — |
| 96 | ✅ | `insight_card.dart` | **`BorderRadius.circular(12)` hardcoded bukan `AppRadius.md`** — `InsightCard` menggunakan nilai literal `12` untuk border radius container; semua widget lain di codebase menggunakan `AppRadius.md` (= `Radius.circular(12)`) via `BorderRadius.circular(AppRadius.md.x)` atau `RoundedRectangleBorder(borderRadius: BorderRadius.all(AppRadius.md))`. Saat radius sistem berubah, card tidak terupdate otomatis | Minor inconsistency; violates "gunakan AppRadius constants" rule di CLAUDE.md | — |
| 97 | ✅ | `month_selector.dart` | **Next chevron icon menggunakan `AppColors.mutedLight` untuk disabled state di dark mode** — `color: isCurrentMonth ? AppColors.mutedLight : textColor`. `mutedLight` (#6B7264) dipakai di semua mode; di dark mode seharusnya `mutedDark` (#7A8C7E) agar konsisten. Dark mode untuk icon disabled state mengabaikan theme | Visual minor: chevron disable terlihat sedikit off-tone di dark mode; inkonsistensi dengan pola dark mode widget lain yang sudah benar | — |
| 98 | ⚠️ | `weekly_bar_chart.dart` · `category_pie_chart.dart` | **Tidak ada tooltip atau label nilai pada bar chart** — `BarChart` tidak mengkonfigurasi `barTouchData` atau `BarTooltipItem`. User hanya bisa melihat tinggi relatif antar bar; tidak bisa mengetahui nilai pasti pengeluaran setiap minggu. Pie chart juga tidak punya touch interaction (nilai sudah di legend, tapi tidak ada highlight on-tap) | UX kurang informatif; user yang ingin tahu nilai Minggu 3 harus mengestimasi dari ketinggian bar; chart terasa read-only dan tidak interaktif | — |
| 99 | 🔲 | `report_local_datasource.dart` | **`comparedToPreviousMonth == 0.0` menampilkan label "Bulan pertama" walau bukan bulan pertama** — kondisi `prevTotalSpent > 0 ? (totalSpent - prevTotalSpent) / prevTotalSpent : 0.0` menghasilkan 0.0 baik saat bulan pertama (tidak ada data sebelumnya) maupun saat kedua bulan memiliki total pengeluaran Rp 0 (tidak ada transaksi sama sekali). `ReportPage` menampilkan "Bulan pertama" untuk keduanya | Label menyesatkan untuk bulan tanpa transaksi (user puasa, travel, dll.); bisa terjadi setiap kali user buka laporan bulan kosong di masa lalu | — |
| 100 | 🔲 | `functions/src/insights.js` | **`enforceAppCheck: false` — AppCheck tidak diaktifkan untuk Cloud Function AI** — config `onCall({ enforceAppCheck: false })` menonaktifkan client attestation. Auth check (`if (!request.auth)`) masih ada, tapi tanpa AppCheck siapapun yang punya Firebase config valid bisa memanggil function ini dari Postman tanpa device attestation | Keamanan production kurang; potensi abuse (spam ke Vertex AI dengan akun valid); AppCheck seharusnya `true` sebelum production deploy, konsisten dengan function lain (semua masih `false` saat development) | — |
| 110 | 🔲 | `lib/widgets/common/milestone_toast.dart` | **`MilestoneToast.show()` tidak pernah dipanggil dari mana pun** — widget sudah dibangun (A2) tapi tidak ada wiring ke `DashboardBloc`, tidak ada milestone threshold check, tidak ada trigger. Dead widget sejak dibuat | Fitur "milestone celebration" tidak pernah aktif untuk user; konten widget tidak bisa divalidasi fungsional; tidak ada integration test | Phase 6B |
| 111 | 🔲 | `settings_page.dart` | **"Kirim Feedback" `onTap` adalah empty placeholder** — `ListTile` dengan label "Kirim Feedback" di-tap tidak melakukan apa-apa; `onTap: () {}` di-comment sebagai placeholder. Tidak ada `mailto:`, URL launcher, atau form feedback apapun | User yang mau memberi feedback tidak bisa; label ada tapi fungsi nol; misleading UX lebih buruk dari tidak ada sama sekali | Phase 6B |
| 112 | 🔲 | `assets/translations/*.json` · `app_localizations.dart` | **Section headers "NOTIFIKASI" dan "TENTANG" tidak punya l10n key** — `settings_page.dart` menggunakan string hardcode `'NOTIFIKASI'` dan `'TENTANG'` untuk section header. Fix #103 (settings l10n) bergantung pada key-key ini tapi belum tersedia di JSON dan `AppLocalizations` | Prerequisite untuk Fix #103 belum ada; ketika #103 difix, developer harus ingat menambahkan key ini juga; potensi compile error atau missed string | Phase 6B |
| 113 | 🔲 | `settings_bloc.dart` | **`_persist()` melakukan dua DB round-trip tanpa perlu** — `_persist()` pertama memanggil `getSingleOrNull()` untuk membaca row existing, lalu `insertOnConflictUpdate()`. Row `id=1` selalu ada setelah onboarding selesai — read pertama tidak diperlukan. Partial update via `Companion` lebih efisien | Minor performa overhead; dua queries yang bisa dioptimasi menjadi satu; tidak berbahaya tapi bertentangan dengan prinsip lean queries | Phase 6C |

| 114 | ✅ | `functions/src/budget_warning.js` | **`monthKey` dihitung dari UTC, bukan WIB** — `const now = new Date()` di Cloud Functions menghasilkan UTC. Transaksi yang masuk pukul 00:00–06:59 WIB (= 17:00–23:59 UTC hari sebelumnya) akan increment cache ke bulan yang salah. Contoh: transaksi 1 Juni jam 02:00 WIB → `now.getMonth()` = 4 (Mei UTC). Sama dengan bug yang sudah fixed di `daily_reminder.js` (#81) dan `payday_reminder.js` (#82), tapi `budget_warning.js` tidak ikut di-fix | `budgetCache` terisi di key bulan salah → rasio budget warning tidak akurat untuk transaksi dini hari WIB | — |
| 115 | 🔲 | `functions/src/budget_warning.js` | **`budgetCache` tidak di-update saat transaksi diedit atau dihapus** — `onDocumentCreated` hanya trigger saat create; edit/delete tidak men-decrement counter. Running total jadi stale jika user mengoreksi nominal atau menghapus transaksi yang salah | Rasio budget warning berdasarkan total yang tidak akurat; bisa memicu atau tidak memicu notifikasi di waktu yang salah | — |
| 116 | ✅ | `functions/src/budget_warning.js` | **Early return sebelum `cacheRef.set(increment)` jika `fcmToken` null** — baris `if (!fcmToken) return;` ada SEBELUM cache update. User tanpa FCM token (notifikasi dimatikan) tidak pernah men-update budgetCache. Saat mereka re-enable notifikasi, total di cache adalah 0 — warning tidak akan muncul sampai transaksi baru masuk | User re-enable notif tidak mendapat budget warning karena cache reset ke 0; silent gap coverage | — |
| 117 | ✅ | `lib/features/report/presentation/widgets/category_pie_chart.dart` | **`_touchedIndex` tidak di-reset saat bulan berganti** — `StatefulWidget` mempertahankan `_touchedIndex` across rebuild. Saat user navigasi ke bulan sebelumnya, index yang sama highlight section berbeda (data berbeda) | Section yang salah ter-highlight setelah navigasi bulan; tooltip menampilkan data kategori yang tidak sesuai yang di-tap | — |
| 118 | ✅ | `lib/features/report/domain/entities/report_entity.dart` | **`categoryBreakdown.entries` tidak di-sort sebelum spread ke `props`** — urutan Map entries bergantung pada insertion order; dua `ReportEntity` dengan data identik tapi Map berbeda insertion order dianggap tidak equal oleh Equatable → unnecessary BLoC re-emit saat navigasi bulan yang sama dua kali | Potential duplicate state emission; BLoC rebuild tanpa data berubah | — |
| 119 | ✅ | `lib/features/report/presentation/pages/report_page.dart` | **`netBalance == 0` menampilkan `'+ Rp 0'`** — kondisi `report.netBalance < 0 ? '− ' : '+ '` selalu memberi prefix `+` untuk nilai nol | Semantik odd: balance nol seharusnya tidak punya prefix surplus/defisit | Phase 6C |
| 120 | ✅ | `lib/features/report/presentation/widgets/insight_card.dart` | **Skeleton loading pakai `BorderRadius.circular(4)` hardcoded** — shimmer/skeleton di `InsightCard` menggunakan nilai literal 4 untuk border radius, tidak menggunakan `AppRadius` token | Violates "gunakan AppRadius constants" rule; inkonsistensi minor | Phase 6C |
| 121 | ✅ | `lib/features/report/domain/entities/report_entity.dart` | **`copyWith` tidak bisa explicitly null-ify `savingTip`** — `savingTip: savingTip ?? this.savingTip` mencegah passing `null` eksplisit untuk clear field; jika CF refresh tidak mengembalikan `savingTip`, nilai lama tetap tersimpan | Old savingTip persist meski server tidak mengembalikan nilai baru; tidak bisa clear programatically | Phase 6C (sentinel pattern) |

| 122 | 🔲 | `lib/core/database/app_database.dart` | **Migration v3: user existing kehilangan visibility breakdown expense** — `UPDATE app_settings SET other_fixed_expense = fixed_expenses` preserve total, tapi 4 field lain (`rentExpense`, `utilitiesExpense`, `internetExpense`, `phoneExpense`) default 0. Settings UI menampilkan semua sebagai "Lainnya" | UX: user tidak bisa melihat breakdown kos/listrik/internet dari onboarding sebelumnya; semua tampil di "Lainnya" | Phase 6C-fix |
| 123 | ✅ | `lib/core/sync/sync_dispatcher.dart` | **`(op as DeleteOp).path` adalah unsafe cast** — line 27: `final docRef = firestore.doc(op is SetOp ? op.path : (op as DeleteOp).path)`. `FirestoreOp` sealed class tidak punya abstract `path` field. Jika subtype ke-3 ditambahkan tanpa `path`, `CastError` dilempar saat runtime bukan compile time | Fragile pattern; menambahkan subtype baru tidak akan gagal di compile-time tapi crash di production | Phase 6C-fix |
| 124 | ✅ | `lib/features/onboarding/presentation/pages/onboarding_page.dart` | **Missing Semantics di `_ExpenseInputRow` dan Slider** — Phase 6C (#22) menambahkan Semantics di `_QuickChip` dan `_DateSegmentPicker` (Step 1), tapi `_ExpenseInputRow` TextField (Step 2) dan `Slider` emergency fund (Step 3) tidak punya semantic label | Screen reader tidak bisa mengidentifikasi input field di Step 2–3; accessibility fix incomplete | Phase 6C-fix |
| 125 | ✅ | `lib/features/onboarding/presentation/pages/onboarding_page.dart` | **10+ hardcoded Indonesian string tidak tercakup #58** — string validasi ("Masukkan jumlah kiriman yang valid.", "Isi paling tidak satu pengeluaran tetap."), label `_CalcRow` ("Sisa anggaran", "Anggaran harian", dll.), subtext slider, dan label step header tidak di-wire ke `AppLocalizations` meski 40+ key baru sudah ada | Partial localization: page punya `l10n` import tapi masih banyak hardcode; EN mode akan mixed Indonesian/English | Phase 6C-fix |
| 126 | ✅ | `lib/features/onboarding/presentation/pages/onboarding_page.dart` | **`_DateSegmentPicker` Semantics label tidak announce selection state** — label hanya `"Tanggal $date"` atau `"Lain"`, tanpa state "dipilih". Screen reader tidak membedakan mana yang aktif vs tidak | Pengguna screen reader tidak mendapat feedback saat pilihan tanggal berubah | Phase 7 |
| 127 | ✅ | `test/features/report/domain/` | **Tidak ada test untuk `ReportEntity.copyWith()` sentinel pattern** — `static const _sentinel = Object()` dan `identical()` check yang memungkinkan null-ify `savingTip` tidak tercover. Perubahan pattern ini (#121) tidak punya regression guard | Sentinel logic bisa silently break jika ada refactor; tidak terdeteksi tanpa test | Phase 7 |
| 128 | ✅ | `lib/core/routing/app_router.dart` | **`_redirect` akses `sl<AppDatabase>()` tanpa runtime guard** — `createAppRouter()` dipanggil di DI init, tapi closure `_redirect` mengakses `sl<AppDatabase>()` saat runtime. Jika DI belum ready atau DB gagal init, throw `StateError` tanpa graceful fallback | Cold start race potential; uncaught error di routing bisa crash app | Phase 7 |
| 129 | ✅ | `test/features/onboarding/presentation/onboarding_page_test.dart` | **Test tidak verify Semantics labels** — 4 widget test yang ada tidak mengecek `find.bySemanticsLabel()`. Aksesibilitas yang ditambahkan di #22 tidak punya regression test | Semantics bisa hilang tanpa test notice | Phase 7 |
| 130 | ✅ | `lib/core/database/app_database.dart` | **Schema migration SQL defaults tidak dikroscek dengan Dart table `defaultValue`** — kolom baru `rentExpense` dll. memiliki `INTEGER DEFAULT 0` di SQL migration, tapi perlu verified bahwa `IntColumn get rentExpense => integer().withDefault(const Constant(0))()` di Dart table definition juga ada default yang sama | Potential mismatch antara migration SQL dan Dart schema; bisa manifest sebagai null constraint error pada fresh install vs upgrade | Phase 6C-fix (verified) |

| 131 | 🔲 | `lib/core/utils/currency_config.dart` | **`CurrencyConfig.props` tidak menyertakan `compactThousand` dan `compactMillion`** — dua field ini tidak masuk ke equality check; dua config dengan symbol/locale sama tapi compact suffix berbeda (`'rb'` vs `'k'`) dianggap equal oleh Equatable | Equality check tidak lengkap; instans `CurrencyConfig` berbeda compact format bisa lolos sebagai identik; berdampak saat Phase 8B menambah config currency lain | Phase 7-prep-fix |
| 132 | 🔲 | `lib/core/utils/currency_formatter.dart` | **`formatCurrencyCompact` behavioral regression — `.0` suffix untuk jutaan bulat** — `formatCurrencyCompact(2000000, idr)` → `"Rp 2.0jt"` tapi perilaku lama `formatRupiahCompact(2000000)` → `"Rp 2jt"` (tanpa `.0`). `toStringAsFixed(1)` selalu menambahkan satu desimal walau tidak perlu | Tampilan compact berubah untuk semua angka jutaan bulat; regresi UX dari perilaku sebelumnya | Phase 7-prep-fix |
| 133 | 🔲 | `lib/core/database/app_database.dart` | **`Goals.createdAt` dan `Goals.targetDate` pakai `IntColumn` bukan `DateTimeColumn`** — inkonsisten dengan kolom waktu di tabel lain (`Transactions.date`, `Transactions.createdAt`, `AppSettings.onboardingCreatedAt`) yang semuanya pakai `DateTimeColumn`; data layer perlu konversi manual `millisecondsSinceEpoch` ↔ `DateTime` | Inkonsistensi schema; konversi manual rawan error; tidak bisa pakai Drift query builder `dateTime.isBefore()` langsung | Phase 7-prep-fix |
| 134 | 🔲 | `lib/core/utils/currency_formatter.dart` | **`formatCurrencyCompact` tidak handle jumlah negatif dengan benar** — `formatCurrencyCompact(-500000, idr)` → `"Rp -500rb"` (minus di dalam simbol) bukan `"-Rp 500rb"`; tanda minus harus di luar prefix simbol | Tampilan negatif tidak konsisten dengan konvensi standar; prefix Rp seharusnya di luar tanda negatif | Phase 7F |
| 135 | 🔲 | `lib/core/utils/currency_formatter.dart` | **`formatCurrency` membuat instance `NumberFormat` baru setiap panggilan — tidak ada caching** — dalam `ListView` dengan banyak `TransactionItem`, setiap frame build membuat alokasi `NumberFormat` berulang yang tidak perlu | Minor performa overhead; bisa visible pada scroll list panjang dengan 50+ item | Phase 7F |
| 136 | 🔲 | `lib/core/utils/currency_config.dart` | **`CurrencyConfig.fromCode()` case-sensitive: `fromCode('idr')` tidak mengembalikan IDR** — menghasilkan fallback IDR tanpa error atau log; typo kecil atau input dari API dengan casing berbeda menjadi silent mismatch | Saat Phase 8B menambah banyak currency, typo casing menyebabkan silent currency mismatch yang tidak terdeteksi | Phase 7F |
| 137 | 🔲 | `lib/core/database/app_database.dart` | **`Goals` table tidak punya kolom `updatedAt`** — semua tabel data lain (`Transactions`) punya `updatedAt` timestamp; goal yang di-edit judul atau tanggal tidak punya audit trail perubahan terakhir | Tidak bisa sort goals by "recently updated"; tidak ada metadata untuk conflict resolution jika multi-device ditambahkan | Phase 7-prep-fix |
| 138 | 🔲 | `lib/core/database/app_database.dart` | **`PRAGMA foreign_keys = ON` tidak diaktifkan setelah schema v4 menambah `goalId`** — SQLite tidak enforce foreign key secara default; hapus record di `Goals` tanpa unlink transaksi menghasilkan dangling `goalId` di `Transactions` | Orphan `goalId` di Transactions tidak terdeteksi; `savedAmount` query untuk goal yang sudah dihapus diam-diam return 0 tanpa error atau warning | Phase 7F |
| 139 | 🔲 | `test/core/utils/currency_formatter_test.dart` | **Nama test `'formats exact million without decimal'` kontradiksi dengan ekspektasi `'Rp 2.0jt'`** — nama test menyiratkan "tidak ada desimal" tapi assertion expects nilai yang mengandung `.0`; menyesatkan developer yang membaca laporan test | Nama test misleading; developer bisa salah interpret apakah `.0` disengaja atau merupakan bug yang perlu difix | Phase 7-prep-fix |
| 140 | 🔲 | `test/core/utils/currency_formatter_test.dart` | **Tidak ada test untuk nilai negatif di `formatCurrency` dan `formatCurrencyCompact`** — edge case penting untuk tampilan transaksi expense yang bisa negatif | Perilaku untuk amount negatif tidak terdokumentasi dan tidak ter-guard via test | Phase 7F |
| 141 | 🔲 | `test/core/utils/currency_config_test.dart` | **Tidak ada test `fromCode` dengan input lowercase** — `fromCode('idr')` menghasilkan fallback (bukan IDR yang dimaksud) tapi tidak pernah ditest; test yang ada hanya cover `'IDR'` (uppercase) dan `'USD'` (unknown) | Perilaku case-sensitive tidak terdokumentasi dalam test; jika `fromCode` di-update untuk normalize case, tidak ada regression guard | Phase 7F |
| 142 | 🔲 | `lib/core/utils/currency_formatter.dart` | **`formatCurrencyCompact` untuk ribuan menggunakan `toStringAsFixed(0)` — rounding implisit tanpa dokumentasi** — `formatCurrencyCompact(1500, idr)` → `"Rp 2rb"` (pembulatan 1.5 → 2); perilaku banker's rounding tidak eksplisit terdokumentasikan | Tampilan bisa terasa off-by-one bagi user (`"Rp 2rb"` untuk Rp 1.500); acceptable tapi perlu dokumentasi bahwa ini disengaja | Phase 8 |
| 143 | 🔲 | `lib/core/database/app_database.dart` | **SQL `CREATE TABLE IF NOT EXISTS goals` di migration v4 menggunakan multi-line string dengan indentasi leading whitespace** — kosmetik; tidak mempengaruhi runtime tapi inkonsisten dengan migration statement v2/v3 yang pakai format inline | Murni kosmetik; tidak ada dampak runtime | — |
| 170 | 🔲 | `goal_card.dart:110` · `goal_detail_page.dart:173` | **`_progressColor()` logic duplikat di dua file** — method identik (threshold ≥1.0 → success, ≥0.5 → primaryBright, else → caution) didefinisikan terpisah di `GoalCard` dan `GoalDetailPage`. Jika threshold atau token warna berubah, harus update 2 file | DRY violation; perubahan threshold bisa mudah lupa di-update salah satu file | Phase 7F |

**Fix yang direkomendasikan (Post-6B):**
- `#114` → tambah WIB offset di `budget_warning.js`: `const wibOffset = 7 * 60 * 60 * 1000; const wibNow = new Date(Date.now() + wibOffset); const monthKey = \`${wibNow.getUTCFullYear()}_${String(wibNow.getUTCMonth() + 1).padStart(2, '0')}\``
- `#115` → pindah ke `onDocumentWritten` trigger (handle create/update/delete); untuk delete: `FieldValue.increment(-oldAmount)`; untuk update: `FieldValue.increment(newAmount - oldAmount)`; atau terima cache sebagai approximate dan tambah "refresh" tiap awal bulan
- `#116` → pisah cache update dari notif send — hapus early return `if (!fcmToken)` sebelum cache update; hanya skip `fcm.send()` jika no token
- `#117` → tambah `didUpdateWidget` di `_CategoryPieChartState`: `if (widget.breakdown != oldWidget.breakdown) setState(() => _touchedIndex = -1);`
- `#118` → sort entries sebelum spread: `...categoryBreakdown.entries.toList()..sort((a, b) => a.key.name.compareTo(b.key.name)).map((e) => '${e.key.name}:${e.value}')`
- `#119` → ubah kondisi: `report.netBalance <= 0 ? '− ' : '+ '`; atau hilangkan prefix untuk nilai 0
- `#120` → ganti `BorderRadius.circular(4)` → `BorderRadius.circular(AppRadius.sm.x)` di skeleton container
- `#121` → gunakan sentinel pattern: tambah optional parameter `clearSavingTip: bool = false`; atau ubah ke nullable parameter dengan `Object? savingTip = _keep` sentinel

**Fix yang direkomendasikan (Post-6C):**
- `#122` → tambahkan migration notice di `SettingsPage` saat semua breakdown 0 tapi `otherFixedExpense > 0`: tampilkan banner "Rincian pengeluaran tetap belum diatur. Ketuk untuk mengisi."; atau, saat upgrade dari v2→v3, set `rentExpense = fixed_expenses` (bukan `other_fixed_expense`) jika semua breakdown 0
- `#123` → tambah abstract getter `String get path` ke sealed class `FirestoreOp`; update `SetOp` dan `DeleteOp` untuk override-nya; line 27 jadi `firestore.doc(op.path)` tanpa cast
- `#124` → wrap tiap `_ExpenseInputRow` TextField dengan `Semantics(label: l10n.fieldLabel, textField: true, child: ...)`, atau set `semanticLabel` di `TextField`; untuk `Slider` tambah `semanticFormatterCallback: (v) => '${v.round()}%'` atau wrap dengan `Semantics(label: 'Dana darurat ${v}%')`
- `#125` → buat key l10n baru untuk validation messages, calc row labels, dan slider subtext; wire di `onboarding_page.dart`; tambah padanan di `en.json` dan getter di `AppLocalizations`
- `#126` → update Semantics label di `_DateSegmentPicker`: `label: isSelected ? '${semanticLabel}, dipilih' : semanticLabel`
- `#127` → buat `test/features/report/domain/report_entity_test.dart`; test: `copyWith(savingTip: null)` returns null, `copyWith()` tanpa arg preserve original, `copyWith(savingTip: 'new')` update value
- `#128` → wrap `sl<AppDatabase>()` di `_redirect` dalam try-catch; return null (no redirect) jika sl belum siap; atau gunakan `sl.isRegistered<AppDatabase>()` guard
- `#129` → tambahkan `testWidgets('QuickChip has semantics label', ...)` di onboarding test; gunakan `find.bySemanticsLabel()` untuk verify `_QuickChip` dan `_DateSegmentPicker`
- `#130` → tambah `// SYNC-CHECK: migration SQL harus match Dart default` komentar di migration; atau buat test Drift `verifySchemaVersion` yang checks default values

**Fix yang direkomendasikan (Phase 7-prep-fix — wajib sebelum 7B/7C):**
- `#132` → di `formatCurrencyCompact`: `final val = amount % 1000000 == 0 ? (amount / 1000000).toStringAsFixed(0) : (amount / 1000000).toStringAsFixed(1)`; sehingga `2000000` → `"Rp 2jt"` dan `1200000` → `"Rp 1.2jt"`; fix test name bersamaan: `'formats exact million without decimal'` → `'formats exact million as integer suffix'` dan update ekspektasi ke `'Rp 2jt'`
- `#131` → tambah `compactThousand` dan `compactMillion` ke `CurrencyConfig.props`: `@override List<Object> get props => [code, symbol, locale, decimalDigits, compactThousand, compactMillion];`
- `#133` + `#137` → (batch satu build_runner run) ubah `Goals.createdAt` dan `Goals.targetDate` ke `DateTimeColumn`: `DateTimeColumn get createdAt => dateTime()();` dan `DateTimeColumn get targetDate => dateTime()();`; tambah `DateTimeColumn get updatedAt => dateTime()();` untuk `#137`; update migration SQL v4 untuk mencerminkan perubahan; jalankan `dart run build_runner build` sekali setelah semua perubahan
- `#139` → setelah fix `#132`, update nama test di `currency_formatter_test.dart`: ganti `'formats exact million without decimal'` → `'formats exact million as integer suffix'`; update ekspektasi dari `'Rp 2.0jt'` → `'Rp 2jt'`

**Fix yang direkomendasikan (Phase 7C-fix — goal feature, P3):**
- `#168` → buat l10n keys baru: `goalStatusActive` (`"Sedang berjalan"` / `"Active"`), `goalActionComplete` (`"Tandai tercapai"` / `"Mark complete"`), `goalActionDelete` (`"Hapus tujuan"` / `"Delete goal"`), `goalDeleteTitle` (`"Hapus Tujuan"` / `"Delete Goal"`), `goalDeleteBtn` (`"Hapus"` / `"Delete"`), `goalLinkGuide` (kalimat instruksi linking); tambah ke `id.json`, `en.json`, dan getter `AppLocalizations`; wire di `goal_detail_page.dart`

**Fix yang direkomendasikan (Phase 7F — goal tech debt):**
- `#167` → ubah `_GoalProgressBar` menjadi `StatefulWidget`; tambah field `double _prevPercent = 0`; di `didUpdateWidget`: simpan nilai animasi terakhir ke `_prevPercent` saat widget rebuild; gunakan `Tween(begin: _prevPercent, end: percent)` agar animasi mulai dari nilai posisi saat ini bukan dari 0
- `#169` → rewrite `loadGoals()` dengan single Drift join query: `_db.select(_db.goals).join([leftOuterJoin(_db.transactions, _db.transactions.goalId.equalsExp(_db.goals.id) & _db.transactions.amount.isBiggerThanValue(0))]) ..addColumns([_db.transactions.amount.sum()]) ..groupBy([_db.goals.id])`; eliminasi `Future.wait` loop N queries
- `#170` → pindahkan `_progressColor(double pct)` ke `GoalEntity` sebagai getter atau ke `lib/core/utils/goal_color_utils.dart` sebagai top-level function; hapus definisi duplikat dari `goal_card.dart` dan `goal_detail_page.dart`; import dari satu tempat

**Fix yang direkomendasikan (Phase 7F — tech debt):**
- `#134` → di `formatCurrencyCompact`: tambah guard awal `final isNegative = amount < 0; final absAmount = amount.abs();`; proses dengan `absAmount`; kembalikan `isNegative ? '-${result}' : result`; pastikan tanda minus selalu di luar prefix Rp
- `#135` → buat static atau `const`-like cache `Map<String, NumberFormat>` di `currency_formatter.dart`; gunakan `_formatterCache.putIfAbsent(config.locale, () => NumberFormat.currency(...))` sebagai factory; atau buat `CurrencyConfig.formatter` getter yang di-cache di dalam class
- `#136` → di `CurrencyConfig.fromCode()`: tambah `.toUpperCase()` normalisasi: `static CurrencyConfig fromCode(String code) => registry[code.toUpperCase()] ?? idr;`; tambah test `fromCode('idr')` → `CurrencyConfig.idr` ke `currency_config_test.dart`
- `#138` → aktifkan PRAGMA FK di `MigrationStrategy.beforeOpen`: `beforeOpen: (details) async { await customStatement('PRAGMA foreign_keys = ON'); }`; sudah ada pattern ini di `phase7-plan.md` — tinggal apply ke `app_database.dart`
- `#140` → tambah test group `'negative amounts'` di `currency_formatter_test.dart`: test `formatCurrency(-100000, idr)` dan `formatCurrencyCompact(-100000, idr)` untuk dokumentasikan perilaku yang diharapkan
- `#141` → tambah `test('fromCode falls back to IDR for lowercase code', () { expect(CurrencyConfig.fromCode('idr'), CurrencyConfig.idr); });` ke `currency_config_test.dart` (akan fail sampai #136 di-fix)

**Fix yang direkomendasikan (P4 dashboard):**
- `#63` → gunakan `StatefulNavigationShell` dari go_router v7+ untuk shell route dengan bottom nav yang auto-sync; atau wrap setiap navigate call dengan `setState(() => _navIndex = targetIdx)`
- `#67` → tambah label di bawah bar: teks caption kecil "`$daysToLive dari $remainingDays hari aman`"; atau tambah titik anotasi kiri/kanan bar
- `#68` → ubah denominator menjadi total income (`emergencyFundMonthly / monthlyIncome`); memerlukan `monthlyIncome` di `DashboardEntity`; atau hitung dari `totalMonthlyBudget + fixedExpenses + emergencyFundMonthly`
- `#69` → setelah `onRefresh` selesai, tampilkan `ScaffoldMessenger.showSnackBar(SnackBar(content: Text('Data diperbarui'), duration: Duration(seconds: 1)))`
- `#70` → di `_DashboardHeader`: cek `user?.photoURL != null`; jika ada tampilkan `CircleAvatar(backgroundImage: NetworkImage(url))`; jika tidak, generate background color dari hash nama: `AppColors.primary` / `AppColors.caution` / `AppColors.success` bergantian
- `#83` → setelah `OnboardingSuccess`, dispatch `RequestPermission` tapi tunda navigasi: `context.read<NotificationBloc>().add(const RequestPermission()); await Future.delayed(const Duration(milliseconds: 100)); if (mounted) context.go('/dashboard');`; atau navigasi langsung dan handle permission di `NotificationBloc` tanpa blokir navigasi
- `#84` → tambahkan `NotificationSettingsPage` atau section di settings page yang memungkinkan user toggle reminder on/off dan pilih jam; dispatch `ScheduleDailyReminder(hour: h, minute: m)` dari UI tersebut; aktifkan reminder secara default (20:00) saat `RequestPermission` berhasil di `_onRequestPermission`
- `#85` → simpan running total pengeluaran bulan ini di dokumen `users/{uid}/meta/monthlyStats` (increment via `FieldValue.increment()`); `budgetWarning` hanya baca satu dokumen stats, tidak perlu scan transaksi. Update stats dari Cloud Function lain atau client-side saat transaksi di-commit
- `#96` → ganti `BorderRadius.circular(12)` dengan `BorderRadius.circular(AppRadius.md.x)` atau `BorderRadius.all(AppRadius.md)` di `InsightCard`
- `#97` → ganti `AppColors.mutedLight` ke `isDark ? AppColors.mutedDark : AppColors.mutedLight` untuk disabled state chevron; inject `isDark` dari `Theme.of(context).brightness`
- `#98` → tambahkan `barTouchData: BarTouchData(enabled: true, touchTooltipData: BarTouchTooltipData(getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(formatRupiah(rod.toY.round()), AppTextStyles.caption.copyWith(color: Colors.white))))` ke `BarChartData`; similar untuk `PieChart`: tambah `pieTouchData` dengan callback highlight section
- `#99` → gunakan nullable prev comparison: return `null` dari kalkulasi jika `prevTotalSpent == 0` untuk membedakan "bulan pertama" dari "bulan kosong"; tambah field `comparedToPreviousMonth: double?` (nullable); di `ReportPage`: `comparedPct == null → 'Bulan pertama'`; `comparedPct == 0.0 → '±0% dari bulan lalu'`
- `#100` → ubah ke `enforceAppCheck: true` sebelum production deploy (semua 4 Cloud Functions); tambah konfigurasi AppCheck di `main.dart` dan Firebase Console; saat ini `false` di semua functions — ubah secara bersamaan agar tidak ada inkonsistensi
- `#110` → di `DashboardBloc`, tambah `_prevDaysToLive` tracking; setelah `watchDashboard()` emit state baru: jika `daysToLive > 14 && _prevDaysToLive <= 14`, emit event internal; `BlocListener<DashboardBloc>` di `DashboardPage` panggil `MilestoneToast.show(context, l10n.milestoneMessage)`; tambah key `milestone_message` ke JSON
- `#111` → tambah `url_launcher` package; `onTap: () => launchUrl(Uri.parse('mailto:devanoahmadd@gmail.com?subject=Feedback+Penyintas'))` atau buka URL Google Form; atau tampilkan `AlertDialog` "Fitur segera hadir" sebagai sementara
- `#112` → tambah ke `id.json`: `"settings_section_notification": "NOTIFIKASI"`, `"settings_section_about": "TENTANG"`; ke `en.json`: `"settings_section_notification": "NOTIFICATIONS"`, `"settings_section_about": "ABOUT"`; tambah getter ke `AppLocalizations`; selesaikan ini sebelum Fix #103
- `#113` → di `_persist()`, hapus `getSingleOrNull()` call; gunakan langsung `(_db.update(_db.appSettings)..where((t) => t.id.equals(1))).write(companion)`; jika perlu upsert semantics gunakan `into(_db.appSettings).insertOnConflictUpdate(companion)` langsung tanpa read awal

---

## Roadmap Penanganan

### Phase 5A — ✅ Selesai (2026-05-08)

**Semua 16 item diselesaikan:**

| # | Item |
|---|------|
| ✅ | `#23` Logo SVG fix |
| ✅ | `#24` `todayTransactions` di `props` |
| ✅ | `#25` Fixed expenses double-counting |
| ✅ | `#26` `onError` Crashlytics dashboard |
| ✅ | `#27` Wire `SyncService.dispose()` ke app lifecycle |
| ✅ | `#28` TTL 7 hari di sync queue |
| ✅ | `#29` BudgetBar animasi dari nilai sebelumnya |
| ✅ | `#30` `emergencyFundPct` di `OnboardingStep3` state |
| ✅ | `#37` `restartable()`/`droppable()` transformer di DashboardBloc |
| ✅ | `#38` `daysInCycle()` fallback, bukan hardcode 30 |
| ✅ | `#4` `onConnectivityChanged` pakai `asyncMap(isConnected)` |
| ✅ | `#15` Global `catch (_)` → `catch (e, s)` + Crashlytics |
| ✅ | `#31` 12 unit tests untuk `_compute()` |
| ✅ | `#33` Settings cache di `watchDashboard()` |
| ✅ | `#34` `DashboardRefreshed` conditional |
| ✅ | `#35` "DAYS TO LIVE" → localization key |
| ⚠️ | `#32` SyncDispatcher test — deferred ke Phase 6 |

**Catatan teknis:**
- `bloc_concurrency ^0.3.0` (bukan `^0.2.0`) — konflik dengan `bloc_test ^10`
- `fake_cloud_firestore ^3` inkompatibel dengan `cloud_firestore ^6.3.0` → #32 deferred

### Phase 5B — ✅ Selesai (2026-05-11)

**Onboarding polish — 17 item:**

| # | Step | Item | Status |
|---|------|------|--------|
| `#46` | 1 | Hapus validasi `maxDay` untuk `paymentDate` recurring | ✅ |
| `#47` | 3 | DTL preview card: label & nilai yang akurat | ✅ |
| `#48` | 3 | Pin CTA "Mulai Bertahan" ke bawah layar | ✅ |
| `#49` | 3 | Warning saat `fixedExpenses >= income` | ✅ |
| `#39` | 2 | `AutomaticKeepAliveClientMixin` — preserve state saat back | ✅ |
| `#41` | 2 | Clear `_submitError` saat user mengetik | ✅ |
| `#51` | 1 | Clear `_incomeError` saat `onChanged` & `onClear` | ✅ |
| `#52` | 3 | `_DotFormatter` untuk field target dana darurat | ✅ |
| `#50` | 1 | `_dailyIncome` preview pakai `daysInCycle()` | ✅ |
| `#53` | 1 | `_DatePickerSheet` tandai tanggal 29–31 + footnote | ✅ |
| `#42` | 2 | `FocusNode` chain antar 5 field expense | ✅ |
| `#43` | 2 | Auto-focus field pertama saat Step 2 mount | ✅ |
| `#44` | 2 | Kontras summary card dark mode | ✅ |
| `#45` | 2 | Hint text "—" gantikan "0" | ✅ |
| `#54` | 3 | Label "Alokasi dana darurat" gantikan "Cicilan" | ✅ |
| `#55` | 3 | Fallback teks saat `_dailyBudget = 0` di hari kiriman | ✅ |
| `#56` | — | `dashboard_days_to_live` → "Hari Aman" di `id.json` | ✅ |

**Dashboard quick wins — 6 item:**

| # | Item | Status |
|---|------|--------|
| `#61` | Fallback "transaksi terkini" ke last7 jika hari ini kosong | ✅ |
| `#62` | Clamp `_safeUntilDate()` agar tidak melampaui akhir siklus | ✅ |
| `#64` | Label "Catat" di bawah FAB bottom nav | ✅ |
| `#65` | "Lihat semua →" routing lewat `_onNavTap(1)` | ✅ |
| `#66` | Sync dot indicator di `_TxnRow` | ✅ |
| `#57` | Key `category_income` di JSON + `categoryIncome` getter | ✅ |

**Fitur scope asli 5B — Notification Feature:** ✅ Selesai (kode 90/90 tests) · ⚠️ Bug ditemukan (#71–#85, wajib fix sebelum release)

### Phase 5B-fix — ✅ Selesai (2026-05-12)

| # | Priority | Item | Status |
|---|----------|------|--------|
| `#71` | P1 | Panggil `initialize()` di `_onInit` dengan real `onTap` callback | ✅ |
| `#72` | P1 | Fix `budget_warning.js` compound query: hapus inequality `category !=`, filter di JS | ✅ |
| `#73` | P1 | Fix cron `daily_reminder.js`: ubah ke `'0 20 * * *'` + timezone Jakarta | ✅ |
| `#74` | P2 | Simpan dan cancel `onMessageOpenedApp` subscription di `close()` | ✅ |
| `#75` | P2 | Wire `onTap` callback ke `NotificationBloc.add(NotificationTapped(...))` | ✅ |
| `#76` | P2 | Read/write `reminderEnabled/Hour/Minute` dari DB; reschedule on `InitNotification` | ✅ |
| `#77` | P2 | Fix cron `payday_reminder.js`: ubah ke `'0 7 * * *'` + timezone Jakarta | ✅ |
| `#78` | P2 | Reset `notifStatus` di awal bulan (inline check + simpan `month` field) | ✅ |

### Phase 5C — ✅ Selesai (2026-05-12)

**Report Feature:** kalkulasi bulanan + AI insight via Vertex AI + fl_chart PieChart+BarChart

| # | Komponen | Status |
|---|----------|--------|
| — | `ReportEntity` + `WeeklySpendEntity` + use cases | ✅ |
| — | `ReportLocalDatasourceImpl` (kalkulasi Drift) | ✅ |
| — | `ReportRemoteDatasourceImpl` (Cloud Function + Firestore cache) | ✅ |
| — | `ReportBloc` (4 events, droppable transformer) | ✅ |
| — | `ReportPage` + 4 widgets (MonthSelector, PieChart, BarChart, InsightCard) | ✅ |
| — | `functions/src/insights.js` + `functions/src/index.js` | ✅ |
| — | Routing `/report` + DI + Dashboard nav case 3 | ✅ |
| — | 19 test baru → 109/109 total | ✅ |

**Analisis pasca-implementasi:** +15 issue baru ditemukan (#86–#100)

| # | Priority | Item |
|---|----------|------|
| `#86` | P1 | Field name mismatch antara Dart client dan `insights.js` — AI selalu menerima data kosong |
| `#87` | P1 | Cache key format mismatch (0-indexed JS vs 1-indexed Dart) — 24h cache tidak pernah berfungsi |
| `#88` | P2 | `JSON.parse()` tanpa sanitasi markdown fence — crash pada LLM response tidak patuh |
| `#89` | P2 | Unsafe `candidates[0].content.parts[0].text` — crash saat safety filter/quota |
| `#90` | P2 | `dailyAverageSpend` pakai total hari bulan, bukan hari yang sudah berjalan |
| `#91` | P2 | `_SummaryItem` label hardcode `AppColors.mutedLight` — dark mode contrast issue |
| `#92` | P3 | `Map<TransactionCategory, int>` di Equatable `props` — reference equality, bukan value |
| `#93` | P3 | `savingTip` dari Cloud Function tidak pernah disimpan/ditampilkan |
| `#94` | P3 | `netBalance.abs()` tanpa sign indicator — defisit tidak terbaca tanpa warna |
| `#95` | P3 | `_categoryColors` hardcoded Material colors — melanggar AppColors token rule |
| `#96` | P4 | `BorderRadius.circular(12)` hardcoded bukan `AppRadius.md` |
| `#97` | P4 | Month selector disabled chevron pakai `mutedLight` di dark mode |
| `#98` | P4 | Tidak ada tooltip/interaksi pada bar dan pie chart |
| `#99` | P4 | `comparedToPreviousMonth == 0.0` label "Bulan pertama" palsu untuk bulan tanpa transaksi |
| `#100` | P4 | `enforceAppCheck: false` — production hardening belum dilakukan |

### Phase 5C-fix — ✅ Selesai (2026-05-12)

P1 dan P2 dari Phase 5C; 109/109 tests tetap passing setelah semua fix.

| # | Priority | Item | Status |
|---|----------|------|--------|
| `#86` | P1 | Fix field name mismatch `insights.js` ↔ Dart client | ❌ Obsolete — false positive, kode sudah benar |
| `#87` | P1 | Fix cache key: gunakan `transactions?.month` dari client (1-indexed) | ✅ `insights.js` rewrite |
| `#88` | P2 | `safeParseJson()` helper — strip markdown fence sebelum `JSON.parse()` | ✅ `insights.js` rewrite |
| `#89` | P2 | Null guard pada `candidates` dan `text` dari Vertex AI response | ✅ `insights.js` rewrite |
| `#90` | P2 | `elapsedDays` untuk bulan berjalan vs `end.day` untuk bulan lalu | ✅ `report_local_datasource.dart` |
| `#91` | P2 | `_SummaryItem` label: `isDark ? mutedDark : mutedLight` | ✅ `report_page.dart` |

### Phase 6A — ✅ Selesai (2026-05-19)

Settings Page + UI Polish, MilestoneToast, l10n fixes, notification dead code cleanup. 109/109 tests.

| # | Item | Status |
|---|------|--------|
| **A1** | Settings Page UI: theme/language `RadioGroup`, reminder `SwitchListTile` + `TimePicker` | ✅ |
| **A2** | `MilestoneToast` widget (`lib/widgets/common/milestone_toast.dart`) | ✅ |
| `#59` | Wire 5 onboarding JSON keys ke `onboarding_page.dart` via `AppLocalizations` | ✅ |
| `#60` | Label "CICILAN DARURAT" → "ALOKASI DARURAT" di `assets/translations/id.json` | ✅ |
| `#79` | Hapus `showNotification()` dead code dari datasource abstract + impl | ✅ |
| `#80` | Hapus `getFcmToken()` + `initialize()` dari domain interface + impl | ✅ |
| — | Router `/settings` → `SettingsPage()` (was `_PlaceholderPage`) | ✅ |

**Analisis pasca-implementasi:** +13 issue baru ditemukan (#101–#113)

| # | Priority | Item |
|---|----------|------|
| `#101` | P1 | `_onCancel()` mengabaikan Either result, tidak emit state apapun |
| `#102` | P2 | `SettingsPage` tidak punya `BlocListener` untuk `NotificationBloc` |
| `#103` | P3 | Seluruh teks `SettingsPage` hardcoded — tidak berubah saat ganti bahasa |
| `#104` | P3 | `onboardingIncomeHint` dipetakan ke `label:` (floating label), bukan `hintText:` |
| `#105` | P3 | `_loadReminder()` query DB langsung dari widget — violates Clean Architecture |
| `#106` | P3 | `_reminderLoaded` flag tidak melindungi "NOTIFIKASI" section header |
| `#107` | P3 | `MilestoneToast` tidak punya `margin` — toast tertutup bottom nav |
| `#108` | P3 | Copy onboarding di `id.json` kehilangan tone percakapan original |
| `#109` | P3 | Version string `'v0.1.0+1'` hardcoded di widget |
| `#110` | P4 | `MilestoneToast.show()` tidak dipanggil dari mana pun — dead widget |
| `#111` | P4 | "Kirim Feedback" `onTap` adalah empty placeholder |
| `#112` | P4 | Section headers "NOTIFIKASI"/"TENTANG" tidak punya l10n key |
| `#113` | P4 | `_persist()` melakukan dua DB round-trip yang tidak perlu |

**6A-fix sprint (wajib selesai sebelum 6B):**

| # | Priority | Item | Status |
|---|----------|------|--------|
| `#101` | P1 | `_onCancel()` Either check + emit `NotificationCancelled` | ✅ 6A-fix |
| `#102` | P2 | Tambah `BlocListener<NotificationBloc>` di `SettingsPage` | ✅ 6A-fix |
| `#104` | P3 | `onboardingIncomeHint` pindah ke `hintText:`, buat key `onboardingIncomeLabel` | ✅ 6A-fix |
| `#106` | P3 | Guard "NOTIFIKASI" header dengan `_reminderLoaded` | ✅ 6A-fix |
| `#107` | P3 | Tambah `margin` ke `MilestoneToast` SnackBar | ✅ 6A-fix |

### Phase 6B — ✅ Selesai (2026-05-20)

Cloud Functions WIB timezone fix, Report Polish, savingTip chain. 109/109 tests.

| # | Priority | Item | Status |
|---|----------|------|--------|
| `#81` | P3 | WIB midnight fix di `daily_reminder.js` | ✅ |
| `#82` | P3 | WIB date fix di `payday_reminder.js` | ✅ |
| `#83` (plan) | P3 | iOS: 300ms delay sebelum `getToken()` di `notification_bloc.dart` | ✅ (bukan #83 tracker) |
| `#84` | P3 | `ScheduleDailyReminder` UI trigger di Settings page | ✅ (6A) |
| `#85` | P4 | `budget_warning.js` → running total cache via `FieldValue.increment` | ✅ |
| `#92` | P3 | `ReportEntity.props` — Map entries spread sebagai string | ✅ |
| `#93` | P3 | `savingTip` chain: entity → datasource → repo → usecase → bloc → widget | ✅ |
| `#94` | P3 | `netBalance` tampil dengan prefix `− ` / `+ ` | ✅ |
| `#95` | P3 | `CategoryPieChart` pakai `AppColors` (ganti Material colors) | ✅ |
| `#96` | P4 | `InsightCard` `BorderRadius.circular(12)` → `AppRadius.md` | ✅ |
| `#97` | P4 | `MonthSelector` chevron disabled: `mutedLight` → dark-aware `mutedColor` | ✅ |
| `#98` | P4 | `CategoryPieChart` → `StatefulWidget` + `pieTouchData` tooltip | ⚠️ (pie ✅, bar 🔲) |
| `#99` tracker | P4 | `comparedToPreviousMonth == 0.0` label palsu | 🔲 Deferred ke 6C |
| `#100` tracker | P4 | `enforceAppCheck: false` di `insights.js` | 🔲 Deferred ke 6C |

**Analisis pasca-implementasi:** +8 issue baru ditemukan (#114–#121)

| # | Priority | Item |
|---|----------|------|
| `#114` | P2 | `budget_warning.js` monthKey pakai UTC, bukan WIB — cache salah bulan |
| `#115` | P2 | `budgetCache` tidak update saat transaksi diedit/dihapus |
| `#116` | P2 | Early return sebelum cache increment jika `fcmToken` null |
| `#117` | P3 | `_touchedIndex` tidak reset saat bulan berganti di `CategoryPieChart` |
| `#118` | P3 | `categoryBreakdown.entries` tidak di-sort — urutan Map tidak stabil di `props` |
| `#119` | P4 | `netBalance == 0` menampilkan `'+ Rp 0'` |
| `#120` | P4 | `InsightCard` skeleton pakai `BorderRadius.circular(4)` hardcoded |
| `#121` | P4 | `copyWith` tidak bisa null-ify `savingTip` |

**6B-fix sprint — ✅ Selesai (2026-05-20):**

| # | Priority | Item | Status |
|---|----------|------|--------|
| `#114` | P2 | `budget_warning.js` monthKey WIB fix | ✅ |
| `#116` | P2 | Pisah cache update dari early return fcmToken check | ✅ |
| `#117` | P3 | `didUpdateWidget` reset `_touchedIndex` di `CategoryPieChart` | ✅ |
| `#118` | P3 | Sort `categoryBreakdown.entries` sebelum spread ke `props` | ✅ |

> `#115` adalah keputusan desain (cache approximate vs exact) — defer ke Phase 8 (multi-currency redesign akan refactor Cloud Functions secara menyeluruh).

### Phase 6C — ✅ Selesai (2026-05-20)

119/119 tests · 0 flutter analyze issues.

| # | Priority | Item | Status |
|---|----------|------|--------|
| `#40` | P3 | Schema v3: 5 kolom expense breakdown + migration + `fixedExpenses` → computed getter | ✅ |
| `#32` | P3 | `toFirestoreOp()` pure fn (sealed `FirestoreOp`) + 6 unit tests | ✅ |
| `#36` | P4 | `Future.wait` di `watchDashboard()` | ✅ |
| `#58` | P3 | AppLocalizations: `context.l10n` ext + 40+ keys + 5 pages wired | ✅ |
| `#21` | P4 | Widget test `OnboardingPage` — 4 tests Steps 1 & 2 | ✅ |
| `#22` | P4 | Accessibility: `_QuickChip` + `_DateSegmentPicker` Semantics | ✅ |
| `#18` | P4 | `createAppRouter()` factory injectable via GetIt | ✅ |
| `#119` | P4 | `netBalance == 0` fix | ✅ |
| `#120` | P4 | `InsightCard` skeleton `AppRadius.sm` | ✅ |
| `#121` | P4 | `copyWith()` sentinel pattern untuk `savingTip` | ✅ |
| `#17` | P4 | ~~Split AppSettings tabel~~ | ↩ Defer → Phase 8A |
| `#19` | P4 | Cache `onboardingCompleted` | ↩ Defer → Phase 7 |
| `#20` | P4 | Splash timeout via RemoteConfig | ↩ Defer → Phase 7 |

**Analisis pasca-implementasi:** +9 issue baru ditemukan (#122–#130)

### Phase 6C-fix — ✅ Selesai (2026-05-20)

127/127 tests · 0 flutter analyze issues.

| # | Priority | Item | Status |
|---|----------|------|--------|
| `#122` | P1 | Settings UI: migration v3 collapse semua ke "Lainnya" untuk user existing | ⚠️ Defer → Phase 8 (budget breakdown UI belum ada di Settings) |
| `#123` | P1 | `sync_dispatcher.dart:27` unsafe cast — abstract `path` getter harus ditambahkan ke `FirestoreOp` | ✅ Phase 6C-fix — `String get path` ditambah ke `FirestoreOp`; `@override` di subclass; line 27 jadi `op.path` |
| `#124` | P2 | Missing Semantics di `_ExpenseInputRow` (Step 2) dan `Slider` (Step 3) | ✅ Phase 6C-fix — `Semantics(label: name)` wrap TextField; `Semantics(label:, value:)` wrap Slider |
| `#125` | P2 | 10+ hardcoded string di `onboarding_page.dart` tidak tercakup #58 | ✅ Phase 6C-fix — 21 key baru di id.json/en.json + AppLocalizations; semua validate/eyebrow/row strings dipakai |
| `#126` | P3 | `_DateSegmentPicker` Semantics label tidak announce selection state | ✅ Phase 6C-fix — `label: isSelected ? '\$semanticLabel, dipilih' : semanticLabel` |
| `#127` | P3 | Tidak ada test `ReportEntity.copyWith()` sentinel | ✅ Phase 6C-fix — 5 unit tests di `test/features/report/domain/report_entity_test.dart` |
| `#128` | P3 | `_redirect` akses `sl<AppDatabase>()` tanpa runtime guard | ✅ N/A — existing try-catch di `_redirect` menangkap StateError dan redirect ke `/login` |
| `#129` | P3 | `onboarding_page_test.dart` tidak verify Semantics labels | ✅ Phase 6C-fix — 3 Semantics tests: button chips, expense row labels, dipilih suffix |
| `#130` | P3 | Schema migration SQL defaults tidak dikroscek dengan Dart table definition | ✅ Verified — SQL `DEFAULT 0` konsisten dengan `withDefault(const Constant(0))` di semua 5 kolom |

### Phase 7-prep — ✅ Selesai (2026-05-20)

143/143 tests · 0 flutter analyze issues · +16 test baru.

| Komponen | Status |
|----------|--------|
| `currency_config.dart` FILE BARU — `CurrencyConfig.idr`, registry, `fromCode()` | ✅ |
| `currency_formatter.dart` — `formatCurrency()`, `formatCurrencyCompact()`, shim `formatRupiah()` | ✅ |
| `currency_config_test.dart` (5 tests) + `currency_formatter_test.dart` (11 tests) | ✅ |

**Analisis pasca-implementasi:** +8 issue baru ditemukan (#131–#138).

| # | Priority | Item |
|---|----------|------|
| `#131` | P3 | `CurrencyConfig.props` tidak menyertakan `compactThousand`/`compactMillion` |
| `#132` | P3 | `formatCurrencyCompact` regression: `"Rp 2.0jt"` bukan `"Rp 2jt"` untuk jutaan bulat |
| `#133` | P3 | `Goals.createdAt` dan `Goals.targetDate` pakai `IntColumn` bukan `DateTimeColumn` |
| `#134` | P3 | `formatCurrencyCompact` tidak handle negatif dengan benar (`"Rp -500rb"` bukan `"-Rp 500rb"`) |
| `#135` | P4 | `formatCurrency` membuat `NumberFormat` baru setiap panggilan — tidak ada caching |
| `#136` | P3 | `fromCode()` case-sensitive: `fromCode('idr')` fallback silent bukan IDR |
| `#137` | P4 | `Goals` table tidak punya kolom `updatedAt` |
| `#138` | P3 | `PRAGMA foreign_keys = ON` tidak diaktifkan setelah schema v4 tambah `goalId` |

**7-prep-fix sprint (wajib sebelum 7B/7C):** `#132` → `#131` → `#133+#137` (batch satu build_runner) → `#139`

### Phase 7A — ✅ Selesai (2026-05-20)

143/143 tests · 0 flutter analyze issues · schema v4 applied.

| Komponen | Status |
|----------|--------|
| `Goals` table baru (id, title, targetAmount, targetDate, isCompleted, createdAt) | ✅ |
| `Transactions.goalId INTEGER NULL` | ✅ |
| `AppSettings.survivalModeActivatedAt INTEGER NULL` | ✅ |
| `schemaVersion == 4` | ✅ |
| Migration raw SQL `customStatement` (konsisten dengan v2/v3) | ✅ |
| `dart run build_runner build` — 124 outputs, 0 error | ✅ |

**Analisis pasca-implementasi:** +5 issue baru ditemukan (#139–#143).

| # | Priority | Item |
|---|----------|------|
| `#139` | P4 | Test name `'formats exact million without decimal'` kontradiksi ekspektasi `'Rp 2.0jt'` |
| `#140` | P4 | Tidak ada test untuk nilai negatif di `formatCurrency`/`formatCurrencyCompact` |
| `#141` | P4 | Tidak ada test `fromCode` dengan input lowercase |
| `#142` | P4 | `formatCurrencyCompact` ribuan pakai `toStringAsFixed(0)` — rounding implisit |
| `#143` | P4 | SQL migration v4 multi-line whitespace — kosmetik |

### Phase 7-prep-fix — ✅ Selesai (2026-05-21)

143/143 tests · 0 flutter analyze issues.

| # | Priority | Item | Status |
|---|----------|------|--------|
| `#132` | P3 | `formatCurrencyCompact` jutaan bulat → `"Rp 2.0jt"` bukan `"Rp 2jt"` | ✅ `truncateToDouble()` check |
| `#131` | P3 | `CurrencyConfig.props` tidak menyertakan `compactThousand`/`compactMillion` | ✅ tambah ke props |
| `#133` | P3 | `Goals.createdAt`/`targetDate` pakai `IntColumn` bukan `DateTimeColumn` | ✅ diganti DateTimeColumn |
| `#137` | P4 | `Goals` table tidak punya kolom `updatedAt` | ✅ ditambahkan |
| `#139` | P4 | Test name misleading + ekspektasi salah | ✅ nama + ekspektasi diperbaiki |

### Phase 7B — ✅ Selesai (2026-05-21)

153/153 tests · 0 flutter analyze issues · +10 test baru (survival_bloc_test.dart).

**Analisis pasca-implementasi:** +13 issue baru ditemukan (#144–#156).

| # | Priority | File | Kelemahan | Dampak |
|---|----------|------|-----------|--------|
| `#144` | **P1** | `survival_repository_impl.dart` · `survival_remote_datasource.dart` | **`on Exception` tidak menangkap `TypeError`/`CastError`** — cast `result.data['tips'] as List` dan `.cast<Map<String, dynamic>>()` melempar `TypeError` (extends `Error`, bukan `Exception`) saat CF mengembalikan data malformed. `on Exception` tidak menangkap `Error` subtype → exception propagates uncaught ke BLoC → potensial crash UI atau BLoC error yang tidak ter-handle | App crash saat AI mengembalikan format tidak terduga |
| `#145` | **P2** | `survival_bloc.dart` | **`_recordActivated()` dan `_clearActivated()` tidak di-`await`** — line 42 & 46 memanggil Future tanpa `await`. Fire-and-forget: (a) jika DB write gagal, error diam-diam dibuang; (b) `activatedAt` timestamp tidak reliabel tersimpan; (c) next app open, `activatedAt` masih `null` → `_recordActivated()` dipanggil lagi → timestamp reset setiap buka app | `activatedAt` tidak pernah tersimpan dengan reliabel; record/clear timestamp gagal silent |
| `#146` | **P2** | `survival_repository_impl.dart` | **`catch (_)` di semua 4 method — tidak ada Crashlytics logging** — semua handler memakai `catch (_)` (error detail dibuang) atau `on Exception` tanpa logging. Violasi fix #15 Phase 5A | Error di layer data tidak terdeteksi di Crashlytics; debugging production sangat sulit |
| `#147` | P3 | `survival_mode_entity.dart` | **`copyWith()` tidak bisa null-ify `activatedAt`** — `activatedAt: activatedAt ?? this.activatedAt` tidak bisa di-override ke `null`. Sentinel pattern yang sama sudah difix di #121 untuk `ReportEntity.savingTip` | Tidak bisa membuat copy entity dengan `activatedAt = null` via `copyWith` |
| `#148` | P3 | `survival_tips_page.dart` · `survival_mode_banner.dart` | **Pakai `formatRupiah`/`formatRupiahCompact` bukan `formatCurrency`/`formatCurrencyCompact`** — violasi aturan 7-prep: "semua file Phase 7 baru langsung pakai `formatCurrency()`". File terdampak: `_SummaryCard` (line 224, 232), `_TipCard` (line 317), `SurvivalModeBanner` (line 55) | Ketidakkonsistenan — saat Phase 8G migrasi ke dynamic currency, file ini harus diupdate manual |
| `#149` | P3 | `survival_tips_page.dart` · `survival_mode_banner.dart` | **10+ string hardcoded tidak ada di `AppLocalizations`** — `'Tips Bertahan'`, `'TIPS HEMAT UNTUKMU'`, `'SISA ANGGARAN'`, `'untuk X hari · disarankan'`, `'Hemat ~/hari'`, `'Coba lagi'` di page; `'Mode Hemat Aktif'`, `'Lentur dulu. Kita lewati minggu ini bersama.'`, `'Sisa ... untuk X hari.'`, `'Lihat tips hemat →'` di banner | UI tidak berubah saat ganti bahasa ke English; inkonsisten dengan Phase 6C fix #58 |
| `#150` | P3 | `survival_tips_page.dart` | **Empty state tidak ada saat `entity.tips.isEmpty` setelah load** — jika AI mengembalikan `[]` kosong dan state menjadi `SurvivalTipsLoaded`, `_TipsBody` menampilkan list kosong tanpa pesan apapun | Layar kosong tanpa feedback ke user saat AI gagal menghasilkan tips |
| `#151` | P3 | `survival_bloc.dart` | **`SurvivalTipsLoading` state tidak dipreservasi saat dashboard refresh** — `_onLoad` hanya cek `state is SurvivalTipsLoaded` untuk preserve tips; jika state adalah `SurvivalTipsLoading` (fetch sedang berjalan) dan dashboard refresh masuk, bloc emit `SurvivalActive` — overwrite loading state → `SurvivalTipsPage` berkedip dari loading → aktif → loaded | Flicker UI saat dashboard refresh bersamaan dengan fetch tips yang sedang berjalan |
| `#152` | P4 | `injection_container.dart` · `survival_bloc.dart` | **`SurvivalBloc` singleton tidak di-reset saat logout** — `registerLazySingleton` mempertahankan instance dan state antar sesi. Jika user A punya tips cached (`SurvivalTipsLoaded`), lalu logout, lalu user B login — `FetchSurvivalTips` tidak re-fetch karena guard `if (state is SurvivalTipsLoaded) return` | User B singkat melihat tips milik user A (data leak antar akun di shared device) |
| `#153` | P4 | `survival_tips_page.dart` | **`_ErrorBody.isLoading` dead parameter** — parameter diterima constructor tapi tidak dipakai sama sekali di `build()`. Selalu dipanggil dengan `isLoading: false` | Dead code — confusing bagi pembaca |
| `#154` | P4 | `survival_mode_banner.dart` | **`GestureDetector` tidak punya `Semantics`** — banner yang bisa di-tap (saat `onTap != null`) tidak diumumkan sebagai elemen interaktif oleh screen reader. Tidak ada label aksesibilitas | Tidak accessible bagi pengguna dengan keterbatasan visual (TalkBack/VoiceOver) |
| `#155` | ✅ | `survival_tips_page.dart` | **Blank screen untuk `SurvivalInitial`/`SurvivalInactive` state** — `BlocBuilder` mengembalikan `SizedBox.shrink()` untuk state yang tidak dikenali. User bisa membuka `/survival/tips` saat tidak dalam survival mode (back navigation) dan melihat halaman kosong | UX buruk; tidak ada pesan penjelasan atau auto-navigate back | Hotfix 2026-05-26 |
| `#156` | P4 | `test/features/survival/` | **Tidak ada unit test untuk data layer** — tidak ada test untuk `SurvivalRepositoryImpl`, `SurvivalLocalDatasource`, `SurvivalRemoteDatasource`. Hanya `survival_bloc_test.dart` yang ada | Coverage rendah untuk layer data Survival Mode; bug seperti #144/#145 tidak ter-detect via test |

**7B-fix sprint ✅ SELESAI (2026-05-21):**

| # | Priority | Item | Status |
|---|----------|------|--------|
| `#144` | P1 | Fix `on Exception` → `catch (e, s)` di `getSurvivalTips` repo + guard cast di remote datasource | ✅ Selesai |
| `#145` | P2 | `await _recordActivated()` + `await _clearActivated()` di `_onLoad` | ✅ Selesai |
| `#146` | P2 | Tambah Crashlytics logging di semua catch handler `SurvivalRepositoryImpl` | ✅ Selesai |
| `#147` | P3 | `SurvivalModeEntity.copyWith()` sentinel `_kSentinel` untuk `activatedAt` | ✅ Selesai |
| `#148` | P3 | Ganti `formatRupiah`/`formatRupiahCompact` → `formatCurrency`/`formatCurrencyCompact` di 2 file | ✅ Selesai |
| `#149` | P3 | Pindah 8 string ke `AppLocalizations` (id.json + en.json) | ✅ Selesai |
| `#150` | P3 | Tambah `_EmptyTipsState` saat `entity.tips.isEmpty` | ✅ Selesai |
| `#151` | P3 | Preserve `SurvivalTipsLoading` saat `LoadSurvivalMode`; refactor `_onLoad` keluar dari fold | ✅ Selesai |
| `#152` | P4 | Reset `SurvivalBloc` state saat logout | ↩ Defer 7F |
| `#153` | P4 | Hapus `isLoading` dead parameter dari `_ErrorBody` | ↩ Defer 7F |
| `#154` | P4 | Tambah `Semantics` ke `SurvivalModeBanner` GestureDetector | ↩ Defer 7F |
| `#155` | P4 | Tambah fallback UI untuk `SurvivalInitial`/`SurvivalInactive` di `SurvivalTipsPage` | ✅ Selesai (Hotfix 2026-05-26) |
| `#156` | P4 | Unit test: `SurvivalRepositoryImpl` + `SurvivalLocalDatasource` | ↩ Defer 7F |

### Phase 7C — ✅ Selesai (2026-05-21)

175/175 tests · 0 flutter analyze issues · +22 test baru (goal_bloc_test, goal_list_page_test, goal_detail_page_test).

| Komponen | Status |
|----------|--------|
| `GoalBloc` (6 events, `restartable`/`droppable`) + 10 unit tests | ✅ |
| `savedAmount` computed via JOIN query di `GoalRepositoryImpl` | ✅ |
| Milestone detection (25/50/75/100%) di `GoalBloc._onUpdate` | ✅ |
| `GoalListPage` + `GoalCard` + `AddGoalSheet` | ✅ |
| `_GoalPicker` di `AddTransactionSheet` — link transaksi ke goal | ✅ |
| Router `/goals` + `/goals/:id` + DI | ✅ |

**Analisis pasca-implementasi (1 — transaksi screen):** +5 issue baru ditemukan (#157–#161).

| # | Priority | File | Kelemahan |
|---|----------|------|-----------|
| `#157` | P3 | `transaction_list_page.dart` | Filter chip labels `'Semua'`/`'Masuk'`/`'Keluar'` hardcoded; tidak ada l10n key |
| `#158` | P3 | `transaction_list_page.dart` | Empty state hardcoded; key `emptyStateTransactions` tersedia tapi tidak digunakan |
| `#159` | P3 | `transaction_list_page.dart` | Date headers `'HARI INI'`/`'KEMARIN'` hardcoded; tidak ada l10n key |
| `#160` | P3 | `transaction_list_page.dart` | Month picker singkatan bulan + locale `id_ID` hardcoded di dua tempat |
| `#161` | P3 | `transaction_item.dart` · `add_transaction_sheet.dart` | 8 label kategori hardcoded; keys sudah ada di `AppLocalizations` sejak #57 tapi tidak dipakai |

**Analisis pasca-implementasi (2 — Goal feature):** +9 issue baru ditemukan (#162–#170).

| # | Priority | File | Kelemahan | Effort |
|---|----------|------|-----------|--------|
| `#162` | **P1** | `add_transaction_sheet.dart` · 3 caller | GoalPicker tidak muncul — `activeGoals` tidak di-pass; seluruh fitur Goal mati total | XS |
| `#163` | **P1** | `add_goal_sheet.dart` | `_submit()` pop sebelum tunggu hasil — error saving goal silent | S |
| `#164` | P2 | `goal_detail_page.dart` | GoalDetailPage stale data setelah aksi (CompleteGoal, linking baru) | M |
| `#165` | P2 | `goal_bloc.dart` · `add_transaction_bloc.dart` | Milestone tidak trigger dari flow `AddTransactionSheet` | M |
| `#166` | P2 | `goal_bloc.dart:123` | `_onUnlink()` tidak memanggil repository — silent no-op | XS |
| `#167` | P3 | `goal_card.dart` | `TweenAnimationBuilder` restart dari 0 setiap rebuild | S |
| `#168` | P3 | `goal_detail_page.dart` | 7+ string hardcoded non-l10n | S |
| `#169` | P3 | `goal_local_datasource.dart` | N+1 query pattern di `loadGoals()` | M |
| `#170` | P4 | `goal_card.dart` · `goal_detail_page.dart` | `_progressColor()` duplikat di 2 file | XS |

### Phase 7C-fix — ✅ Selesai (2026-05-21)

**175/175 tests · flutter analyze: 0 issues**

| # | Priority | Item | Effort | Status |
|---|----------|------|--------|--------|
| `#162` | **P1** | Pass `activeGoals` ke `AddTransactionSheet` di 3 caller | XS | ✅ |
| `#163` | **P1** | `AddGoalSheet`: tambah `BlocListener`, hapus premature `pop()` | S | ✅ |
| `#164` | P2 | `GoalDetailPage`: baca goal live dari `GoalBloc` state | M | ✅ |
| `#165` | P2 | Reload `GoalBloc` setelah `AddTransactionSheet` saved = true | M | ✅ |
| `#166` | P2 | `_onUnlink()`: tambah panggilan repo sebelum reload | XS | ✅ |
| `#168` | P3 | `GoalDetailPage`: wire 7 string ke l10n keys baru | S | ✅ |

**Catatan arsitektur:**
- `GoalBloc` diubah dari `registerFactory` → `registerLazySingleton` (mirip `SurvivalBloc`)
- `UnlinkTransactionUseCase` baru dibuat di `lib/features/goal/domain/usecases/`
- 8 l10n keys baru ditambah: `goal_detail_*` dan `goal_date_picker_hint`
- Router `/goals` route berubah dari `BlocProvider(create:...)` → `BlocProvider.value(value: sl<GoalBloc>())`

**Defer ke Phase 7F:**

| # | Priority | Item |
|---|----------|------|
| `#167` | P3 | `TweenAnimationBuilder` begin dari `_prevPercent` |
| `#169` | P3 | Rewrite `loadGoals()` jadi single JOIN query |
| `#170` | P4 | Konsolidasi `_progressColor()` ke satu lokasi |

### Phase 7D — ✅ Selesai (2026-05-21)

175/175 tests · 0 flutter analyze issues.

| Komponen | Status |
|----------|--------|
| `home_widget: ^0.9.1` ditambahkan ke pubspec.yaml | ✅ |
| `PenyintasWidgetProvider.kt` — `onUpdate`, warna adaptif per `BudgetStatus`, tap intent | ✅ |
| `penyintas_widget.xml` — layout 2×1 (DTL angka + budget) | ✅ |
| `penyintas_widget_info.xml` + `widget_background.xml` + `strings.xml` | ✅ |
| `AndroidManifest.xml` — `<receiver>` + `<meta-data>` terdaftar | ✅ |
| `DashboardBloc._pushToWidget()` — fire-and-forget chain, change guard record | ✅ |
| Konstanta string key widget di `dashboard_bloc.dart` (`_kWidgetDaysToLive`, dll.) | ✅ |

### Phase 7E — ✅ Selesai (2026-05-21)

180/180 tests · 0 flutter analyze issues · +5 test baru.

| Komponen | Status |
|----------|--------|
| `share_plus: ^10.0.0` ditambahkan ke pubspec.yaml | ✅ |
| `ReportPage` → `StatefulWidget` + `GlobalKey _shareKey` + `_shareReport()` | ✅ |
| `RepaintBoundary(key: shareKey)` membungkus summary card dengan header bulan + watermark | ✅ |
| Screenshot: `toImage(pixelRatio: 3.0)` → temp PNG → `Share.shareXFiles([XFile(...)])` | ✅ |
| Cleanup temp file via `finally { await file.delete().catchError((_) => file); }` | ✅ |
| Single `BlocBuilder<ReportBloc>` wrapping seluruh Scaffold (konsolidasi dari 3) | ✅ |
| Settings: seksi "EKSPOR DATA" + `_exportCsv()` → CSV → `Share.shareXFiles()` | ✅ |
| CSV: header `tanggal,kategori,nominal,catatan,goal_id`; note field di-escape dengan `""` | ✅ |

### Phase 7F — ✅ Selesai (2026-05-21)

180/180 tests · 0 flutter analyze issues · +5 test baru.

| # | Priority | Item | Status |
|---|----------|------|--------|
| `#19` | P4 | Cache `_onboardingDone` di router — sudah ada `_onboardingDone ??= ...` + `null` on logout | ✅ (sudah ada sejak sebelumnya) |
| `#20` | P4 | Splash timeout via RemoteConfig — `setDefaults` + `getInt` + clamp 1500–8000ms | ✅ |
| `#134` | P3 | `formatCurrencyCompact` negatif: `isNeg = amount < 0`, proses `abs`, prefix `-` | ✅ |
| `#135` | P4 | `NumberFormat` cache via `_fmtCache.putIfAbsent(config.code, ...)` | ✅ |
| `#136` | P3 | `fromCode()` case-insensitive via `code.toUpperCase()` | ✅ |
| `#138` | P3 | `PRAGMA foreign_keys = ON` aktif di `MigrationStrategy.beforeOpen` | ✅ |
| `#140` | P4 | Test group `'negative amounts'` (4 test baru) di `currency_formatter_test.dart` | ✅ |
| `#141` | P4 | Test `fromCode` lowercase/mixedcase (1 test baru) di `currency_config_test.dart` | ✅ |
| `#167` | P3 | `TweenAnimationBuilder` begin dari `_prevPercent` di `GoalCard` | ↩ Defer → Phase 8 |
| `#169` | P3 | Rewrite `loadGoals()` jadi single JOIN query | ↩ Defer → Phase 8 |
| `#170` | P4 | Konsolidasi `_progressColor()` | ↩ Defer → Phase 8 |
| `#152–#156` | P4 | Survival Mode tech debt (singleton reset, dead param, Semantics, fallback, test) | ↩ Defer → Phase 8 |

**Analisis pasca-implementasi Phase 7D/7E/7F:** +11 issue baru ditemukan (#171–#181).

| # | Priority | File | Kelemahan | Dampak |
|---|----------|------|-----------|--------|
| `#171` | **P2** | `settings_page.dart` | **`_exportCsv()` tidak cleanup temp file setelah share** — `_shareReport()` memakai `finally { file.delete() }` tapi `_exportCsv()` tidak. Setiap export meninggalkan file CSV di temp dir. | Temp dir menumpuk file; inkonsisten dengan pattern `_shareReport()` | ✅ fixed inline |
| `#172` | **P2** | `splash_page.dart` | **`_startSplashTimer()` hanya set defaults, tidak fetch RemoteConfig dari server** — `rc.setDefaults(...)` + `rc.getInt(...)` tanpa `await rc.fetchAndActivate()`. Nilai dari Firebase Console tidak pernah terambil. | Fitur #20 (kontrol splash via RemoteConfig) tidak berfungsi — selalu 2500ms | ✅ fixed inline (+ 2s timeout) |
| `#173` | P3 | `android/.../drawable/widget_background.xml` | **Widget background tidak ada dark mode variant** — selalu `#FBFAF6` (bgLight). Tidak ada `drawable-night/` counterpart. | Widget tampak terang di dark mode Android — jarring, tidak konsisten |
| `#174` | P3 | `android/.../layout/penyintas_widget.xml` | **Label "hari"/"tersisa" hardcoded bahasa Indonesia** — `android:text="hari"` dan `android:text="tersisa"` tidak pakai `@string/` resource. Widget tidak mengikuti locale user. | User English tetap lihat "hari tersisa" — inkonsisten dengan UI app |
| `#175` | P3 | `PenyintasWidgetProvider.kt` | **Warna DTL hardcoded hex** — `Color.parseColor("#E07A3C")`, `"#D4A93C"`, `"#0F7A3E"` inline. Jika color token berubah, Kotlin dan Dart harus di-update terpisah. | Risiko divergensi warna brand antara app dan widget |
| `#176` | P3 | `report_page.dart` · `settings_page.dart` | **Share/export strings tidak l10n** — share subject `'Laporan Keuangan Penyintas $month'` hardcoded Indonesia; label ListTile `'Export Transaksi (CSV)'` mixing English ("Export" bukan "Ekspor"). | User English mendapat teks Indonesian saat share dialog; inkonsistensi copy |
| `#177` | P4 | `PenyintasWidgetProvider.kt` | **Widget tap tidak selalu buka DashboardPage** — Intent hanya launch `MainActivity`, GoRouter tidak tahu halaman tujuan. Jika app di background di halaman lain, user tidak langsung ke dashboard. | UX tidak konsisten; widget harusnya selalu buka dashboard |
| `#178` | P4 | `android/.../layout/penyintas_widget.xml` | **`android:layout_marginLeft` deprecated** — harus `android:layout_marginStart` untuk RTL layout support. | RTL locale tidak mendapat margin yang benar | ✅ fixed inline (sekaligus dgn #181) |
| `#179` | P4 | `report_page.dart` | **Tidak ada loading state saat share report screenshot** — `toImage(pixelRatio: 3.0)` + file write bisa butuh 300–800ms tanpa feedback. Tombol share tidak disabled selama proses. | User bisa tap berulang → multiple concurrent `_shareReport()` → multiple share dialogs |
| `#180` | **P3** | `pubspec.yaml` | **`home_widget 0.8.0+` menarik Glance alpha → build gagal** — `home_widget 0.8.0` memperkenalkan Jetpack Compose Glance sebagai opsi Android widget, yang menarik `androidx.glance:glance-appwidget:1.3.0-alpha01`. Library alpha ini memerlukan AGP 9.1.0+ dan compileSdk 37+, sedangkan project menggunakan AGP 8.11.1 dan `compileSdk = flutter.compileSdkVersion` (36). App gagal build dengan error `checkDebugAarMetadata` setiap `flutter pub get` resolve ke versi ≥0.8.0. Fix: pin `">=0.5.1 <0.8.0"` → resolves ke `0.7.0+1`. `PenyintasWidgetProvider.kt` pakai classic `AppWidgetProvider` (bukan Compose/Glance) sehingga 0.7.0+1 kompatibel penuh. | Build gagal total — app tidak bisa dijalankan sama sekali saat constraint naik ke ≥0.8.0 | ✅ fixed inline (pin `">=0.5.1 <0.8.0"`) |
| `#181` | **P1** | `android/.../layout/penyintas_widget.xml` | **`android.view.View` dilarang di RemoteViews API 31+ → widget selalu "can't load widget"** — Android 12+ (API 31+) menerapkan allowlist ketat untuk class yang boleh di-inflate di RemoteViews (proses renderer terpisah). `android.view.View` (base class) tidak masuk allowlist — hanya concrete subclass seperti `TextView`, `LinearLayout`, `FrameLayout`, `ImageView` yang diizinkan. Layout widget memakai dua `<View>`: (1) spacer `layout_height="6dp"` sebelum baris DTL; (2) divider `layout_height="1dp"` antara DTL dan budget. Keduanya menyebabkan `InflateException: Class not allowed to be inflated android.view.View` setiap launcher mencoba render widget. Diagnosed via `adb logcat -d \| grep AppWidgetHostView` pada emulator API 37 (Android 16). Fix: (a) hapus spacer `<View>` → tambah `android:layout_marginTop="6dp"` ke DTL LinearLayout; (b) ganti divider `<View>` → `<FrameLayout android:layout_height="1dp" android:background="#E2DCC8" />`; (c) sekaligus fix #178: `marginLeft` → `marginStart`. | Widget render gagal total di semua perangkat API 31+ (Android 12+) — "can't load widget" di home screen | ✅ fixed inline (FrameLayout + marginTop + marginStart) |

### Hotfix — 2026-05-26

3 issue baru ditemukan dan langsung diperbaiki, + 1 deferred issue (#155) sekaligus diselesaikan.

| # | Priority | File | Kelemahan | Fix |
|---|----------|------|-----------|-----|
| `#182` | P2 | `settings_page.dart` · `saya_page.dart` | `ListTile` wrapped `Container(BoxDecoration(color:...))` — no `Material` ancestor, ink splash assertion + non-functional tap feedback | `Container` → `Material(color, clipBehavior, shape: RoundedRectangleBorder(side: BorderSide(...)))` di `_CardContainer` dan 2 card section saya_page ✅ |
| `#183` | P1 | `app_router.dart:109–116` | Sub-route `/goals/:id` builder calls `context.read<GoalBloc>()` — GoRouter routing context tidak mewarisi `BlocProvider.value` dari parent `pageBuilder` → `ProviderNotFoundException`, tap goal tidak respond | `context.read<GoalBloc>()` → `sl<GoalBloc>()` (lazySingleton, instance sama) ✅ |
| `#184` | P1 | `app_router.dart:61–73` | `/dashboard` route pakai `BlocProvider(create:...)` → `close()` dipanggil pada `DashboardBloc` lazySingleton saat stack di-replace via `context.go('/survival/tips')`. Return ke dashboard: `add(LoadDashboard())` pada closed bloc → `StateError` → force close | `BlocProvider(create:...)` → `BlocProvider.value(value: sl<DashboardBloc>())` — singleton tidak pernah ditutup oleh widget ✅ |
| `#155` | P4 | `survival_tips_page.dart` | `BlocBuilder` return `SizedBox.shrink()` untuk `SurvivalInitial`/`SurvivalInactive` — halaman blank tanpa penjelasan, terlihat "not responding" | Tambah `_InactiveBody` widget: ikon shield + judul + deskripsi singkat ✅ |

---

## Sumber Data

- `PROMPT.md` §Analisis Kelemahan Phase 1–3 (item #1–22)
- `PROMPT.md` §Analisis Kelemahan Phase 4 (item #23–38)
- `PROMPT.md` §Deviasi dari Rencana Awal Phase 4
- `docs/drift-migration-plan.md` — status selesai item #32 (sebagian)
- Analisis manual kode Phase 5B notification (item #71–#85): `notification_local_datasource.dart`, `notification_remote_datasource.dart`, `notification_repository_impl.dart`, `notification_bloc.dart`, `daily_reminder.js`, `budget_warning.js`, `payday_reminder.js`
- Analisis manual kode Phase 5C report (item #86–#100): `report_entity.dart`, `report_local_datasource.dart`, `report_remote_datasource.dart`, `report_repository_impl.dart`, `report_bloc.dart`, `report_page.dart`, `category_pie_chart.dart`, `weekly_bar_chart.dart`, `insight_card.dart`, `month_selector.dart`, `functions/src/insights.js`
- Analisis manual kode Phase 6C (item #122–#130): `app_database.dart` (migration v3), `sync_dispatcher.dart` (unsafe cast), `onboarding_page.dart` (Semantics gap + hardcoded strings), `report_entity.dart` (sentinel test gap), `app_router.dart` (sl guard)
- Analisis manual kode Phase 7-prep & 7A (item #131–#143): `currency_config.dart` (props gap, case-sensitivity), `currency_formatter.dart` (compact regression, negative, caching), `app_database.dart` (Goals IntColumn vs DateTimeColumn, missing updatedAt, PRAGMA FK), test files (nama misleading, coverage gap)
- Analisis manual kode Phase 7B (item #144–#156): `survival_repository_impl.dart` (catch gap, Crashlytics), `survival_remote_datasource.dart` (unsafe cast), `survival_bloc.dart` (unawaited calls, state preservation, singleton reset), `survival_mode_entity.dart` (copyWith sentinel), `survival_tips_page.dart` (formatRupiah usage, hardcoded strings, empty state, dead param, blank fallback), `survival_mode_banner.dart` (formatRupiah usage, hardcoded strings, Semantics), test coverage gap
- Analisis manual kode transaksi screen Phase 7C (item #157–#161): `transaction_list_page.dart` (filter chips hardcode, empty state key unused, date headers hardcode, month picker locale hardcode), `transaction_item.dart` + `add_transaction_sheet.dart` (8 label kategori hardcode, keys l10n ada tapi tidak dipakai)
- Analisis manual Goal feature Phase 7C (item #162–#170): `add_transaction_sheet.dart` + 3 caller (activeGoals tidak di-pass → GoalPicker mati total), `add_goal_sheet.dart` (premature pop sebelum tunggu hasil), `goal_detail_page.dart` (stale data, hard-coded strings, _progressColor duplikat), `goal_bloc.dart` (_onUnlink no-op, milestone tidak trigger dari AddTransactionSheet), `goal_card.dart` (TweenAnimationBuilder restart dari 0, _progressColor duplikat), `goal_local_datasource.dart` (N+1 query pattern)
- Analisis manual Phase 7D/7E/7F (item #171–#179): `settings_page.dart` (CSV temp file tidak di-cleanup), `splash_page.dart` (RemoteConfig tidak fetchAndActivate → fitur mati), `widget_background.xml` (tidak ada dark mode variant), `penyintas_widget.xml` (label bahasa hardcoded, marginLeft deprecated), `PenyintasWidgetProvider.kt` (warna hex hardcoded, tap intent tidak deep link ke dashboard), `report_page.dart` (share subject non-l10n, tidak ada loading guard), `settings_page.dart` (label "Export" bukan "Ekspor")
- Build error saat run app Phase 7D (item #180): `pubspec.yaml` — `home_widget ^0.9.1` (versi awal 7D) resolve ke 0.9.1 yang menarik `androidx.glance:glance-appwidget:1.3.0-alpha01`; butuh AGP 9.1+ dan compileSdk 37+; project pakai AGP 8.11.1/compileSdk 36 → `checkDebugAarMetadata` error; fix: pin `">=0.5.1 <0.8.0"` → `home_widget 0.7.0+1`
- Runtime bug widget Phase 7D (item #181): diagnosed via `adb logcat -d | grep AppWidgetHostView` pada emulator API 37 — `InflateException: Class not allowed to be inflated android.view.View`; `penyintas_widget.xml` memakai dua `<View>` (spacer + divider) yang tidak diizinkan RemoteViews API 31+; fix: `<FrameLayout>` + `android:layout_marginTop` + `android:layout_marginStart` (sekaligus fix #178)
- Hotfix 2026-05-26 (item #182–#184 + #155): #182 — runtime assertion `ListTile` tanpa `Material` ancestor (`_CardContainer` + 2 card section `saya_page.dart`), fixed → `Material(shape: RoundedRectangleBorder(...))`; #183 — `ProviderNotFoundException` saat tap goal item, sub-route builder memanggil `context.read<GoalBloc>()` pada GoRouter routing context, fixed → `sl<GoalBloc>()`; #184 — `DashboardBloc` lazySingleton ditutup paksa via `BlocProvider(create:...)` saat `context.go('/survival/tips')` replace stack, return ke dashboard → `StateError: Cannot add event after calling close`, fixed → `BlocProvider.value(value: sl<DashboardBloc>())`; #155 — `SurvivalTipsPage` blank screen untuk `SurvivalInitial`/`SurvivalInactive`, fixed → `_InactiveBody` widget dengan pesan informatif
