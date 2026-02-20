import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/test_session.dart';
import '../models/test_result.dart';
import '../providers/test_provider.dart';

class TestSummaryScreen extends StatefulWidget {
  final int wordlistId;
  final int sessionId;
  final String wordlistName;

  const TestSummaryScreen({
    super.key,
    required this.wordlistId,
    required this.sessionId,
    required this.wordlistName,
  });

  @override
  State<TestSummaryScreen> createState() => _TestSummaryScreenState();
}

class _TestSummaryScreenState extends State<TestSummaryScreen> {
  TestSession? _session;

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    final provider = context.read<TestProvider>();
    final session = await provider.getSessionWithResults(widget.sessionId);
    if (mounted) {
      setState(() => _session = session);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Complete'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  // Score display
                  if (session.isPerfect)
                    const Text(
                      '⭐',
                      style: TextStyle(fontSize: 64),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    '${session.correctCount} out of ${session.totalWords}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (session.isPerfect) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Perfect score!',
                      style:
                          Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.amber.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Per-word breakdown
                  ...session.results.map((result) => _ResultRow(result: result)),
                  const SizedBox(height: 32),
                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/main',
                            (route) => false,
                          );
                        },
                        child: const Text('Back to Lists'),
                      ),
                      const SizedBox(width: 16),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed(
                            '/wordlist/results',
                            arguments: widget.wordlistId,
                          );
                        },
                        child: const Text('View All Results'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final TestResult result;

  const _ResultRow({required this.result});

  @override
  Widget build(BuildContext context) {
    final isCorrect = result.status.isCorrect;
    final icon = isCorrect ? Icons.check_circle : Icons.cancel;
    final color = isCorrect ? const Color(0xFF0072B2) : Theme.of(context).colorScheme.error;

    String subtitle;
    switch (result.status) {
      case TestResultStatus.correctFirst:
        subtitle = '1st attempt';
      case TestResultStatus.correctSecond:
        subtitle = '2nd attempt';
      case TestResultStatus.incorrect:
        subtitle = 'Incorrect — typed "${result.childAnswer}"';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              result.word,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}
