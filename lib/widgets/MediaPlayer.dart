import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/PlayQueue.dart';
import '../utils/AudioPlayer.dart';

class MediaPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final playQueue = Provider.of<PlayQueue>(context);
    final audioPlayerHandler = Provider.of<AudioStreamHandler>(context);

    if (playQueue.currentSong == null) {
      return const SizedBox.shrink();
    }

    final currentSong = playQueue.currentSong!;

    print(currentSong['image']);
    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          currentSong['image'] != null
              ? Image.network(
            currentSong['image']!,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          )
              : const Icon(Icons.music_note, color: Colors.white70),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentSong['title'] ?? 'Unknown Title',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  currentSong['artist'] ?? 'Unknown Artist',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white),
            onPressed: playQueue.playPrevious,
          ),
          IconButton(
            icon: Icon(
              audioPlayerHandler.player.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            onPressed: () {
              playQueue.pause_resume();
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white),
            onPressed: playQueue.playNext,
          ),
        ],
      ),
    );
  }
}