import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rhythm/services/recently_played_service.dart';
import 'package:rhythm/services/audio_controller.dart';
import 'package:rhythm/model/local_song_model.dart';
import 'package:rhythm/screens/player_screen.dart';
import 'package:rhythm/widgets/rhythm_dialog.dart';
import 'package:rhythm/widgets/custom_notification.dart';

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
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewPadding.bottom + 100,
                    ),
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      return _buildSongTile(song);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile(LocalSongModel song) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return InkWell(
      onTap: () async {
        final songIndex = _audioController.songs.value.indexWhere((s) => s.id == song.id);
        if (songIndex != -1) {
          await _audioController.playSong(songIndex);
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PlayerScreen(
                  song: song,
                  index: songIndex,
                ),
              ),
            );
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 56,
                height: 56,
                child: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkFit: BoxFit.cover,
                  nullArtworkWidget: Container(
                    color: Theme.of(context).primaryColor.withAlpha((0.2 * 255).round()),
                    child: Icon(
                      Icons.music_note,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Title and Artist
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Play icon
            Icon(
              Icons.play_circle_outline,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ],
        ),
      ),
    );
  }
}
