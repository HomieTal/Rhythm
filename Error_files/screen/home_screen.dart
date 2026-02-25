import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Rhythm/utils/platform_utils.dart';
import 'package:Rhythm/screen/local_song_screen.dart';
import 'package:Rhythm/screen/search_page.dart';
import 'package:Rhythm/screen/library_page.dart';
import 'package:Rhythm/screen/playlists_page.dart';
import 'package:Rhythm/screen/artists_page.dart';
import 'package:Rhythm/screen/albums_page.dart';
import '/settings/settings_page.dart';
import '/settings/theme_provider.dart';
import 'package:Rhythm/screen/player_screen.dart';
import 'package:Rhythm/songsrepo/Saavn/saavn_api.dart';
import 'package:Rhythm/service/audio_controller.dart';
import 'package:Rhythm/model/local_song_model.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'dart:ui';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/custom_notification.dart';
import '../widgets/hamburger_menu.dart';
import '../widgets/app_sidebar.dart';
import '../widgets/permission_dialog.dart';
import '../widgets/rhythm_dialog.dart';
import '../service/update_service.dart';
import '../service/recently_played_service.dart';
import '../service/sleep_timer_service.dart';
import '../screen/sleep_timer_page.dart';
import 'dart:async';

class RhythmHome extends StatefulWidget {
  const RhythmHome({super.key});

  @override
  State<RhythmHome> createState() => _RhythmHomeState();
}

