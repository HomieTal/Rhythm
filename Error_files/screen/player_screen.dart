import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:provider/provider.dart';

import '../model/local_song_model.dart';
import '../service/audio_controller.dart';
import '../service/favorites_service.dart';
import '../settings/theme_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../screen/queue_page.dart';
import '../screen/playerhambergpage.dart';
import '../widgets/custom_notification.dart';
import '../model/lyrics_models.dart';
import '../songsrepo/Lyrics/lyrics.dart';

class PlayerScreen extends StatefulWidget {
  final LocalSongModel song;
  final int index;

  const PlayerScreen({super.key, required this.song, required this.index});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  final audioController = AudioController();
  final favoritesService = FavoritesService();
  bool _isPlaying = false;
  late LocalSongModel currentSong;

  // Lyrics state
  Lyrics? _currentLyrics;
  bool _isLoadingLyrics = false;
  bool _showLyrics = false;
  int _currentLyricIndex = 0;
  final ScrollController _lyricsScrollController = ScrollController();

  // Animation controller for swipe gesture
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  double _dragOffset = 0.0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    currentSong = widget.song;

    // Initialize animation controller with smoother duration
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Load songs if not already loaded
    if (audioController.songs.value.isEmpty) {
      audioController.loadSongs().then((_) {
        _initializePlayer();
      });
    } else {
      _initializePlayer();
    }

    audioController.isPlaying.addListener(_updatePlayingState);
    audioController.currentIndex.addListener(_updateCurrentSong);

