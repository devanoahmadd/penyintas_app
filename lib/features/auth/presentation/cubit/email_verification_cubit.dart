import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:penyintas_app/features/auth/domain/usecases/send_email_verification_usecase.dart';

/// B4: state pengiriman ulang email verifikasi — khusus banner.
/// Terpisah dari AuthBloc agar feedback sukses/gagal tidak mengganggu state
/// auth global (pola sama dengan TimezoneReconciliationCubit).
sealed class EmailVerificationState extends Equatable {
  const EmailVerificationState();

  @override
  List<Object?> get props => [];
}

final class EmailVerificationIdle extends EmailVerificationState {
  const EmailVerificationIdle();
}

final class EmailVerificationSending extends EmailVerificationState {
  const EmailVerificationSending();
}

final class EmailVerificationSent extends EmailVerificationState {
  const EmailVerificationSent();
}

final class EmailVerificationFailed extends EmailVerificationState {
  const EmailVerificationFailed(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class EmailVerificationCubit extends Cubit<EmailVerificationState> {
  EmailVerificationCubit(this._sendEmailVerification)
    : super(const EmailVerificationIdle());

  final SendEmailVerificationUseCase _sendEmailVerification;

  Future<void> resend({String? languageCode}) async {
    if (state is EmailVerificationSending) return; // single-flight
    emit(const EmailVerificationSending());
    final result = await _sendEmailVerification(
      SendEmailVerificationParams(languageCode: languageCode),
    );
    if (isClosed) return; // banner bisa unmount saat request in-flight
    result.fold(
      (failure) => emit(EmailVerificationFailed(failure.message)),
      (_) => emit(const EmailVerificationSent()),
    );
  }
}
