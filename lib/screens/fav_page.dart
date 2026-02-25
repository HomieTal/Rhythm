import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rhythm/model/local_song_model.dart';
import 'package:rhythm/services/favorites_service.dart';
import 'package:rhythm/services/audio_controller.dart';
import 'package:rhythm/screens/player_screen.dart';
import 'package:rhythm/widgets/custom_notification.dart';

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

  void _removeFavorite(LocalSongModel song) {
    favoritesService.toggleFavorite(song);
    CustomNotification.show(
      context,
      message: 'Removed from favorites',
      icon: Icons.favorite_border,
      color: Colors.pink,
    );
  }

  List<LocalSongModel> _getSortedFavorites(List<LocalSongModel> favorites) {
    final sorted = List<LocalSongModel>.from(favorites);
    switch (_sortBy) {
      case 'Title (A-Z)':
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'Title (Z-A)':
        sorted.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case 'Artist':
        sorted.sort((a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()));
        break;
      case 'Recently Added':
      default:
        // Keep original order (most recently added first)
        break;
    }
    return sorted;
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
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back, color: textColor, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Favourites',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ValueListenableBuilder<List<LocalSongModel>>(
                          valueListenable: favoritesService.favorites,
                          builder: (context, favorites, _) {
                            return Text(
                              '${favorites.length} ${favorites.length == 1 ? 'song' : 'songs'}',
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
                  // Sort button
                  IconButton(
                    icon: Icon(Icons.sort, color: textColor),
                    onPressed: _showSortOptions,
                  ),
                  // Toggle view button
                  IconButton(
                    icon: Icon(_isGridView ? Icons.list : Icons.grid_view, color: textColor),
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                  ),
                ],
              ),
            ),

            // Favorites list
            Expanded(
              child: ValueListenableBuilder<List<LocalSongModel>>(
                valueListenable: favoritesService.favorites,
                builder: (context, favorites, _) {
                  if (favorites.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 80,
                            color: isDark
                                ? Colors.white.withAlpha((0.3 * 255).round())
                                : Colors.black.withAlpha((0.3 * 255).round()),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No favorites yet',
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
                            'Songs you like will appear here',
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

                  final sortedFavorites = _getSortedFavorites(favorites);

                  return ListView.builder(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewPadding.bottom + 100,
                    ),
                    itemCount: sortedFavorites.length,
                    itemBuilder: (context, index) {
                      final song = sortedFavorites[index];
                      return _buildSongTile(song, index);
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

  Widget _buildSongTile(LocalSongModel song, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return InkWell(
      onTap: () async {
        final songIndex = audioController.songs.value.indexWhere((s) => s.id == song.id);
        if (songIndex != -1) {
          await audioController.playSong(songIndex);
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
            // Remove from favorites button
            IconButton(
              icon: Icon(Icons.favorite, color: Colors.pink.shade400),
              onPressed: () => _removeFavorite(song),
            ),
          ],
        ),
      ),
    );
  }
}
