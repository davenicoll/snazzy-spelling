import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../models/wordlist.dart';
import '../models/test_result.dart';
import '../providers/settings_provider.dart';
import '../providers/wordlist_provider.dart';
import '../providers/test_provider.dart';
import '../utils/sfx_player.dart';
import '../widgets/qwerty_keyboard.dart';

class TestScreen extends StatefulWidget {
  final int wordlistId;

  const TestScreen({super.key, required this.wordlistId});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final FlutterTts _tts = FlutterTts();
  final SfxPlayer _sfx = SfxPlayer();
  Wordlist? _wordlist;
  List<String> _words = [];
  int _currentIndex = 0;
  String _typedText = '';
  int _attemptNumber = 1;
  String? _feedback;
  Color? _feedbackColor;
  bool _showCorrection = false;
  bool _isSpeaking = false;
  String? _firstAttemptText;

  final List<TestResult> _results = [];

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
        _wordlist = wordlist;
        _words = sorted;
      });
      _speakCurrentWord();
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.4);
    await _tts.awaitSpeakCompletion(true);
    _tts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setErrorHandler((msg) {
      if (mounted) setState(() => _isSpeaking = false);
    });
    if (Platform.isIOS) {
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

  Future<void> _playSound(String asset) async {
    if (context.read<SettingsProvider>().playSounds) {
      await _sfx.play('sounds/$asset');
    }
  }

  Future<void> _speakCurrentWord() async {
    if (_currentIndex < _words.length) {
      await _tts.stop();
      await _tts.speak(_words[_currentIndex]);
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onKeyPressed(String letter) {
    if (_showCorrection) return;
    setState(() => _typedText += letter);
  }

  void _onBackspace() {
    if (_showCorrection) return;
    if (_typedText.isNotEmpty) {
      setState(() => _typedText = _typedText.substring(0, _typedText.length - 1));
    }
  }

  void _onSubmit() {
    if (_typedText.isEmpty || _showCorrection) return;

    final correctWord = _words[_currentIndex];
    final isCorrect =
        _typedText.trim().toLowerCase() == correctWord.toLowerCase();

    if (isCorrect) {
      final status = _attemptNumber == 1
          ? TestResultStatus.correctFirst
          : TestResultStatus.correctSecond;
      _results.add(TestResult(
        sessionId: 0,
        word: correctWord,
        status: status,
        firstAttempt: _firstAttemptText,
      ));
      _playSound('correct.mp3');
      setState(() {
        _feedback = 'Correct!';
        _feedbackColor = context.read<SettingsProvider>().colorTheme.correctColor;
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) _moveToNextWord();
      });
    } else if (_attemptNumber == 1) {
      // First wrong attempt
      _firstAttemptText = _typedText.trim();
      _playSound('wrong.mp3');
      setState(() {
        _attemptNumber = 2;
        _typedText = '';
        _feedback = 'Try again';
        _feedbackColor = context.read<SettingsProvider>().colorTheme.incorrectColor;
      });
      _tts.stop().then((_) => _tts.speak(correctWord));
    } else {
      // Second wrong attempt
      _playSound('wrong.mp3');
      _results.add(TestResult(
        sessionId: 0,
        word: correctWord,
        status: TestResultStatus.incorrect,
        firstAttempt: _firstAttemptText,
        childAnswer: _typedText.trim(),
      ));
      setState(() {
        _showCorrection = true;
        _feedback = null;
      });
    }
  }

  void _moveToNextWord() {
    if (_currentIndex + 1 >= _words.length) {
      _finishTest();
      return;
    }

    setState(() {
      _currentIndex++;
      _typedText = '';
      _attemptNumber = 1;
      _firstAttemptText = null;
      _feedback = null;
      _feedbackColor = null;
      _showCorrection = false;
    });
    _speakCurrentWord();
  }

  Future<void> _finishTest() async {
    _playSound('finish.mp3');
    final correctCount =
        _results.where((r) => r.status.isCorrect).length;
    final testProvider = context.read<TestProvider>();
    final session = await testProvider.saveSession(
      wordlistId: widget.wordlistId,
      totalWords: _words.length,
      correctCount: correctCount,
      results: _results,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(
      '/wordlist/test-summary',
      arguments: {
        'wordlistId': widget.wordlistId,
        'sessionId': session.id,
        'wordlistName': _wordlist?.name ?? '',
      },
    );
  }

  @override
  void dispose() {
    _tts.stop();
    _sfx.dispose();
    super.dispose();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Leave test?'),
                content: const Text(
                    'Your progress will be lost if you leave now.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Stay'),
                  ),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Leave'),
                  ),
                ],
              ),
            );
          },
        ),
        title: Text('Test: ${_wordlist!.name}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentIndex + 1} of ${_words.length}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top area: typed text display + feedback
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _showCorrection
                      ? _buildCorrectionView()
                      : _buildTypingView(),
                ),
              ),
            ),
            // Keyboard area — capped at 40% of screen height
            if (!_showCorrection)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: QwertyKeyboard(
                    onKeyPressed: _onKeyPressed,
                    onBackspace: _onBackspace,
                    onSubmit: _onSubmit,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Replay button
        IconButton.filledTonal(
          onPressed: _isSpeaking
              ? null
              : () {
                  if (_currentIndex < _words.length) {
                    _tts.speak(_words[_currentIndex]);
                  }
                },
          icon: const Icon(Icons.volume_up),
          iconSize: 32,
          tooltip: 'Listen again',
        ),
        const SizedBox(height: 16),
        // Typed text display
        Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outline,
                width: 2,
              ),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _typedText.isEmpty ? ' ' : _typedText,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 114,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                    color: _typedText.isEmpty ? Colors.transparent : null,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ),
        if (_feedback != null) ...[
          const SizedBox(height: 8),
          Text(
            _feedback!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: _feedbackColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildCorrectionView() {
    final correctWord = _words[_currentIndex];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'The correct spelling is:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 12),
        Text(
          correctWord,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: context.read<SettingsProvider>().colorTheme.correctColor,
              ),
        ),
        const SizedBox(height: 24),
        Text(
          'You wrote:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 12),
        Text(
          _typedText,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.error,
              ),
        ),
        const SizedBox(height: 40),
        FilledButton.icon(
          onPressed: _moveToNextWord,
          icon: const Icon(Icons.arrow_forward),
          label: Text(
            _currentIndex + 1 >= _words.length ? 'Finish' : 'Next Word',
          ),
        ),
      ],
    );
  }
}
