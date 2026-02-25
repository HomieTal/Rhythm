import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'fav_page.dart';
import 'history_page.dart';
import 'offline_playlist_page.dart';
import '../service/favorites_service.dart';
import '../service/recently_played_service.dart';
import '../service/audio_controller.dart';
import '../service/cache_service.dart';
import '../service/playlist_service.dart';
import '../service/imported_playlist_service.dart';
import '../widgets/custom_notification.dart';
import '../widgets/rhythm_dialog.dart';
import 'online_album_page.dart';
import 'playlist_detail_page.dart';

class PlaylistsPage extends StatefulWidget {
  const PlaylistsPage({super.key});

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  final favoritesService = FavoritesService();
  final recentlyPlayedService = RecentlyPlayedService();
  final audioController = AudioController.instance;
  final cacheService = CacheService();
  final importedPlaylistService = ImportedPlaylistService();
  String _sortBy = 'Date Modified';
  List<Map<String, dynamic>> _customPlaylists = [];
  int _offlineSongsCount = 0;

  @override
  void initState() {
    super.initState();
    PlaylistService.instance.loadFromStorage();
    importedPlaylistService.loadImportedPlaylists();
    _loadCustomPlaylists();
    _loadOfflineSongsCount();
  }

  Future<void> _loadOfflineSongsCount() async {
    await cacheService.initialize();
    final cachedSongs = cacheService.getCachedSongs();
    setState(() {
      _offlineSongsCount = cachedSongs.length;
    });
  }

