import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:penyintas_app/widgets/common/app_version_text.dart';

void main() {
  testWidgets('menampilkan versi dinamis dari PackageInfo', (tester) async {
    PackageInfo.setMockInitialValues(
      appName: 'Penyintas',
      packageName: 'com.onaved.penyintas',
      version: '9.9.9',
      buildNumber: '42',
      buildSignature: '',
      installerStore: null,
    );
    AppVersionText.resetCache();
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppVersionText())),
    );
    await tester.pumpAndSettle();
    expect(find.text('v9.9.9+42'), findsOneWidget);
  });
}
