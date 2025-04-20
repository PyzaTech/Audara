import 'package:audara/utils/AudioPlayer.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/PlayQueue.dart';

class MediaPlayer extends StatelessWidget {
  const MediaPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final playQueue = Provider.of<PlayQueue>(context);
    final audioPlayerHandler = Provider.of<AudioStreamHandler>(context, listen: false);

    print('🔄 MediaPlayer rebuild. Current song: ${playQueue.currentSong?['title']}');

    if (playQueue.currentSong == null) {
      return const SizedBox.shrink();
    }

    final currentSong = playQueue.currentSong!;

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
            onPressed: playQueue.hasPrevious ? playQueue.playPrevious : null,
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.white),
            onPressed: () {
              audioPlayerHandler.pause_resume();
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white),
            onPressed: () {
              print('🔄 Next song button pressed');
              playQueue.playNext();
            }
          ),
        ],
      ),
    );
  }
}