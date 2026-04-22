import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/test_session.dart';
import '../models/test_result.dart';
import '../providers/settings_provider.dart';
import '../providers/test_provider.dart';

class ResultDetailScreen extends StatefulWidget {
  final int sessionId;

  const ResultDetailScreen({super.key, required this.sessionId});

  @override
  State<ResultDetailScreen> createState() => _ResultDetailScreenState();
}

class _ResultDetailScreenState extends State<ResultDetailScreen> {
  TestSession? _session;
  // Mirror the post-test summary screen: cap the emission loop at the
  // controller level, stop explicitly after ~5s, and dispose on teardown so
  // no particles or timers linger when the user leaves the screen.
  static const Duration _confettiDuration = Duration(seconds: 5);
  final ConfettiController _confettiController =
      ConfettiController(duration: _confettiDuration);

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final provider = context.read<TestProvider>();
    final session = await provider.getSessionWithResults(widget.sessionId);
    if (!mounted) return;
    setState(() => _session = session);
    if (session != null && session.isPerfect) {
      _confettiController.play();
      Future.delayed(_confettiDuration, () {
        if (mounted) _confettiController.stop();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final session = _session!;
    final dateFormat = DateFormat('EEEE, d MMMM yyyy · h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Detail'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          if (session.isPerfect)
                            const Text('⭐', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 8),
                          Text(
                            '${session.correctCount} out of ${session.totalWords}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            dateFormat.format(session.completedAt.toLocal()),
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Results
                    ...session.results.map((result) => _DetailRow(result: result)),
                  ],
                ),
              ),
            ),
          ),
          // Non-blocking confetti overlay: IgnorePointer lets taps fall
          // through, and the controller is stopped+disposed in _loadSession /
          // dispose so no timers or particles linger.
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2, // straight down
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.05,
                numberOfParticles: 12,
                maxBlastForce: 20,
                minBlastForce: 8,
                gravity: 0.25,
                shouldLoop: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final TestResult result;

  const _DetailRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final isCorrect = result.status.isCorrect;
    final icon = isCorrect ? Icons.check_circle : Icons.cancel;
    final colorTheme = context.read<SettingsProvider>().colorTheme;
    final color = isCorrect ? colorTheme.correctColor : colorTheme.incorrectColor;

    String attemptText;
    switch (result.status) {
      case TestResultStatus.correctFirst:
        attemptText = '1st attempt';
      case TestResultStatus.correctSecond:
        attemptText = '2nd attempt';
      case TestResultStatus.incorrect:
        attemptText = 'Incorrect';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.word,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (result.status == TestResultStatus.correctSecond &&
                    result.firstAttempt != null)
                  Text(
                    '1st: "${result.firstAttempt}"',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                if (result.status == TestResultStatus.incorrect) ...[
                  if (result.firstAttempt != null)
                    Text(
                      '1st: "${result.firstAttempt}"',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  if (result.childAnswer != null)
                    Text(
                      '2nd: "${result.childAnswer}"',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                ],
              ],
            ),
          ),
          Text(
            attemptText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
