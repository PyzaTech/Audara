import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/PlayQueue.dart';
import '../utils/AudioPlayer.dart';

class SongDetailScreen extends StatelessWidget {
  const SongDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer2<PlayQueue, AudioStreamHandler>(
      builder: (context, playQueue, audioPlayerHandler, child) {
        final currentSong = playQueue.currentSong;

        if (currentSong == null) {
          return _emptyState();
        }

        final currentPosition = audioPlayerHandler.currentPosition.inSeconds;
        final totalDuration = audioPlayerHandler.totalDuration.inSeconds;
        final imageUrl = currentSong['image']?.replaceAll('cover_small', 'cover_big') ?? '';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Now Playing'),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.queue_music),
                onPressed: () => _showQueue(context, playQueue),
              ),
            ],
          ),
          backgroundColor: Colors.black,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  height: 300,
                  width: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 300, color: Colors.grey),
                )
              else
                const Icon(Icons.music_note, size: 300, color: Colors.grey),
              const SizedBox(height: 20),
              Text(currentSong['title'] ?? 'Unknown Title',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(currentSong['artist'] ?? 'Unknown Artist',
                  style: const TextStyle(fontSize: 18, color: Colors.white70),
                  textAlign: TextAlign.center),
              const SizedBox(height: 30),
              Slider(
                value: currentPosition.toDouble(),
                max: totalDuration > 0 ? totalDuration.toDouble() : 1.0,
                onChanged: (value) async =>
                await audioPlayerHandler.player.seekToPlayer(Duration(seconds: value.toInt())),
                activeColor: Colors.green,
                inactiveColor: Colors.white24,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_formatTime(currentPosition), style: const TextStyle(color: Colors.white70)),
                    Text(_formatTime(totalDuration), style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _controlButtons(playQueue, audioPlayerHandler),
              const SizedBox(height: 10),
              _loopControl(playQueue),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Now Playing'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('No song is currently playing.', style: TextStyle(color: Colors.white)),
      ),
      backgroundColor: Colors.black,
    );
  }

  Widget _controlButtons(PlayQueue playQueue, AudioStreamHandler audioPlayerHandler) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 40, color: Colors.white),
          onPressed: playQueue.hasPrevious ? playQueue.playPrevious : null,
        ),
        IconButton(
          icon: Icon(
            audioPlayerHandler.player.isPlaying ? Icons.pause_circle : Icons.play_circle,
            size: 60,
            color: Colors.green,
          ),
          onPressed: playQueue.pause_resume,
        ),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 40, color: Colors.white),
          onPressed: playQueue.hasNext ? playQueue.playNext : null,
        ),
      ],
    );
  }

  Widget _loopControl(PlayQueue playQueue) {
    IconData icon;
    Color color = Colors.white;
    String tooltip;

    if (playQueue.loopCurrent) {
      icon = Icons.repeat_one;
      color = Colors.green;
      tooltip = "Looping Current Song";
    } else if (playQueue.loopQueue) {
      icon = Icons.repeat;
      color = Colors.green;
      tooltip = "Looping Queue";
    } else {
      icon = Icons.repeat;
      tooltip = "Loop Off";
    }

    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: playQueue.toggleLoop,
      tooltip: tooltip,
    );
  }


  void _showQueue(BuildContext context, PlayQueue playQueue) {
    showModalBottomSheet(
      backgroundColor: Colors.black87,
      context: context,
      builder: (_) {
        return ListView.builder(
          itemCount: playQueue.queue.length,
          itemBuilder: (context, index) {
            final song = playQueue.queue[index];
            return ListTile(
              title: Text(song['title'] ?? 'Unknown', style: const TextStyle(color: Colors.white)),
              subtitle: Text(song['artist'] ?? 'Unknown', style: const TextStyle(color: Colors.white54)),
              trailing: playQueue.queue == index ? const Icon(Icons.play_arrow, color: Colors.green) : null,
              // onTap: () => playQueue.playAt(index),
            );
          },
        );
      },
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }
}
