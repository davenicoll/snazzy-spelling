import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/wordlist_provider.dart';

class WordlistCreateScreen extends StatefulWidget {
  final bool firstLaunch;

  const WordlistCreateScreen({super.key, this.firstLaunch = false});

  @override
  State<WordlistCreateScreen> createState() => _WordlistCreateScreenState();
}

class _WordlistCreateScreenState extends State<WordlistCreateScreen> {
  late final TextEditingController _nameController;
  final TextEditingController _wordController = TextEditingController();
  final List<String> _words = [];
  final FocusNode _wordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final day = now.day;
    final suffix = _daySuffix(day);
    final formatted = DateFormat("EEEE, d'$suffix' MMMM, yyyy").format(now);
    _nameController = TextEditingController(text: formatted);
  }

  String _daySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  void _addWord() {
    final word = _wordController.text.trim();
    if (word.isNotEmpty && !_words.contains(word.toLowerCase())) {
      setState(() {
        _words.add(word);
        _wordController.clear();
      });
      _wordFocusNode.requestFocus();
    }
  }

  void _removeWord(int index) {
    setState(() => _words.removeAt(index));
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty || _words.isEmpty) return;

    final provider = context.read<WordlistProvider>();
    await provider.create(_nameController.text.trim(), _words);

    if (!mounted) return;

    if (!widget.firstLaunch) {
      Navigator.of(context).pop();
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Wordlist Created'),
        content: const Text('What would you like to do next?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed(
                '/settings/wordlist/create',
                arguments: true,
              );
            },
            child: const Text('Create More Wordlists'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/main',
                (route) => false,
              );
            },
            child: const Text('Ready to Start'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _wordController.dispose();
    _wordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _nameController.text.trim().isNotEmpty && _words.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Wordlist'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Name field
            TextField(
              controller: _nameController,
              maxLength: 255,
              decoration: const InputDecoration(
                labelText: 'Wordlist Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            // Add word field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wordController,
                    focusNode: _wordFocusNode,
                    decoration: const InputDecoration(
                      labelText: 'Add a word',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addWord(),
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addWord,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Word list
            if (_words.isNotEmpty)
              Text(
                '${_words.length} word${_words.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: _words.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_words[index]),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _removeWord(index),
                    ),
                  );
                },
              ),
            ),
            // Save button
            SafeArea(
              child: FilledButton(
                onPressed: canSave ? _save : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Save Wordlist'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
