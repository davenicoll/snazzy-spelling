import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/test_session.dart';
import '../providers/test_provider.dart';
import '../providers/wordlist_provider.dart';

class ResultsHistoryScreen extends StatefulWidget {
  final int wordlistId;

  const ResultsHistoryScreen({super.key, required this.wordlistId});

  @override
  State<ResultsHistoryScreen> createState() => _ResultsHistoryScreenState();
}

class _ResultsHistoryScreenState extends State<ResultsHistoryScreen> {
  List<TestSession>? _sessions;
  String _wordlistName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final testProvider = context.read<TestProvider>();
    final wordlistProvider = context.read<WordlistProvider>();

    final sessions =
        await testProvider.getSessionsForWordlist(widget.wordlistId);
    final wordlist = await wordlistProvider.getById(widget.wordlistId);

    if (mounted) {
      setState(() {
        _sessions = sessions;
        _wordlistName = wordlist?.name ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_sessions == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Results: $_wordlistName'),
      ),
      body: _sessions!.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bar_chart_outlined,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No test results yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Complete a test to see your results here',
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
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sessions!.length,
              itemBuilder: (context, index) {
                final session = _sessions![index];
                final dateFormat = DateFormat('EEEE, d MMMM yyyy · h:mm a');

                return Card(
                  child: ListTile(
                    leading: session.isPerfect
                        ? const Text('⭐', style: TextStyle(fontSize: 24))
                        : null,
                    title: Text(
                      '${session.correctCount} out of ${session.totalWords}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      dateFormat.format(session.completedAt.toLocal()),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        '/wordlist/result-detail',
                        arguments: session.id,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