    audioController.audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });

    // Fetch lyrics for the initial song
    _fetchLyrics();

    // Listen to position changes to update current lyric
    audioController.audioPlayer.positionStream.listen((position) {
      if (mounted && _currentLyrics?.parsedLyrics != null && _showLyrics) {
        _updateCurrentLyric(position);
      }
    });
  }

  void _initializePlayer() {
    if (!mounted) return;

    final index = audioController.songs.value.indexWhere(
          (s) => s.id == widget.song.id,
    );

    // Only play the song if it's found and not already playing
    if (index != -1 && audioController.currentIndex.value != index) {
      try {
        audioController.playSong(index);
      } catch (e) {
        debugPrint('Error playing song: $e');
      }
    } else if (index == -1) {
      debugPrint('Warning: Song not found in audioController songs list');
    }
  }

  void _updatePlayingState() {
    if (mounted) {
      setState(() {
        _isPlaying = audioController.isPlaying.value;
      });
    }
  }

  void _updateCurrentSong() {
    if (mounted && audioController.currentSong != null) {
      setState(() {
        currentSong = audioController.currentSong!;
      });
      // Fetch lyrics for the new song
      _fetchLyrics();
    }
  }

  // Fetch lyrics for the current song
  Future<void> _fetchLyrics() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLyrics = true;
      _currentLyrics = null;
      _currentLyricIndex = 0;
    });

    try {
      // Clean the song title - remove file path and extension
      String cleanTitle = currentSong.title;

      // Remove file path if present
      if (cleanTitle.contains('/')) {
        cleanTitle = cleanTitle.split('/').last;
      }
      if (cleanTitle.contains('\\')) {
        cleanTitle = cleanTitle.split('\\').last;
      }

      // Remove file extension
      cleanTitle = cleanTitle.replaceAll(RegExp(r'\.(mp3|m4a|flac|wav|aac|ogg|opus)$', caseSensitive: false), '');

      // Clean artist name
      String cleanArtist = currentSong.artist;
      if (cleanArtist == '<unknown>' || cleanArtist.toLowerCase() == 'unknown artist') {
        cleanArtist = '';
      }

      debugPrint('🎵 Fetching lyrics for: "$cleanTitle" by "$cleanArtist"');

      // Try with full metadata first
      Lyrics? lyrics;
      try {
        lyrics = await LyricsRepository.getLyrics(
          cleanTitle,
          cleanArtist,
          duration: Duration(milliseconds: currentSong.duration),
          provider: LyricsProvider.lrcnet,
        );
      } catch (e) {
        debugPrint('⚠️ First attempt failed: $e');

        // Try with just title if artist is empty
        if (cleanArtist.isEmpty) {
          try {
            debugPrint('🔄 Retrying with title only: "$cleanTitle"');
            final searchResults = await LyricsRepository.searchLyrics(
              cleanTitle,
              '',
              provider: LyricsProvider.lrcnet,
            );
            if (searchResults.isNotEmpty) {
              lyrics = searchResults.first;
            }
          } catch (e2) {
            debugPrint('⚠️ Second attempt failed: $e2');
          }
        } else {
          // Try searching with partial match
          try {
            debugPrint('🔄 Retrying with search: "$cleanTitle $cleanArtist"');
            final searchResults = await LyricsRepository.searchLyrics(
              cleanTitle,
              cleanArtist,
              provider: LyricsProvider.lrcnet,
            );
            if (searchResults.isNotEmpty) {
              lyrics = searchResults.first;
            }
          } catch (e2) {
            debugPrint('⚠️ Search attempt failed: $e2');
          }
        }
      }

      if (mounted) {
        if (lyrics != null) {
          setState(() {
            _currentLyrics = lyrics;
            _isLoadingLyrics = false;
          });
          debugPrint('✅ Lyrics loaded: ${lyrics.lyricsSynced != null ? "Synced" : "Plain text only"}');
          debugPrint('   Title: ${lyrics.title}');
          debugPrint('   Artist: ${lyrics.artist}');
        } else {
          setState(() {
            _isLoadingLyrics = false;
          });
          debugPrint('❌ No lyrics found for: "$cleanTitle" by "$cleanArtist"');
        }
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error fetching lyrics: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingLyrics = false;
        });
      }
    }
  }

  // Update current lyric index based on playback position
  void _updateCurrentLyric(Duration position) {
    if (_currentLyrics?.parsedLyrics == null) return;

    final lyrics = _currentLyrics!.parsedLyrics!.lyrics;
    if (lyrics.isEmpty) return;

    // Find the current lyric index
    int newIndex = 0;
    for (int i = 0; i < lyrics.length; i++) {
      if (position >= lyrics[i].start) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _currentLyricIndex) {
      setState(() {
        _currentLyricIndex = newIndex;
      });

      // Auto-scroll to current lyric
      if (_lyricsScrollController.hasClients && _showLyrics) {
        final double offset = (newIndex * 80.0) - 200; // Approximate height per lyric
        _lyricsScrollController.animateTo(
          offset.clamp(0.0, _lyricsScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _handleDragUpdate(DragUpdateDetails details, double width) {
    if (_isAnimating) return;

    setState(() {
      _dragOffset += details.delta.dx / (width * 0.8);
      _dragOffset = _dragOffset.clamp(-1.0, 1.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isAnimating) return;

    const swipeThreshold = 0.25;
    final velocity = details.primaryVelocity ?? 0;

    // Consider both drag distance and velocity
    if (_dragOffset > swipeThreshold || velocity > 500) {
      // Swipe right - previous song
      _animateAndChangeSong(true);
    } else if (_dragOffset < -swipeThreshold || velocity < -500) {
      // Swipe left - next song
      _animateAndChangeSong(false);
    } else {
      // Reset position with animation
      _resetPosition();
    }
  }

  void _resetPosition() {
    _slideAnimation = Tween<Offset>(
      begin: Offset(_dragOffset, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward(from: 0).then((_) {
      setState(() {
        _dragOffset = 0.0;
      });
      _animationController.reset();
    });
  }

  void _animateAndChangeSong(bool isPrevious) {
    _isAnimating = true;

    _slideAnimation = Tween<Offset>(
      begin: Offset(_dragOffset, 0),
      end: Offset(isPrevious ? 1.5 : -1.5, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0 - (_dragOffset.abs() * 0.1),
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    _opacityAnimation = Tween<double>(
      begin: 1.0 - (_dragOffset.abs() * 0.3),
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    _animationController.forward(from: 0).then((_) {
      if (isPrevious) {
        audioController.previousSong();
      } else {
        audioController.nextSong();
      }

      // Reset animation
      setState(() {
        _dragOffset = 0.0;
        _isAnimating = false;
      });
      _animationController.reset();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _lyricsScrollController.dispose();
    audioController.isPlaying.removeListener(_updatePlayingState);
    audioController.currentIndex.removeListener(_updateCurrentSong);
    super.dispose();
  }

  Widget _buildBlurredBackground() {
    final albumArt = currentSong.albumArt;

    Widget backgroundImage;
    if (albumArt.startsWith('http://') || albumArt.startsWith('https://')) {
      backgroundImage = Image.network(
        albumArt,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _defaultGradientBackground();
        },
      );
    } else if (albumArt.isNotEmpty && albumArt != 'null') {
      backgroundImage = QueryArtworkWidget(
        id: currentSong.id,
        type: ArtworkType.AUDIO,
        artworkBorder: BorderRadius.circular(0),
        artworkWidth: double.infinity,
        artworkHeight: double.infinity,
        artworkFit: BoxFit.cover,
        nullArtworkWidget: _defaultGradientBackground(),
      );
    } else {
      backgroundImage = _defaultGradientBackground();
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: backgroundImage,
      ),
    );
  }

  Widget _defaultGradientBackground() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final baseColor = themeProvider.dynamicColor;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor.withValues(alpha: 0.6),
            baseColor.withValues(alpha: 0.3),
            const Color(0xFF1a1a2e),
          ],
        ),
      ),
    );
  }

  Widget _buildAlbumArtwork() {
    final albumArt = currentSong.albumArt;

    if (albumArt.startsWith('http://') || albumArt.startsWith('https://')) {
      return Image.network(
        albumArt,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholderArtwork(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
              color: Colors.white,
            ),
          );
        },
      );
    } else if (albumArt.isNotEmpty && albumArt != 'null') {
      return QueryArtworkWidget(
        id: currentSong.id,
        type: ArtworkType.AUDIO,
        artworkBorder: BorderRadius.circular(20),
        nullArtworkWidget: _buildPlaceholderArtwork(),
      );
    } else {
      return _buildPlaceholderArtwork();
    }
  }

  Widget _buildPlaceholderArtwork() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final baseColor = themeProvider.dynamicColor;

    return Image.asset(
      'assets/images/app_icon.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              baseColor.withValues(alpha: 0.6),
              baseColor.withValues(alpha: 0.3),
              const Color(0xFF1a1a2e),
            ],
          ),
        ),
        child: Center(
          child: Icon(
            Icons.music_note_rounded,
            size: 80,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  void _openQueuePage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (_) => QueuePage(
        songs: audioController.currentSongList,
        currentIndex: audioController.currentIndex.value,
      ),
    );
  }

  Widget _buildLyricsView() {
    if (_currentLyrics == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'No lyrics available',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    // Check if we have synced lyrics
    if (_currentLyrics!.parsedLyrics != null &&
        _currentLyrics!.parsedLyrics!.lyrics.isNotEmpty) {
      return _buildSyncedLyrics();
    } else {
      return _buildPlainLyrics();
    }
  }

  Widget _buildSyncedLyrics() {
    final lyrics = _currentLyrics!.parsedLyrics!.lyrics;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.builder(
        controller: _lyricsScrollController,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        itemCount: lyrics.length,
        itemBuilder: (context, index) {
          final lyric = lyrics[index];
          final isCurrentLyric = index == _currentLyricIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isCurrentLyric
                    ? const Color(0xFFE91E63)
                    : Colors.white.withValues(alpha: isCurrentLyric ? 1.0 : 0.5),
                fontSize: isCurrentLyric ? 20 : 16,
                fontWeight: isCurrentLyric ? FontWeight.bold : FontWeight.normal,
                height: 1.5,
              ),
              child: Text(
                lyric.text,
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlainLyrics() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.black.withValues(alpha: 0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        controller: _lyricsScrollController,
        padding: const EdgeInsets.all(20),
        child: Text(
          _currentLyrics!.lyricsPlain,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.8,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: Stack(
        children: [
          // Blurred background
          Positioned.fill(child: _buildBlurredBackground()),

          // Dark overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header with back button, title, and menu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const Text(
                        "Today's top hits",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          showGeneralDialog(
                            context: context,
                            barrierDismissible: true,
                            barrierLabel: 'Dismiss',
                            barrierColor: Colors.black54,
                            transitionDuration: const Duration(milliseconds: 300),
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return Align(
                                alignment: Alignment.centerRight,
                                child: Material(
                                  color: Colors.transparent,
                                  child: PlayerHambergPage(song: currentSong),
                                ),
                              );
                            },
                            transitionBuilder: (context, animation, secondaryAnimation, child) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(1, 0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOut,
                                )),
                                child: child,
                              );
                            },
                          );
                        },
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Album Artwork with Swipe Gesture OR Lyrics View
                GestureDetector(
                  onHorizontalDragUpdate: (details) => _handleDragUpdate(details, size.width),
                  onHorizontalDragEnd: _handleDragEnd,
                  onTap: () {
                    // Toggle between album art and lyrics
                    if (_currentLyrics != null) {
                      setState(() {
                        _showLyrics = !_showLyrics;
                      });
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final offset = _animationController.isAnimating
                          ? _slideAnimation.value
                          : Offset(_dragOffset, 0);

                      final scale = _animationController.isAnimating
                          ? _scaleAnimation.value
                          : (1.0 - (offset.dx.abs() * 0.1)).clamp(0.85, 1.0);

                      final opacity = _animationController.isAnimating
                          ? _opacityAnimation.value
                          : (1.0 - (offset.dx.abs() * 0.3)).clamp(0.0, 1.0);

                      // Add subtle rotation for more dynamic feel
                      final rotation = offset.dx * 0.05;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..translate(offset.dx * size.width * 0.5, 0.0)
                          ..scale(scale)
                          ..rotateZ(rotation),
                        child: Opacity(
                          opacity: opacity.clamp(0.0, 1.0),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      height: size.width * 0.88,
                      width: size.width * 0.88,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 5,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Album Artwork
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedOpacity(
                              opacity: _showLyrics ? 0.0 : 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: _buildAlbumArtwork(),
                            ),
                          ),
                          // Lyrics View
                          if (_showLyrics)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: _buildLyricsView(),
                            ),
                          // Lyrics toggle icon
                          if (_currentLyrics != null && !_isLoadingLyrics)
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _showLyrics ? Icons.image : Icons.lyrics,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          // Loading indicator
                          if (_isLoadingLyrics)
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Song title and artist
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        currentSong.title.toString().split('/').last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              currentSong.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.verified,
                            color: Color(0xFFE91E63),
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: StreamBuilder<Duration>(
                    stream: audioController.audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration =
                          audioController.audioPlayer.duration ?? Duration.zero;
                      return ProgressBar(
                        progress: position,
                        total: duration,
                        progressBarColor: const Color(0xFFE91E63),
                        baseBarColor: Colors.white.withValues(alpha: 0.2),
                        bufferedBarColor: Colors.white.withValues(alpha: 0.3),
                        thumbColor: const Color(0xFFE91E63),
                        thumbRadius: 6,
                        barHeight: 3,
                        timeLabelTextStyle: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        onSeek: (duration) {
                          audioController.audioPlayer.seek(duration);
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // Share and favorite buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          // Share functionality
                        },
                        icon: const Icon(
                          Icons.ios_share_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      ValueListenableBuilder<List<LocalSongModel>>(
                        valueListenable: favoritesService.favorites,
                        builder: (context, favorites, _) {
                          final isFavorite = favoritesService.isFavorite(currentSong.id);
                          return IconButton(
                            onPressed: () async {
                              await favoritesService.toggleFavorite(currentSong);
                              if (mounted) {
                                CustomNotification.show(
                                  context,
                                  message: isFavorite
                                      ? 'Removed from favorites'
                                      : 'Added to favorites',
                                  icon: isFavorite
                                      ? Icons.favorite_border
                                      : Icons.favorite,
                                  color: Colors.purpleAccent,
                                  duration: const Duration(seconds: 1),
                                );
                              }
                            },
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.white,
                              size: 28,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Controls container with glassmorphism
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8), // Reduced from 16 to 10
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.withValues(alpha: 0.3)
                            : Colors.grey.shade800.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ValueListenableBuilder<bool>(
                            valueListenable: audioController.isShuffle,
                            builder: (context, shuffle, _) {
                              return IconButton(
                                onPressed: audioController.toggleShuffle,
                                padding: EdgeInsets.zero, // Remove extra padding
                                constraints: const BoxConstraints(), // Remove minimum size constraints
                                icon: Icon(
                                  Icons.shuffle_rounded,
                                  color: shuffle ? const Color(0xFFE91E63) : Colors.white70,
                                  size: 24, // Reduced from 26
                                ),
                              );
                            },
                          ),
                          IconButton(
                            onPressed: audioController.previousSong,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.skip_previous_rounded,
                              color: Colors.white,
                              size: 32, // Reduced from 36
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFE91E63),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: audioController.togglePlayPause,
                              icon: Icon(
                                _isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 32, // Reduced from 36
                              ),
                              padding: const EdgeInsets.all(12), // Reduced from 16
                            ),
                          ),
                          IconButton(
                            onPressed: audioController.nextSong,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.skip_next_rounded,
                              color: Colors.white,
                              size: 32, // Reduced from 36
                            ),
                          ),
                          ValueListenableBuilder<LoopMode>(
                            valueListenable: audioController.loopMode,
                            builder: (context, mode, _) {
                              IconData icon;
                              Color color;
                              switch (mode) {
                                case LoopMode.all:
                                  icon = Icons.repeat_rounded;
                                  color = const Color(0xFFE91E63);
                                  break;
                                case LoopMode.one:
                                  icon = Icons.repeat_one_rounded;
                                  color = const Color(0xFFE91E63);
                                  break;
                                case LoopMode.off:
                                  icon = Icons.repeat_rounded;
                                  color = Colors.white70;
                              }
                              return IconButton(
                                onPressed: audioController.toggleRepeat,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(icon, color: color, size: 24), // Reduced from 26
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                const SizedBox(height: 12),

                // Queue button - FULL WIDTH, NO HORIZONTAL MARGIN
                GestureDetector(
                  onTap: _openQueuePage,
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
                      _openQueuePage();
                    }
                  },
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        width: double.infinity, // Full width
                        padding: const EdgeInsets.only(top: 12, bottom: 30), // Reduced top padding from 16 to 12
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.withValues(alpha: 0.3)
                              : Colors.grey.shade800.withValues(alpha: 0.85),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Drag handle
                            Container(
                              width: 50,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 8), // Reduced from 12
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}