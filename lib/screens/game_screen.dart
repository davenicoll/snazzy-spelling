import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:provider/provider.dart';
import '../models/wordlist.dart';
import '../providers/settings_provider.dart';
import '../providers/wordlist_provider.dart';
import '../utils/sfx_player.dart';
import '../widgets/qwerty_keyboard.dart';
import '../widgets/tap_button.dart';

/// "Spelling Game" mode: a word is spoken and the child spells it one letter at
/// a time. Each correct letter chirps and is revealed; a wrong letter buzzes and
/// is ignored. After three mistakes the correct spelling is shown and read out,
/// then play moves on. Nothing is recorded — this is a low-stakes practice step
/// between Flash Cards and the Test.
class GameScreen extends StatefulWidget {
  final int wordlistId;

  const GameScreen({super.key, required this.wordlistId});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  static const _maxMistakes = 3;
  static const _heartColor = Color(0xFFE53935);

  final FlutterTts _tts = FlutterTts();
  final SfxPlayer _sfx = SfxPlayer();

  // Drives the 3-quick-blinks of the skulls when the last life is lost.
  late final AnimationController _blinkController;
  bool _blinkingSkulls = false;

  Wordlist? _wordlist;
  List<String> _words = [];
  int _currentIndex = 0;

  /// Number of leading characters of the current word that have been revealed
  /// (correctly typed, plus any auto-revealed non-letter characters).
  int _progress = 0;
  int _mistakes = 0;
  bool _completed = false; // word spelled correctly
  bool _failed = false; // ran out of mistakes; correct spelling revealed
  bool _isSpeaking = false;
  bool _finished = false; // whole list played through

  int _correctWords = 0;

