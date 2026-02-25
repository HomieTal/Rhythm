import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rhythm/services/audio_controller.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rhythm/widgets/custom_notification.dart';
import 'package:rhythm/widgets/permission_dialog.dart';
import 'package:rhythm/settings/settings_page.dart';
import 'package:rhythm/settings/theme_provider.dart';
import 'package:rhythm/utils/page_transitions.dart';

class SongsLocalScreen extends StatefulWidget {
  const SongsLocalScreen({super.key});

  @override
  State<SongsLocalScreen> createState() => _SongsLocalScreenState();
}

class _SongsLocalScreenState extends State<SongsLocalScreen> {
  final audioController = AudioController();
  bool _hasPermission = false;
  String _sortBy = 'A-Z';
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

    if (_searchQuery.isNotEmpty) {
      songs = songs.where((song) =>
        song.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        song.artist.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    switch (_sortBy) {
      case 'A-Z':
        songs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case 'Z-A':
        songs.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case 'Most songs':
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
                title: Text('A-Z', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  setState(() => _sortBy = 'A-Z');
                  Navigator.pop(context);
                  CustomNotification.show(context, message: 'Sorted A-Z', icon: Icons.sort_by_alpha, color: const Color(0xFF4A9FBF));
                },
              ),
              ListTile(
                leading: Icon(
                  _sortBy == 'Z-A' ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: _sortBy == 'Z-A' ? Theme.of(context).primaryColor : (isDark ? Colors.white60 : Colors.black54),
                ),
                title: Text('Z-A', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  setState(() => _sortBy = 'Z-A');
                  Navigator.pop(context);
                  CustomNotification.show(context, message: 'Sorted Z-A', icon: Icons.sort_by_alpha, color: const Color(0xFF4A9FBF));
                },
              ),
              ListTile(
                leading: Icon(
                  _sortBy == 'Recent' ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: _sortBy == 'Recent' ? Theme.of(context).primaryColor : (isDark ? Colors.white60 : Colors.black54),
                ),
                title: Text('Recent', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                onTap: () {
                  setState(() => _sortBy = 'Recent');
                  Navigator.pop(context);
                  CustomNotification.show(context, message: 'Sorted by Recent', icon: Icons.access_time, color: const Color(0xFF4A9FBF));
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
      final audioStatus = await Permission.audio.status;
      if (audioStatus.isGranted) {
        setState(() => _hasPermission = true);
        _loadSongsWithProtection();
        return;
      }

      if (!mounted) return;
      final granted = await PermissionDialog.requestAudioPermission(context);

      setState(() => _hasPermission = granted);

      if (granted) {
        _loadSongsWithProtection();
      }
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      setState(() => _hasPermission = false);
    }
  }

  Future<void> _loadSongsWithProtection() async {
    try {
      await audioController.loadSongs().timeout(
        const Duration(seconds: 45),
        onTimeout: () {
          debugPrint('⏱️ Load songs timeout');
        },
      );
    } catch (e) {
      debugPrint('❌ Error loading songs with protection: $e');
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
        child: Column(
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
                                  hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                                  filled: true,
                                  fillColor: isDark ? Colors.white.withAlpha((0.05 * 255).round()) : Colors.black.withAlpha((0.05 * 255).round()),
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
                          ),
                          IconButton(
                            onPressed: _showSortMenu,
                            icon: Icon(
                              Icons.sort_rounded,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              final themeProvider = Provider.of<ThemeProvider>(context);
                              final useBottomNav = themeProvider.useBottomNav;

                              if (!useBottomNav) {
                                return const SizedBox.shrink();
                              }

                              return IconButton(
                                onPressed: () {
                                  context.pushWithFadeSlide(const SettingsPage());
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
                    return _buildPermissionRequired(isDark);
                  }

                  if (songs.isEmpty) {
                    return _buildNoMusicFound(isDark);
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: _getSortedSongs().length,
                    itemBuilder: (context, index) {
                      final sortedSongs = _getSortedSongs();
                      final song = sortedSongs[index];
                      final allSongs = audioController.songs.value;

                      return ListTile(
                        onTap: () async {
                          final actualIndex = allSongs.indexWhere((s) => s.id == song.id);
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
                          onPressed: () {},
                        ),
                      );
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

  Widget _buildPermissionRequired(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha((0.05 * 255).round()) : Colors.black.withAlpha((0.05 * 255).round()),
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
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.black38),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _checkAndRequestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoMusicFound(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withAlpha((0.05 * 255).round()) : Colors.black.withAlpha((0.05 * 255).round()),
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
              style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.black38),
            ),
          ],
        ),
      ),
    );
  }
}