class _RhythmHomeState extends State<RhythmHome> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final GlobalKey<_HomePageState> _homePageKey = GlobalKey<_HomePageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();

    // Initialize pages list first to prevent null errors
    _pages = [
      HomePage(key: _homePageKey),      // 0: Quick picks
      const SearchPage(),                 // 1: Discover
      const LibraryPage(),                // 2: Library
      const PlaylistsPage(),              // 3: Playlists
      const ArtistsPage(),                // 4: Artists
      const AlbumsPage(),                 // 5: Albums
      const SongsLocalScreen(),           // 6: Local
      const SleepTimerPage(),             // 7: Sleep Timer
    ];

    try {
      WidgetsBinding.instance.addObserver(this);

      // Request permissions after frame is rendered
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _requestAllPermissions();
          _checkForUpdates();
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Error in home screen initState: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _loadSongsInBackground() async {
    try {
      debugPrint('🎵 Loading songs in AudioController from home screen...');
      final audioController = AudioController.instance;

      // Load songs in background if not already loaded
      if (audioController.songs.value.isEmpty) {
        audioController.loadSongs().then((_) {
          debugPrint('✅ Songs loaded in AudioController: ${audioController.songs.value.length} tracks');
        }).catchError((e) {
          debugPrint('⚠️ Error loading songs: $e');
        });
      } else {
        debugPrint('✅ Songs already loaded: ${audioController.songs.value.length} tracks');
      }
    } catch (e) {
      debugPrint('⚠️ Error in _loadSongsInBackground: $e');
    }
  }

  Future<void> _requestAllPermissions() async {
    try {
      // Wait a moment for UI to be ready
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Check if audio permission is already granted
      final audioStatus = await Permission.audio.status;

      if (!audioStatus.isGranted) {
        // Don't request permission here - let local song screen handle it
        debugPrint('⚠️ Audio permission not granted - will be requested when accessing local songs');
      } else {
        // Audio already granted, load songs
        _loadSongsInBackground();
      }
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      // Wait a bit for the app to fully load
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final shouldCheck = await UpdateService.shouldShowUpdateDialog();
      if (!shouldCheck || !mounted) return;

      final updateInfo = await UpdateService.checkForUpdate();

      if (updateInfo['needsUpdate'] == true && mounted) {
        showDialog(
          context: context,
          barrierDismissible: !updateInfo['forceUpdate'],
          builder: (context) => UpdateDialog(
            currentVersion: updateInfo['currentVersion'],
            latestVersion: updateInfo['latestVersion'],
            forceUpdate: updateInfo['forceUpdate'],
            updateUrl: updateInfo['updateUrl'],
            releaseNotes: updateInfo['releaseNotes'] ?? '',
            releaseName: updateInfo['releaseName'] ?? 'New Version Available',
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      // Don't show error to user, just log it
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Don't stop audio here - let the audio service handle background playback
    // The audio service will continue playing even when the app is closed
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('🔄 App lifecycle state changed to: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground - refresh home page
        debugPrint('✅ App resumed - refreshing data');
        _homePageKey.currentState?.refreshAllSongs();
        break;

      case AppLifecycleState.paused:
        // App is in background - audio service will continue playing
        debugPrint('⏸️ App paused - audio continues in background');
        break;

      case AppLifecycleState.inactive:
        // App is inactive (e.g., during a phone call) - keep playing
        debugPrint('⏸️ App inactive - audio continues');
        break;

      case AppLifecycleState.detached:
        // App is detached (swiped away) - audio service continues playing in background
        debugPrint('🎵 App detached - audio service continues in background');
        // Don't stop the audio player here - the audio service handles background playback
        break;

      case AppLifecycleState.hidden:
        // App is hidden but still running
        debugPrint('🙈 App hidden - audio continues');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final useBottomNav = themeProvider.useBottomNav;
    final audioController = AudioController.instance;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Move app to background instead of closing
        await PlatformUtils.moveToBackground();
      },
      child: Scaffold(
        extendBody: true,
        drawer: useBottomNav ? const HamburgerMenu() : null,
        body: !useBottomNav
            ? Stack(
                children: [
                  Row(
                    children: [
                      AppSidebar(onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      }),
                      Expanded(child: _pages[_currentIndex]),
                    ],
                  ),
                  // Add mini player at bottom when sidebar is enabled
                  Positioned(
                    bottom: 0,
                    left: 80, // Account for sidebar width
                    right: 0,
                    child: ValueListenableBuilder(
                      valueListenable: audioController.currentIndex,
                      builder: (context, currentIndex, _) {
                        final currentSong = audioController.currentSong;
                        if (currentSong == null) return const SizedBox.shrink();

                        return _buildSidebarMiniPlayer(context, currentSong, audioController, isDark, primaryColor);
                      },
                    ),
                  ),
                ],
              )
            : _pages[_currentIndex],
        bottomNavigationBar: useBottomNav ? _buildCombinedBottomBar(context, primaryColor, isDark) : null,
      ),
    );
  }

  Widget _buildCombinedBottomBar(BuildContext context, Color primaryColor, bool isDark) {
    final audioController = AudioController.instance;

    // Listen to both currentIndex AND songs changes to ensure sync
    return ValueListenableBuilder(
      valueListenable: audioController.currentIndex,
      builder: (context, currentIndex, _) {
        return ValueListenableBuilder(
          valueListenable: audioController.songs,
          builder: (context, songs, _) {
            return ValueListenableBuilder(
              valueListenable: audioController.currentPlaylist,
              builder: (context, playlist, _) {
                final currentSong = audioController.currentSong;
                final hasActiveSong = currentSong != null;

                return Container(
                  margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade900.withAlpha((0.4 * 255).round())
                              : Colors.grey.shade300.withAlpha((0.6 * 255).round()),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withAlpha((0.15 * 255).round())
                                : Colors.white.withAlpha((0.5 * 255).round()),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha((0.2 * 255).round()),
                              blurRadius: 40,
                              spreadRadius: 0,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Bottom Player Section (shown when song is playing)
                            if (hasActiveSong) ...[
                              _buildMiniPlayer(context, currentSong, audioController, isDark, primaryColor),
                              // Divider between player and navigation
                              Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                color: Colors.white.withAlpha((0.15 * 255).round()),
                              ),
                              const SizedBox(height: 8),
                            ],

                            // Navigation Bar
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: hasActiveSong
                                    ? const BorderRadius.only(
                                        bottomLeft: Radius.circular(30),
                                        bottomRight: Radius.circular(30),
                                      )
                                    : BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildNavItem(Icons.home_rounded, 'Home', 0, primaryColor),
                                  _buildNavItem(Icons.search_rounded, 'Search', 1, primaryColor),
                                  _buildNavItem(Icons.library_music_rounded, 'Library', 2, primaryColor),
                                  _buildNavItem(Icons.music_note_rounded, 'Songs', 6, primaryColor),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, Color primaryColor) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Icon(
            icon,
            size: 32,
            color: isSelected ? primaryColor : Colors.white.withAlpha((0.6 * 255).round()),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(BuildContext context, dynamic currentSong, AudioController audioController, bool isDark, Color primaryColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              song: currentSong,
              index: audioController.currentIndex.value,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Row(
          children: [
            // Album artwork
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildAlbumArt(currentSong, isDark),
            ),
            const SizedBox(width: 12),

            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentSong.title.split('/').last,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentSong.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withAlpha((0.75 * 255).round()),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Control buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Previous button
                IconButton(
                  onPressed: audioController.previousSong,
                  icon: Icon(
                    Icons.skip_previous_rounded,
                    color: primaryColor,
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),

                const SizedBox(width: 8),

                // Play/Pause button
                StreamBuilder<PlayerState>(
                  stream: audioController.audioPlayer.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final processingState = playerState?.processingState;
                    final playing = playerState?.playing;

                    if (processingState == ProcessingState.loading ||
                        processingState == ProcessingState.buffering) {
                      return SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          strokeWidth: 2,
                        ),
                      ); // <-- Correct closing parenthesis for SizedBox
                    }
                    return Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: audioController.togglePlayPause,
                        icon: Icon(
                          playing == true
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    );
                  },
                ),

                const SizedBox(width: 8),

                // Next button
                IconButton(
                  onPressed: audioController.nextSong,
                  icon: Icon(
                    Icons.skip_next_rounded,
                    color: primaryColor,
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarMiniPlayer(BuildContext context, dynamic currentSong, AudioController audioController, bool isDark, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withAlpha((0.9 * 255).round())
            : Colors.white.withAlpha((0.95 * 255).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withAlpha((0.1 * 255).round())
              : Colors.black.withAlpha((0.1 * 255).round()),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.3 * 255).round()),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    song: currentSong,
                    index: audioController.currentIndex.value,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withAlpha((0.6 * 255).round())
                    : Colors.white.withAlpha((0.95 * 255).round()),
              ),
              child: Row(
                children: [
                  // Album artwork
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildAlbumArt(currentSong, isDark),
                  ),
                  const SizedBox(width: 12),

                  // Song info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentSong.title.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentSong.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Playback controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Previous button
                      IconButton(
                        onPressed: audioController.previousSong,
                        icon: Icon(
                          Icons.skip_previous_rounded,
                          color: primaryColor,
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),

                      const SizedBox(width: 8),

                      // Play/Pause button
                      StreamBuilder<PlayerState>(
                        stream: audioController.audioPlayer.playerStateStream,
                        builder: (context, snapshot) {
                          final playerState = snapshot.data;
                          final processingState = playerState?.processingState;
                          final playing = playerState?.playing;

                          if (processingState == ProcessingState.loading ||
                              processingState == ProcessingState.buffering) {
                            return SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                strokeWidth: 2,
                              ),
                            );
                          }
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: audioController.togglePlayPause,
                              icon: Icon(
                                playing == true
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 8),

                      // Next button
                      IconButton(
                        onPressed: audioController.nextSong,
                        icon: Icon(
                          Icons.skip_next_rounded,
                          color: primaryColor,
                          size: 28,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build album art for both local and online songs
  Widget _buildAlbumArt(dynamic currentSong, bool isDark) {
    // Check if it's a local song (has uri starting with content://)
    final isLocalSong = currentSong.uri != null &&
                        currentSong.uri!.startsWith('content://');

    if (isLocalSong) {
      // Use QueryArtworkWidget for local songs
      return QueryArtworkWidget(
        id: currentSong.id,
        type: ArtworkType.AUDIO,
        artworkBorder: BorderRadius.circular(8),
        artworkWidth: 48,
        artworkHeight: 48,
        nullArtworkWidget: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.music_note,
            color: isDark ? Colors.white54 : Colors.black54,
            size: 24,
          ),
        ),
      );
    } else {
      // Use Image.network for online songs
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: currentSong.albumArt != null && currentSong.albumArt!.isNotEmpty
            ? Image.network(
                currentSong.albumArt!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.music_note,
                  color: isDark ? Colors.white54 : Colors.black54,
                  size: 24,
                ),
              )
            : Icon(
                Icons.music_note,
                color: isDark ? Colors.white54 : Colors.black54,
                size: 24,
              ),
      );
    }
  }
}

// ============================================================
// Home Page with Enhanced UI and Refresh Button
// ============================================================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SaavnAPI api = SaavnAPI();

  List recentListens = [];
  List topRecents = [];
  List mixSongs = [];
  bool loadingRecent = true;
  bool loadingTop = true;
  bool loadingMix = true;
  bool isRefreshing = false;

  // Greeting helper used in the header
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  // Format remaining duration for display in the top bar (e.g. 5:08 or 1h 05m)
  String _formatRemaining(Duration duration) {
    if (duration.inHours > 0) {
      final h = duration.inHours;
      final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
      return '${h}h ${m}m';
    }
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void fetchAllSongs() {
    fetchTopRecents();
    fetchRecentListens();
    fetchMixes();
  }

  // Public method to refresh all songs (called from parent)
  void refreshAllSongs() {
    if (!isRefreshing) {
      _handleRefresh();
    }
  }

  Future<void> _handleRefresh() async {
    if (isRefreshing) return;

    setState(() => isRefreshing = true);

    // Show refresh feedback
    if (mounted) {
      CustomNotification.show(
        context,
        message: 'Refreshing songs...',
        icon: Icons.refresh_rounded,
        color: Theme.of(context).primaryColor,
        duration: const Duration(seconds: 1),
      );
    }

    // Fetch all songs again
    await Future.wait([
      _fetchTopRecentsAsync(),
      _fetchRecentListensAsync(),
      _fetchMixesAsync(),
    ]);

    setState(() => isRefreshing = false);

    if (mounted) {
      CustomNotification.show(
        context,
        message: 'Songs refreshed successfully!',
        icon: Icons.check_circle_rounded,
        color: Colors.green,
        duration: const Duration(seconds: 2),
      );
    }
  }


  Future<void> _fetchTopRecentsAsync() async {
    setState(() => loadingTop = true);
    final result = await api.fetchSongSearchResults(searchQuery: "Top Hits");
    if (mounted) {
      setState(() {
        topRecents = result['songs'] ?? [];
        loadingTop = false;
      });
    }
  }

  Future<void> _fetchRecentListensAsync() async {
    setState(() => loadingRecent = true);
    final result = await api.fetchSongSearchResults(searchQuery: "Trending");
    if (mounted) {
      setState(() {
        recentListens = result['songs'] ?? [];
        loadingRecent = false;
      });
    }
  }

  Future<void> _fetchMixesAsync() async {
    setState(() => loadingMix = true);
    final result = await api.fetchSongSearchResults(searchQuery: "Deep House Mix");
    if (mounted) {
      setState(() {
        mixSongs = result['songs'] ?? [];
        loadingMix = false;
      });
    }
  }

  void fetchTopRecents() async {
    setState(() => loadingTop = true);
    final result = await api.fetchSongSearchResults(searchQuery: "Top Hits");
    setState(() {
      topRecents = result['songs'] ?? [];
      loadingTop = false;
    });
  }

  void fetchRecentListens() async {
    setState(() => loadingRecent = true);
    final result = await api.fetchSongSearchResults(searchQuery: "Trending");
    setState(() {
      recentListens = result['songs'] ?? [];
      loadingRecent = false;
    });
  }

  void fetchMixes() async {
    setState(() => loadingMix = true);
    final result = await api.fetchSongSearchResults(searchQuery: "Deep House Mix");
    setState(() {
      mixSongs = result['songs'] ?? [];
      loadingMix = false;
    });
  }

  String getDownloadUrl(dynamic song) {
    if (song['downloadUrl'] != null) {
      if (song['downloadUrl'] is List && (song['downloadUrl'] as List).isNotEmpty) {
        final downloads = song['downloadUrl'] as List;
        final lastItem = downloads.last;
        if (lastItem is Map && lastItem['url'] != null) {
          return lastItem['url'].toString();
        }
      } else if (song['downloadUrl'] is String) {
        return song['downloadUrl'].toString();
      }
    }
    if (song['url'] != null) return song['url'].toString();
    if (song['media_url'] != null) return song['media_url'].toString();
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;
    final backgroundColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: primaryColor,
        backgroundColor: backgroundColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===================== Top Bar =====================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Hamburger menu button (only show when using bottom nav)
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        final useBottomNav = themeProvider.useBottomNav;

                        if (!useBottomNav) {
                          return const SizedBox.shrink();
                        }

                        return IconButton(
                          icon: Icon(Icons.menu_rounded,
                              color: primaryColor, size: 28),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                        );
                      },
                    ),
                    Text(
                      'Rhythm',
                      style: TextStyle(
                        fontFamily: 'Cursive',
                        fontSize: 34,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        letterSpacing: 1,
                      ),
                    ),
                    Row(
                      children: [
                        // Covered pill showing the sleep-timer remaining (when active)
                        ValueListenableBuilder<bool>(
                          valueListenable: SleepTimerService.instance.isActive,
                          builder: (context, isActive, _) {
                            if (!isActive) return const SizedBox.shrink();
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SleepTimerPage()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white12 : Colors.black12,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.bedtime_rounded, color: Colors.amber, size: 18),
                                    const SizedBox(width: 8),
                                    ValueListenableBuilder<Duration>(
                                      valueListenable: SleepTimerService.instance.remaining,
                                      builder: (context, remaining, _) {
                                        return Text(
                                          _formatRemaining(remaining),
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.settings, color: primaryColor, size: 28),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SettingsPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ===================== Greeting Header =====================
                Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 24),

                // ===================== Quick Picks Section =====================
                Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Quick picks',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildQuickPicksList(),
                const SizedBox(height: 32),

                // ===================== Mixes Section =====================
                Row(
                  children: [
                    Icon(Icons.grid_view_rounded, color: subtitleColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Mixes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildMixCards(),
                const SizedBox(height: 32),

                // ===================== Recent Listens =====================
                _buildSectionHeader(
                  icon: Icons.history_rounded,
                  title: 'Recent Listens',
                  onViewAll: () {},
                ),
                const SizedBox(height: 12),
                _buildHorizontalSongList(recentListens, loadingRecent),
                const SizedBox(height: 32),

                // ===================== Top Recents =====================
                _buildSectionHeader(
                  icon: Icons.trending_up_rounded,
                  title: 'Top Recents',
                  onViewAll: () {},
                ),
                const SizedBox(height: 12),
                _buildHorizontalSongList(topRecents, loadingTop),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required VoidCallback onViewAll,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? Colors.grey.shade300 : Colors.grey.shade700;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: subtitleColor, size: 22),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: subtitleColor,
              ),
            ),
          ],
        ),
        IconButton(
          icon: Icon(Icons.arrow_forward_ios,
              color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              size: 18),
          onPressed: onViewAll,
        ),
      ],
    );
  }

  Widget _buildMixCards() {
    final primaryColor = Theme.of(context).primaryColor;

    if (loadingMix) {
      return SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    if (mixSongs.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No mixes available', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: mixSongs.length.clamp(0, 4),
        itemBuilder: (context, index) {
          final song = mixSongs[index];
          final title = song['title'] ?? 'Unknown Mix';
          final subtitle = song['primaryArtists'] ?? '';
          final imageUrl = song['image'] ?? '';

          return GestureDetector(
            onTap: () => _playSong(song, fromSection: mixSongs),
            child: Container(
              width: 280,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.purple.withAlpha((0.3 * 255).round()),
                    Colors.blue.withAlpha((0.2 * 255).round()),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      height: 200,
                      width: 280,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      color: Colors.grey.shade800,
                      child: const Center(
                        child: Icon(Icons.music_note, color: Colors.white, size: 48),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha((0.7 * 255).round()),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade300,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha((0.5 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.play_circle_filled, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${(index + 1) * 12}',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalSongList(List songs, bool loading) {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    if (loading) {
      return SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    if (songs.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('No songs found', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        itemBuilder: (context, index) {
          final song = songs[index];
          final title = song['title'] ?? 'Unknown';
          final artist = song['primaryArtists'] ?? 'Unknown Artist';
          final imageUrl = song['image'] ?? '';

          return GestureDetector(
            onTap: () => _playSong(song, fromSection: songs),
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                      imageUrl,
                      height: 150,
                      width: 150,
                      fit: BoxFit.cover,
                    )
                        : Container(
                      height: 150,
                      width: 150,
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                      child: Icon(Icons.music_note,
                          color: isDark ? Colors.white : Colors.black54,
                          size: 40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickPicksList() {
    final primaryColor = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return ValueListenableBuilder(
      valueListenable: RecentlyPlayedService().recentlyPlayed,
      builder: (context, recentlyPlayed, _) {
        if (recentlyPlayed.isEmpty) {
          return const SizedBox(
            height: 80,
            child: Center(
              child: Text('No recently played songs', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentlyPlayed.length,
            itemBuilder: (context, index) {
              final song = recentlyPlayed[index];

              return GestureDetector(
                onTap: () async {
                  final audioCtrl = AudioController.instance;
                  final songIndex = audioCtrl.songs.value.indexWhere((s) => s.id == song.id);

                  if (songIndex != -1) {
                    await audioCtrl.playSong(songIndex);
                    if (mounted) {
                      CustomNotification.show(
                        context,
                        message: 'Now playing: [1m${song.title}[0m',
                        icon: Icons.play_circle_filled_rounded,
                        color: primaryColor,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  } else {
                    // Song not found, add to AudioController and play
                    final updated = List<LocalSongModel>.from(audioCtrl.songs.value)..add(song);
                    audioCtrl.songs.value = updated;
                    final newIndex = updated.length - 1;
                    await audioCtrl.playSong(newIndex);
                    if (mounted) {
                      CustomNotification.show(
                        context,
                        message: 'Added to library & playing: [1m${song.title}[0m',
                        icon: Icons.library_add_rounded,
                        color: primaryColor,
                        duration: const Duration(seconds: 2),
                      );
                    }
                  }
                },
                child: Container(
                  width: 320,
                  margin: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      // Album artwork
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: QueryArtworkWidget(
                          id: song.id,
                          type: ArtworkType.AUDIO,
                          artworkBorder: BorderRadius.circular(8),
                          artworkWidth: 64,
                          artworkHeight: 64,
                          nullArtworkWidget: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: primaryColor.withAlpha((0.2 * 255).round()),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.music_note,
                              color: primaryColor,
                              size: 32,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Song info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              song.title,
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
                                color: subtitleColor,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Play icon indicator
                      Icon(
                        Icons.play_circle_filled,
                        color: primaryColor,
                        size: 32,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _playSong(dynamic song, {List<dynamic>? fromSection}) async {
    final title = song['title'] ?? 'Unknown';
    final artist = song['primaryArtists'] ?? 'Unknown Artist';
    final imageUrl = song['image'] ?? '';
    final url = getDownloadUrl(song);

    if (url.isEmpty) {
      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Unable to play song: Invalid URL',
          icon: Icons.error_outline_rounded,
          color: Colors.red,
          duration: const Duration(seconds: 2),
        );
      }
      return;
    }

    try {
      final audioCtrl = AudioController.instance;
      final int baseId = DateTime.now().millisecondsSinceEpoch;

      // If we have a section (list of songs), create a playlist
      if (fromSection != null && fromSection.isNotEmpty) {
        final playlist = <LocalSongModel>[];

        for (int i = 0; i < fromSection.length; i++) {
          var s = fromSection[i];
          final songUrl = getDownloadUrl(s);
          if (songUrl.isNotEmpty) {
            final songTitle = s['title'] ?? 'Unknown';
            final songArtist = s['primaryArtists'] ?? 'Unknown Artist';
            final songImage = s['image'] ?? '';

            playlist.add(LocalSongModel(
              id: -(baseId + i),
              title: songTitle,
              artist: songArtist,
              uri: songUrl,
              albumArt: songImage,
              duration: 0,
            ));
          }
        }

        debugPrint('📋 Created home playlist with ${playlist.length} songs');

        // Find the current song in the playlist by URI
        final currentSongInPlaylist = playlist.firstWhere(
          (s) => s.uri == url,
          orElse: () => LocalSongModel(
            id: -baseId,
            title: title,
            artist: artist,
            uri: url,
            albumArt: imageUrl,
            duration: 0,
          ),
        );

        // Play from playlist
        final bool ok = await audioCtrl.playFromPlaylist(currentSongInPlaylist, playlist: playlist);

        if (!ok) {
          if (mounted) {
            CustomNotification.show(
              context,
              message: 'Playback failed',
              icon: Icons.error_outline_rounded,
              color: Colors.red,
              duration: const Duration(seconds: 2),
            );
          }
        } else {
          if (mounted) {
            CustomNotification.show(
              context,
              message: 'Now playing: $title',
              icon: Icons.play_circle_filled_rounded,
              color: Theme.of(context).primaryColor,
              duration: const Duration(seconds: 2),
            );
          }
        }
      } else {
        // Fallback to old behavior if no section provided
        final LocalSongModel currentSong = LocalSongModel(
          id: -baseId,
          title: title,
          artist: artist,
          uri: url,
          albumArt: imageUrl,
          duration: 0,
        );

        final existing = audioCtrl.songs.value;
        int existingIndex = -1;

        for (int i = 0; i < existing.length; i++) {
          if (existing[i].uri == url) {
            existingIndex = i;
            break;
          }
        }

        if (existingIndex != -1) {
          await audioCtrl.playSong(existingIndex);
          if (mounted) {
            CustomNotification.show(
              context,
              message: 'Now playing: $title',
              icon: Icons.play_circle_filled_rounded,
              color: Theme.of(context).primaryColor,
              duration: const Duration(seconds: 2),
            );
          }
        } else {
          final updated = List<LocalSongModel>.from(existing)..add(currentSong);
          audioCtrl.songs.value = updated;
          final newIndex = updated.length - 1;
          await audioCtrl.playSong(newIndex);

          if (mounted) {
            CustomNotification.show(
              context,
              message: 'Added to library: $title',
              icon: Icons.library_add_rounded,
              color: Theme.of(context).primaryColor,
              duration: const Duration(seconds: 2),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error playing song: $e');
      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Error playing song',
          icon: Icons.error_outline_rounded,
          color: Colors.red,
          duration: const Duration(seconds: 2),
        );
      }
    }
  }
}

