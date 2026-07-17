import 'package:flutter/material.dart';
import 'package:penyintas_app/core/di/injection_container.dart';
import 'package:penyintas_app/core/l10n/app_localizations_ext.dart';
import 'package:penyintas_app/features/app_lock/domain/repositories/app_lock_repository.dart';
import 'package:penyintas_app/features/app_lock/presentation/widgets/pin_entry_scaffold.dart';

/// Set PIN awal (atau PIN baru saat ganti PIN): masukkan 6 digit → ulangi
/// untuk konfirmasi. Bila cocok → `repo.setPin` lalu `onDone`/`pop(true)`.
/// Bila tak cocok → tampil pesan mismatch dan kembali ke langkah pertama.
class SetPinPage extends StatefulWidget {
  const SetPinPage({super.key, required this.uid, this.onDone});

  final String uid;
  final VoidCallback? onDone;

  @override
  State<SetPinPage> createState() => _SetPinPageState();
}

class _SetPinPageState extends State<SetPinPage> {
  String _first = '';
  String _pin = '';
  bool _confirming = false;
  bool _mismatch = false;

  void _onDigit(String d) {
    if (_pin.length >= 6) return;
    setState(() {
      _mismatch = false;
      _pin += d;
    });
    if (_pin.length == 6) _handleComplete();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _handleComplete() async {
    if (!_confirming) {
      setState(() {
        _first = _pin;
        _pin = '';
        _confirming = true;
      });
      return;
    }
    if (_pin == _first) {
      await sl<AppLockRepository>().setPin(_pin, widget.uid);
      if (!mounted) return;
      widget.onDone?.call();
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _mismatch = true;
        _pin = '';
        _first = '';
        _confirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return PinEntryScaffold(
      title: _confirming ? l.applockConfirmTitle : l.applockSetTitle,
      subtitle: _confirming ? l.applockConfirmSubtitle : l.applockSetSubtitle,
      message: _mismatch ? l.applockMismatch : '',
      filled: _pin.length,
      onDigit: _onDigit,
      onBackspace: _onBackspace,
    );
  }
}
