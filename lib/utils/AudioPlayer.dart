import 'dart:async';
import 'package:audara/main.dart';
import 'package:audara/utils/PlayQueue.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class AudioStreamHandler with ChangeNotifier {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  Timer? _progressTimer;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;

  FlutterSoundPlayer get player => _player;

  Future<void> initializePlayer() async {
    if (!_player.isOpen()) {
      await _player.openPlayer();
      print('✅ Player initialized');
    }
  }

  Future<void> playFromUrl(String url) async {
    PlayQueue playQueue = Provider.of<PlayQueue>(navigatorKey.currentContext!, listen: false);
    print('🔄 Playing audio from URL: $url');
    try {
      await initializePlayer();

      if (_player.isPlaying) {
        await _player.stopPlayer();
      }

      if (!_player.isOpen()) {
        await _player.openPlayer();
        print('✅ Player opened');
      }

      await _player.startPlayer(
        fromURI: url,
        codec: Codec.mp3,
        whenFinished: () {
          print('🎵 Playback finished');
          playQueue.playNext();
          notifyListeners();
        },
      );


      print('▶️ Playback started');
      notifyListeners();
      // TODO: Add a 500ms delay before running playQueue.startProgressListener();
      await Future.delayed(const Duration(milliseconds: 500));
      playQueue.startProgressListener();
    } catch (e, stackTrace) {
      print('❌ Error playing audio from URL: $e');
      print('StackTrace: $stackTrace');
    }
  }

  void _stopProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  Future<void> stopPlayer() async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
      print('🛑 Playback stopped');
    }
    _stopProgressTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _stopProgressTimer();
    _player.closePlayer();
    super.dispose();
  }
}