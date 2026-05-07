import 'dart:async';

import 'package:flutter/foundation.dart';

/// Jembatan antara BLoC/stream dan GoRouter refreshListenable.
/// Setiap kali stream emit nilai baru, GoRouter re-evaluasi redirect.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
