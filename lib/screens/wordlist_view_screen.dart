import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/wordlist.dart';
import '../providers/settings_provider.dart';
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
    // Ensure the viewed-words cache is populated so the gate renders
    // correctly on first build.
    await provider.loadViewedWords(widget.wordlistId);
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Consumer2<WordlistProvider, SettingsProvider>(
              builder: (context, provider, settings, _) {
                final viewed = provider.viewedWords(widget.wordlistId);
                final gated = _wordlist!.isTestGated(
                  requireFullFlashcardView: settings.requireFullFlashcardView,
                  viewedWords: viewed,
                );
                final remaining = _wordlist!.words
                    .where((w) => !viewed.contains(w))
                    .length;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OptionCard(
                      icon: Icons.style_outlined,
                      title: 'Flash Cards',
                      subtitle: 'Learn and review the words',
                      onTap: () async {
                        final wlProvider =
                            context.read<WordlistProvider>();
                        await Navigator.of(context).pushNamed(
                          '/wordlist/flashcards',
                          arguments: widget.wordlistId,
                        );
                        // Refresh viewed-word cache when returning, in case
                        // the flashcard screen's notifications were missed
                        // during a rebuild.
                        if (mounted) {
                          await wlProvider
                              .loadViewedWords(widget.wordlistId);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    _OptionCard(
                      icon: Icons.sports_esports_outlined,
                      title: 'Spelling Game',
                      subtitle: 'Spell the word, letter by letter',
                      onTap: () {
                        Navigator.of(context).pushNamed(
                          '/wordlist/game',
                          arguments: widget.wordlistId,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _OptionCard(
                      icon: Icons.quiz_outlined,
                      title: 'Test',
                      subtitle: 'Listen and spell each word',
                      disabled: gated,
                      disabledTooltip: gated
                          ? 'View all flashcards first'
                              ' ($remaining word${remaining == 1 ? '' : 's'} left)'
                          : null,
                      onTap: gated
                          ? null
                          : () {
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
                );
              },
            ),
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
  final VoidCallback? onTap;
  final bool disabled;
  final String? disabledTooltip;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.disabled = false,
    this.disabledTooltip,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dimOpacity = disabled ? 0.38 : 1.0;

    final card = Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: disabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Opacity(
            opacity: dimOpacity,
            child: Row(
              children: [
                Icon(icon, size: 40, color: colorScheme.primary),
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
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  disabled ? Icons.lock_outline : Icons.chevron_right,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (disabled && disabledTooltip != null) {
      return Tooltip(
        message: disabledTooltip!,
        triggerMode: TooltipTriggerMode.tap,
        showDuration: const Duration(seconds: 3),
        child: card,
      );
    }
    return card;
  }
}
