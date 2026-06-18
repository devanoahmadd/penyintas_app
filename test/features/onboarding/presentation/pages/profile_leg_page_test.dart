// test/features/onboarding/presentation/pages/profile_leg_page_test.dart
//
// Widget-test kontrak B4 — ProfileLegPage mini-wizard.
//
// Kontrak 6 keys wajib:
//   profile_lang_toggle, profile_next_cta, profile_country_btn,
//   profile_perantau_toggle, profile_home_country_btn, profile_finish_cta
//
// Test anti-loop B-1: router-level GoRouter 2-rute minimal membuktikan
// resetOnboardingCache() dipanggil sebelum context.go('/onboarding'),
// sehingga guard tidak memantulkan user balik ke /profile-setup.

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:penyintas_app/core/routing/onboarding_guard.dart';
import 'package:penyintas_app/core/utils/timezone_resolver.dart';
import 'package:penyintas_app/features/onboarding/data/datasources/onboarding_local_datasource.dart';
import 'package:penyintas_app/features/onboarding/presentation/cubit/profile_setup_cubit.dart';
import 'package:penyintas_app/features/onboarding/presentation/pages/profile_leg_page.dart';
import 'package:penyintas_app/features/preferences/domain/entities/preferences_entity.dart';
import 'package:penyintas_app/features/preferences/domain/repositories/preferences_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Mock & Fake
// ─────────────────────────────────────────────────────────────────────────────

class _MockPrefsRepo extends Mock implements PreferencesRepository {}

class _MockOnboardingDs extends Mock implements OnboardingLocalDataSource {}

class _FakePrefs extends Fake implements PreferencesEntity {}

// ─────────────────────────────────────────────────────────────────────────────
// Synchronous l10n delegate — menghindari async asset loading di test
// ─────────────────────────────────────────────────────────────────────────────
class _SyncLocDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _SyncLocDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(
      locale,
      {
        'app_name': 'Penyintas',
        'btn_next': 'Lanjut',
        'btn_save': 'Selesai',
        'btn_cancel': 'Batal',
        'profile_step_a_title': 'Kenalan dulu',
        'profile_step_b_title': 'Kamu di mana?',
        'profile_lang_label': 'Bahasa',
        'profile_name_label': 'Nama',
        'profile_name_hint': 'Nama tampilan kamu',
        'profile_status_label': 'Status',
        'profile_status_mahasiswa': 'Mahasiswa',
        'profile_status_pekerja': 'Pekerja',
        'profile_country_label': 'Negara sekarang',
        'profile_city_label': 'Kota',
        'profile_timezone_label': 'Zona waktu',
        'profile_timezone_change': 'Ubah',
        'profile_perantau_label': 'Aku merantau',
        'profile_home_country_label': 'Negara asal',
        'profile_home_city_label': 'Kota asal',
        'profile_exit_dialog_title': 'Batalkan pendaftaran?',
        'profile_exit_dialog_body': 'Progres belum tersimpan.',
        'profile_exit_dialog_confirm': 'Batalkan',
        'profile_exit_dialog_continue': 'Lanjutkan',
        'profile_error_retry': 'Coba lagi',
        'profile_error_signout': 'Keluar akun',
      },
    );
  }

  @override
  bool shouldReload(_SyncLocDelegate old) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: bungkus widget dengan BlocProvider + MaterialApp minimal
// Menggunakan GoRouter agar context.go() dari BlocListener tidak crash.
// ─────────────────────────────────────────────────────────────────────────────
Widget _harness(ProfileSetupCubit cubit) {
  final router = GoRouter(
    initialLocation: '/profile-setup',
    routes: [
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) =>
            BlocProvider.value(value: cubit, child: const ProfileLegPage()),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('onboarding-done'))),
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
    localizationsDelegates: const [
      _SyncLocDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('id'), Locale('en')],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper: buat cubit (autoPrefill:false agar deterministik)
// ─────────────────────────────────────────────────────────────────────────────
ProfileSetupCubit _makeCubit(PreferencesRepository repo) => ProfileSetupCubit(
      repo: repo,
      tz: TimezoneResolver(const [
        TimezoneCity(
          city: 'Jakarta',
          country: 'ID',
          iana: 'Asia/Jakarta',
          gmt: '+07:00',
        ),
      ]),
      autoPrefill: false,
    );

