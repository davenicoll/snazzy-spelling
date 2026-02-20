import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/wordlist.dart';
import '../providers/wordlist_provider.dart';

class WordlistViewScreen extends StatefulWidget {
  final int wordlistId;

  const WordlistViewScreen({super.key, required this.wordlistId});

  @override
  State<WordlistViewScreen> createState() => _WordlistViewScreenState();
}

class _WordlistViewScreenState extends State<WordlistViewScreen> {
  Wordlist? _wordlist;

  @override
  void initState() {
    super.initState();
    _loadWordlist();
  }

  Future<void> _loadWordlist() async {
    final provider = context.read<WordlistProvider>();
    final wordlist = await provider.getById(widget.wordlistId);
    if (mounted) {
      setState(() => _wordlist = wordlist);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_wordlist == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_wordlist!.name),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OptionCard(
                  icon: Icons.style_outlined,
                  title: 'Flash Cards',
                  subtitle: 'Learn and review the words',
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/wordlist/flashcards',
                      arguments: widget.wordlistId,
                    );
                  },
                ),
                const SizedBox(height: 16),
                _OptionCard(
                  icon: Icons.quiz_outlined,
                  title: 'Test',
                  subtitle: 'Listen and spell each word',
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/wordlist/test',
                      arguments: widget.wordlistId,
                    );
                  },
                ),
                const SizedBox(height: 16),
                _OptionCard(
                  icon: Icons.bar_chart_outlined,
                  title: 'Test Results',
                  subtitle: 'View past test scores',
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      '/wordlist/results',
                      arguments: widget.wordlistId,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
