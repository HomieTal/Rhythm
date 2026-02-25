import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../model/local_song_model.dart';
import '../service/favorites_service.dart';
import '../service/audio_controller.dart';
import 'player_screen.dart';
import '../widgets/bottom_mini_player.dart';
import '../widgets/custom_notification.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with WidgetsBindingObserver {
  final favoritesService = FavoritesService();
  final audioController = AudioController.instance;
  String _sortBy = 'Recently Added';
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAudio();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {});
    }
  }

  Future<void> _initializeAudio() async {
    try {
      await audioController.loadSongs();
      debugPrint('Songs loaded for favorites playback: ${audioController.songs.value.length}');
    } catch (e) {
      debugPrint('Error loading songs: $e');
    }
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
              ...['Recently Added', 'Title (A-Z)', 'Title (Z-A)', 'Artist'].map((option) {
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
                      fontWeight: _sortBy == option ? FontWeight.w600 : FontWeight.normal,
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

  void _showSongMenu(BuildContext context, LocalSongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1A1A1A)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.play_arrow),
                title: const Text('Play Next'),
                onTap: () {
                  Navigator.pop(context);
                  _playNext(song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text('Add to Playlist'),
                onTap: () {
                  Navigator.pop(context);
                  CustomNotification.show(
                    context,
                    message: 'Feature coming soon',
                    icon: Icons.construction,
                    color: Colors.orange,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share'),
                onTap: () {
                  Navigator.pop(context);
                  CustomNotification.show(
                    context,
                    message: 'Share feature coming soon',
                    icon: Icons.share,
                    color: Colors.blue,
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.favorite, color: Colors.pink.shade400),
                title: const Text('Remove from Favorites'),
                onTap: () {
                  Navigator.pop(context);
                  _removeFavorite(song);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _playNext(LocalSongModel song) async {
    final songIndex = audioController.songs.value.indexWhere((s) => s.id == song.id);
    if (songIndex != -1) {
      CustomNotification.show(
        context,
        message: 'Feature coming soon',
        icon: Icons.queue_music,
        color: Colors.green,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Favorites',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isGridView ? Icons.view_list : Icons.grid_view,
                      color: textColor,
                    ),
                    onPressed: () {
                      setState(() => _isGridView = !_isGridView);
                    },
                  ),
                ],
              ),
            ),

            // Song count and sort
            ValueListenableBuilder<List<LocalSongModel>>(
              valueListenable: favoritesService.favorites,
              builder: (context, favorites, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${favorites.length} Song${favorites.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          InkWell(
                            onTap: _showSortOptions,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                children: [
                                  Icon(Icons.sort, color: subtextColor, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    _sortBy,
                                    style: TextStyle(
                                      color: subtextColor,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_down, color: subtextColor, size: 18),
                                ],
                              ),
                            ),
                          ),
                          if (favorites.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.shuffle, color: subtextColor, size: 22),
                              onPressed: () async {
                                await audioController.loadSongs();
                                final shuffledFavorites = List<LocalSongModel>.from(favorites)..shuffle();
                                if (shuffledFavorites.isNotEmpty) {
                                  final firstSong = shuffledFavorites.first;
                                  final songIndex = audioController.songs.value.indexWhere(
                                        (s) => s.id == firstSong.id,
                                  );
                                  if (songIndex != -1) {
                                    await audioController.playSong(songIndex);
                                    if (mounted) {
                                      CustomNotification.show(
                                        context,
                                        message: 'Shuffling favorites',
                                        icon: Icons.shuffle,
                                        color: primaryColor,
                                        duration: const Duration(seconds: 2),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            // Songs list/grid (FULL WIDTH)
            Expanded(
              child: ValueListenableBuilder<List<LocalSongModel>>(
                valueListenable: favoritesService.favorites,
                builder: (context, favorites, _) {
                  if (favorites.isEmpty) {
                    return _buildEmptyState();
                  }

                  return _isGridView
                      ? _buildGridView(favorites)
                      : _buildListView(favorites);
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomMiniPlayer(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.pink.withAlpha((0.1 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border,
              size: 64,
              color: Colors.pink.shade300,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No favorite songs yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Tap the heart icon on songs to add them to your favorites',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withAlpha((0.6 * 255).round()),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<LocalSongModel> favorites) {
    return ListView.builder(
      itemCount: favorites.length,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 100), // Full width
      itemBuilder: (context, index) {
        final song = favorites[index];
        return _buildSongListTile(song, index);
      },
    );
  }

  Widget _buildGridView(List<LocalSongModel> favorites) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
        childAspectRatio: 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 100), // Full width
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final song = favorites[index];
        return _buildSongGridTile(song, index);
      },
    );
  }

  Widget _buildSongListTile(LocalSongModel song, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    return InkWell(
      onTap: () => _playSong(song, index),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            // Artwork
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: song.albumArt.isNotEmpty
                  ? Image.network(
                      song.albumArt,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.pink.shade300.withAlpha((0.3 * 255).round()),
                              Colors.purple.shade300.withAlpha((0.3 * 255).round()),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    )
                  : QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      artworkWidth: 50,
                      artworkHeight: 50,
                      artworkFit: BoxFit.cover,
                      keepOldArtwork: true,
                      artworkQuality: FilterQuality.medium,
                      nullArtworkWidget: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.pink.shade300.withAlpha((0.3 * 255).round()),
                              Colors.purple.shade300.withAlpha((0.3 * 255).round()),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.music_note,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 12),
            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.white.withAlpha((0.6 * 255).round()) : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Three dots menu
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 22,
              ),
              onPressed: () => _showSongMenu(context, song),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongGridTile(LocalSongModel song, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    return InkWell(
      onTap: () => _playSong(song, index),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Artwork
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: QueryArtworkWidget(
                      id: song.id,
                      type: ArtworkType.AUDIO,
                      artworkWidth: 200,
                      artworkHeight: 200,
                      artworkFit: BoxFit.cover,
                      keepOldArtwork: true,
                      artworkQuality: FilterQuality.high,
                      nullArtworkWidget: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.pink.shade300.withAlpha((0.3 * 255).round()),
                              Colors.purple.shade300.withAlpha((0.3 * 255).round()),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Three dots overlay
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha((0.5 * 255).round()),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: isDark ? Colors.white : Colors.black54,
                        size: 18,
                      ),
                      onPressed: () => _showSongMenu(context, song),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Song info
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title.split('/').last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white.withAlpha((0.6 * 255).round()) : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playSong(LocalSongModel song, int index) async {
    try {
      debugPrint('Playing favorite song: ${song.title}');
      if (audioController.songs.value.isEmpty) {
        await audioController.loadSongs();
        if (!mounted) return;
        CustomNotification.show(
          context,
          message: 'Loading songs...',
          icon: Icons.hourglass_empty,
          color: Theme.of(context).primaryColor,
          duration: const Duration(seconds: 1),
        );
      }
      // Try by id, then by uri, then fallback to play from playlist
      final songIndex = audioController.songs.value.indexWhere((s) => s.id == song.id);
      if (!mounted) return;
      if (songIndex != -1) {
        final success = await audioController.playSong(songIndex);
        if (!success) {
          if (!mounted) return;
          CustomNotification.show(
            context,
            message: 'Failed to play song',
            icon: Icons.error_outline,
            color: Colors.red,
            duration: const Duration(seconds: 2),
          );
          return;
        }
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(song: song, index: songIndex),
          ),
        );
      } else {
        final uriIndex = audioController.songs.value.indexWhere((s) => s.uri == song.uri);
        if (uriIndex != -1) {
          final success = await audioController.playSong(uriIndex);
          if (success && mounted) {
            await Future.delayed(const Duration(milliseconds: 300));
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerScreen(
                  song: audioController.songs.value[uriIndex],
                  index: uriIndex,
                ),
              ),
            );
          }
        } else if (song.uri.isNotEmpty) {
          // Fallback: play from playlist with only this song
          final tempPlaylist = [song];
          final ok = await audioController.playFromPlaylist(song, playlist: tempPlaylist);
          if (ok && mounted) {
            await Future.delayed(const Duration(milliseconds: 300));
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerScreen(song: song, index: 0),
              ),
            );
          } else {
            if (mounted) {
              CustomNotification.show(
                context,
                message: 'Song not found in library',
                icon: Icons.error_outline,
                color: Colors.red,
                duration: const Duration(seconds: 2),
              );
            }
          }
        } else {
          if (mounted) {
            CustomNotification.show(
              context,
              message: 'Song not found in library',
              icon: Icons.error_outline,
              color: Colors.red,
              duration: const Duration(seconds: 2),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Play error: $e\n$stackTrace');
      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Error playing song',
          icon: Icons.error_outline,
          color: Colors.red,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _removeFavorite(LocalSongModel song) async {
    await favoritesService.toggleFavorite(song);
    if (mounted) {
      CustomNotification.show(
        context,
        message: 'Removed from favorites',
        icon: Icons.favorite_border,
        color: Colors.pink,
        duration: const Duration(seconds: 2),
      );
    }
  }
}