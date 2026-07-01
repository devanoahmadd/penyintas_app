/// Penampung singleton untuk route deep-link saat app diluncurkan dari state
/// TERMINATED (via FCM `getInitialMessage`). Navigasi langsung akan balapan
/// dengan SplashPage/redirect bootstrap; route disimpan di sini lalu
/// dikonsumsi SplashPage SETELAH bootstrap selesai (anti-swallow, K3).
class NotificationLaunchHolder {
  /// Route yang menunggu untuk dikonsumsi. Gunakan [takePendingRoute] untuk
  /// mengambil sekali lalu membersihkan, atau akses langsung bila hanya ingin membaca.
  String? pendingRoute;

  /// Ambil route pending sekali lalu bersihkan. Null bila tak ada.
  String? takePendingRoute() {
    final route = pendingRoute;
    pendingRoute = null;
    return route;
  }
}
