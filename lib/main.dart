import 'dart:ui';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:penyintas_app/app.dart';
import 'package:penyintas_app/core/database/app_database.dart';
import 'package:penyintas_app/core/di/injection_container.dart' as di;
import 'package:penyintas_app/core/sync/sync_service.dart';
import 'package:penyintas_app/firebase_options.dart';

/// Top-level handler untuk FCM background message.
/// Harus berupa fungsi top-level (bukan method class) agar bisa di-register
/// dengan FirebaseMessaging.onBackgroundMessage.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase harus diinit ulang di isolate background
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background notification ditampilkan otomatis oleh FCM; tidak perlu aksi tambahan.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ─────────────────────────────────────────────────────────────
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // FCM background handler — harus didaftarkan sebelum runApp
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseAppCheck.instance.activate(
    providerAndroid: kReleaseMode
        ? AndroidPlayIntegrityProvider()
        : AndroidDebugProvider(),
    providerApple: kReleaseMode
        ? AppleDeviceCheckProvider()
        : AppleDebugProvider(),
  );

  FlutterError.onError = (details) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // ── Drift ─────────────────────────────────────────────────────────────────
  try {
    final db = AppDatabase();

    // ── Dependency Injection ──────────────────────────────────────────────
    await di.init(db: db);

    // ── Sync Service ──────────────────────────────────────────────────────
    di.sl<SyncService>().start();

    runApp(const PenyintasApp());
  } catch (e, stack) {
    FirebaseCrashlytics.instance.recordError(e, stack, fatal: true);
    runApp(const _DbErrorApp());
  }
}

class _DbErrorApp extends StatelessWidget {
  const _DbErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Gagal memuat data. Coba restart aplikasi.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
