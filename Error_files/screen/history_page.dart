import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../service/recently_played_service.dart';
import '../service/audio_controller.dart';
import '../model/local_song_model.dart';
import 'player_screen.dart';
import '../widgets/bottom_mini_player.dart';
import '../widgets/rhythm_dialog.dart';
import '../widgets/custom_notification.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final RecentlyPlayedService _historyService = RecentlyPlayedService();
  final AudioController _audioController = AudioController.instance;

  void _clearHistory() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    showRhythmDialog(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Clear History?',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'This will permanently delete all your listening history.',
              style: TextStyle(color: subtextColor, fontSize: 15),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    _historyService.clearHistory();
                    Navigator.pop(context);
                    CustomNotification.show(
                      context,
                      message: 'History cleared',
                      icon: Icons.check_circle,
                      color: Theme.of(context).primaryColor,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Clear', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.arrow_back,
                          color: textColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Listening History',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ValueListenableBuilder(
                          valueListenable: _historyService.recentlyPlayed,
                          builder: (context, songs, _) {
                            return Text(
                              '${songs.length} ${songs.length == 1 ? 'song' : 'songs'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                  ? Colors.white.withAlpha((0.6 * 255).round())
                                  : Colors.black.withAlpha((0.6 * 255).round()),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_sweep_rounded, color: textColor),
                    onPressed: _clearHistory,
                  ),
                ],
              ),
            ),

            // Songs List
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _historyService.recentlyPlayed,
                builder: (context, songs, _) {
                  if (songs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 80,
                            color: isDark
                              ? Colors.white.withAlpha((0.3 * 255).round())
                              : Colors.black.withAlpha((0.3 * 255).round()),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No listening history',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                ? Colors.white.withAlpha((0.6 * 255).round())
                                : Colors.black.withAlpha((0.6 * 255).round()),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Songs you play will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                ? Colors.white.withAlpha((0.4 * 255).round())
                                : Colors.black.withAlpha((0.4 * 255).round()),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return _buildSongItem(song, index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomMiniPlayer(),
    );
  }

  Widget _buildSongItem(LocalSongModel song, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final primaryColor = Theme.of(context).primaryColor;

    // Normalize artwork URL for online images (some sources use leading '//')
    String artworkUrl = song.albumArt;
    if (artworkUrl.isNotEmpty && artworkUrl.startsWith('//')) {
      artworkUrl = 'https:$artworkUrl';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: primaryColor.withAlpha((0.2 * 255).round()),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: (artworkUrl.isNotEmpty && (artworkUrl.startsWith('http') || artworkUrl.startsWith('https')))
              ? Image.network(
                  artworkUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    width: 50,
                    height: 50,
                    color: primaryColor.withAlpha((0.2 * 255).round()),
                    child: Icon(Icons.music_note_rounded, color: primaryColor, size: 24),
                  ),
                )
              : QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkBorder: BorderRadius.circular(8),
                  artworkFit: BoxFit.cover,
                  nullArtworkWidget: Container(
                    color: primaryColor.withAlpha((0.2 * 255).round()),
                    child: Icon(Icons.music_note_rounded, color: primaryColor, size: 24),
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
          color: subtitleColor,
          fontSize: 12,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: isDark ? Colors.white70 : Colors.black54, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) async {
          if (value == 'play') {
            int songIndex = _audioController.songs.value.indexWhere((s) => s.id == song.id || s.uri == song.uri);
            bool played = false;
            try {
              if (songIndex != -1) {
                played = await _audioController.playSong(songIndex);
              } else {
                played = await _audioController.playFromPlaylist(song, playlist: _historyService.recentlyPlayed.value);
              }
            } catch (e) {
              debugPrint('⚠️ Play from menu failed: $e');
            }

            if (played && mounted) {
              final idx = _audioController.currentIndex.value;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    song: _audioController.currentSong ?? song,
                    index: idx,
                  ),
                ),
              );
            }
          } else if (value == 'add') {
            try {
              final list = List<LocalSongModel>.from(_audioController.currentPlaylist.value);
              if (!list.any((s) => s.uri == song.uri)) {
                list.add(song);
                _audioController.currentPlaylist.value = list;
                CustomNotification.show(
                  context,
                  message: 'Added to playlist',
                  icon: Icons.playlist_add,
                  color: Colors.green,
                );
              } else {
                CustomNotification.show(
                  context,
                  message: 'Song already in playlist',
                  icon: Icons.info_outline,
                  color: Colors.orange,
                );
              }
            } catch (e) {
              debugPrint('⚠️ Add to playlist failed: $e');
            }
          } else if (value == 'remove') {
            try {
              await _historyService.removeSongAt(index);
              CustomNotification.show(
                context,
                message: 'Removed from history',
                icon: Icons.delete,
                color: Colors.red,
              );
            } catch (e) {
              debugPrint('⚠️ Remove from history failed: $e');
            }
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'play',
            child: Row(children: [Icon(Icons.play_arrow, size: 18), SizedBox(width: 8), Text('Play')]),
          ),
          PopupMenuItem(
            value: 'add',
            child: Row(children: [Icon(Icons.playlist_add, size: 18), SizedBox(width: 8), Text('Add to Playlist')]),
          ),
          PopupMenuItem(
            value: 'remove',
            child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 18), SizedBox(width: 8), Text('Remove', style: TextStyle(color: Colors.red))]),
          ),
        ],
      ),
      onTap: () async {
        final songIndex = _audioController.songs.value.indexWhere(
          (s) => s.id == song.id,
        );

        if (songIndex != -1) {
          await _audioController.playSong(songIndex);

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
}
