import 'package:audioplayers/audioplayers.dart';

/// A lightweight sound-effect player that maintains a small pool of
/// [AudioPlayer] instances so that rapid successive calls never collide
/// on a single player.
class SfxPlayer {
  SfxPlayer({this.maxPlayers = 3});

  final int maxPlayers;
  final List<AudioPlayer> _players = [];
  int _nextIndex = 0;

  Future<void> play(String assetPath) async {
    if (_players.length < maxPlayers) {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.stop);
      _players.add(player);
    }

    final player = _players[_nextIndex % _players.length];
    _nextIndex = (_nextIndex + 1) % _players.length;

    await player.stop();
    await player.play(AssetSource(assetPath));
  }

  void dispose() {
    for (final player in _players) {
      player.dispose();
    }
    _players.clear();
  }
}
