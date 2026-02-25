import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:Rhythm/songsrepo/Saavn/saavn_api.dart';
import 'package:Rhythm/service/audio_controller.dart';
import 'package:Rhythm/model/local_song_model.dart';
import 'package:Rhythm/service/playlist_service.dart';
import 'player_screen.dart';
import '../widgets/bottom_mini_player.dart';
import '../widgets/custom_notification.dart';

class OnlineAlbumPage extends StatefulWidget {
  final String token;
  const OnlineAlbumPage({super.key, required this.token});

  @override
  State<OnlineAlbumPage> createState() => _OnlineAlbumPageState();
}

class _OnlineAlbumPageState extends State<OnlineAlbumPage> {
  final SaavnAPI api = SaavnAPI();
  final AudioController audioCtrl = AudioController.instance;

  bool loading = true;
  Map? albumDetails;
  List songs = [];
  bool isAlbumInPlaylist = false;

  @override
  void initState() {
    super.initState();
    _loadAlbum();
    // Check if album is already in playlist
    isAlbumInPlaylist = PlaylistService.instance.isAlbumInPlaylist(widget.token);
  }

  // Format duration in mm:ss
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _getBestAlbumImage(Map? albumDetails) {
    if (albumDetails == null) return '';
    final keys = [
      'image_1200x1200',
      'image_500x500',
      'image_high',
      'image',
    ];
    for (final k in keys) {
      if (albumDetails[k] != null && albumDetails[k].toString().isNotEmpty) {
        return albumDetails[k].toString();
      }
    }
    // Try to construct a higher-res image from a low-res URL
    final img = albumDetails['image']?.toString() ?? '';
    if (img.contains('50x50')) {
      return img.replaceAll('50x50', '500x500');
    }
    return img;
  }

