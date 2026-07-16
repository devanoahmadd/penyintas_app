import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:penyintas_app/features/app_lock/presentation/cubit/app_lock_cubit.dart';
import 'package:penyintas_app/features/app_lock/presentation/pages/change_pin_page.dart';
import 'package:penyintas_app/features/app_lock/presentation/pages/set_pin_page.dart';
import 'package:penyintas_app/features/app_lock/presentation/pages/verify_pin_page.dart';
import 'package:penyintas_app/features/notification/domain/repositories/notification_repository.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_event.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_state.dart';
import 'package:penyintas_app/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:penyintas_app/widgets/common/app_version_text.dart';

/// Diskriminator toggle terakhir yang diubah — dipakai di revert listener.
enum _ToggleKind { reminder, push }

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _reminderEnabled = true;
  int _reminderHour = 20;
  int _reminderMinute = 0;
  bool _reminderLoaded = false;
  bool _prevReminderEnabled = true;

  bool _pushEnabled = true;
  bool _prevPushEnabled = true;
  // Diskriminator: toggle mana yang terakhir diubah (untuk revert yang tepat).
  _ToggleKind? _lastToggle;

  @override
  void initState() {
    super.initState();
    _loadReminder();
    _loadPushPref();
  }

  Future<void> _loadReminder() async {
    final row = await (sl<AppDatabase>().select(
      sl<AppDatabase>().appSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    if (!mounted) return;
    setState(() {
      _reminderEnabled = row?.reminderEnabled ?? true;
      _reminderHour = row?.reminderHour ?? 20;
      _reminderMinute = row?.reminderMinute ?? 0;
      _reminderLoaded = true;
    });
  }

  Future<void> _loadPushPref() async {
    final uid = sl<FirebaseAuth>().currentUser?.uid;
    if (uid == null) return;
    final result = await sl<NotificationRepository>().getPushEnabled(uid);
    if (!mounted) return;
    result.fold(
      (_) {}, // gagal baca → biarkan default true
      (enabled) => setState(() => _pushEnabled = enabled),
    );
  }

  void _onToggleReminder(bool value) {
    _lastToggle = _ToggleKind.reminder;
    _prevReminderEnabled = _reminderEnabled;
    setState(() => _reminderEnabled = value);
    if (value) {
      context.read<NotificationBloc>().add(
        ScheduleDailyReminder(hour: _reminderHour, minute: _reminderMinute),
      );
    } else {
      context.read<NotificationBloc>().add(const CancelDailyReminder());
    }
  }

  void _onTogglePush(bool value) {
    _lastToggle = _ToggleKind.push;
    _prevPushEnabled = _pushEnabled;
    setState(() => _pushEnabled = value);
    context.read<NotificationBloc>().add(SetPushPreference(value));
  }

  Future<void> _exportCsv() async {
    final subjectText = context.l10n.settingsExportSubject(
      DateFormat('yyyy-MM').format(DateTime.now()),
    );
    final failedText = context.l10n.settingsExportFailed;
    try {
      final db = sl<AppDatabase>();
      final txs = await db.select(db.transactions).get();

      final dateFmt = DateFormat('yyyy-MM-dd');
      final buf = StringBuffer('tanggal,kategori,nominal,catatan,goal_id\n');
      for (final tx in txs) {
        final date = dateFmt.format(tx.date);
        final note = '"${(tx.note ?? '').replaceAll('"', '""')}"';
        final goalId = tx.goalId?.toString() ?? '';
        buf.writeln('$date,${tx.category},${tx.amount},$note,$goalId');
      }

      final dir = await getTemporaryDirectory();
      final month = DateFormat('yyyy-MM').format(DateTime.now());
      final file = File('${dir.path}/penyintas_export_$month.csv');
      await file.writeAsString(buf.toString());

      try {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'text/csv')],
            subject: subjectText,
          ),
        );
      } finally {
        await file.delete().catchError((_) => file);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failedText,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.warn,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _onPickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinute),
    );
    if (picked != null && mounted) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinute = picked.minute;
      });
      context.read<NotificationBloc>().add(
        ScheduleDailyReminder(hour: picked.hour, minute: picked.minute),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor = isDark
        ? AppColors.textSoftDark
        : AppColors.textSoftLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return BlocListener<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationError) {
          final isPush = _lastToggle == _ToggleKind.push;
          setState(() {
            if (isPush) {
              _pushEnabled = _prevPushEnabled;
            } else {
              _reminderEnabled = _prevReminderEnabled;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isPush
                    ? context.l10n.settingsErrorPush(state.message)
                    : context.l10n.settingsErrorReminder(state.message),
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
              ),
              backgroundColor: AppColors.warn,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: Text(
            context.l10n.settingsPageTitle,
            style: AppTextStyles.h3.copyWith(color: textColor),
          ),
          iconTheme: IconThemeData(color: textColor),
        ),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
              children: [
                _SectionHeader(
                  label: context.l10n.settingsTheme.toUpperCase(),
                  mutedColor: mutedColor,
                ),
                _CardContainer(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  child: RadioGroup<ThemeMode>(
                    groupValue: state.themeMode,
                    onChanged: (v) {
                      if (v != null) {
                        context.read<SettingsBloc>().add(ChangeTheme(v));
                      }
                    },
                    child: Column(
                      children: [
                        _RadioTile(
                          title: context.l10n.settingsThemeLight,
                          value: ThemeMode.light,
                          textColor: textColor,
                          borderColor: borderColor,
                          showDivider: true,
                        ),
                        _RadioTile(
                          title: context.l10n.settingsThemeDark,
                          value: ThemeMode.dark,
                          textColor: textColor,
                          borderColor: borderColor,
                          showDivider: true,
                        ),
                        _RadioTile(
                          title: context.l10n.settingsThemeSystem,
                          value: ThemeMode.system,
                          textColor: textColor,
                          borderColor: borderColor,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                ),
                _SectionHeader(
                  label: context.l10n.settingsLanguage.toUpperCase(),
                  mutedColor: mutedColor,
                ),
                _CardContainer(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  child: RadioGroup<String>(
                    groupValue: state.locale,
                    onChanged: (v) {
                      if (v != null) {
                        context.read<SettingsBloc>().add(ChangeLanguage(v));
                      }
                    },
                    child: Column(
                      children: [
                        _RadioTile(
                          title: 'Indonesia',
                          value: 'id',
                          textColor: textColor,
                          borderColor: borderColor,
                          showDivider: true,
                        ),
                        _RadioTile(
                          title: 'English',
                          value: 'en',
                          textColor: textColor,
                          borderColor: borderColor,
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_reminderLoaded) ...[
                  _SectionHeader(
                    label: context.l10n.settingsSectionNotification
                        .toUpperCase(),
                    mutedColor: mutedColor,
                  ),
                  _CardContainer(
                    surfaceColor: surfaceColor,
                    borderColor: borderColor,
                    child: Column(
                      children: [
                        SwitchListTile(
                          value: _reminderEnabled,
                          onChanged: _onToggleReminder,
                          title: Text(
                            context.l10n.settingsReminderTitle,
                            style: AppTextStyles.body.copyWith(
                              color: textColor,
                            ),
                          ),
                          subtitle: Text(
                            context.l10n.settingsReminderSubtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: textSoftColor,
                            ),
                          ),
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primary.withValues(
                            alpha: 0.4,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.xs,
                          ),
                        ),
                        if (_reminderEnabled) ...[
                          Divider(height: 1, color: borderColor),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.xs,
                            ),
                            title: Text(
                              context.l10n.settingsReminderTime,
                              style: AppTextStyles.body.copyWith(
                                color: textColor,
                              ),
                            ),
                            trailing: Text(
                              '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.primary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            onTap: _onPickTime,
                          ),
                        ],
                        Divider(height: 1, color: borderColor),
                        SwitchListTile(
                          value: _pushEnabled,
                          onChanged: _onTogglePush,
                          title: Text(
                            context.l10n.settingsPushTitle,
                            style: AppTextStyles.body.copyWith(
                              color: textColor,
                            ),
                          ),
                          subtitle: Text(
                            context.l10n.settingsPushSubtitle,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: textSoftColor,
                            ),
                          ),
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primary.withValues(
                            alpha: 0.4,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.xs,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SecuritySection(),
                _SectionHeader(
                  label: context.l10n.settingsSectionExport.toUpperCase(),
                  mutedColor: mutedColor,
                ),
                _CardContainer(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xs,
                    ),
                    title: Text(
                      context.l10n.settingsExportCsvTitle,
                      style: AppTextStyles.body.copyWith(color: textColor),
                    ),
                    subtitle: Text(
                      context.l10n.settingsExportCsvSubtitle,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: textSoftColor,
                      ),
                    ),
                    trailing: Icon(
                      Icons.download_outlined,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    onTap: _exportCsv,
                  ),
                ),
                _SectionHeader(
                  label: context.l10n.settingsSectionAbout.toUpperCase(),
                  mutedColor: mutedColor,
                ),
                _CardContainer(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        title: Text(
                          context.l10n.sayaVersionLabel,
                          style: AppTextStyles.body.copyWith(color: textColor),
                        ),
                        trailing: AppVersionText(
                          style: AppTextStyles.bodySmall.copyWith(
                            color: mutedColor,
                          ),
                        ),
                      ),
                      Divider(height: 1, color: borderColor),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xs,
                        ),
                        title: Text(
                          context.l10n.settingsFeedbackLabel,
                          style: AppTextStyles.body.copyWith(color: textColor),
                        ),
                        trailing: Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: mutedColor,
                        ),
                        onTap: () {
                          // placeholder — mailto link
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Section "Keamanan" — App Lock opsional (PIN 6 digit + biometrik).
///
/// Punya state & loader sendiri (bukan bagian dari `_SettingsPageState`) agar
/// bisa diuji tanpa menyeret seluruh dependency SettingsPage (AppDatabase,
/// SettingsBloc, NotificationBloc). Tetap tinggal di file ini supaya bisa
/// memakai `_SectionHeader` & `_CardContainer` yang privat di library ini.
///
/// Device-local murni: tak pernah menyentuh Firestore/`PreferencesEntity`.
class SecuritySection extends StatefulWidget {
  const SecuritySection({super.key});

  @override
  State<SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<SecuritySection> {
  bool _lockEnabled = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _lockLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLock();
  }

  Future<void> _loadLock() async {
    final repo = sl<AppLockRepository>();
    final cfg = await repo.readConfig();
    final available = await repo.isBiometricAvailable();
    final uid = sl<FirebaseAuth>().currentUser?.uid;
    if (!mounted) return;
    setState(() {
      // Meniru PERSIS syarat penegakan `_enforced` di AppLockCubit: enabled,
      // hasPin, DAN config milik uid yang sedang login. Tanpa conjunct uid,
      // config peninggalan akun lain (sign-out tak memanggil disableLock())
      // akan tampil ON padahal cubit sudah menganggapnya OFF (`_enforced`
      // false) — toggle berbohong soal proteksi, dan user baru itu buntu:
      // mematikannya butuh PIN milik pemilik lama yang tak akan pernah cocok.
      _lockEnabled =
          cfg.enabled && cfg.hasPin && uid != null && uid == cfg.ownerUid;
      _biometricEnabled = cfg.biometricEnabled;
      _biometricAvailable = available;
      _lockLoaded = true;
    });
  }

  Future<void> _onToggleLock(bool value) async {
    final uid = sl<FirebaseAuth>().currentUser?.uid;
    if (uid == null) return;
    if (value) {
      final done = await Navigator.of(
        context,
      ).push<bool>(MaterialPageRoute(builder: (_) => SetPinPage(uid: uid)));
      if (done != true) return; // batal di tengah → tak ada yang berubah
    } else {
      // Mematikan lock WAJIB lewat verifikasi PIN dulu: tanpa ini siapa pun
      // yang memegang device saat sesi terbuka bisa melucuti kuncinya.
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (ctx) =>
              VerifyPinPage(title: ctx.l10n.applockVerifyToDisable),
        ),
      );
      if (ok != true) return;
      await sl<AppLockRepository>().disableLock();
    }
    await _syncCubitThenReload();
  }

  Future<void> _onToggleBiometric(bool value) async {
    await sl<AppLockRepository>().setBiometricEnabled(value);
    await _syncCubitThenReload();
  }

  Future<void> _onChangePin() async {
    final uid = sl<FirebaseAuth>().currentUser?.uid;
    if (uid == null) return;
    final done = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => ChangePinPage(uid: uid)));
    if (done != true) return;
    await _syncCubitThenReload();
  }

  /// WAJIB dipanggil setelah SETIAP perubahan state lock (setPin, disableLock,
  /// toggle biometrik).
  ///
  /// `AppLockCubit` adalah singleton app-scoped yang meng-cache config-nya
  /// sendiri. Tanpa `onSettingsChanged()` cache itu basi: lock sudah OFF dari
  /// sini tapi cubit masih menegakkan → resume >60 detik memunculkan
  /// LockScreen dengan PIN yang SUDAH TERHAPUS (user terkunci di luar
  /// aplikasinya sendiri, tanpa cara masuk); atau sebaliknya, lock yang baru
  /// dinyalakan tak pernah menegakkan grace sampai cold restart.
  ///
  /// Cubit disegarkan DULUAN, dan sengaja TIDAK di-guard `mounted`: sinkronisasi
  /// tetap wajib walau user keburu meninggalkan halaman Settings. Guard
  /// `mounted` cukup di `_loadLock()` (yang memanggil setState).
  Future<void> _syncCubitThenReload() async {
    await sl<AppLockCubit>().onSettingsChanged();
    await _loadLock();
  }

  @override
  Widget build(BuildContext context) {
    if (!_lockLoaded) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textDark : AppColors.textLight;
    final textSoftColor = isDark
        ? AppColors.textSoftDark
        : AppColors.textSoftLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    // Aksen WAJIB adaptif — AppColors.primary polos gagal kontras di dark mode.
    final accent = isDark ? AppColors.shoot : AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionHeader(
          label: context.l10n.settingsSectionSecurity.toUpperCase(),
          mutedColor: mutedColor,
        ),
        _CardContainer(
          surfaceColor: surfaceColor,
          borderColor: borderColor,
          child: Column(
            children: [
              SwitchListTile(
                value: _lockEnabled,
                onChanged: _onToggleLock,
                title: Text(
                  context.l10n.applockToggleTitle,
                  style: AppTextStyles.body.copyWith(color: textColor),
                ),
                subtitle: Text(
                  context.l10n.applockToggleSubtitle,
                  style: AppTextStyles.bodySmall.copyWith(color: textSoftColor),
                ),
                activeThumbColor: accent,
                activeTrackColor: accent.withValues(alpha: 0.4),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
              ),
              // Sub-toggle biometrik hanya relevan bila lock aktif DAN device
              // memang punya biometrik terdaftar.
              if (_lockEnabled && _biometricAvailable) ...[
                Divider(height: 1, color: borderColor),
                SwitchListTile(
                  value: _biometricEnabled,
                  onChanged: _onToggleBiometric,
                  title: Text(
                    context.l10n.applockBiometricTitle,
                    style: AppTextStyles.body.copyWith(color: textColor),
                  ),
                  subtitle: Text(
                    context.l10n.applockBiometricSubtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: textSoftColor,
                    ),
                  ),
                  activeThumbColor: accent,
                  activeTrackColor: accent.withValues(alpha: 0.4),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                ),
              ],
              if (_lockEnabled) ...[
                Divider(height: 1, color: borderColor),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  title: Text(
                    context.l10n.applockChangePin,
                    style: AppTextStyles.body.copyWith(color: textColor),
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: mutedColor,
                  ),
                  onTap: _onChangePin,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.mutedColor});
  final String label;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: mutedColor),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  const _CardContainer({
    required this.child,
    required this.surfaceColor,
    required this.borderColor,
  });
  final Widget child;
  final Color surfaceColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Material(
        color: surfaceColor,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: borderColor),
        ),
        child: child,
      ),
    );
  }
}

class _RadioTile<T> extends StatelessWidget {
  const _RadioTile({
    required this.title,
    required this.value,
    required this.textColor,
    required this.borderColor,
    required this.showDivider,
  });
  final String title;
  final T value;
  final Color textColor;
  final Color borderColor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RadioListTile<T>(
          value: value,
          title: Text(
            title,
            style: AppTextStyles.body.copyWith(color: textColor),
          ),
          activeColor: AppColors.primary,
          contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          dense: true,
        ),
        if (showDivider) Divider(height: 1, color: borderColor),
      ],
    );
  }
}
