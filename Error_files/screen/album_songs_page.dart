import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:Rhythm/service/audio_controller.dart';
import 'package:Rhythm/model/local_song_model.dart';
import 'package:Rhythm/screen/player_screen.dart';
import 'dart:ui';

class AlbumSongsPage extends StatefulWidget {
  final AlbumModel album;

  const AlbumSongsPage({super.key, required this.album});

  @override
  State<AlbumSongsPage> createState() => _AlbumSongsPageState();
}

class _AlbumSongsPageState extends State<AlbumSongsPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioController _audioController = AudioController.instance;
  List<LocalSongModel> _albumSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbumSongs();
  }

  Future<void> _loadAlbumSongs() async {
    setState(() => _isLoading = true);

    try {
      // Ensure songs are loaded in AudioController first
      if (_audioController.songs.value.isEmpty) {
        debugPrint('🔄 Loading songs in AudioController...');
        await _audioController.loadSongs();
      }

      final songs = await _audioQuery.queryAudiosFrom(
        AudiosFromType.ALBUM_ID,
        widget.album.id,
      );

      // Convert to LocalSongModel
      final allSongs = _audioController.songs.value;
      final localSongs = songs.map((song) {
        return allSongs.firstWhere(
          (s) => s.id == song.id,
          orElse: () => LocalSongModel(
            id: song.id,
            title: song.title,
            artist: song.artist ?? 'Unknown Artist',
            uri: song.uri ?? '',
            albumArt: '',
            duration: song.duration ?? 0,
          ),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _albumSongs = localSongs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading album songs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    // sizes used in header
    final double headerArtSize = 88.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Header with large centered artwork (Spotify-like)
                Container(
                  // make the header visually prominent
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button row
                      Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Gradient backdrop and centered artwork
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(context).canvasColor.withOpacity(0.02),
                              Theme.of(context).scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: QueryArtworkWidget(
                                  id: widget.album.id,
                                  type: ArtworkType.ALBUM,
                                  artworkWidth: headerArtSize * 2.8,
                                  artworkHeight: headerArtSize * 2.8,
                                  artworkFit: BoxFit.cover,
                                  nullArtworkWidget: Container(
                                    width: headerArtSize * 2.8,
                                    height: headerArtSize * 2.8,
                                    color: primaryColor.withAlpha((0.16 * 255).round()),
                                    child: const Center(child: Icon(Icons.album_rounded, size: 80, color: Colors.white24)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Title and artist
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.album.album.isNotEmpty ? widget.album.album : 'Unknown Album',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.album.artist ?? 'Unknown Artist',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Controls row: small icons on left + big play button on right
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Row(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white10 : Colors.black12,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.check_circle, color: Colors.green),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white10 : Colors.black12,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.download_rounded, color: Colors.white),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white10 : Colors.black12,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.more_vert, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  // Large play button
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (_albumSongs.isNotEmpty) {
                                        final firstSongIndex = _audioController.songs.value.indexWhere((s) => s.id == _albumSongs.first.id);
                                        if (firstSongIndex != -1) await _audioController.playSong(firstSongIndex);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(14),
                                    ),
                                    child: const Icon(Icons.play_arrow_rounded, size: 28, color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Play all button
                if (!_isLoading && _albumSongs.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_albumSongs.isNotEmpty) {
                            final firstSongIndex = _audioController.songs.value.indexWhere(
                              (s) => s.id == _albumSongs.first.id,
                            );
                            if (firstSongIndex != -1) {
                              await _audioController.playSong(firstSongIndex);

                              // Navigate to player screen
                              if (mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerScreen(
                                      song: _albumSongs.first,
                                      index: firstSongIndex,
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                        label: const Text(
                          'Play All',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Songs list
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(color: primaryColor),
                        )
                      : _albumSongs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.music_note_rounded,
                                    size: 64,
                                    color: Colors.white.withAlpha((0.3 * 255).round()),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No songs in this album',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withAlpha((0.5 * 255).round()),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                              itemCount: _albumSongs.length,
                              itemBuilder: (context, index) {
                                final song = _albumSongs[index];
                                return _buildSongItem(song, index);
                              },
                            ),
                ),
              ],
            ),
          ),

          // Bottom Mini Player
          _buildBottomMiniPlayer(context, isDark, primaryColor),
        ],
      ),
    );
  }

  Widget _buildSongItem(LocalSongModel song, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withAlpha((0.2 * 255).round()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ),
      title: Text(
        song.title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        _formatDuration(song.duration),
        style: TextStyle(
          color: isDark ? Colors.white54 : Colors.black54,
          fontSize: 12,
        ),
      ),
      onTap: () async {
        // Find song in main list and play it
        final songIndex = _audioController.songs.value.indexWhere(
          (s) => s.id == song.id,
        );
        if (songIndex != -1) {
          await _audioController.playSong(songIndex);

          // Navigate to player screen
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerScreen(
                  song: song,
                  index: songIndex,
                ),
              ),
            );
          }
        }
      },
    );
  }

  Widget _buildBottomMiniPlayer(BuildContext context, bool isDark, Color primaryColor) {
    return ValueListenableBuilder(
      valueListenable: _audioController.currentIndex,
      builder: (context, currentIndex, _) {
        final currentSong = _audioController.currentSong;

        if (currentSong == null) {
          return const SizedBox.shrink();
        }

        // size used in mini player
        final double miniArtSize = 44.0;

        return Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    song: currentSong,
                    index: currentIndex,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withAlpha((0.6 * 255).round())
                    : Colors.white.withAlpha((0.95 * 255).round()),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withAlpha((0.1 * 255).round())
                      : Colors.black.withAlpha((0.1 * 255).round()),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.5 * 255).round()),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Row(
                    children: [
                      // Album artwork
                      // Album artwork (mini-player) — slightly reduced for balance
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: QueryArtworkWidget(
                          id: currentSong.id,
                          type: ArtworkType.AUDIO,
                          artworkWidth: miniArtSize,
                          artworkHeight: miniArtSize,
                          artworkFit: BoxFit.cover,
                          nullArtworkWidget: Container(
                            width: miniArtSize,
                            height: miniArtSize,
                            color: primaryColor.withAlpha((0.18 * 255).round()),
                            child: Icon(
                              Icons.music_note_rounded,
                              color: primaryColor,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Song info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              currentSong.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              currentSong.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark ? Colors.white60 : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Play/Pause button
                      ValueListenableBuilder(
                        valueListenable: _audioController.isPlaying,
                        builder: (context, isPlaying, _) {
                          return IconButton(
                            icon: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: primaryColor,
                              size: 32,
                            ),
                            onPressed: () {
                              if (isPlaying) {
                                _audioController.pauseSong();
                              } else {
                                _audioController.resumeSong();
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
