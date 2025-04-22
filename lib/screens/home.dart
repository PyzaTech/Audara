import 'dart:convert';
import 'package:audara/screens/search.dart';
import 'package:audara/screens/start/StartScreen.dart';
import 'package:audara/widgets/MediaPlayer.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/PlayQueue.dart';
import '../utils/WebSocketHandler.dart';
import 'SongDetailScreen.dart';
import 'dart:math';

class Home extends StatelessWidget {
  const Home({super.key});

  Future<Map<String, dynamic>> _getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // return prefs.getString('username') ?? 'User';
    String? username = prefs.getString('username');
    String? profilePictureUrl = prefs.getString('profilePictureUrl');
    return {
      'username': username ?? 'User',
      'profilePictureUrl': profilePictureUrl ?? '',
    };
  }

  Future<List<Map<String, String>>> _fetchRandomPicks() async {
    final response = await http.get(Uri.parse("https://api.deezer.com/chart"));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final tracks = (data['tracks']['data'] as List).map((item) {
        return {
          'title': item['title'] as String? ?? 'Unknown Title',
          'artist': item['artist']['name'] as String? ?? 'Unknown Artist',
          'image': item['album']['cover_big'] as String? ?? '',
        };
      }).toList();

      // Shuffle the tracks
      tracks.shuffle();

      // Use a Set to ensure unique songs
      final uniqueSongs = <Map<String, String>>{};
      for (var track in tracks) {
        if (uniqueSongs.length >= 10) break; // Limit to 10 unique songs
        uniqueSongs.add(track);
      }

      return uniqueSongs.toList();
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'Error loading data',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        String username = snapshot.data?['username'] ?? 'User';
        String profilePictureUrl = snapshot.data?['profilePictureUrl'] ?? '';

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.black,
            elevation: 0,
            title: Text(
              'Good Evening $username',
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  showMenu(
                    context: context,
                    position: RelativeRect.fromLTRB(100, 80, 0, 0), // Adjust position as needed
                    items: [
                      PopupMenuItem(
                        value: 0,
                        child: Row(
                          children: const [
                            Icon(Icons.person, color: Colors.white),
                            SizedBox(width: 8),
                            Text('View Profile', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 1,
                        child: Row(
                          children: const [
                            Icon(Icons.settings, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Settings', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 2,
                        child: Row(
                          children: const [
                            Icon(Icons.logout, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Logout', style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                    color: Colors.black,
                  ).then((value) async {
                    if (value == 0) {
                      print('View Profile tapped');
                      // Handle "View Profile" action
                    } else if (value == 1) {
                      print('Settings tapped');
                      // Handle "Settings" action
                    } else if (value == 2) {
                      print('Logout tapped');
                      // Handle "Logout" action
                      // For example, clear user data and navigate to login screen
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      prefs.remove("username");
                      prefs.remove("profilePictureUrl");
                      prefs.remove("password");
                      String serverUrl = prefs.getString("server_url") ?? "";
                      await Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) =>
                          StartScreen(serverUrl: serverUrl, webSocketHandler: Provider.of<WebSocketHandler>(context, listen: false)),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                        ),
                      );
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    backgroundImage: (profilePictureUrl.isNotEmpty)
                        ? NetworkImage(profilePictureUrl)
                        : null,
                    radius: 16,
                    child: (profilePictureUrl.isEmpty)
                        ? const Icon(Icons.person, color: Colors.black)
                        : null, // Adjust the size as needed
                  ),
                ),
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recently Played',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.music_note,
                                  color: Colors.white, size: 40),
                              const SizedBox(height: 8),
                              const Text(
                                'Playlist',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Random Picks',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Map<String, String>>>(
                    future: _fetchRandomPicks(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No random picks available',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      }

                      final randomPicks = snapshot.data!;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: randomPicks.length,
                        itemBuilder: (context, index) {
                          final song = randomPicks[index];
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
                            trailing: const Icon(Icons.more_vert, color: Colors.white),
                            onTap: () {
                              final playQueue = Provider.of<PlayQueue>(context, listen: false);
                              final webSocketHandler = Provider.of<WebSocketHandler>(context, listen: false);

                              print('🎵 Song selected: ${song['title']} by ${song['artist']}');
                              print(playQueue.queue);
                              playQueue.streamSong(webSocketHandler, song, context);

                            },
                          );
                        },
                      );
                    },
                  ),

                ],
              ),
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  final playQueue = Provider.of<PlayQueue>(context, listen: false);
                  if (playQueue.currentSong != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SongDetailScreen(),
                      ),
                    );
                  }
                },
                child: MediaPlayer(),
              ),
              BottomNavigationBar(
                backgroundColor: Colors.black,
                selectedItemColor: Colors.green,
                unselectedItemColor: Colors.white70,
                currentIndex: 0, // Set the current index to highlight the Home tab
                onTap: (index) {
                  if (index == 1) { // Index 1 corresponds to the Search tab
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                        const SearchScreen(),
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
      },
    );
  }
}