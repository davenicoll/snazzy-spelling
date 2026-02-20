import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/pin_input.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  bool _verifiedOldPin = false;
  String? _newPin;
  String? _errorMessage;

  Future<void> _onPinEntered(String pin) async {
    final settings = context.read<SettingsProvider>();

    if (!_verifiedOldPin) {
      // Verifying current PIN
      final isCorrect = await settings.verifyPin(pin);
      if (!mounted) return;

      if (isCorrect) {
        setState(() {
          _verifiedOldPin = true;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN. Please try again.';
        });
      }
    } else if (_newPin == null) {
      // Setting new PIN
      setState(() {
        _newPin = pin;
        _errorMessage = null;
      });
    } else {
      // Confirming new PIN
      if (pin == _newPin) {
        await settings.changePin(pin);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN changed successfully')),
        );
        Navigator.of(context).pop();
      } else {
        setState(() {
          _newPin = null;
          _errorMessage = 'PINs do not match. Please try again.';
        });
      }
    }
  }

  String get _title {
    if (!_verifiedOldPin) return 'Enter Current PIN';
    if (_newPin == null) return 'Enter New PIN';
    return 'Confirm New PIN';
  }

  String get _subtitle {
    if (!_verifiedOldPin) return 'Verify your current PIN to continue';
    if (_newPin == null) return 'Choose a new 4-digit PIN';
    return 'Enter the new PIN again';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change PIN'),
      ),
      body: PinInput(
        key: ValueKey('$_verifiedOldPin-${_newPin != null}'),
        title: _title,
        subtitle: _subtitle,
        errorMessage: _errorMessage,
        onCompleted: _onPinEntered,
      ),
    );
  }
}
