import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:penyintas_app/core/sync/sync_service.dart';
import 'package:penyintas_app/core/theme/app_theme.dart';
import 'package:penyintas_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_bloc.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_event.dart';
import 'package:penyintas_app/features/notification/presentation/bloc/notification_state.dart';
import 'package:penyintas_app/features/settings/presentation/bloc/settings_bloc.dart';

class PenyintasApp extends StatefulWidget {
  const PenyintasApp({super.key});

  @override
  State<PenyintasApp> createState() => _PenyintasAppState();
}

class _PenyintasAppState extends State<PenyintasApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    sl<SyncService>().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<SettingsBloc>()..add(const SettingsLoaded()),
        ),
        BlocProvider(
          create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
        ),
        BlocProvider(
          create: (_) =>
              sl<NotificationBloc>()..add(const InitNotification()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settings) {
          return BlocListener<NotificationBloc, NotificationState>(
            listener: (_, state) {
              if (state is NotificationTapHandled) {
                // Navigasi ke route yang dikirim via FCM data payload
                sl<GoRouter>().go(state.route);
              }
            },
            child: MaterialApp.router(
              title: 'Penyintas',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: settings.themeMode,
              routerConfig: sl<GoRouter>(),
              locale: Locale(settings.locale),
              localizationsDelegates: [
                AppLocalizations.delegateFor(Locale(settings.locale)),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('id'),
                Locale('en'),
              ],
              debugShowCheckedModeBanner: false,
            ),
          );
        },
      ),
    );
  }
}
