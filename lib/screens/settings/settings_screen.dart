import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wordlist_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WordlistProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/main',
              (route) => false,
            );
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance section
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('Auto'),
                            icon: Icon(Icons.brightness_auto),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (selected) {
                          settings.setThemeMode(selected.first);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return Card(
                child: SwitchListTile(
                  title: const Text('Play sounds'),
                  secondary: const Icon(Icons.volume_up_outlined),
                  value: settings.playSounds,
                  onChanged: (value) => settings.setPlaySounds(value),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          // Wordlists section
          Text(
            'Wordlists',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Consumer<WordlistProvider>(
            builder: (context, provider, _) {
              return Column(
                children: [
                  ...provider.wordlists.map((wordlist) => Card(
                        child: ListTile(
                          title: Text(wordlist.name),
                          subtitle: Text(
                            '${wordlist.words.length} word${wordlist.words.length == 1 ? '' : 's'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit',
                                onPressed: () async {
                                  final nav = Navigator.of(context);
                                  final wlProvider = context.read<WordlistProvider>();
                                  await nav.pushNamed(
                                    '/settings/wordlist/edit',
                                    arguments: wordlist.id,
                                  );
                                  if (mounted) {
                                    wlProvider.load();
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                tooltip: 'Delete',
                                onPressed: () => _confirmDelete(
                                    context, provider, wordlist.id!, wordlist.name),
                              ),
                            ],
                          ),
                        ),
                      )),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final nav = Navigator.of(context);
                        final wlProvider = context.read<WordlistProvider>();
                        await nav.pushNamed('/settings/wordlist/create');
                        if (mounted) {
                          wlProvider.load();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Wordlist'),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          // PIN section
          Text(
            'Security',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change PIN'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).pushNamed('/settings/change-pin');
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WordlistProvider provider, int id,
      String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wordlist'),
        content: Text(
          'Are you sure you want to delete "$name"? This will also delete all associated test results. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await provider.delete(id);
              if (context.mounted) Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
