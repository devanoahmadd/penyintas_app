import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/theme/app_colors.dart';
import 'package:penyintas_app/core/theme/app_spacing.dart';
import 'package:penyintas_app/core/theme/app_text_styles.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_event.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_state.dart';
import 'package:penyintas_app/features/settings/presentation/bloc/settings_bloc.dart';

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

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    final row = await (sl<AppDatabase>().select(sl<AppDatabase>().appSettings)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (!mounted) return;
    setState(() {
      _reminderEnabled = row?.reminderEnabled ?? true;
      _reminderHour = row?.reminderHour ?? 20;
      _reminderMinute = row?.reminderMinute ?? 0;
      _reminderLoaded = true;
    });
  }

  void _onToggleReminder(bool value) {
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
    final textSoftColor =
        isDark ? AppColors.textSoftDark : AppColors.textSoftLight;
    final mutedColor = isDark ? AppColors.mutedDark : AppColors.mutedLight;
    final surfaceColor =
        isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return BlocListener<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationError) {
          setState(() => _reminderEnabled = _prevReminderEnabled);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal mengubah pengingat: ${state.message}',
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
          'Pengaturan',
          style: AppTextStyles.h3.copyWith(color: textColor),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
            children: [
              _SectionHeader(label: 'TAMPILAN', mutedColor: mutedColor),
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
                        title: 'Terang',
                        value: ThemeMode.light,
                        textColor: textColor,
                        borderColor: borderColor,
                        showDivider: true,
                      ),
                      _RadioTile(
                        title: 'Gelap',
                        value: ThemeMode.dark,
                        textColor: textColor,
                        borderColor: borderColor,
                        showDivider: true,
                      ),
                      _RadioTile(
                        title: 'Ikut sistem',
                        value: ThemeMode.system,
                        textColor: textColor,
                        borderColor: borderColor,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ),
              _SectionHeader(label: 'BAHASA', mutedColor: mutedColor),
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
                _SectionHeader(label: 'NOTIFIKASI', mutedColor: mutedColor),
                _CardContainer(
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  child: Column(
                    children: [
                      SwitchListTile(
                        value: _reminderEnabled,
                        onChanged: _onToggleReminder,
                        title: Text(
                          'Pengingat harian',
                          style:
                              AppTextStyles.body.copyWith(color: textColor),
                        ),
                        subtitle: Text(
                          'Ingatkan untuk mencatat pengeluaran setiap hari',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: textSoftColor),
                        ),
                        activeThumbColor: AppColors.primary,
                        activeTrackColor:
                            AppColors.primary.withValues(alpha: 0.4),
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
                            'Waktu pengingat',
                            style:
                                AppTextStyles.body.copyWith(color: textColor),
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
                    ],
                  ),
                ),
              ],
              _SectionHeader(label: 'TENTANG', mutedColor: mutedColor),
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
                        'Versi',
                        style: AppTextStyles.body.copyWith(color: textColor),
                      ),
                      trailing: Text(
                        'v0.1.0+1',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: mutedColor),
                      ),
                    ),
                    Divider(height: 1, color: borderColor),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      title: Text(
                        'Kirim Feedback',
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
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor),
        ),
        clipBehavior: Clip.antiAlias,
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
          title: Text(title, style: AppTextStyles.body.copyWith(color: textColor)),
          activeColor: AppColors.primary,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          dense: true,
        ),
        if (showDivider) Divider(height: 1, color: borderColor),
      ],
    );
  }
}
