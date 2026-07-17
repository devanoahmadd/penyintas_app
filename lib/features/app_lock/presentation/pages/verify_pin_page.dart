import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/features/app_lock/presentation/pages/pin_verify_flow_mixin.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/pin_entry_scaffold.dart';

/// Verifikasi PIN saat ini → `pop(true)`. Dipakai Settings (mis. sebelum
/// `disableLock()`). Tunduk lockout progresif yang sama dengan LockScreen
/// (lihat [PinVerifyFlowMixin]).
class VerifyPinPage extends StatefulWidget {
  const VerifyPinPage({super.key, required this.title});

  final String title;

  @override
  State<VerifyPinPage> createState() => _VerifyPinPageState();
}

class _VerifyPinPageState extends State<VerifyPinPage>
    with PinVerifyFlowMixin<VerifyPinPage> {
  @override
  Future<void> onVerified() async {
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locked = lockedSeconds > 0;
    return PinEntryScaffold(
      title: widget.title,
      message: locked
          ? l.applockLockedWait(lockedSeconds)
          : (wrong ? l.applockWrong : ''),
      filled: pin.length,
      onDigit: onDigit,
      onBackspace: onBackspace,
      keypadEnabled: !locked,
    );
  }
}
