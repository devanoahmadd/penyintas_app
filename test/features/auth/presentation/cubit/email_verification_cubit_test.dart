import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:penyintas_app/core/error/failures.dart';
import 'package:penyintas_app/features/auth/domain/usecases/send_email_verification_usecase.dart';
import 'package:penyintas_app/features/auth/presentation/cubit/email_verification_cubit.dart';

class MockSendEmailVerificationUseCase extends Mock
    implements SendEmailVerificationUseCase {}

class FakeSendEmailVerificationParams extends Fake
    implements SendEmailVerificationParams {}

void main() {
  late MockSendEmailVerificationUseCase mockSend;

  setUpAll(() => registerFallbackValue(FakeSendEmailVerificationParams()));
  setUp(() => mockSend = MockSendEmailVerificationUseCase());

  EmailVerificationCubit buildCubit() => EmailVerificationCubit(mockSend);

  blocTest<EmailVerificationCubit, EmailVerificationState>(
    'sukses → [Sending, Sent] + usecase menerima languageCode',
    build: () {
      when(() => mockSend(any())).thenAnswer((_) async => const Right(null));
      return buildCubit();
    },
    act: (cubit) => cubit.resend(languageCode: 'id'),
    expect: () => const [EmailVerificationSending(), EmailVerificationSent()],
    verify: (_) {
      verify(
        () => mockSend(const SendEmailVerificationParams(languageCode: 'id')),
      ).called(1);
    },
  );

  blocTest<EmailVerificationCubit, EmailVerificationState>(
    'gagal → [Sending, Failed] — pesan tenang datasource diteruskan apa adanya',
    build: () {
      when(() => mockSend(any())).thenAnswer(
        (_) async => const Left(
          AuthFailure('Terlalu banyak percobaan. Tunggu sebentar ya.'),
        ),
      );
      return buildCubit();
    },
    act: (cubit) => cubit.resend(),
    expect: () => const [
      EmailVerificationSending(),
      EmailVerificationFailed('Terlalu banyak percobaan. Tunggu sebentar ya.'),
    ],
  );

  blocTest<EmailVerificationCubit, EmailVerificationState>(
    'resend kedua saat masih Sending → diabaikan (single-flight)',
    build: () {
      when(() => mockSend(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return const Right(null);
      });
      return buildCubit();
    },
    act: (cubit) async {
      final first = cubit.resend();
      await cubit.resend(); // masuk saat state masih Sending → no-op
      await first;
    },
    expect: () => const [EmailVerificationSending(), EmailVerificationSent()],
    verify: (_) => verify(() => mockSend(any())).called(1),
  );
}
