import 'dart:async';
import 'dart:convert';
import 'package:audara/screens/home.dart';
import 'package:audara/utils/WebSocketHandler.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../utils/PlayQueue.dart';
import '../widgets/MediaPlayer.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _songs = [];

  Future<void> _searchSongs(String query) async {
    if (query.isEmpty) {
      setState(() {
        _songs = [];
      });
      return;
    }

    final response = await http.get(
      Uri.parse('https://api.deezer.com/search?q=$query'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _songs = (data['data'] as List?)?.map((item) {
          return {
            'title': item['title'] as String? ?? 'Unknown Title', // Default title
            'artist': item['artist']['name'] as String? ?? 'Unknown Artist', // Default artist
            'image': item['album']['cover_small'] as String? ?? '', // Default to empty string
          };
        }).toList() ?? [];
      });
    } else {
      setState(() {
        _songs = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[900],
                hintText: 'What do you want to listen to?',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _searchSongs,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _songs.isEmpty
                  ? const Center(
                child: Text(
                  'No results found',
                  style: TextStyle(color: Colors.white70),
                ),
              )
                  : ListView.builder(
                itemCount: _songs.length,
                itemBuilder: (context, index) {
                  final song = _songs[index];
                  return ListTile(
                    leading: song['image']!.isNotEmpty
                        ? Image.network(
                      song['image']!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                        : const Icon(Icons.music_note, color: Colors.white70),
                    title: Text(
                      song['title']!,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      song['artist']!,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      final playQueue = Provider.of<PlayQueue>(context, listen: false);
                      final webSocketHandler = Provider.of<WebSocketHandler>(context, listen: false);

                      print('🎵 Song selected: ${song['title']} by ${song['artist']}');
                      playQueue.streamSong(webSocketHandler, song, context);

                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MediaPlayer(), // Add the MediaPlayer widget here
          BottomNavigationBar(
            backgroundColor: Colors.black,
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.white70,
            currentIndex: 1, // Set the current index to highlight the Search tab
            onTap: (index) {
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const Home(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ),
                );
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Search',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.library_music),
                label: 'Your Library',
              ),
            ],
          ),
        ],
      ),
    );
  }
}