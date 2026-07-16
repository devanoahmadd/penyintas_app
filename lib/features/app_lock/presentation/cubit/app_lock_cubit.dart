import 'dart:async';
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/features/app_lock/domain/entities/app_lock_config.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_state.dart';

/// Otak fitur App Lock — state machine `unknown → disabled → unlocked → locked`.
///
/// Device-local murni: tidak pernah menyentuh Firestore atau
/// `PreferencesEntity`. Semua UI (Task 11–13) hanya membaca state cubit ini.
///
/// Lifecycle: grace 60 detik saat background sungguhan (`paused`/`hidden`),
/// shade tanpa grace-clock saat `inactive` transient, dan guard
/// `authInProgress` agar prompt biometrik tak memicu lock-diri-sendiri.
/// Lihat [onLifecycle].
class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit({
    required AppLockRepository repo,
    required String? Function() currentUid,
    required Stream<String?> uidChanges,
    DateTime Function()? clock,
  })  : _repo = repo,
        _currentUid = currentUid,
        _uidChanges = uidChanges,
        _clock = clock ?? DateTime.now,
        super(const AppLockUnknown());

  final AppLockRepository _repo;
  final String? Function() _currentUid;
  final Stream<String?> _uidChanges;
  final DateTime Function() _clock;

  AppLockConfig _config = const AppLockConfig(
      enabled: false, hasPin: false, biometricEnabled: false);
  bool _biometricAvailable = false;
  bool _authInProgress = false;
  StreamSubscription<String?>? _uidSub;
  Timer? _unknownFallback;

  /// Jam mulai grace 60 detik — diset saat `paused`/`hidden` sungguhan
  /// (bukan `inactive` transient). In-memory saja (by design): process
  /// death → cold start → `init()` selalu emit Locked, jadi aman tanpa
  /// persist.
  DateTime? _backgroundedAt;

  bool get _enforced =>
      _config.enabled &&
      _config.hasPin &&
      _currentUid() != null &&
      _currentUid() == _config.ownerUid;

  Future<void> init() async {
    try {
      _config = await _repo.readConfig();
      _biometricAvailable = await _repo.isBiometricAvailable();
    } catch (_) {
      // `AppLockSecureStoreImpl.read()` TIDAK fail-safe (beda dari
      // BiometricDataSourceImpl) — keystore korup (mis. pasca device-restore)
      // akan melempar sampai ke sini, SEBELUM `_unknownFallback` sempat diset.
      // JANGAN fail-open (mis. anggap `enabled: false`) — itu membuka lock
      // milik user yang benar-benar mengaktifkannya = bocor privasi. Fail
      // CLOSED ke Locked: tetap recoverable lewat "Lupa PIN?" -> forgotPin()
      // -> disableLock() (dibuat fail-safe juga, lihat forgotPin()).
      if (isClosed) return;
      emit(const AppLockLocked(
        failedAttempts: 0,
        lockedUntilMs: 0,
        biometricAvailable: false,
      ));
      return;
    }
    _uidSub = _uidChanges.listen((_) => _reevaluate());
    if (isClosed) return;
    if (_enforced) {
      await _emitLocked();
      return;
    }
    if (_config.enabled && _config.hasPin && _currentUid() == null) {
      // Config ter-enable tapi uid belum resolve (restorasi Firebase Auth
      // async di cold start). Tahan di Unknown (shade fail-closed) sampai
      // emisi authStateChanges pertama — JANGAN emit Disabled (pass-through
      // = bocor privasi). Fallback 3s bila stream diam (firebase_auth selalu
      // emit saat subscribe; timer hanya jaring pengaman).
      _unknownFallback = Timer(const Duration(seconds: 3), _reevaluate);
      return;
    }
    emit(const AppLockDisabled());
  }

  void _reevaluate() {
    _unknownFallback?.cancel();
    _unknownFallback = null;
    if (isClosed) return;
    if (!_enforced) {
      emit(const AppLockDisabled());
      return;
    }
    // Baru ter-enforce (login owner / uid resolve dari Unknown) → kunci.
    if (state is AppLockDisabled || state is AppLockUnknown) {
      _emitLocked();
    }
  }

  /// WAJIB dipanggil Settings setelah setPin/disableLock/toggle biometrik.
  /// Tanpa ini `_config` basi: lock OFF dari Settings tapi cubit masih
  /// enforce → resume >60s memunculkan LockScreen dengan PIN yang sudah
  /// terhapus (user terkunci); atau lock baru ON tak pernah menegakkan
  /// grace sampai cold restart.
  Future<void> onSettingsChanged() async {
    _config = await _repo.readConfig();
    _biometricAvailable = await _repo.isBiometricAvailable();
    if (isClosed) return;
    if (!_enforced) {
      emit(const AppLockDisabled());
      return;
    }
    // Lock baru dinyalakan dari sesi aktif → user baru saja set PIN,
    // jangan mengunci layar yang sedang dipakai.
    if (state is AppLockDisabled || state is AppLockUnknown) {
      emit(const AppLockUnlocked(obscured: false));
    }
    // State Unlocked/Locked lain dibiarkan; internal (_config,
    // _biometricAvailable) sudah segar untuk keputusan berikutnya.
  }

  Future<AppLockLocked> _lockedState({bool authInProgress = false}) async {
    final attempts = await _repo.getFailedAttempts();
    final until = await _repo.getLockedUntilMs();
    return AppLockLocked(
      failedAttempts: attempts,
      lockedUntilMs: until,
      biometricAvailable: _biometricAvailable && _config.biometricEnabled,
      authInProgress: authInProgress,
    );
  }

  Future<void> _emitLocked({bool authInProgress = false}) async {
    final next = await _lockedState(authInProgress: authInProgress);
    if (isClosed) return; // emit-after-close guard (dipanggil dari path async)
    emit(next);
  }

  Future<void> submitPin(String pin) async {
    // Guard lockout: keypad-disabled hanyalah UI — tolak juga di sini.
    // WAJIB `>`, BUKAN `!= 0` — getLockedUntilMs() pasif, tetap mengembalikan
    // timestamp lampau setelah jeda kedaluwarsa.
    final until = await _repo.getLockedUntilMs();
    if (until > _clock().millisecondsSinceEpoch) {
      await _emitLocked();
      return;
    }
    final ok = await _repo.verifyPin(pin);
    if (isClosed) return;
    if (ok) {
      await _repo.resetFailedAttempts();
      if (isClosed) return; // emit-after-close guard: cubit bisa di-close saat await di atas
      emit(const AppLockUnlocked(obscured: false));
    } else {
      await _repo.recordFailedAttempt();
      await _emitLocked();
    }
  }

  Future<void> tryBiometric(String reason) async {
    if (_authInProgress) return;
    _authInProgress = true;
    try {
      await _emitLocked(authInProgress: true);
      final ok = await _repo.authenticateBiometric(reason);
      if (isClosed) return;
      if (ok) {
        await _repo.resetFailedAttempts();
        if (isClosed) return; // emit-after-close guard: cubit bisa di-close saat await di atas
        emit(const AppLockUnlocked(obscured: false));
      } else {
        await _emitLocked(authInProgress: false);
      }
    } finally {
      // WAJIB try/finally: badan di atas bisa melempar (mis. _store.read()
      // keystore korup pasca restore) — tanpa ini flag tersangkut true
      // selamanya, membuat guard di onLifecycle jadi early-return permanen
      // (shade & grace mati sepanjang umur proses = kebocoran privasi senyap).
      _authInProgress = false;
    }
  }

  Future<void> forgotPin() async {
    try {
      await _repo.disableLock();
    } catch (_) {
      // Escape hatch WAJIB tetap jalan walau storage korup — user memang
      // sedang meminta reset PIN lewat "Lupa PIN?" (akan sign-out setelah
      // ini). Fail-OPEN di sini disengaja & diminta eksplisit — beda dari
      // init() di atas yang WAJIB fail-closed.
    }
    _config = const AppLockConfig(
        enabled: false, hasPin: false, biometricEnabled: false);
    if (isClosed) return;
    emit(const AppLockDisabled());
  }

  void onLifecycle(AppLifecycleState lifecycle) {
    if (!_enforced) return;
    if (_authInProgress) return; // prompt biometrik memicu lifecycle palsu

    switch (lifecycle) {
      case AppLifecycleState.inactive:
        // Transient (notif shade / control center / prompt). Shade saja,
        // JANGAN mulai grace-clock.
        if (state is AppLockUnlocked) {
          if (isClosed) return;
          emit(const AppLockUnlocked(obscured: true));
        }
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Background sejati → mulai grace-clock. WAJIB `??=`, BUKAN `=`:
        // Flutter mensintesis `hidden` di KEDUA arah — turun (paused) MAUPUN
        // pulang (resumed selalu didahului hidden→inactive). Dengan `=`,
        // jam pertama tertimpa oleh jam kedua (yang sudah jauh lebih baru)
        // saat urutan pulang menembak cabang ini lagi, sehingga elapsed
        // yang dihitung di `resumed` selalu ≈0 dan aplikasi tak pernah
        // mengunci. `??=` menjamin jam PERTAMA yang menang; `resumed` tetap
        // satu-satunya yang meng-clear (`_backgroundedAt = null`).
        if (state is AppLockUnlocked) {
          _backgroundedAt ??= _clock();
          if (isClosed) return;
          emit(const AppLockUnlocked(obscured: true));
        }
      case AppLifecycleState.resumed:
        final bg = _backgroundedAt;
        _backgroundedAt = null;
        if (state is AppLockLocked) {
          return; // tetap locked; lock screen sudah tampil
        }
        if (state is AppLockUnlocked) {
          if (bg != null &&
              _clock().difference(bg).inMilliseconds > 60000) {
            _emitLocked();
          } else {
            if (isClosed) return;
            emit(const AppLockUnlocked(obscured: false));
          }
        }
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  Future<void> close() {
    _unknownFallback?.cancel();
    _uidSub?.cancel();
    return super.close();
  }
}
