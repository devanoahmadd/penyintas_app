import 'package:flutter_test/flutter_test.dart';
import 'package:penyintas_app/core/utils/feedback_mailto.dart';

void main() {
  test('tanpa versionLine → URI mailto valid, subjek saja', () {
    final uri = buildFeedbackMailto();

    expect(uri.scheme, 'mailto');
    expect(uri.path, feedbackEmail);
    expect(uri.query, 'subject=Feedback%20Penyintas');
  });

  test('dengan versionLine → body berisi baris versi ter-encode', () {
    final uri = buildFeedbackMailto(versionLine: 'Versi: 1.0.0 (12) · Android');

    expect(uri.query, startsWith('subject=Feedback%20Penyintas&body='));
    expect(uri.queryParameters['body'], '\n\n—\nVersi: 1.0.0 (12) · Android');
  });
}
