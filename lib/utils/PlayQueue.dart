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

  final AudioStreamHandler _audioPlayer;

  PlayQueue(this._audioPlayer);

  void Function(Map<String, String>)? onSongChanged; // Listener for song changes

  Map<String, String>? get currentSong => _currentSong;

  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  void addToQueue(Map<String, String> song) {
    _queue.add(song);
    print('📥 Song added to queue: ${song['title']} by ${song['artist']}');
    notifyListeners();
  }

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
  }

  void playPrevious() {
    if (hasPrevious) {
      _currentIndex--;
      _notifySongChanged();
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
    _currentIndex = _queue.indexOf(song);
    _currentSong = song;
    print('🎶 Current song set: ${_currentSong?['title']} by ${_currentSong?['artist']}, song url: ${song['url']}');

    try {
      // Initialize and play the song
      await _audioPlayer.initializePlayer();
      await _audioPlayer.playFromUrl(song['url']!);
    } catch (e) {
      print('❌ Error playing song: $e');
    }

    notifyListeners(); // Notify listeners after updating the current song
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
          setCurrentSong(streamSong); // Set the current song

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

}