import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../service/cache_service.dart';
import '../service/audio_controller.dart';
import '../model/local_song_model.dart';
import '../widgets/bottom_mini_player.dart';
import '../widgets/custom_notification.dart';
import '../widgets/rhythm_dialog.dart';

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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
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
      await _loadCachedSongs();
      if (mounted) {
        CustomNotification.show(context, message: 'Removed "${metadata.songTitle}"', icon: Icons.delete, color: Colors.orange);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : const Color(0xFFF8F9FA);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    final bottomPadding = MediaQuery.of(context).padding.bottom + 80;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Offline',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(Icons.tune, color: textColor),
            onPressed: _showFilterMenu,
            tooltip: 'Filter by Artist',
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF2C5F2D)),
          )
              : _filteredSongs.isEmpty
              ? _buildEmptyState(isDark)
              : Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
            child: ListView.builder(
              itemCount: _filteredSongs.length,
              itemBuilder: (context, index) {
                final metadata = _filteredSongs[index];
                return _buildSongTile(metadata, isDark, textColor, subtitleColor);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomMiniPlayer(),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 80,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 32),
            Text(
              'No Offline Songs',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Songs will be cached automatically\nwhen you play them online',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile(
      CacheMetadata metadata,
      bool isDark,
      Color textColor,
      Color subtitleColor,
      ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          color: const Color(0xFF2C5F2D),
          child: metadata.albumArt.isNotEmpty &&
              (metadata.albumArt.startsWith('http://') || metadata.albumArt.startsWith('https://'))
              ? CachedNetworkImage(
            imageUrl: metadata.albumArt,
            fit: BoxFit.cover,
            placeholder: (_, __) => const Icon(Icons.music_note, color: Colors.white70, size: 20),
            errorWidget: (_, __, ___) => const Icon(Icons.music_note, color: Colors.white70, size: 20),
          )
              : const Icon(Icons.music_note, color: Colors.white70, size: 20),
        ),
      ),
      title: Text(
        metadata.songTitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: textColor,
        ),
      ),
      subtitle: Text(
        metadata.songArtist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: subtitleColor,
        ),
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: isDark ? Colors.white70 : Colors.black54, size: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (value) {
          if (value == 'play') {
            _playCachedSong(metadata);
          } else if (value == 'remove') {
            _removeSong(metadata);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'play',
            child: Row(children: [Icon(Icons.play_arrow, size: 18), SizedBox(width: 8), Text('Play')]),
          ),
          const PopupMenuItem(
            value: 'remove',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Remove', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
      onTap: () => _playCachedSong(metadata),
    );
  }
}