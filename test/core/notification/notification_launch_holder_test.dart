import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/notification/notification_launch_holder.dart';

void main() {
  test('takePendingRoute mengembalikan nilai lalu membersihkan (one-shot)', () {
    final holder = NotificationLaunchHolder();
    holder.pendingRoute = '/budget';

    expect(holder.takePendingRoute(), '/budget');
    expect(holder.takePendingRoute(), isNull); // sudah bersih
  });

  test('takePendingRoute null saat belum di-set', () {
    expect(NotificationLaunchHolder().takePendingRoute(), isNull);
  });
}
