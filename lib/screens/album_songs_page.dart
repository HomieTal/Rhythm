import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rhythm/services/audio_controller.dart';
import 'package:rhythm/model/local_song_model.dart';
import 'package:rhythm/screens/player_screen.dart';

class AlbumSongsPage extends StatefulWidget {
  final AlbumModel album;

  const AlbumSongsPage({super.key, required this.album});

  @override
  State<AlbumSongsPage> createState() => _AlbumSongsPageState();
}

class _AlbumSongsPageState extends State<AlbumSongsPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioController _audioController = AudioController.instance;
  List<LocalSongModel> _albumSongs = [];
  bool _isLoading = true;

  static const double _headerArtSize = 246.4; // 88.0 * 2.8

  @override
  void initState() {
    super.initState();
    _loadAlbumSongs();
  }

  Future<void> _loadAlbumSongs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Ensure songs are loaded in AudioController first
      if (_audioController.songs.value.isEmpty) {
        debugPrint('🔄 Loading songs in AudioController...');
        await _audioController.loadSongs();
      }

      // Add small delay to avoid concurrent OnAudioQuery calls
      await Future.delayed(const Duration(milliseconds: 100));

      final songs = await _audioQuery.queryAudiosFrom(
        AudiosFromType.ALBUM_ID,
        widget.album.id,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('⏱️ Query album songs timeout');
          return [];
        },
      );

      // Convert to LocalSongModel
      final allSongs = _audioController.songs.value;
      final localSongs = songs.map((song) {
        return allSongs.firstWhere(
          (s) => s.id == song.id,
          orElse: () => LocalSongModel(
            id: song.id,
            title: song.title,
            artist: song.artist ?? 'Unknown Artist',
            uri: song.uri ?? '',
            albumArt: '',
            duration: song.duration ?? 0,
          ),
        );
      }).toList();

      if (mounted) {
        setState(() {
          _albumSongs = localSongs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading album songs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _playShuffled() async {
    if (_albumSongs.isEmpty) return;
    final shuffled = List<LocalSongModel>.from(_albumSongs)..shuffle();
    await _audioController.playFromPlaylist(shuffled.first, playlist: shuffled);
  }

  Future<void> _playFromStart() async {
    if (_albumSongs.isEmpty) return;
    await _audioController.playFromPlaylist(_albumSongs.first, playlist: _albumSongs);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerScreen(
            song: _albumSongs.first,
            index: 0,
          ),
        ),
      );
    }
  }

  Future<void> _playSong(LocalSongModel song, int index) async {
    await _audioController.playFromPlaylist(song, playlist: _albumSongs);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlayerScreen(
            song: song,
            index: index,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark, primaryColor),
            _buildSongsList(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Album artwork and info
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).canvasColor.withAlpha(5),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                _buildAlbumArtwork(primaryColor),
                const SizedBox(height: 16),
                _buildAlbumInfo(isDark),
                const SizedBox(height: 12),
                _buildControls(isDark, primaryColor),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArtwork(Color primaryColor) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: QueryArtworkWidget(
          id: widget.album.id,
          type: ArtworkType.ALBUM,
          artworkWidth: _headerArtSize,
          artworkHeight: _headerArtSize,
          artworkFit: BoxFit.cover,
          nullArtworkWidget: Container(
            width: _headerArtSize,
            height: _headerArtSize,
            color: primaryColor.withAlpha(41),
            child: const Center(
              child: Icon(Icons.album_rounded, size: 80, color: Colors.white24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumInfo(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Text(
            widget.album.album.isNotEmpty ? widget.album.album : 'Unknown Album',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.album.artist ?? 'Unknown Artist',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControls(bool isDark, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          _buildControlButton(
            icon: Icons.shuffle,
            onPressed: _playShuffled,
            isDark: isDark,
          ),
          const SizedBox(width: 12),
          _buildControlButton(
            icon: Icons.favorite_border,
            onPressed: () {},
            isDark: isDark,
          ),
          const Spacer(),
          _buildPlayButton(primaryColor),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black12,
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white70, size: 22),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildPlayButton(Color primaryColor) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IconButton(
        icon: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
        onPressed: _playFromStart,
      ),
    );
  }

  Widget _buildSongsList(Color primaryColor) {
    return Expanded(
      child: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _albumSongs.isEmpty
              ? const Center(
                  child: Text(
                    'No songs found',
                    style: TextStyle(color: Colors.white60),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewPadding.bottom + 100,
                  ),
                  itemCount: _albumSongs.length,
                  itemBuilder: (context, index) => _buildSongTile(_albumSongs[index], index),
                ),
    );
  }

  Widget _buildSongTile(LocalSongModel song, int index) {
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () => _playSong(song, index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // Track number
            SizedBox(
              width: 32,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: QueryArtworkWidget(
                  id: song.id,
                  type: ArtworkType.AUDIO,
                  artworkFit: BoxFit.cover,
                  nullArtworkWidget: Container(
                    color: primaryColor.withAlpha(51),
                    child: Icon(Icons.music_note, color: primaryColor, size: 24),
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    song.artist,
                    style: const TextStyle(fontSize: 13, color: Colors.white60),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Duration
            Text(
              _formatDuration(song.duration),
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(width: 8),
            // More options
            const Icon(Icons.more_vert, color: Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }
}
