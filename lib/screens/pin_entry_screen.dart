import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/pin_input.dart';

class PinEntryScreen extends StatefulWidget {
  final String destination;

  const PinEntryScreen({super.key, required this.destination});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  String? _errorMessage;

  Future<void> _onPinEntered(String pin) async {
    final settings = context.read<SettingsProvider>();
    final isCorrect = await settings.verifyPin(pin);

    if (!mounted) return;

    if (isCorrect) {
      Navigator.of(context).pushReplacementNamed(widget.destination);
    } else {
      setState(() {
        _errorMessage = 'Incorrect PIN. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PinInput(
        title: 'Enter PIN',
        subtitle: 'Enter your 4-digit PIN to access settings',
        errorMessage: _errorMessage,
        onCompleted: _onPinEntered,
      ),
    );
  }
}