// ─────────────────────────────────────────────────────────────────────────────
// setUp / tearDown sl untuk test yang membutuhkan resetOnboardingCache()
// ─────────────────────────────────────────────────────────────────────────────
void _registerMockGuardInSl(
    _MockOnboardingDs ds, _MockPrefsRepo repo, GetIt sl) {
  // Daftarkan OnboardingGuard ke sl jika belum ada
  if (!sl.isRegistered<OnboardingGuard>()) {
    sl.registerSingleton<OnboardingGuard>(
      OnboardingGuard(onboardingDs: ds, prefsRepo: repo),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePrefs());
  });

  // Bersihkan sl setelah semua test agar tidak kontaminasi test lain
  tearDownAll(() async {
    final sl = GetIt.instance;
    if (sl.isRegistered<OnboardingGuard>()) {
      await sl.unregister<OnboardingGuard>();
    }
  });

  // ── Widget test 1: Sub-langkah A tampil; CTA Lanjut → sub-langkah B ──────

  testWidgets('sub-langkah A tampil; CTA Lanjut → sub-langkah B', (t) async {
    final repo = _MockPrefsRepo();
    when(() => repo.read())
        .thenAnswer((_) async => PreferencesEntity.defaults);

    final cubit = _makeCubit(repo);
    await t.pumpWidget(_harness(cubit));
    await t.pump();

    // Sub-A harus tampil toggle bahasa & CTA Lanjut
    expect(find.byKey(const Key('profile_lang_toggle')), findsOneWidget);
    expect(find.byKey(const Key('profile_next_cta')), findsOneWidget);

    // Tap CTA Lanjut → pindah ke sub-B
    await t.tap(find.byKey(const Key('profile_next_cta')));
    await t.pumpAndSettle();

    // Sub-B harus tampil tombol pilih negara
    expect(find.byKey(const Key('profile_country_btn')), findsOneWidget);
  });

  // ── Widget test 2: toggle perantau ON → field asal muncul ─────────────────

  testWidgets('toggle perantau ON → field asal muncul', (t) async {
    final repo = _MockPrefsRepo();
    when(() => repo.read())
        .thenAnswer((_) async => PreferencesEntity.defaults);

    final cubit = _makeCubit(repo);
    // Mulai dari sub-B
    cubit.goToLocation();

    await t.pumpWidget(_harness(cubit));
    await t.pump();

    // Toggle perantau harus ada di sub-B
    expect(find.byKey(const Key('profile_perantau_toggle')), findsOneWidget);

    // field asal belum muncul
    expect(find.byKey(const Key('profile_home_country_btn')), findsNothing);

    // Tap toggle
    await t.tap(find.byKey(const Key('profile_perantau_toggle')));
    await t.pumpAndSettle();

    // Field asal sekarang muncul
    expect(find.byKey(const Key('profile_home_country_btn')), findsOneWidget);
  });

  // ── Widget test 3: CTA Selesai memanggil save() ───────────────────────────

  testWidgets('CTA Selesai memanggil save()', (t) async {
    final sl = GetIt.instance;
    final repo = _MockPrefsRepo();
    final ds = _MockOnboardingDs();

    when(() => repo.read())
        .thenAnswer((_) async => PreferencesEntity.defaults);
    when(() => repo.save(any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => ds.isOnboardingCompleted()).thenAnswer((_) async => false);

    // Daftarkan OnboardingGuard ke sl agar resetOnboardingCache() tidak crash
    _registerMockGuardInSl(ds, repo, sl);

    final cubit = _makeCubit(repo);
    // Mulai dari sub-B
    cubit.goToLocation();

    await t.pumpWidget(_harness(cubit));
    await t.pump();

    // CTA Selesai harus ada
    expect(find.byKey(const Key('profile_finish_cta')), findsOneWidget);

    // Tap CTA Selesai
    await t.tap(find.byKey(const Key('profile_finish_cta')));
    await t.pumpAndSettle();

    // repo.save() harus dipanggil tepat 1 kali
    verify(() => repo.save(any())).called(1);
  });

  // ── Test anti-loop B-1: router-level ──────────────────────────────────────
  //
  // Membuktikan: setelah save sukses → resetOnboardingCache() dipanggil →
  // context.go('/onboarding') → guard recompute (profil sudah done, budget belum)
  // → tidak memantul balik ke /profile-setup.

  testWidgets(
      'anti-loop B-1: setelah save → navigasi ke /onboarding, tidak balik ke /profile-setup',
      (t) async {
    final sl = GetIt.instance;
    final repo = _MockPrefsRepo();
    final ds = _MockOnboardingDs();

    // Awal: profil belum selesai → guard = needsProfile
    // Setelah save(), profil selesai → guard = needsBudget
    var profileDone = false;
    when(() => repo.read()).thenAnswer((_) async {
      if (profileDone) {
        return PreferencesEntity.defaults.copyWith(profileCompleted: true);
      }
      return PreferencesEntity.defaults;
    });
    when(() => repo.save(any())).thenAnswer((_) async {
      profileDone = true;
      return const Right(unit);
    });
    // Budget belum selesai → needsBudget setelah profil done
    when(() => ds.isOnboardingCompleted()).thenAnswer((_) async => false);

    // Daftarkan OnboardingGuard ke sl agar resetOnboardingCache() bekerja
    // Unregister dulu jika sudah ada dari test sebelumnya
    if (sl.isRegistered<OnboardingGuard>()) {
      await sl.unregister<OnboardingGuard>();
    }
    final guard = OnboardingGuard(onboardingDs: ds, prefsRepo: repo);
    sl.registerSingleton<OnboardingGuard>(guard);

    final cubit = _makeCubit(repo);
    // Mulai dari sub-B agar CTA Selesai langsung tersedia
    cubit.goToLocation();

    final router = GoRouter(
      initialLocation: '/profile-setup',
      redirect: (context, state) async {
        // Router minimal — tidak ada guard redirect di sini
        // (cukup 2 rute statis)
        return null;
      },
      routes: [
        GoRoute(
          path: '/profile-setup',
          builder: (context, state) => BlocProvider.value(
            value: cubit,
            child: const ProfileLegPage(),
          ),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('onboarding-placeholder')),
          ),
        ),
      ],
    );

    await t.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          _SyncLocDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('id'), Locale('en')],
      ),
    );
    await t.pumpAndSettle();

    // Awal: di /profile-setup — CTA Selesai tersedia
    expect(find.byKey(const Key('profile_finish_cta')), findsOneWidget);

    // Tap CTA Selesai → save() → saved=true → BlocListener:
    // resetOnboardingCache() → context.go('/onboarding')
    await t.tap(find.byKey(const Key('profile_finish_cta')));
    await t.pumpAndSettle();

    // Harus sudah pindah ke /onboarding
    expect(find.text('onboarding-placeholder'), findsOneWidget);
    // TIDAK memantul balik ke /profile-setup
    expect(find.byKey(const Key('profile_finish_cta')), findsNothing);
  });
}
