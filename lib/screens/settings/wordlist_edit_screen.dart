import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wordlist_provider.dart';

class WordlistEditScreen extends StatefulWidget {
  final int wordlistId;

  const WordlistEditScreen({super.key, required this.wordlistId});

  @override
  State<WordlistEditScreen> createState() => _WordlistEditScreenState();
}

class _WordlistEditScreenState extends State<WordlistEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _wordController = TextEditingController();
  final FocusNode _wordFocusNode = FocusNode();
  final List<String> _words = [];
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadWordlist();
  }

  Future<void> _loadWordlist() async {
    final provider = context.read<WordlistProvider>();
    final wordlist = await provider.getById(widget.wordlistId);
    if (mounted && wordlist != null) {
      setState(() {
        _nameController.text = wordlist.name;
        _words.addAll(wordlist.words);
        _isLoaded = true;
      });
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
    await provider.update(widget.wordlistId, _nameController.text.trim(), _words);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wordlist updated')),
    );
    Navigator.of(context).pop();
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
    if (!_isLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final canSave = _nameController.text.trim().isNotEmpty && _words.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Wordlist'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
            SafeArea(
              child: FilledButton(
                onPressed: canSave ? _save : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Save Changes'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
