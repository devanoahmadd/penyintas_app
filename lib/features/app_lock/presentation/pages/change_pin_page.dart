import 'package:flutter/material.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/features/app_lock/presentation/pages/pin_verify_flow_mixin.dart';
import 'package:penyintas_app/features/app_lock/presentation/pages/set_pin_page.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/pin_entry_scaffold.dart';

/// Ubah PIN: verifikasi PIN lama (ber-lockout, lihat [PinVerifyFlowMixin])
/// → dorong [SetPinPage] untuk PIN baru. Selesai set PIN baru → `pop(true)`
/// sampai ke pemanggil (Settings). Batal di tengah set PIN baru → kembali
/// ke input PIN lama, siap dicoba ulang.
class ChangePinPage extends StatefulWidget {
  const ChangePinPage({super.key, required this.uid});

  final String uid;

  @override
  State<ChangePinPage> createState() => _ChangePinPageState();
}

class _ChangePinPageState extends State<ChangePinPage>
    with PinVerifyFlowMixin<ChangePinPage> {
  @override
  Future<void> onVerified() async {
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SetPinPage(uid: widget.uid)),
    );
    if (!mounted) return;
    if (done == true) {
      Navigator.of(context).pop(true);
    } else {
      resetAfterCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locked = lockedSeconds > 0;
    return PinEntryScaffold(
      title: l.applockChangeCurrent,
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
