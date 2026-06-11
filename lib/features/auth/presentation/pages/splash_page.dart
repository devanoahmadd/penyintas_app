import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/routing/app_router.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/core/usecases/usecase.dart';
import 'package:penyintas_app/features/auth/domain/usecases/sync_user_settings_usecase.dart';
import 'package:penyintas_app/features/budget/domain/repositories/budget_repository.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:penyintas_app/widgets/common/penyintas_logo.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  // Navigasi hanya boleh terjadi setelah branding minimum 2500ms.
  // GoRouter tidak menginterrupt /splash (lihat app_router.dart),
  // sehingga SplashPage memegang kendali penuh atas timing navigasi.
  bool _canNavigate = false;
  VoidCallback? _pendingNav;
  bool _syncStarted = false;

  void _navigateWhenReady(VoidCallback nav) {
    if (_canNavigate) {
      nav();
    } else {
      _pendingNav = nav;
    }
  }

  Future<void> _syncThenNavigate() async {
    if (_syncStarted) return;
    _syncStarted = true;
    // Restaurasi flag onboarding (settings/app) dan data finansial
    // (budget_settings/current) secara paralel — keduanya independen.
    // Timeout tiap step 3s agar splash gate tak menggantung di jaringan lemot.
    try {
      await Future.wait([
        sl<SyncUserSettingsUseCase>()(const NoParams()),
        sl<BudgetRepository>()
            .syncBudgetFromRemote()
            .timeout(const Duration(seconds: 3)),
      ]);
    } catch (e, s) {
      // Sync gagal/timeout — lanjut; data akan terisi saat online berikutnya.
      debugPrint('[Splash] sync skipped: $e');
      try {
        FirebaseCrashlytics.instance.recordError(e, s, fatal: false);
      } catch (_) {}
    }
    resetOnboardingCache();
    if (!mounted) return;
    _navigateWhenReady(() => context.go('/dashboard'));
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // #20: Durasi splash dari RemoteConfig (default 2500ms).
    // setDefaults + getInt membaca nilai cached — tidak block UI.
    _startSplashTimer();
  }

  Future<void> _startSplashTimer() async {
    int durationMs = 2500;
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setDefaults(const {'splash_duration_ms': 2500});
      await rc
          .fetchAndActivate()
          .timeout(const Duration(seconds: 2), onTimeout: () => false);
      final value = rc.getInt('splash_duration_ms');
      if (value >= 1500 && value <= 8000) durationMs = value;
    } catch (_) {
      // fallback ke 2500ms jika RemoteConfig tidak tersedia / timeout
    }

    await Future.delayed(Duration(milliseconds: durationMs));
    if (!mounted) return;
    _canNavigate = true;
    if (_pendingNav != null) {
      _pendingNav!();
      _pendingNav = null;
    } else {
      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // "Setiap widget harus responsif terhadap Theme.of(context).brightness"
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Warna teks di atas latar bg splash
    final onBg = isDark ? AppColors.textDark : Colors.white;
    final onBgMuted =
        isDark ? AppColors.mutedDark : Colors.white.withValues(alpha: 0.85);
    final onBgDim =
        isDark ? AppColors.mutedDark : Colors.white.withValues(alpha: 0.5);

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          _navigateWhenReady(() => context.go('/login'));
        } else if (state is Authenticated) {
          // #192: sync identity settings dulu (blocking gate), lalu navigate.
          _syncThenNavigate();
        }
      },
      child: Scaffold(
        // Light: latar primary (#0F7A3E) — Dark: latar bgDark (#0B1F14)
        backgroundColor: isDark ? AppColors.bgDark : AppColors.primary,
        body: FadeTransition(
          opacity: _fade,
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Light: logo putih (reversed) — Dark: logo shoot via PenyintasLogo auto-switch
                    PenyintasLogo(size: 120, reversed: !isDark),
                    const SizedBox(height: 24),
                    // Display scale ("Hero, splash, slogan") di-scale ke 44px
                    Text(
                      'Penyintas',
                      style: AppTextStyles.display.copyWith(
                        fontSize: 44,
                        letterSpacing: -1.3,
                        color: onBg,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // BodySmall (14px Inter Tight) — slogan selalu dua kalimat, diakhiri titik
                    Text(
                      'Bertahan. Berkembang.',
                      style: AppTextStyles.bodySmall.copyWith(
                        letterSpacing: 0.1,
                        color: onBgMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Versi — caption mono di bottom, non-interaktif
              Positioned(
                bottom: 36,
                left: 0,
                right: 0,
                child: Text(
                  'v0.1 · 2026',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 10,
                    color: onBgDim,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