  String get _target => _words[_currentIndex];

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _init();
  }

  Future<void> _init() async {
    _initTts();

    final provider = context.read<WordlistProvider>();
    final wordlist = await provider.getById(widget.wordlistId);
    if (mounted && wordlist != null) {
      final shuffled = List<String>.from(wordlist.words)..shuffle(Random());
      setState(() {
        _wordlist = wordlist;
        _words = shuffled;
      });
      _startWord();
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

  bool _isTypable(String char) {
    if (char.length != 1) return false;
    final c = char.toLowerCase().codeUnitAt(0);
    return c >= 0x61 && c <= 0x7a; // a-z
  }

  /// Advance [_progress] past any leading non-typeable characters (spaces,
  /// apostrophes, hyphens) so the child is only ever asked for letters.
  void _skipNonTypable() {
    while (_progress < _target.length && !_isTypable(_target[_progress])) {
      _progress++;
    }
  }

  void _startWord() {
    setState(() {
      _progress = 0;
      _mistakes = 0;
      _completed = false;
      _failed = false;
      _skipNonTypable();
    });
    if (_progress >= _target.length) {
      // Degenerate word with no typeable letters — count it and move on.
      _completed = true;
      return;
    }
    _speakWord();
  }

  Future<void> _speakWord() async {
    await _tts.stop();
    await _tts.speak(_target);
  }

  void _onKeyPressed(String letter) {
    if (_completed || _failed || _blinkingSkulls) return;

    final expected = _target[_progress];
    if (letter.toLowerCase() == expected.toLowerCase()) {
      _playSound('chirp.mp3');
      setState(() {
        _progress++;
        _skipNonTypable();
      });
      if (_progress >= _target.length) {
        _correctWords++;
        _playSound('correct.mp3');
        setState(() => _completed = true);
      }
    } else {
      // Wrong letter: ignore the entry, count a mistake.
      _playSound('wrong.mp3');
      setState(() => _mistakes++);
      if (_mistakes >= _maxMistakes) {
        _startFailSequence();
      }
    }
  }

  /// Out of lives: blink the three skulls 3× quickly, then reveal the answer.
  void _startFailSequence() {
    setState(() => _blinkingSkulls = true);
    _blinkController.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() => _blinkingSkulls = false);
      _failWord();
    });
  }

  void _failWord() {
    setState(() => _failed = true);
    final spelled = _target
        .split('')
        .where((c) => c.trim().isNotEmpty)
        .join(', ');
    _tts
        .stop()
        .then((_) => _tts.speak('That is incorrect. $_target is spelled $spelled'));
  }

  void _nextWord() {
    if (_currentIndex + 1 >= _words.length) {
      setState(() => _finished = true);
      _tts.stop();
      _playSound('finish.mp3');
      return;
    }
    setState(() => _currentIndex++);
    _startWord();
  }

  @override
  void dispose() {
    _blinkController.dispose();
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

    if (_finished) {
      return _buildFinishView();
    }

    final showKeyboard = !_completed && !_failed;

    return Scaffold(
      appBar: AppBar(
        title: Text('Game: ${_wordlist!.name}'),
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
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: _completed
                        ? _buildCompletedView()
                        : _failed
                            ? _buildFailedView()
                            : _buildPlayingView(),
                  ),
                ),
              ),
            ),
            if (showKeyboard)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: QwertyKeyboard(
                    onKeyPressed: _onKeyPressed,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'Listen again',
          child: TapIconButton(
            icon: Icons.volume_up,
            iconSize: 32,
            semanticLabel: 'Listen again',
            onPressed: _isSpeaking ? null : _speakWord,
          ),
        ),
        const SizedBox(height: 24),
        _buildWordSlots(),
        const SizedBox(height: 24),
        _buildLives(),
      ],
    );
  }

  Widget _buildCompletedView() {
    final correctColor =
        context.read<SettingsProvider>().colorTheme.correctColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check_circle, size: 48, color: correctColor),
        const SizedBox(height: 16),
        _buildWordSlots(revealColor: correctColor),
        const SizedBox(height: 16),
        Text(
          'Correct!',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: correctColor,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 32),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildFailedView() {
    final correctColor =
        context.read<SettingsProvider>().colorTheme.correctColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'The word is spelled:',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 16),
        _buildWordSlots(revealAll: true, revealColor: correctColor),
        const SizedBox(height: 32),
        _buildNextButton(),
      ],
    );
  }

  Widget _buildNextButton() {
    final isLast = _currentIndex + 1 >= _words.length;
    return FilledButton.icon(
      onPressed: _nextWord,
      icon: Icon(isLast ? Icons.flag : Icons.arrow_forward),
      label: Text(isLast ? 'Finish' : 'Next Word'),
    );
  }

  /// Renders one tile per character of the current word: revealed characters
  /// show the letter, the rest show an underscore placeholder.
  Widget _buildWordSlots({bool revealAll = false, Color? revealColor}) {
    final scheme = Theme.of(context).colorScheme;
    final shown = revealAll ? _target.length : _progress;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 8,
      children: List.generate(_target.length, (i) {
        final char = _target[i];
        final isSpace = char.trim().isEmpty;
        if (isSpace) {
          return const SizedBox(width: 16, height: 44);
        }
        final revealed = i < shown;
        return Container(
          constraints: const BoxConstraints(minWidth: 28),
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                revealed ? char : '',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: revealColor ?? scheme.onSurface,
                    ),
              ),
              Container(
                width: 28,
                height: 3,
                color: scheme.outline,
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildLives() {
    final row = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_maxMistakes, (i) {
        // Lives are lost left-to-right: each used life shows a skull.
        final lost = i < _mistakes;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: lost
              ? const Text('💀', style: TextStyle(fontSize: 20))
              : const Icon(Icons.favorite, color: _heartColor, size: 20),
        );
      }),
    );

    if (!_blinkingSkulls) return row;

    // Three quick blinks across the controller's 400ms.
    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        final opacity =
            0.15 + 0.85 * (0.5 + 0.5 * cos(_blinkController.value * 2 * pi * 3));
        return Opacity(opacity: opacity, child: child);
      },
      child: row,
    );
  }

  Widget _buildFinishView() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Game: ${_wordlist!.name}'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 16),
                Text(
                  'Great spelling!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'You spelled $_correctWords of ${_words.length} '
                  'word${_words.length == 1 ? '' : 's'} correctly.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
