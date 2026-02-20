import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/pin_input.dart';

class PinSetupScreen extends StatefulWidget {
  final bool isChangingPin;

  const PinSetupScreen({super.key, this.isChangingPin = false});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String? _firstPin;
  String? _errorMessage;

  void _onPinEntered(String pin) {
    if (_firstPin == null) {
      setState(() {
        _firstPin = pin;
        _errorMessage = null;
      });
    } else {
      if (pin == _firstPin) {
        _savePin(pin);
      } else {
        setState(() {
          _firstPin = null;
          _errorMessage = 'PINs do not match. Please try again.';
        });
      }
    }
  }

  Future<void> _savePin(String pin) async {
    final settings = context.read<SettingsProvider>();
    if (widget.isChangingPin) {
      await settings.changePin(pin);
    } else {
      await settings.setPin(pin);
    }

    if (!mounted) return;

    if (widget.isChangingPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN changed successfully')),
      );
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(
        '/settings/wordlist/create',
        arguments: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isChangingPin
          ? AppBar(title: const Text('Change PIN'))
          : null,
      body: Column(
        children: [
          if (!widget.isChangingPin) ...[
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Welcome, parent!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                "Let's set up parent access so only you can manage settings.",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          Expanded(
            child: PinInput(
              key: ValueKey('pin-step-${_firstPin != null}'),
              title: _firstPin == null ? 'Create a PIN' : 'Confirm your PIN',
              subtitle: _firstPin == null
                  ? 'Choose a 4-digit PIN'
                  : 'Enter the same PIN again',
              errorMessage: _errorMessage,
              onCompleted: _onPinEntered,
            ),
          ),
        ],
      ),
    );
  }
}
