import 'package:flutter/material.dart';
import 'package:rhythm/services/cache_service.dart';
import 'package:rhythm/services/audio_controller.dart';
import 'package:rhythm/model/local_song_model.dart';
import 'package:rhythm/widgets/custom_notification.dart';
import 'package:rhythm/widgets/rhythm_dialog.dart';

class OfflinePlaylistPage extends StatefulWidget {
  final bool refreshed;
  const OfflinePlaylistPage({super.key, this.refreshed = false});

  @override
  State<OfflinePlaylistPage> createState() => _OfflinePlaylistPageState();
}

class _OfflinePlaylistPageState extends State<OfflinePlaylistPage> {
  final CacheService _cacheService = CacheService();
  final AudioController _audioController = AudioController.instance;
  List<CacheMetadata> _cachedSongs = [];
  List<CacheMetadata> _filteredSongs = [];
  bool _isLoading = true;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadCachedSongs();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.refreshed && mounted) {
        CustomNotification.show(context, message: 'Offline list refreshed', icon: Icons.refresh, color: Colors.green);
      }
    });
  }

  Future<void> _loadCachedSongs() async {
    setState(() => _isLoading = true);
    await _cacheService.initialize();
    final songs = _cacheService.getCachedSongs();
    setState(() {
      _cachedSongs = songs;
      _filteredSongs = songs;
      _isLoading = false;
    });
  }

  void _applyFilter(String filter) {
    setState(() {
      _filter = filter;
      if (filter == 'All') {
        _filteredSongs = _cachedSongs;
      } else {
        _filteredSongs = _cachedSongs
            .where((song) => song.songArtist.toLowerCase().contains(filter.toLowerCase()))
            .toList();
      }
    });
  }

  void _showFilterMenu() {
    final artists = _cachedSongs.map((s) => s.songArtist).toSet().toList()..sort();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Filter by Artist',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              ...['All', ...artists].map((artist) {
                return ListTile(
                  leading: Icon(
                    _filter == artist ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: _filter == artist ? Theme.of(context).primaryColor : null,
                  ),
                  title: Text(artist),
                  onTap: () {
                    _applyFilter(artist);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _playCachedSong(CacheMetadata metadata) async {
    final cachedPath = _cacheService.getCachedFilePath(metadata.originalUrl);
    if (cachedPath == null) {
      CustomNotification.show(context, message: 'Cached file not found', icon: Icons.error, color: Colors.red);
      return;
    }

    final song = LocalSongModel(
      id: int.tryParse(metadata.songId) ?? 0,
      title: metadata.songTitle,
      artist: metadata.songArtist,
      uri: cachedPath,
      albumArt: metadata.albumArt,
      duration: 0,
    );

    final playlist = _filteredSongs
        .map((cached) {
      final path = _cacheService.getCachedFilePath(cached.originalUrl);
      if (path != null) {
        return LocalSongModel(
          id: int.tryParse(cached.songId) ?? 0,
          title: cached.songTitle,
          artist: cached.songArtist,
          uri: path,
          albumArt: cached.albumArt,
          duration: 0,
        );
      }
      return null;
    })
        .whereType<LocalSongModel>()
        .toList();

    await _audioController.playFromPlaylist(song, playlist: playlist);
    if (mounted) {
      CustomNotification.show(context, message: 'Playing: ${metadata.songTitle}', icon: Icons.play_arrow, color: Colors.green);
    }
  }

  Future<void> _removeSong(CacheMetadata metadata) async {
    final confirm = await showRhythmDialog<bool>(
      context: context,
      glassy: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Remove from Offline',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Remove "${metadata.songTitle}" from offline cache?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withAlpha((0.7 * 255).round()),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Colors.white.withAlpha((0.6 * 255).round()),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _cacheService.removeSongFromCache(metadata.songId);
      _loadCachedSongs();
      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Song removed from offline',
          icon: Icons.delete,
          color: Colors.red,
        );
      }
    }
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
                      onTap: () => Navigator.pop(context, true),
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
                          'Offline Songs',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_filteredSongs.length} ${_filteredSongs.length == 1 ? 'song' : 'songs'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white.withAlpha((0.6 * 255).round())
                                : Colors.black.withAlpha((0.6 * 255).round()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.filter_list, color: textColor),
                    onPressed: _cachedSongs.isNotEmpty ? _showFilterMenu : null,
                  ),
                ],
              ),
            ),

            // Songs List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : _filteredSongs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.offline_pin_rounded,
                                size: 80,
                                color: isDark
                                    ? Colors.white.withAlpha((0.3 * 255).round())
                                    : Colors.black.withAlpha((0.3 * 255).round()),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No offline songs',
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
                                'Downloaded songs will appear here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white.withAlpha((0.4 * 255).round())
                                      : Colors.black.withAlpha((0.4 * 255).round()),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewPadding.bottom + 100,
                          ),
                          itemCount: _filteredSongs.length,
                          itemBuilder: (context, index) {
                            final song = _filteredSongs[index];
                            return _buildSongTile(song);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile(CacheMetadata song) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return InkWell(
      onTap: () => _playCachedSong(song),
      onLongPress: () => _removeSong(song),
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
                child: song.albumArt.isNotEmpty
                    ? Image.network(
                        song.albumArt,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Theme.of(context).primaryColor.withAlpha((0.2 * 255).round()),
                            child: Icon(
                              Icons.music_note,
                              color: Theme.of(context).primaryColor,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Theme.of(context).primaryColor.withAlpha((0.2 * 255).round()),
                          child: Icon(
                            Icons.music_note,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    : Container(
                        color: Theme.of(context).primaryColor.withAlpha((0.2 * 255).round()),
                        child: Icon(
                          Icons.music_note,
                          color: Theme.of(context).primaryColor,
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
                    song.songTitle,
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
                    song.songArtist,
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
            // Offline badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.offline_pin, color: Colors.green, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Offline',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 11,
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
