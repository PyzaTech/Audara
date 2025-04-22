import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'AesCrypto.dart';
import 'AudioPlayer.dart';
import 'WebSocketHandler.dart';

class PlayQueue with ChangeNotifier {
  final List<Map<String, String>> _queue = [];
  int _currentIndex = -1;
  Map<String, String>? _currentSong;
  bool loopQueue = false; // Loop queue flag
  bool loopCurrent = false; // Loop current song flag

  final AudioStreamHandler _audioPlayer;

  PlayQueue(this._audioPlayer);

  void Function(Map<String, String>)? onSongChanged; // Listener for song changes

  Map<String, String>? get currentSong => _currentSong;

  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;
  List<Map<String, String>> get queue => _queue;

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      if (_currentIndex >= _queue.length) {
        _currentIndex = _queue.length - 1;
      }
      notifyListeners();
    }
  }

  void playNext() async {
    if (hasNext) {
      _currentIndex++;
      _audioPlayer.stopPlayer();

      print('🔄 Playing next song: ${_queue[_currentIndex]['title']} by ${_queue[_currentIndex]['artist']}');
      _notifySongChanged();
    } else {
      _currentSong = null;
      _audioPlayer.stopPlayer();
      notifyListeners();
      print('🎵 No more songs in the queue.');
    }
    notifyListeners();
  }

  void playPrevious() {
    if (hasPrevious) {
      _currentIndex--;
      _currentSong = _queue[_currentIndex]; // Update the current song
      print('🔄 Playing previous song: ${_currentSong?['title']} by ${_currentSong?['artist']}');
      _notifySongChanged();
    } else {
      print('🎵 No previous song in the queue.');
    }
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    _currentSong = null;
    notifyListeners();
  }

  void _notifySongChanged() async {
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      _audioPlayer.stopPlayer();
      _currentSong = _queue[_currentIndex];
      print('🎶 Current song changed: ${_currentSong?['title']} by ${_currentSong?['artist']}');
      if (onSongChanged != null) {
        onSongChanged!(_currentSong!);
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final serverUrl = prefs.getString('server_url') ?? 'https://example.com/';
      final url = _currentSong!['url']?.replaceAll('URLPATH', serverUrl);

      await _audioPlayer.initializePlayer();
      await _audioPlayer.playFromUrl(url!);
    } else {
      _audioPlayer.stopPlayer();
      _currentSong = null;
    }
    notifyListeners(); // Ensure listeners are notified
  }

  void setCurrentSong(Map<String, String> song) async {
    if (_currentSong == song) return; // Avoid redundant updates
    _currentIndex = _queue.indexOf(song);
    _currentSong = song;
    print('🎶 Current song set: ${_currentSong?['title']} by ${_currentSong?['artist']}');

    try {
      await _audioPlayer.initializePlayer();
      await _audioPlayer.playFromUrl(song['url']!);
    } catch (e) {
      print('❌ Error playing song: $e');
    }

    notifyListeners(); // Notify only when the song changes
  }

  void addToQueue(Map<String, String> song) {
    if (!_queue.contains(song)) {
      _queue.add(song);
      notifyListeners(); // Notify only when the queue changes
    }
  }


  Future<void> streamSong(WebSocketHandler webSocketHandler, Map<String, String> song, BuildContext context) async {
    final songMetaData = {
      'action': 'stream-song',
      'title': song['title'],
      'artist': song['artist'],
    };

    String jsonString = jsonEncode(songMetaData);

    // Encrypt the JSON string
    final encrypted = AesCrypto().encryptText(jsonString);

    webSocketHandler.channel?.sink.add(encrypted);

    StreamSubscription? _subscription;
    _subscription = webSocketHandler.stream.listen((message) async {
      try {
        // Decrypt the message
        final decryptedMessage = AesCrypto().decryptText(message);
        print('Decrypted message: $decryptedMessage');

        // Parse the decrypted JSON string
        final Map<String, dynamic> jsonResponse = jsonDecode(decryptedMessage);

        if (jsonResponse['action'] != 'stream-song') return;

        // Access specific fields from the JSON
        print('Response from server: $jsonResponse');
        if (jsonResponse['success'] == true) {
          if (jsonResponse['type'] != 'url') return;

          String title = song['title'] ?? 'Unknown Title';
          String artist = song['artist'] ?? 'Unknown Artist';
          String image = song['image'] ?? '';

          SharedPreferences prefs = await SharedPreferences.getInstance();
          final serverUrl = prefs.getString('server_url') ?? 'https://example.com/'; // Default URL
          final songURL = jsonResponse['url']?.replaceAll('URLPATH', serverUrl) ?? '';
          print('Song URL: $songURL');

          Map<String, String> streamSong = {
            'title': title,
            'artist': artist,
            'image': image,
            'url': songURL,
          };

          addToQueue(streamSong);
          if(currentSong == null) {
            setCurrentSong(streamSong); // Set the current song
          }

          print('✅ Song added to PlayQueue and set as current song.');
          _subscription?.cancel();
        } else {
          print('❌ Error: ${jsonResponse['error']}');
          _subscription?.cancel();
        }
      } catch (e) {
        print('Error processing server response: $e');
      }
    });
  }

  void pause_resume() {
    if (_audioPlayer.player.isPlaying) {
      _audioPlayer.player.pausePlayer();
      print('⏸️ Playback paused');
    } else {
      _audioPlayer.player.resumePlayer();
      print('▶️ Playback resumed');
    }
    notifyListeners();
  }

  void startProgressListener() {
    print("🕒 Starting progress listener");
    _audioPlayer.player.onProgress?.listen((event) {
      print('⏳ Current position: ${event.position.inSeconds} seconds');
      _audioPlayer.currentPosition = event.position;
      _audioPlayer.totalDuration = event.duration;
      notifyListeners();
    }, onError: (error) {
      print('❌ Error in onProgress stream: $error');
    });
  }

  void toggleLoop() {
    if(!loopQueue && !loopCurrent) {
      loopQueue = true;
      print('Looping the entire queue');
    } else if(loopQueue && !loopCurrent) {
      loopCurrent = true;
      loopQueue = false;
      print('Looping the current song');
    } else if(loopCurrent) {
      loopCurrent = false;
      print('Looping disabled');
    }
    notifyListeners();
  }

}