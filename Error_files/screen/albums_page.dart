import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:Rhythm/service/audio_controller.dart';
import 'album_songs_page.dart';

class AlbumsPage extends StatefulWidget {
  const AlbumsPage({super.key});

  @override
  State<AlbumsPage> createState() => _AlbumsPageState();
}

class _AlbumsPageState extends State<AlbumsPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioController _audioController = AudioController.instance;
  List<AlbumModel> _albums = [];
  bool _isLoading = true;
  String _sortBy = 'A-Z';

  @override
  void initState() {
    super.initState();
    _loadAlbums();
    _ensureSongsLoaded();
  }

  Future<void> _ensureSongsLoaded() async {
    if (_audioController.songs.value.isEmpty) {
      debugPrint('🔄 Loading songs in AudioController...');
      await _audioController.loadSongs();
    }
  }

  Future<void> _loadAlbums() async {
    setState(() => _isLoading = true);

    try {
      final albums = await _audioQuery.queryAlbums(
        sortType: AlbumSortType.ALBUM,
        orderType: OrderType.ASC_OR_SMALLER,
      );

      if (mounted) {
        setState(() {
          _albums = albums;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading albums: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<AlbumModel> _getSortedAlbums() {
    final albums = List<AlbumModel>.from(_albums);

    switch (_sortBy) {
      case 'A-Z':
        albums.sort((a, b) => a.album.compareTo(b.album));
        break;
      case 'Z-A':
        albums.sort((a, b) => b.album.compareTo(a.album));
        break;
      case 'Most Songs':
        albums.sort((a, b) => b.numOfSongs.compareTo(a.numOfSongs));
        break;
      case 'Recent':
        albums.sort((a, b) => b.id.compareTo(a.id));
        break;
    }

    return albums;
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
              ...['A-Z', 'Z-A', 'Most Songs', 'Recent'].map((option) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final sortedAlbums = _getSortedAlbums();

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter/Sort Bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha((0.05 * 255).round())
                      : Colors.black.withAlpha((0.05 * 255).round()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha((0.1 * 255).round())
                        : Colors.black.withAlpha((0.1 * 255).round()),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.album_rounded,
                            size: 20,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${sortedAlbums.length} Albums',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: _showSortOptions,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Text(
                                    _sortBy,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.sort_rounded,
                                    size: 20,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Albums Grid or Empty State
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : sortedAlbums.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF9c27b0).withAlpha((0.2 * 255).round()),
                                      const Color(0xFF673ab7).withAlpha((0.2 * 255).round()),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.album_rounded,
                                  size: 72,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'No Albums Yet',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Your album collection will appear here',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white38 : Colors.black38,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: sortedAlbums.length,
                          itemBuilder: (context, index) {
                            final album = sortedAlbums[index];
                            return _buildAlbumCard(album);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumCard(AlbumModel album) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        // Navigate to album songs page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlbumSongsPage(album: album),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withAlpha((0.05 * 255).round())
              : Colors.black.withAlpha((0.05 * 255).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha((0.1 * 255).round())
                : Colors.black.withAlpha((0.1 * 255).round()),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Artwork
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Theme.of(context).primaryColor.withAlpha((0.1 * 255).round()),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: QueryArtworkWidget(
                    id: album.id,
                    type: ArtworkType.ALBUM,
                    artworkWidth: double.infinity,
                    artworkHeight: double.infinity,
                    artworkFit: BoxFit.cover,
                    nullArtworkWidget: Container(
                      color: Theme.of(context).primaryColor.withAlpha((0.2 * 255).round()),
                      child: Center(
                        child: Icon(
                          Icons.album_rounded,
                          size: 48,
                          color: Theme.of(context).primaryColor.withAlpha((0.5 * 255).round()),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Album Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    album.album.isNotEmpty ? album.album : 'Unknown Album',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    album.artist ?? 'Unknown Artist',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${album.numOfSongs} ${album.numOfSongs == 1 ? 'song' : 'songs'}',
                    style: TextStyle(
                      fontSize: 9,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}