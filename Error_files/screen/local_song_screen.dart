import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:Rhythm/service/audio_controller.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../widgets/custom_notification.dart';
import '../widgets/permission_dialog.dart';
import '../utils/playlist_helper.dart';
import '/settings/settings_page.dart';
import '/settings/theme_provider.dart';

class SongsLocalScreen extends StatefulWidget {
  const SongsLocalScreen({super.key});

  @override
  State<SongsLocalScreen> createState() => _SongsLocalScreenState();
}

class _SongsLocalScreenState extends State<SongsLocalScreen> {
  final audioController = AudioController();
  bool _hasPermission = false;
  String _sortBy = 'A-Z'; // Sorting option
  final ScrollController _scrollController = ScrollController();
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  List<dynamic> _getSortedSongs() {
    var songs = audioController.songs.value.toList();

    // Filter by search query first
    if (_searchQuery.isNotEmpty) {
      songs = songs.where((song) =>
        song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        song.artist.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }


    // Apply sorting
    switch (_sortBy) {
      case 'A-Z':
        songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'Z-A':
        songs.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case 'Most songs':
        // Sort by artist song count (group by artist and count)
        final artistCounts = <String, int>{};
        for (var song in audioController.songs.value) {
          artistCounts[song.artist] = (artistCounts[song.artist] ?? 0) + 1;
        }
        songs.sort((a, b) => (artistCounts[b.artist] ?? 0).compareTo(artistCounts[a.artist] ?? 0));
        break;
      case 'Recent':
        songs.sort((a, b) => b.id.compareTo(a.id));
        break;
    }

    return songs;
  }


  void _showSortMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Sort By',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  _sortBy == 'A-Z' ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: _sortBy == 'A-Z' ? Theme.of(context).primaryColor : (isDark ? Colors.white60 : Colors.black54),
                ),
                title: Text(
                  'A-Z',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  setState(() => _sortBy = 'A-Z');
                  Navigator.pop(context);
                  CustomNotification.show(
                    context,
                    message: 'Sorted A-Z',
                    icon: Icons.sort_by_alpha,
                    color: const Color(0xFF4A9FBF),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  _sortBy == 'Z-A' ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: _sortBy == 'Z-A' ? Theme.of(context).primaryColor : (isDark ? Colors.white60 : Colors.black54),
                ),
                title: Text(
                  'Z-A',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  setState(() => _sortBy = 'Z-A');
                  Navigator.pop(context);
                  CustomNotification.show(
                    context,
                    message: 'Sorted Z-A',
                    icon: Icons.sort_by_alpha,
                    color: const Color(0xFF4A9FBF),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  _sortBy == 'Most songs' ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: _sortBy == 'Most songs' ? Theme.of(context).primaryColor : (isDark ? Colors.white60 : Colors.black54),
                ),
                title: Text(
                  'Most songs',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  setState(() => _sortBy = 'Most songs');
                  Navigator.pop(context);
                  CustomNotification.show(
                    context,
                    message: 'Sorted by Most songs',
                    icon: Icons.library_music,
                    color: const Color(0xFF4A9FBF),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  _sortBy == 'Recent' ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: _sortBy == 'Recent' ? Theme.of(context).primaryColor : (isDark ? Colors.white60 : Colors.black54),
                ),
                title: Text(
                  'Recent',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  setState(() => _sortBy = 'Recent');
                  Navigator.pop(context);
                  CustomNotification.show(
                    context,
                    message: 'Sorted by Recent',
                    icon: Icons.access_time,
                    color: const Color(0xFF4A9FBF),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _checkAndRequestPermission() async {
    try {
      // Check audio permission first
      final audioStatus = await Permission.audio.status;
      if (audioStatus.isGranted) {
        setState(() => _hasPermission = true);

        // Load songs with additional protection
        _loadSongsWithProtection();
        return;
      }

      // Use custom permission dialog for audio access
      if (!mounted) return;
      final granted = await PermissionDialog.requestAudioPermission(context);

      setState(() => _hasPermission = granted);

      if (granted) {
        // Load songs with protection
        _loadSongsWithProtection();
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      setState(() => _hasPermission = false);
    }
  }

  // Separate method to load songs with crash protection
  Future<void> _loadSongsWithProtection() async {
    try {
      // Use a future with timeout and error handling
      await audioController.loadSongs().timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          debugPrint('⏱️ Load songs timeout');
        },
      );
    } catch (e) {
      debugPrint('❌ Error loading songs with protection: $e');
      // Don't crash the app, just log the error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading songs. Please restart the app.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Container(
      color: isDark ? Colors.black : Colors.white,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Menu button (only show when using bottom nav)
                          Builder(
                            builder: (context) {
                              final themeProvider = Provider.of<ThemeProvider>(context);
                              final useBottomNav = themeProvider.useBottomNav;

                              if (!useBottomNav) {
                                return const SizedBox.shrink();
                              }

                              return IconButton(
                                onPressed: () {
                                  Scaffold.of(context).openDrawer();
                                },
                                icon: Icon(
                                  Icons.menu_rounded,
                                  color: Theme.of(context).primaryColor,
                                  size: 28,
                                ),
                              );
                            },
                          ),
                          Expanded(
                            child: !_isSearching
                                ? Column(
                                    children: [
                                      Text(
                                        'Local Songs',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ValueListenableBuilder(
                                        valueListenable: audioController.songs,
                                        builder: (context, songs, child) {
                                          return Text(
                                            '${songs.length} ${songs.length == 1 ? 'song' : 'songs'}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: isDark ? Colors.white60 : Colors.black54,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  )
                                : TextField(
                                    controller: _searchController,
                                    autofocus: true,
                                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                    decoration: InputDecoration(
                                      hintText: 'Search songs...',
                                      hintStyle: TextStyle(
                                        color: isDark ? Colors.white38 : Colors.black38,
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.white.withAlpha((0.05 * 255).round())
                                          : Colors.black.withAlpha((0.05 * 255).round()),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        _searchQuery = value;
                                      });
                                    },
                                  ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isSearching = !_isSearching;
                                    if (!_isSearching) {
                                      _searchQuery = '';
                                      _searchController.clear();
                                    }
                                  });
                                },
                                icon: Icon(
                                  _isSearching ? Icons.close_rounded : Icons.search_rounded,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                                tooltip: _isSearching ? 'Close Search' : 'Search',
                              ),
                              IconButton(
                                onPressed: _showSortMenu,
                                icon: Icon(
                                  Icons.sort_rounded,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                                tooltip: 'Sort',
                              ),
                              // Only show settings icon when bottom nav is ON (sidebar is hidden)
                              Builder(
                                builder: (context) {
                                  final themeProvider = Provider.of<ThemeProvider>(context);
                                  final useBottomNav = themeProvider.useBottomNav;

                                  if (!useBottomNav) {
                                    return const SizedBox.shrink();
                                  }

                                  return IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                                      );
                                    },
                                    icon: Icon(
                                      Icons.settings,
                                      color: Theme.of(context).primaryColor,
                                      size: 28,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: ValueListenableBuilder(
                    valueListenable: audioController.songs,
                    builder: (context, songs, child) {
                  if (!_hasPermission) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withAlpha((0.05 * 255).round())
                                    : Colors.black.withAlpha((0.05 * 255).round()),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.music_off_rounded,
                                size: 64,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Permission Required',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'We need access to your music files',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _checkAndRequestPermission,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text('Grant Permission'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (songs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withAlpha((0.05 * 255).round())
                                    : Colors.black.withAlpha((0.05 * 255).round()),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.music_note_rounded,
                                size: 64,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No Music Found',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No audio files found on your device',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white38 : Colors.black38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 60, 100),
                    itemCount: _getSortedSongs().length,
                    itemBuilder: (context, index) {
                      final sortedSongs = _getSortedSongs();
                      final song = sortedSongs[index];
                      final songs = audioController.songs.value;

                      return ListTile(
                        onTap: () async {
                          // Find the actual index in the full song list
                          final actualIndex = songs.indexWhere((s) => s.id == song.id);
                          if (actualIndex != -1) {
                            await audioController.playSong(actualIndex);
                          }
                        },
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withAlpha((0.2 * 255).round()),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: QueryArtworkWidget(
                              id: song.id,
                              type: ArtworkType.AUDIO,
                              artworkBorder: BorderRadius.circular(10),
                              nullArtworkWidget: Icon(
                                Icons.music_note_rounded,
                                color: Theme.of(context).primaryColor,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          song.title,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          song.artist,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                          onPressed: () {
                            final song = sortedSongs[index];
                            _showSongOptions(context, song);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ],
    ),
  ),
);
}

  void _showSongOptions(BuildContext context, dynamic song) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: QueryArtworkWidget(
                        id: song.id,
                        type: ArtworkType.AUDIO,
                        artworkWidth: 50,
                        artworkHeight: 50,
                        artworkFit: BoxFit.cover,
                        nullArtworkWidget: Container(
                          width: 50,
                          height: 50,
                          color: primaryColor.withAlpha((0.2 * 255).round()),
                          child: Icon(
                            Icons.music_note_rounded,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            song.artist,
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.playlist_add, color: primaryColor),
                title: Text(
                  'Add to Playlist',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(context);
                  PlaylistHelper.showAddToPlaylistDialog(context, song);
                },
              ),
              ListTile(
                leading: Icon(Icons.info_outline, color: primaryColor),
                title: Text(
                  'Song Info',
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSongInfo(context, song);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showSongInfo(BuildContext context, dynamic song) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final duration = Duration(milliseconds: song.duration);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1a1a2e) : Colors.white,
        title: Text(
          'Song Information',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Title', song.title, isDark),
            _infoRow('Artist', song.artist, isDark),
            _infoRow('Album', song.albumArt.isNotEmpty ? song.albumArt : 'Unknown', isDark),
            _infoRow('Duration', '$minutes:${seconds.toString().padLeft(2, '0')}', isDark),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

