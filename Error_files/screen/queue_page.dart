import 'package:flutter/material.dart';
import '../model/local_song_model.dart';
import '../songsrepo/Saavn/saavn_api.dart';
import '../service/audio_controller.dart';

class QueuePage extends StatefulWidget {
  final List<LocalSongModel> songs;
  final int currentIndex;

  const QueuePage({super.key, required this.songs, required this.currentIndex});

  @override
  State<QueuePage> createState() => _QueuePageState();
}

class _QueuePageState extends State<QueuePage> {
  final SaavnAPI api = SaavnAPI();
  List<dynamic> similarSongs = [];
  bool isLoadingSimilar = false;
  bool hasLoadedSimilar = false;
  bool isLocalSong = false;

  @override
  void initState() {
    super.initState();
    _loadSimilarSongs();
  }

  Future<void> _loadSimilarSongs() async {
    if (widget.currentIndex < 0 || widget.currentIndex >= widget.songs.length) {
      debugPrint('Invalid song index: ${widget.currentIndex}');
      setState(() {
        hasLoadedSimilar = true;
      });
      return;
    }

    final currentSong = widget.songs[widget.currentIndex];
    debugPrint('Current song: ${currentSong.title}');
    debugPrint('Song URI: ${currentSong.uri}');
    debugPrint('Song ID: ${currentSong.id}');

    // Check if it's an online song (URL starts with http/https)
    final isOnlineSong = currentSong.uri.startsWith('http://') ||
                         currentSong.uri.startsWith('https://');

    debugPrint('Is online song: $isOnlineSong');

    if (!isOnlineSong) {
      debugPrint('Skipping similar songs for local file');
      setState(() {
        hasLoadedSimilar = true;
        isLocalSong = true;
      });
      return; // Don't fetch similar songs for local files
    }

    setState(() {
      isLoadingSimilar = true;
    });

    try {
      // Use the song ID to fetch related songs
      final String songId = currentSong.id.toString();
      debugPrint('Fetching similar songs for ID: $songId');

      final Map result = await api.getRelated(songId);
      final List songs = result['songs'] ?? [];

      debugPrint('Received ${songs.length} similar songs');
      debugPrint('Result error: ${result['error']}');

      if (mounted) {
        setState(() {
          similarSongs = songs;
          isLoadingSimilar = false;
          hasLoadedSimilar = true;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          isLoadingSimilar = false;
          hasLoadedSimilar = true;
        });
      }
      debugPrint('Error loading similar songs: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {

    return DraggableScrollableSheet(
      initialChildSize: 0.75, // 75% of screen height
      minChildSize: 0.3,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.3, 0.75, 0.95],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1a1a2e),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              // Handle bar - make it more prominent for dragging
              GestureDetector(
                onVerticalDragEnd: (details) {
                  // If swiping down with sufficient velocity, close the sheet
                  if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                    Navigator.of(context).pop();
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 60,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 10),
              const Text(
                'Similar Songs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: isLoadingSimilar
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white54,
                        ),
                      )
                    : hasLoadedSimilar && similarSongs.isNotEmpty
                        ? ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: similarSongs.length,
                            itemBuilder: (context, index) {
                              return _buildSimilarSongTile(similarSongs[index]);
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isLocalSong
                                      ? Icons.library_music_rounded
                                      : Icons.music_off_rounded,
                                  size: 64,
                                  color: Colors.white24,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isLocalSong
                                      ? 'Similar songs are only\navailable for online songs'
                                      : 'No similar songs available',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimilarSongTile(dynamic song) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[800],
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: song['image'] != null && song['image'].toString().isNotEmpty
                ? Image.network(
                    song['image'],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: Colors.white54,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white54,
                      size: 30,
                    ),
                  )
                : const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white54,
                    size: 30,
                  ),
          ),
        ),
        title: Text(
          song['title']?.toString() ?? 'Unknown',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          song['artist']?.toString() ?? 'Unknown Artist',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 13,
          ),
        ),
        trailing: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
            onPressed: () {
              _playSimilarSong(song);
            },
          ),
        ),
        onTap: () {
          _playSimilarSong(song);
        },
      ),
    );
  }

  void _playSimilarSong(dynamic song) async {
    try {
      final audioController = AudioController.instance;

      // Create a LocalSongModel from the similar song data
      final int tempId = -DateTime.now().millisecondsSinceEpoch.abs() % 1000000000;
      final LocalSongModel newSong = LocalSongModel(
        id: int.tryParse(song['id']?.toString() ?? '') ?? tempId,
        title: song['title']?.toString() ?? 'Unknown',
        artist: song['artist']?.toString() ?? 'Unknown Artist',
        uri: song['url']?.toString() ?? '',
        albumArt: song['image']?.toString() ?? '',
        duration: int.tryParse(song['duration']?.toString() ?? '0') ?? 0,
      );

      // Check if song already exists in queue
      final existing = audioController.songs.value;
      int existingIndex = -1;

      for (int i = 0; i < existing.length; i++) {
        if (existing[i].uri == newSong.uri) {
          existingIndex = i;
          break;
        }
      }

      if (existingIndex != -1) {
        // Song exists, just play it
        await audioController.playSong(existingIndex);
      } else {
        // Add song to queue and play it
        final updated = List<LocalSongModel>.from(existing)..add(newSong);
        audioController.songs.value = updated;
        final newIndex = updated.length - 1;
        await audioController.playSong(newIndex);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error playing similar song: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing song: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
