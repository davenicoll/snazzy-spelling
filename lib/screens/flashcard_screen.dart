import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../models/wordlist.dart';
import '../providers/settings_provider.dart';
import '../providers/wordlist_provider.dart';
import '../utils/sfx_player.dart';
import '../widgets/word_card.dart';

class FlashcardScreen extends StatefulWidget {
  final int wordlistId;

  const FlashcardScreen({super.key, required this.wordlistId});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final FlutterTts _tts = FlutterTts();
  final SfxPlayer _sfx = SfxPlayer();
  final PageController _pageController = PageController();
  Wordlist? _wordlist;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _initTts();

    final provider = context.read<WordlistProvider>();
    final wordlist = await provider.getById(widget.wordlistId);
    if (mounted && wordlist != null) {
      final sorted = List<String>.from(wordlist.words)..sort();
      setState(() {
        _wordlist = wordlist.copyWith(words: sorted);
      });
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.4);
    await _tts.awaitSpeakCompletion(true);
    if (Platform.isIOS || Platform.isMacOS) {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ],
        IosTextToSpeechAudioMode.defaultMode,
      );
    }
  }

  Future<void> _speak(String word) async {
    await _tts.stop();
    await _tts.speak(word);
  }

  @override
  void dispose() {
    _tts.stop();
    _sfx.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_wordlist == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final words = _wordlist!.words;

    return Scaffold(
      appBar: AppBar(
        title: Text(_wordlist!.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentIndex + 1} of ${words.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: words.length,
            onPageChanged: (index) {
              if (context.read<SettingsProvider>().playSounds) {
                _sfx.play('sounds/swipe.mp3');
              }
              setState(() => _currentIndex = index);
            },
            itemBuilder: (context, index) {
              return WordCard(
                word: words[index],
                onSpeak: () => _speak(words[index]),
              );
            },
          ),
          // Navigation arrows
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton.filledTonal(
                onPressed: _currentIndex > 0
                    ? () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                    : null,
                icon: const Icon(Icons.chevron_left),
                iconSize: 32,
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: IconButton.filledTonal(
                onPressed: _currentIndex < words.length - 1
                    ? () => _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        )
                    : null,
                icon: const Icon(Icons.chevron_right),
                iconSize: 32,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
