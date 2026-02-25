import 'package:flutter/material.dart';
import 'package:rhythm/songsrepo/Saavn/saavn_api.dart';
import 'package:rhythm/services/audio_controller.dart';
import 'package:rhythm/model/local_song_model.dart';
import 'package:rhythm/screens/player_screen.dart';
import 'package:rhythm/widgets/custom_notification.dart';
import 'package:rhythm/utils/page_transitions.dart';

class OnlineAlbumPage extends StatefulWidget {
  final String token;
  final Map? albumData;

  const OnlineAlbumPage({
    super.key,
    required this.token,
    this.albumData,
  });

  @override
  State<OnlineAlbumPage> createState() => _OnlineAlbumPageState();
}

class _OnlineAlbumPageState extends State<OnlineAlbumPage> {
  final SaavnAPI api = SaavnAPI();
  final AudioController audioCtrl = AudioController.instance;

  bool loading = true;
  Map? albumDetails;
  List songs = [];

  @override
  void initState() {
    super.initState();
    _loadAlbum();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getBestAlbumImage(Map? albumDetails) {
    if (albumDetails == null) return '';
    final image = albumDetails['image'] ?? '';
    if (image.contains('50x50')) {
      return image.replaceAll('50x50', '500x500');
    }
    return image;
  }

  Future<void> _loadAlbum() async {
    setState(() => loading = true);
    try {
      debugPrint('🎵 Loading album with token: ${widget.token}');
      final res = await api.fetchAlbumDetails(widget.token);

      List<dynamic> fetchedSongs = res['songs'] ?? [];
      Map? details = res['albumDetails'] ?? {};

      setState(() {
        songs = fetchedSongs;
        albumDetails = details ?? {};
        loading = false;
      });
    } catch (e, st) {
      debugPrint('❌ Error loading album: $e\n$st');
      setState(() => loading = false);
    }
  }

  void _playSong(dynamic song) async {
    try {
      final title = song['title'] ?? 'Unknown';
      final artist = song['artist'] ?? song['primaryArtists'] ?? 'Unknown';
      final url = song['url'] ?? song['downloadUrl'];

      if (url == null) {
        CustomNotification.show(
          context,
          message: 'Cannot play: Invalid URL',
          icon: Icons.error_rounded,
          color: Colors.red,
        );
        return;
      }

      final LocalSongModel currentSong = LocalSongModel(
        id: -(DateTime.now().millisecondsSinceEpoch),
        title: title,
        artist: artist,
        uri: url,
        albumArt: song['image'] ?? '',
        duration: 0,
      );

      await audioCtrl.audioPlayer.setUrl(url);
      await audioCtrl.audioPlayer.play();

      context.pushWithSlide(
        PlayerScreen(
          song: currentSong,
          index: 0,
        ),
      );

      CustomNotification.show(
        context,
        message: 'Now playing: $title',
        icon: Icons.play_circle_filled_rounded,
        color: Theme.of(context).primaryColor,
      );
    } catch (e) {
      debugPrint('Error playing song: $e');
      CustomNotification.show(
        context,
        message: 'Error playing song',
        icon: Icons.error_rounded,
        color: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;
    final albumImage = _getBestAlbumImage(albumDetails);
    final albumTitle = albumDetails?['title'] ?? 'Album';

    if (loading) {
      return Scaffold(
        backgroundColor: isDark ? Colors.black : Colors.white,
        appBar: AppBar(
          title: const Text('Album'),
          backgroundColor: isDark ? Colors.black : Colors.white,
          iconTheme: IconThemeData(color: textColor),
        ),
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          albumTitle,
          style: TextStyle(color: textColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // Album Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Album Image
                  if (albumImage.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        albumImage,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[800] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.album_rounded,
                              size: 80,
                              color: isDark
                                  ? Colors.white.withAlpha((0.3 * 255).round())
                                  : Colors.black.withAlpha((0.3 * 255).round()),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Album Details
                  Text(
                    albumTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    albumDetails?['artist'] ?? 'Unknown Artist',
                    style: TextStyle(
                      fontSize: 16,
                      color: subtextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Play All Button
                  ElevatedButton.icon(
                    onPressed: () {
                      if (songs.isNotEmpty) {
                        _playSong(songs[0]);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Play All'),
                  ),
                ],
              ),
            ),
          ),

          // Songs List
          if (songs.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final song = songs[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor.withAlpha((0.2 * 255).round()),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      song['title'] ?? 'Unknown',
                      style: TextStyle(color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song['primaryArtists'] ?? 'Unknown Artist',
                      style: TextStyle(color: subtextColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatDuration(int.tryParse(song['duration'].toString()) ?? 0),
                      style: TextStyle(color: subtextColor, fontSize: 12),
                    ),
                    onTap: () => _playSong(song),
                  );
                },
                childCount: songs.length,
              ),
            )
          else
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'No songs found',
                    style: TextStyle(color: subtextColor),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