  Future<void> _loadCustomPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = prefs.getString('custom_playlists');
    if (playlistsJson != null) {
      final List<dynamic> decoded = jsonDecode(playlistsJson);
      setState(() {
        _customPlaylists = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  Future<void> _saveCustomPlaylists() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_playlists', jsonEncode(_customPlaylists));
  }

  Future<Map<String, dynamic>> _addCustomPlaylist(String name) async {
    final newPlaylist = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'name': name,
      'songs': <String>[],
      'createdAt': DateTime.now().toIso8601String(),
    };
    setState(() {
      _customPlaylists.add(newPlaylist);
    });
    await _saveCustomPlaylists();
    return newPlaylist;
  }

  Future<void> _deleteCustomPlaylist(String id) async {
    setState(() {
      _customPlaylists.removeWhere((playlist) => playlist['id'] == id);
    });
    await _saveCustomPlaylists();
  }

  void _showSortOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha((0.3 * 255).round())
                      : Colors.black.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ...['Date Modified', 'Name', 'Most Played', 'Recently Added']
                  .map((option) {
                return ListTile(
                  leading: Icon(
                    _sortBy == option ? Icons.check_circle : Icons.circle_outlined,
                    color: _sortBy == option
                        ? Theme.of(context).primaryColor
                        : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  title: Text(
                    option,
                    style: TextStyle(
                      color: _sortBy == option
                          ? Theme.of(context).primaryColor
                          : (isDark ? Colors.white : Colors.black87),
                      fontWeight:
                      _sortBy == option ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() => _sortBy = option);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    final double albumSize = 96.0;

    final onlineAlbumsRaw = PlaylistService.instance.getAlbums();
    final onlineAlbums = List<Map<String, dynamic>>.from(onlineAlbumsRaw);
    onlineAlbums.sort((a, b) {
      final aDate = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime(2000);
      final bDate = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime(2000);
      return aDate.compareTo(bDate);
    });

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Playlist count and sort options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ValueListenableBuilder(
                    valueListenable: favoritesService.favorites,
                    builder: (context, favorites, _) {
                      return ValueListenableBuilder(
                        valueListenable: recentlyPlayedService.recentlyPlayed,
                        builder: (context, recents, _) {
                          int playlistCount = _customPlaylists.length;
                          if (recents.isNotEmpty) playlistCount++;
                          if (favorites.isNotEmpty) playlistCount++;
                          if (_offlineSongsCount > 0) playlistCount++;

                          return Text(
                            '$playlistCount Playlist${playlistCount != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: subtextColor,
                              fontSize: 13,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: _showSortOptions,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Row(
                            children: [
                              Icon(Icons.view_list,
                                  color: subtextColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                _sortBy,
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.keyboard_arrow_down,
                                  color: subtextColor, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.shuffle, color: subtextColor, size: 24),
                        onPressed: () async {
                          final allSongs = audioController.songs.value;
                          if (allSongs.isNotEmpty) {
                            final shuffledSongs = List.from(allSongs)..shuffle();
                            final firstSongIndex =
                            allSongs.indexOf(shuffledSongs.first);
                            await audioController.playSong(firstSongIndex);

                            if (mounted) {
                              CustomNotification.show(
                                context,
                                message: 'Shuffling all songs',
                                icon: Icons.shuffle,
                                color: Theme.of(context).primaryColor,
                                duration: const Duration(seconds: 2),
                              );
                            }
                          } else {
                            if (mounted) {
                              CustomNotification.show(
                                context,
                                message: 'No songs available to shuffle',
                                icon: Icons.error_outline,
                                color: Colors.orange,
                                duration: const Duration(seconds: 2),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Create / Filter buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _showAddPlaylistDialog,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withAlpha((0.1 * 255).round())
                              : Colors.black.withAlpha((0.05 * 255).round()),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withAlpha((0.2 * 255).round())
                                : Colors.black.withAlpha((0.1 * 255).round()),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.playlist_add, color: subtextColor, size: 18),
                            const SizedBox(width: 6),
                            Text('Create',
                                style: TextStyle(
                                    color: subtextColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      // Filter functionality
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withAlpha((0.1 * 255).round())
                            : Colors.black.withAlpha((0.05 * 255).round()),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withAlpha((0.2 * 255).round())
                              : Colors.black.withAlpha((0.1 * 255).round()),
                        ),
                      ),
                      child: Icon(Icons.tune, color: subtextColor, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Scrollable Content: Grid + Online Albums
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewPadding.bottom + 120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // === Playlist Grid ===
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      child: ValueListenableBuilder(
                        valueListenable: importedPlaylistService.importedPlaylists,
                        builder: (context, importedPlaylists, _) {
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6,
                              childAspectRatio: 3.0,
                            ),
                            itemCount: 3 + _customPlaylists.length,
                            itemBuilder: (context, index) {
                          if (index == 0) {
                            return ValueListenableBuilder(
                              valueListenable: recentlyPlayedService.recentlyPlayed,
                              builder: (context, recentSongs, _) {
                                return _buildPlaylistCard(
                                  context: context,
                                  icon: Icons.history,
                                  title: 'History',
                                  count: recentSongs.length,
                                  color: const Color(0xFF424242),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const HistoryPage()),
                                  ),
                                );
                              },
                            );
                          } else if (index == 1) {
                            return ValueListenableBuilder(
                              valueListenable: favoritesService.favorites,
                              builder: (context, favorites, _) {
                                return _buildPlaylistCard(
                                  context: context,
                                  icon: Icons.favorite,
                                  title: 'Favourites',
                                  count: favorites.length,
                                  color: const Color(0xFF424242),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const FavoritesPage()),
                                  ),
                                );
                              },
                            );
                          } else if (index == 2) {
                            return _buildPlaylistCard(
                              context: context,
                              icon: Icons.offline_pin,
                              title: 'Offline',
                              count: _offlineSongsCount,
                              color: const Color(0xFF2C5F2D),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const OfflinePlaylistPage()),
                                );
                                if (result == true || result == null) {
                                  _loadOfflineSongsCount();
                                }
                              },
                            );
                          }

                          // Custom playlists
                          if (index < 3 + _customPlaylists.length) {
                            final playlist = _customPlaylists[index - 3];
                            final songCount = (playlist['songs'] as List).length;

                            return _buildPlaylistCard(
                              context: context,
                              icon: Icons.playlist_play,
                              title: playlist['name'],
                              count: songCount,
                              color: const Color(0xFF3A3A5C),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PlaylistDetailPage(
                                      playlistId: playlist['id'],
                                      playlistName: playlist['name'],
                                    ),
                                  ),
                                );
                              },
                              onLongPress: () => _showDeletePlaylistDialog(
                                  playlist['id'], playlist['name']),
                            );
                          }

                          // Imported playlists - Show as hidden (will be displayed in separate section below)
                          return const SizedBox.shrink();
                        },
                      );
                    },
                  ),
                ),

                    // === Imported Playlists Section with Album Art ===
                    ValueListenableBuilder(
                      valueListenable: importedPlaylistService.importedPlaylists,
                      builder: (context, importedPlaylists, _) {
                        if (importedPlaylists.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        final albumSize = 110.0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.cloud_download_outlined, color: primaryColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Imported Playlists',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 170,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: importedPlaylists.length,
                                itemBuilder: (context, idx) {
                                  final playlist = importedPlaylists[idx];
                                  final songCount = playlist.songIds.length;

                                  // Generate a consistent random color based on playlist name hash
                                  final colorIndex = playlist.name.hashCode.abs() % 10;
                                  final colors = [
                                    const Color(0xFF5C3A7C), // Purple
                                    const Color(0xFF3A5C7C), // Blue
                                    const Color(0xFF7C3A5C), // Magenta
                                    const Color(0xFF7C5C3A), // Brown
                                    const Color(0xFF3A7C5C), // Teal
                                    const Color(0xFF5C7C3A), // Olive
                                    const Color(0xFF7C3A3A), // Red
                                    const Color(0xFF3A7C7C), // Cyan
                                    const Color(0xFF7C7C3A), // Yellow-Green
                                    const Color(0xFF3A3A7C), // Dark Blue
                                  ];
                                  final playlistColor = colors[colorIndex];

                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: idx < importedPlaylists.length - 1 ? 12 : 0,
                                    ),
                                    child: SizedBox(
                                      width: albumSize,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => PlaylistDetailPage(
                                                playlistId: playlist.name,
                                                playlistName: playlist.name,
                                              ),
                                            ),
                                          );
                                        },
                                        onLongPress: () => _showDeleteImportedPlaylistDialog(playlist.name),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Album Art / Playlist Cover
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                width: albumSize,
                                                height: albumSize,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      playlistColor,
                                                      playlistColor.withAlpha((0.7 * 255).round()),
                                                    ],
                                                  ),
                                                ),
                                                child: Stack(
                                                  children: [
                                                    // Background pattern
                                                    Positioned.fill(
                                                      child: Opacity(
                                                        opacity: 0.2,
                                                        child: Icon(
                                                          Icons.music_note_rounded,
                                                          size: 60,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    // Playlist icon and name
                                                    Center(
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            Icons.playlist_play_rounded,
                                                            color: Colors.white,
                                                            size: 40,
                                                          ),
                                                          const SizedBox(height: 4),
                                                          Padding(
                                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                                            child: Text(
                                                              playlist.name,
                                                              style: const TextStyle(
                                                                color: Colors.white,
                                                                fontSize: 11,
                                                                fontWeight: FontWeight.bold,
                                                                shadows: [
                                                                  Shadow(
                                                                    blurRadius: 4,
                                                                    color: Colors.black45,
                                                                  ),
                                                                ],
                                                              ),
                                                              maxLines: 2,
                                                              overflow: TextOverflow.ellipsis,
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    // Song count badge
                                                    Positioned(
                                                      top: 6,
                                                      right: 6,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.black.withAlpha((0.6 * 255).round()),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          '$songCount',
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            // Playlist Title
                                            Text(
                                              playlist.name,
                                              style: TextStyle(
                                                color: textColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                height: 1.2,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            // Song count
                                            Text(
                                              '$songCount song${songCount != 1 ? 's' : ''}',
                                              style: TextStyle(
                                                color: subtextColor,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    // === Online Albums Section ===
                    if (onlineAlbums.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.album, color: primaryColor, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Online Albums',
                                  style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 150,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 0),
                                child: Row(
                                  children: List.generate(onlineAlbums.length, (idx) {
                                    final album = onlineAlbums[idx];
                                    final albumTitle = album['title'] ?? 'Album';
                                    final albumImage = album['image_1200x1200'] ??
                                        album['image_500x500'] ??
                                        album['image_high'] ??
                                        album['image'] ??
                                        '';
                                    final songCount = PlaylistService.instance
                                        .getSongsForAlbum(album['id'] ?? '')
                                        .length;

                                    return Padding(
                                      padding: EdgeInsets.only(
                                          right: idx < onlineAlbums.length - 1 ? 12 : 0),
                                      child: SizedBox(
                                        width: albumSize,
                                        height: 150,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(12),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => OnlineAlbumPage(
                                                    token: album['id'] ?? ''),
                                              ),
                                            );
                                          },
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Album Art
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: albumImage.isNotEmpty
                                                    ? Image.network(
                                                  albumImage,
                                                  width: albumSize,
                                                  height: albumSize,
                                                  fit: BoxFit.cover,
                                                  filterQuality: FilterQuality.high,
                                                  loadingBuilder:
                                                      (context, child, progress) {
                                                    if (progress == null) return child;
                                                    return Container(
                                                      width: albumSize,
                                                      height: albumSize,
                                                      color: Colors.grey.shade300,
                                                      child: Center(
                                                        child: SizedBox(
                                                          width: 18,
                                                          height: 18,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2.0,
                                                            color: primaryColor,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                                    : Container(
                                                  width: albumSize,
                                                  height: albumSize,
                                                  color: Colors.grey.shade300,
                                                  child: Icon(Icons.music_note,
                                                      size: 36, color: primaryColor),
                                                ),
                                              ),
                                              const SizedBox(height: 6),

                                              // Title: Flexible & Constrained
                                              Expanded(
                                                child: Text(
                                                  albumTitle,
                                                  style: TextStyle(
                                                    color: textColor,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.2, // Tight line height
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),

                                              const SizedBox(height: 2),

                                              // Song Count
                                              Text(
                                                '$songCount songs',
                                                style: TextStyle(
                                                    color: subtextColor, fontSize: 10),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int count,
    required Color color,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeletePlaylistDialog(String playlistId, String playlistName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    showRhythmDialog(
      context: context,
      glassy: true,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.delete_outline, color: Colors.red, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delete Playlist',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to delete "$playlistName"?',
              style: TextStyle(color: subtextColor, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CANCEL', style: TextStyle(color: subtextColor)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    await _deleteCustomPlaylist(playlistId);
                    Navigator.pop(context);
                    if (mounted) {
                      CustomNotification.show(
                        context,
                        message: 'Playlist deleted',
                        icon: Icons.delete,
                        color: Colors.red,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('DELETE', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showDeleteImportedPlaylistDialog(String playlistName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    showRhythmDialog(
      context: context,
      glassy: true,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.delete_outline, color: Colors.red, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delete Imported Playlist',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to delete "$playlistName"?',
              style: TextStyle(color: subtextColor, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CANCEL', style: TextStyle(color: subtextColor)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    await importedPlaylistService.deleteImportedPlaylist(playlistName);
                    Navigator.pop(context);
                    if (mounted) {
                      CustomNotification.show(
                        context,
                        message: 'Imported playlist deleted',
                        icon: Icons.delete,
                        color: Colors.red,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('DELETE', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showAddPlaylistDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;
    final hintColor = isDark
        ? Colors.white.withAlpha((0.5 * 255).round())
        : Colors.black.withAlpha((0.4 * 255).round());

    final TextEditingController nameController = TextEditingController();

    showRhythmDialog(
      context: context,
      glassy: true,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.playlist_add_rounded, color: primaryColor, size: 26),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Create Playlist',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Playlist name',
                hintStyle: TextStyle(color: hintColor),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: subtextColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CANCEL', style: TextStyle(color: subtextColor)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      final created = await _addCustomPlaylist(name);
                      Navigator.pop(context);
                      if (mounted) {
                        CustomNotification.show(
                          context,
                          message: 'Playlist "${created['name']}" created',
                          icon: Icons.playlist_add_check,
                          color: primaryColor,
                          duration: const Duration(seconds: 2),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaylistDetailPage(
                              playlistId: created['id'],
                              playlistName: created['name'],
                            ),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('CREATE', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}