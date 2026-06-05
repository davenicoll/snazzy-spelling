import 'package:flutter/material.dart';

import 'tap_button.dart';

class PinInput extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? errorMessage;
  final ValueChanged<String> onCompleted;

  const PinInput({
    super.key,
    required this.title,
    this.subtitle,
    this.errorMessage,
    required this.onCompleted,
  });

  @override
  State<PinInput> createState() => _PinInputState();
}

class _PinInputState extends State<PinInput>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void didUpdateWidget(PinInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorMessage != null && oldWidget.errorMessage == null) {
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });
      setState(() => _pin = '');
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onKeyPressed(String key) {
    if (key == 'backspace') {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
    } else if (_pin.length < 4) {
      final newPin = _pin + key;
      setState(() => _pin = newPin);
      if (newPin.length == 4) {
        widget.onCompleted(newPin);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _shakeController.status == AnimationStatus.dismissed
                          ? 0
                          : _shakeAnimation.value *
                              (_shakeController.value > 0.5 ? -1 : 1),
                      0,
                    ),
                    child: child,
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < _pin.length
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: widget.errorMessage != null
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (widget.errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  widget.errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 40),
              _buildNumpad(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Column(
        children: [
          for (final row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['', '0', 'backspace'],
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((key) {
                  if (key.isEmpty) {
                    return const SizedBox(width: 80, height: 60);
                  }
                  final scheme = Theme.of(context).colorScheme;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: TapButton(
                      width: 80,
                      height: 60,
                      color: scheme.secondaryContainer,
                      pressedColor: scheme.inversePrimary,
                      onPressed: () => _onKeyPressed(key),
                      child: key == 'backspace'
                          ? Icon(Icons.backspace_outlined,
                              color: scheme.onSecondaryContainer)
                          : Text(
                              key,
                              style: TextStyle(
                                fontSize: 24,
                                color: scheme.onSecondaryContainer,
                              ),
                            ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
