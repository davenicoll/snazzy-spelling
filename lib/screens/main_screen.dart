import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../providers/wordlist_provider.dart';
import '../utils/sfx_player.dart';
import '../widgets/completed_pill.dart';
import '../widgets/sort_controls.dart';
import 'package:intl/intl.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static bool _startupPlayed = false;
  SfxPlayer? _sfx;

  @override
  void initState() {
    super.initState();
    context.read<WordlistProvider>().load();
    if (!_startupPlayed) {
      _startupPlayed = true;
      if (context.read<SettingsProvider>().playSounds) {
        _sfx = SfxPlayer();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _sfx?.play('sounds/startup.mp3');
        });
      }
    }
  }

  @override
  void dispose() {
    _sfx?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snazzy Spelling'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.settings),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.of(context).pushNamed(
                  '/pin-entry',
                  arguments: '/settings',
                );
              },
            ),
          ),
        ],
      ),
      body: Consumer<WordlistProvider>(
        builder: (context, provider, _) {
          if (!provider.hasWordlists) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No wordlists yet',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Open settings to create your first wordlist',
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
            );
          }

          return Column(
            children: [
              SortControls(
                sortField: provider.sortField,
                sortDirection: provider.sortDirection,
                onToggleSort: provider.toggleSort,
                hideCompleted: provider.hideCompleted,
                onHideCompletedChanged: provider.setHideCompleted,
              ),
              Expanded(
                child: provider.wordlists.isEmpty
                    ? _AllHiddenNotice(
                        onShowCompleted: () =>
                            provider.setHideCompleted(false),
                      )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.wordlists.length,
                  itemBuilder: (context, index) {
                    final wordlist = provider.wordlists[index];
                    final dateFormat = DateFormat('d MMM yyyy');
                    return Card(
                      child: ListTile(
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                wordlist.name,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ),
                            if (wordlist.isCompleted) ...[
                              const SizedBox(width: 8),
                              const CompletedPill(),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          '${wordlist.words.length} word${wordlist.words.length == 1 ? '' : 's'} · ${dateFormat.format(wordlist.createdAt)}',
                        ),
                        trailing:
                            const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            '/wordlist/view',
                            arguments: wordlist.id,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AllHiddenNotice extends StatelessWidget {
  final VoidCallback onShowCompleted;

  const _AllHiddenNotice({required this.onShowCompleted});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_alt_outlined,
              size: 48,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              'All wordlists are completed',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onShowCompleted,
              child: const Text('Show completed'),
            ),
          ],
        ),
      ),
    );
  }
}
