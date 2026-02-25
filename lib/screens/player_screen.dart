import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/model/local_song_model.dart';
import 'package:rhythm/services/audio_controller.dart';
import 'package:rhythm/settings/theme_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rhythm/screens/player_hamberg_page.dart';
import 'package:rhythm/model/lyrics_models.dart';
import 'package:rhythm/songsrepo/Lyrics/lyrics.dart';

class PlayerScreen extends StatefulWidget {
  final LocalSongModel song;
  final int index;

  const PlayerScreen({super.key, required this.song, required this.index});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final audioController = AudioController();
  late LocalSongModel currentSong;

  // Lyrics state
  Lyrics? _currentLyrics;
  bool _isLoadingLyrics = false;
  bool _showLyrics = false;
  int _currentLyricIndex = 0;
  final ScrollController _lyricsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    currentSong = widget.song;

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
          // State updates handled by StreamBuilder
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

    if (index != -1 && audioController.currentIndex.value != index) {
      try {
        audioController.playSong(index);
      } catch (e) {
        debugPrint('Error playing song: $e');
      }
    }
  }

  void _updatePlayingState() {
    if (mounted) {
      setState(() {
        // State updates handled by StreamBuilder
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
      }

      if (mounted) {
        if (lyrics != null && lyrics.lyricsPlain.isNotEmpty) {
          setState(() {
            _currentLyrics = lyrics;
            _isLoadingLyrics = false;
          });
          debugPrint('✅ Lyrics loaded: ${lyrics.lyricsSynced != null ? "Synced" : "Plain text only"}');
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
      if (_lyricsScrollController.hasClients) {
        final itemHeight = 60.0;
        final offset = newIndex * itemHeight - (MediaQuery.of(context).size.height / 2 - itemHeight);
        _lyricsScrollController.animateTo(
          offset.clamp(0.0, _lyricsScrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
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
  void dispose() {
    audioController.isPlaying.removeListener(_updatePlayingState);
    audioController.currentIndex.removeListener(_updateCurrentSong);
    _lyricsScrollController.dispose();
    super.dispose();
  }

  Widget _buildBlurredBackground() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final baseColor = themeProvider.dynamicColor;
    final albumArt = currentSong.albumArt;

    Widget backgroundImage;
    if (albumArt.startsWith('http://') || albumArt.startsWith('https://')) {
      backgroundImage = Image.network(
        albumArt,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _defaultGradientBackground(baseColor);
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
        nullArtworkWidget: _defaultGradientBackground(baseColor),
      );
    } else {
      backgroundImage = _defaultGradientBackground(baseColor);
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: backgroundImage,
      ),
    );
  }

  Widget _defaultGradientBackground(Color baseColor) {
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
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderArtwork(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryColor = themeProvider.dynamicColor;

    return Scaffold(
      body: Stack(
        children: [
          // Blurred background
          _buildBlurredBackground(),

          // Dark overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Column(
                        children: [
                          const Text(
                            'NOW PLAYING',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentSong.artist,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 28),
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
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Album artwork with lyrics toggle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GestureDetector(
                      onTap: () {
                        // Toggle between album art and lyrics
                        if (_currentLyrics != null) {
                          setState(() {
                            _showLyrics = !_showLyrics;
                          });
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
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
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Song info
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      Text(
                        currentSong.title.split('/').last,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentSong.artist,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: StreamBuilder<Duration?>(
                    stream: audioController.audioPlayer.positionStream,
                    builder: (context, snapshot) {
                      final position = snapshot.data ?? Duration.zero;
                      final duration = Duration(milliseconds: currentSong.duration);

                      return ProgressBar(
                        progress: position,
                        total: duration.inMilliseconds > 0 ? duration : const Duration(minutes: 3),
                        onSeek: (duration) {
                          audioController.audioPlayer.seek(duration);
                        },
                        baseBarColor: Colors.white.withValues(alpha: 0.2),
                        progressBarColor: primaryColor,
                        thumbColor: primaryColor,
                        thumbRadius: 8,
                        timeLabelTextStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Control buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Shuffle
                      ValueListenableBuilder<bool>(
                        valueListenable: audioController.isShuffle,
                        builder: (context, isShuffle, _) {
                          return IconButton(
                            icon: Icon(
                              Icons.shuffle_rounded,
                              color: isShuffle ? primaryColor : Colors.white70,
                              size: 28,
                            ),
                            onPressed: audioController.toggleShuffle,
                          );
                        },
                      ),

                      // Previous
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 40),
                        onPressed: audioController.previousSong,
                      ),

                      // Play/Pause
                      StreamBuilder<PlayerState>(
                        stream: audioController.audioPlayer.playerStateStream,
                        builder: (context, snapshot) {
                          final playerState = snapshot.data;
                          final processingState = playerState?.processingState;
                          final playing = playerState?.playing;

                          if (processingState == ProcessingState.loading ||
                              processingState == ProcessingState.buffering) {
                            return Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  strokeWidth: 3,
                                ),
                              ),
                            );
                          }

                          return GestureDetector(
                            onTap: audioController.togglePlayPause,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Icon(
                                playing == true ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          );
                        },
                      ),

                      // Next
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 40),
                        onPressed: audioController.nextSong,
                      ),

                      // Repeat
                      ValueListenableBuilder<LoopMode>(
                        valueListenable: audioController.loopMode,
                        builder: (context, loopMode, _) {
                          IconData icon;
                          Color color;

                          switch (loopMode) {
                            case LoopMode.off:
                              icon = Icons.repeat_rounded;
                              color = Colors.white70;
                              break;
                            case LoopMode.one:
                              icon = Icons.repeat_one_rounded;
                              color = primaryColor;
                              break;
                            case LoopMode.all:
                              icon = Icons.repeat_rounded;
                              color = primaryColor;
                              break;
                          }

                          return IconButton(
                            icon: Icon(icon, color: color, size: 28),
                            onPressed: audioController.toggleRepeat,
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