  Future<void> _loadAlbum() async {
    setState(() => loading = true);
    try {
      debugPrint('🎵 Loading album with token: ${widget.token}');
      final res = await api.fetchAlbumDetails(widget.token);
      print('🎧 FULL RESPONSE: $res');

      // Use the 'songs' key directly from the response
      List<dynamic> fetchedSongs = res['songs'] ?? [];
      Map? details = res['albumDetails'] ?? {};

      if (fetchedSongs.isEmpty) {
        print('⚠️ No songs found in response');
        setState(() {
          songs = [];
          albumDetails = details ?? {};
          loading = false;
        });
        return;
      }

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

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    // Text color logic for theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;
    // Use higher quality image if available
    final albumImage = _getBestAlbumImage(albumDetails);
    final albumTitle = albumDetails?['title'] ?? 'Album';
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
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              // header area height - gives room for artwork + title + controls
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                // subtle gradient to match album backdrop
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [Colors.black, Colors.black87]
                      : [Colors.white, Colors.grey.shade100],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // center artwork on top
                  Builder(builder: (ctx) {
                    final double maxWidth = MediaQuery.of(ctx).size.width;
                    final double artSize = (maxWidth - 48).clamp(220.0, 360.0);
                    return Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: albumImage.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: albumImage,
                                width: artSize,
                                height: artSize,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                memCacheWidth: (artSize * 2).toInt(), // High resolution cache
                                memCacheHeight: (artSize * 2).toInt(),
                                placeholder: (context, url) => Container(
                                  width: artSize,
                                  height: artSize,
                                  color: isDark ? primary.withAlpha((0.18 * 255).round()) : Colors.grey.shade200,
                                  child: Center(
                                    child: CircularProgressIndicator(color: primary),
                                  ),
                                ),
                                errorWidget: (c, e, s) => Container(
                                  width: artSize,
                                  height: artSize,
                                  color: isDark ? primary.withAlpha((0.18 * 255).round()) : Colors.grey.shade200,
                                  child: Icon(Icons.album_rounded, color: primary, size: artSize * 0.3),
                                ),
                              )
                            : Container(
                                width: artSize,
                                height: artSize,
                                color: isDark ? primary.withAlpha((0.18 * 255).round()) : Colors.grey.shade200,
                                child: Icon(Icons.album_rounded, color: primary, size: artSize * 0.3),
                              ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // title + artist
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          albumTitle,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          albumDetails?['primaryArtists']?.toString() ?? albumDetails?['artist']?.toString() ?? 'Unknown Artist',
                          style: TextStyle(color: subtextColor, fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  // controls row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Row(
                          children: [
                            // album thumbnail small
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.black12,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: albumImage.isNotEmpty
                                      ? Image.network(albumImage, width: 36, height: 36, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.music_note, color: primary))
                                      : Icon(Icons.music_note, color: primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // add/remove album button
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(8)),
                              child: IconButton(
                                icon: Icon(isAlbumInPlaylist ? Icons.check_circle : Icons.add, color: isAlbumInPlaylist ? Colors.green : textColor),
                                onPressed: () async {
                                  setState(() => isAlbumInPlaylist = !isAlbumInPlaylist);
                                  if (isAlbumInPlaylist) {
                                    PlaylistService.instance.addAlbumToPlaylist(widget.token, albumDetails ?? {}, songs);
                                    // Show notification
                                    CustomNotification.show(context, message: 'Album added to your playlist', icon: Icons.playlist_add, color: Colors.green);
                                  } else {
                                    PlaylistService.instance.removeAlbumFromPlaylist(widget.token);
                                    CustomNotification.show(context, message: 'Album removed from your playlist', icon: Icons.delete, color: Colors.orange);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // download placeholder
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.download_rounded, color: textColor),
                            ),
                            const SizedBox(width: 12),
                            // more
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.black12, borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.more_vert, color: textColor),
                            ),
                          ],
                        ),
                        const Spacer(),
                        // big play button
                        ElevatedButton(
                          onPressed: () async {
                            if (songs.isNotEmpty) {
                              // build playlist and play first (reuse logic from list tap)
                              // small helper to build playlist
                              final playlist = <LocalSongModel>[];
                              int baseId = DateTime.now().millisecondsSinceEpoch;
                              for (int i = 0; i < songs.length; i++) {
                                final ss = songs[i];
                                String? su = ss['url'] as String? ?? ss['perma_url'] as String?;
                                if ((su == null || su.isEmpty) && ss['downloadUrl'] != null && ss['downloadUrl'] is List && (ss['downloadUrl'] as List).isNotEmpty) {
                                  try {
                                    final dl = (ss['downloadUrl'] as List).last;
                                    if (dl is Map && dl['url'] != null) su = dl['url'] as String;
                                  } catch (_) {}
                                }
                                if (su != null && su.isNotEmpty) {
                                  final sTitle = (ss['title'] ?? ss['name'] ?? 'Unknown').toString();
                                  final sArtist = (ss['artist'] ?? ss['primaryArtists'] ?? 'Unknown').toString();
                                  final sImage = (ss['image'] ?? '').toString();
                                  final normalized = su.startsWith('//') ? 'https:$su' : (su.startsWith('http') ? su : 'https://$su');
                                  int sid;
                                  final rawId = ss['id'];
                                  if (rawId is int) sid = rawId; else if (rawId is String) sid = int.tryParse(rawId) ?? -(baseId + i); else if (rawId == null) sid = -(baseId + i); else { try { sid = int.tryParse(rawId.toString()) ?? -(baseId + i); } catch (_) { sid = -(baseId + i); } }
                                  playlist.add(LocalSongModel(id: sid, title: sTitle, artist: sArtist, uri: normalized, albumArt: sImage, duration: (ss['duration'] is int) ? ss['duration'] as int : 0));
                                }
                              }
                              if (playlist.isNotEmpty) {
                                final ok = await audioCtrl.playFromPlaylist(playlist.first, playlist: playlist);
                                if (ok && context.mounted) {
                                  Navigator.push(context, MaterialPageRoute(builder: (c) => PlayerScreen(song: playlist.first, index: audioCtrl.currentIndex.value)));
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: primary, shape: const CircleBorder(), padding: const EdgeInsets.all(14)),
                          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final s = songs[index];
                final title = (s['title'] ?? s['name'] ?? 'Unknown').toString();
                final artist = (s['artist'] ?? s['primaryArtists'] ?? 'Unknown').toString();
                final image = (s['image'] ?? '').toString();
                String? uri = s['url'] as String? ?? s['perma_url'] as String?;
                if ((uri == null || uri.isEmpty) &&
                    s['downloadUrl'] != null &&
                    s['downloadUrl'] is List &&
                    (s['downloadUrl'] as List).isNotEmpty) {
                  try {
                    final dl = (s['downloadUrl'] as List).last;
                    if (dl is Map && dl['url'] != null) {
                      uri = dl['url'] as String;
                    }
                  } catch (_) {}
                }
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: image.isNotEmpty
                        ? Image.network(
                            image,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: 48,
                              height: 48,
                              color: primary.withAlpha((0.2 * 255).round()),
                              child: Icon(Icons.music_note, color: primary, size: 24),
                            ),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            color: primary.withAlpha((0.2 * 255).round()),
                            child: Icon(Icons.music_note, color: primary, size: 24),
                          ),
                  ),
                  title: Text(
                    title,
                    style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    artist,
                    style: TextStyle(color: subtextColor, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (s['duration'] is int) ? _formatDuration(s['duration'] as int) : '',
                        style: TextStyle(color: subtextColor, fontSize: 12),
                      ),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, color: textColor),
                        itemBuilder: (context) => [
                          PopupMenuItem(value: 'add_to_playlist', child: Text('Add to Playlist', style: TextStyle(color: textColor))),
                          PopupMenuItem(value: 'share', child: Text('Share', style: TextStyle(color: textColor))),
                        ],
                        onSelected: (value) {
                          // Handle menu actions here
                        },
                      ),
                    ],
                  ),
                  onTap: () async {
                    if (uri == null || uri.isEmpty) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No playable URL')),
                        );
                      }
                      return;
                    }

                    // Build playlist
                    final playlist = <LocalSongModel>[];
                    int baseId = DateTime.now().millisecondsSinceEpoch;
                    for (int i = 0; i < songs.length; i++) {
                      var ss = songs[i];
                      String? su = ss['url'] as String? ??
                          ss['perma_url'] as String?;
                      if ((su == null || su.isEmpty) &&
                          ss['downloadUrl'] != null &&
                          ss['downloadUrl'] is List &&
                          (ss['downloadUrl'] as List).isNotEmpty) {
                        try {
                          final dl = (ss['downloadUrl'] as List).last;
                          if (dl is Map && dl['url'] != null) {
                            su = dl['url'] as String;
                          }
                        } catch (_) {}
                      }
                      if (su != null && su.isNotEmpty) {
                        final sTitle = (ss['title'] ??
                            ss['name'] ??
                            'Unknown')
                            .toString();
                        final sArtist = (ss['artist'] ??
                            ss['primaryArtists'] ??
                            'Unknown')
                            .toString();
                        final sImage = (ss['image'] ?? '').toString();
                        final normalized = su.startsWith('//')
                            ? 'https:$su'
                            : su.startsWith('http')
                            ? su
                            : 'https://$su';
                        int sid;
                        var rawId = ss['id'];
                        if (rawId is int) {
                          sid = rawId;
                        } else if (rawId is String) {
                          sid = int.tryParse(rawId) ?? -(baseId + i);
                        } else if (rawId == null) {
                          sid = -(baseId + i);
                        } else {
                          try {
                            sid = int.tryParse(rawId.toString()) ?? -(baseId + i);
                          } catch (_) {
                            sid = -(baseId + i);
                          }
                        }
                        playlist.add(LocalSongModel(
                            id: sid,
                            title: sTitle,
                            artist: sArtist,
                            uri: normalized,
                            albumArt: sImage,
                            duration: (ss['duration'] is int)
                                ? ss['duration'] as int
                                : 0));
                      }
                    }

                    final normalizedTapped = uri.startsWith('//')
                        ? 'https:$uri'
                        : uri.startsWith('http')
                        ? uri
                        : 'https://$uri';
                    final currentSongInPlaylist = playlist.firstWhere(
                            (p) => p.uri == normalizedTapped,
                        orElse: () => LocalSongModel(
                            id: -baseId,
                            title: title,
                            artist: artist,
                            uri: normalizedTapped,
                            albumArt: image,
                            duration: 0));

                    final ok = await audioCtrl.playFromPlaylist(
                        currentSongInPlaylist,
                        playlist: playlist);
                    if (!ok) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Playback failed')),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (c) => PlayerScreen(
                              song: currentSongInPlaylist,
                              index: audioCtrl.currentIndex.value,
                            ),
                          ),
                        );
                      }
                    }
                  },
                );
              },
              childCount: songs.length,
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 80), // Space for BottomMiniPlayer
          ),
        ],
      ),
      bottomNavigationBar: const BottomMiniPlayer(),
    );
  }
}
