import 'package:flutter_sound/flutter_sound.dart';

class AudioStreamHandler {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  Future<void> initializePlayer() async {
    if (!_player.isOpen()) {
      await _player.openPlayer();
      print('✅ Player initialized');
    }
  }

  Future<void> playFromUrl(String url) async {
    print('🔄 Playing audio from URL: $url');
    try {
      await initializePlayer();

      if (_player.isPlaying) {
        await _player.stopPlayer();
      }
      if(!_player.isOpen()) {
        await _player.openPlayer();
        print('✅ Player opened');
      }
      await _player.startPlayer(
        fromURI: url,
        codec: Codec.mp3,
        whenFinished: () {
          print('🎵 Playback finished');
        },
      );
      print('🎵 Playing audio from URL: $url');
    } catch (e, stackTrace) {
      print('❌ Error playing audio from URL: $e');
      print('StackTrace: $stackTrace');
    }
  }

  Future<void> stopPlayer() async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
      print('🛑 Playback stopped');
    }
  }

  void dispose() {
    _player.closePlayer();
  }

  void pause_resume() {
    if (_player.isPlaying) {
      _player.pausePlayer();
      print('⏸️ Playback paused');
    } else {
      _player.resumePlayer();
      print('▶️ Playback resumed');
    }
  }
}