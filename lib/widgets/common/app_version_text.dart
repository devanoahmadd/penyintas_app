import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Teks versi aplikasi dinamis dari platform (pengganti literal 'v0.1.0+1').
/// Future di-cache static agar PackageInfo hanya dibaca sekali per sesi.
class AppVersionText extends StatelessWidget {
  const AppVersionText({super.key, this.style});

  final TextStyle? style;

  static Future<PackageInfo>? _cached;
  static Future<PackageInfo> _info() => _cached ??= PackageInfo.fromPlatform();

  @visibleForTesting
  static void resetCache() => _cached = null;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: _info(),
      builder: (context, snap) {
        final info = snap.data;
        return Text(
          info == null ? '' : 'v${info.version}+${info.buildNumber}',
          style: style,
        );
      },
    );
  }
}
