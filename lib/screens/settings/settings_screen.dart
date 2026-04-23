import 'dart:io';
import 'dart:typed_data';

import 'package:android_intent_plus/android_intent.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/color_theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wordlist_provider.dart';
import '../../services/backup_service.dart';
import '../../widgets/completed_pill.dart';

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
                      const SizedBox(height: 16),
                      Text(
                        'Color',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: ColorTheme.values.map((theme) {
                          final selected = settings.colorTheme == theme;
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: GestureDetector(
                              onTap: () => settings.setColorTheme(theme),
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: theme.seedColor,
                                      shape: BoxShape.circle,
                                      border: selected
                                          ? Border.all(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                              width: 3,
                                            )
                                          : null,
                                    ),
                                    child: selected
                                        ? const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    theme.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : null,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
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
          // Text-to-speech section
          Text(
            'Text-to-speech',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Consumer<SettingsProvider>(
            builder: (context, settings, _) {
              return Card(
                child: SwitchListTile(
                  secondary: const Icon(Icons.style_outlined),
                  title: const Text(
                    'Require all flashcards viewed before test',
                  ),
                  subtitle: const Text(
                    'Disables the test on every wordlist until each word '
                    'has been viewed as a flashcard.',
                  ),
                  value: settings.requireFullFlashcardView,
                  onChanged: (value) =>
                      settings.setRequireFullFlashcardView(value),
                ),
              );
            },
          ),
          if (Platform.isAndroid) ...[
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.record_voice_over_outlined),
                title: const Text('System TTS Settings'),
                subtitle: const Text('Change voice, speed, and language'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () {
                  const AndroidIntent(
                    action: 'com.android.settings.TTS_SETTINGS',
                  ).launch();
                },
              ),
            ),
          ],
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
              // Admin settings intentionally ignores the main-screen
              // "hide completed" preference and sort controls — this list
              // is always every wordlist, newest first, for reliable
              // management.
              final adminWordlists = provider.allWordlistsByCreatedDesc;
              return Column(
                children: [
                  ...adminWordlists.map((wordlist) => Card(
                        child: ListTile(
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  wordlist.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (wordlist.isCompleted) ...[
                                const SizedBox(width: 8),
                                const CompletedPill(),
                              ],
                            ],
                          ),
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
          // Backup & Restore section
          Text(
            'Backup & Restore',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Backup to file'),
              onTap: _handleBackup,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore from file'),
              onTap: _handleRestore,
            ),
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

  Future<void> _handleBackup() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await BackupService().exportToBytes();
      final timestamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
      final fileName = 'snazzy-spelling-backup-$timestamp.ssbk';

      String? savedPath;
      try {
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save backup',
          fileName: fileName,
          type: FileType.any,
          bytes: bytes,
        );
      } on UnimplementedError {
        // Desktop/web fallback: saveFile may not accept bytes directly — ask
        // for a path, then write ourselves.
        savedPath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save backup',
          fileName: fileName,
          type: FileType.any,
        );
        if (savedPath != null) {
          await File(savedPath).writeAsBytes(bytes, flush: true);
        }
      }

      if (!mounted) return;
      if (savedPath == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Backup cancelled.')),
        );
      } else {
        // On Android with bytes provided, saveFile returns the chosen URI
        // and the plugin has already written the bytes — no extra work here.
        // On desktop the File().writeAsBytes above handled it.
        messenger.showSnackBar(
          const SnackBar(content: Text('Backup saved.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog('Backup failed', e.toString());
    }
  }

  Future<void> _handleRestore() async {
    final messenger = ScaffoldMessenger.of(context);
    final wordlistProvider = context.read<WordlistProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from file?'),
        content: const Text(
          'This will replace all wordlists, tests and results on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Choose backup file',
        type: FileType.any,
        withData: true,
      );
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog('Restore failed', e.toString());
      return;
    }

    if (!mounted) return;
    if (result == null || result.files.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Restore cancelled.')),
      );
      return;
    }

    final Uint8List? bytes = result.files.single.bytes;
    if (bytes == null) {
      await _showErrorDialog('Restore failed',
          'Could not read file contents. Your existing data was not changed.');
      return;
    }

    try {
      final summary = await BackupService().importFromBytes(bytes);
      if (!mounted) return;
      await wordlistProvider.load();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Restored ${summary.wordlists} wordlists, '
            '${summary.words} words, '
            '${summary.results} test results.',
          ),
        ),
      );
    } on BackupFormatException catch (e) {
      if (!mounted) return;
      await _showErrorDialog(
          'Invalid backup file', e.message);
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog('Restore failed',
          '$e. Your existing data was not changed.');
    }
  }

  Future<void> _showErrorDialog(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
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
