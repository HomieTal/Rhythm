import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:audio_service/audio_service.dart';
import 'dart:math';
import 'dart:async';
import 'package:rhythm/services/platform_equalizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rhythm/model/local_song_model.dart';
import 'package:rhythm/utils/safe_audio_query.dart';
import 'package:rhythm/services/audio_handler.dart';
import 'package:rhythm/services/cache_service.dart';
import 'package:rhythm/services/recently_played_service.dart';

class AudioController {
  static final AudioController instance = AudioController._internal();
  factory AudioController() => instance;
  AudioController._internal() {
    _fallbackPlayer = AudioPlayer();
    _initializeAudioService();
  }

  RhythmAudioHandler? _audioHandler;
  late final AudioPlayer _fallbackPlayer;
  AudioPlayer get audioPlayer => _audioHandler?.player ?? _fallbackPlayer;
  bool _isInitialized = false;
  final CacheService _cacheService = CacheService();
  final OnAudioQuery audioQuery = OnAudioQuery();

  final ValueNotifier<List<LocalSongModel>> songs = ValueNotifier([]);
  final ValueNotifier<int> currentIndex = ValueNotifier(-1);
  final ValueNotifier<bool> isPlaying = ValueNotifier(false);

  // Playlist/Queue Management
  final ValueNotifier<List<LocalSongModel>> currentPlaylist = ValueNotifier([]);
  bool _isPlayingFromPlaylist = false;

  // Shuffle and Repeat States
  final ValueNotifier<bool> isShuffle = ValueNotifier(false);
  final ValueNotifier<LoopMode> loopMode = ValueNotifier(LoopMode.off);

  LocalSongModel? get currentSong =>
      _isPlayingFromPlaylist && currentIndex.value != -1 && currentIndex.value < currentPlaylist.value.length
          ? currentPlaylist.value[currentIndex.value]
          : (currentIndex.value != -1 && currentIndex.value < songs.value.length
              ? songs.value[currentIndex.value]
              : null);

  // Helper to get the current active song list
  List<LocalSongModel> get currentSongList =>
      _isPlayingFromPlaylist ? currentPlaylist.value : songs.value;

  // Helper to check if playing from playlist
  bool get isPlayingFromPlaylist => _isPlayingFromPlaylist;

  Future<void> _initializeAudioService() async {
    try {
      final config = AudioServiceConfig(
        androidNotificationChannelId: 'com.rhythm.audio.channel',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      );

      _audioHandler = await AudioService.init(
        builder: () => RhythmAudioHandler(),
        config: config,
      );

      _isInitialized = true;
      _setupAudioPlayer();
    } catch (e) {
      debugPrint('Error initializing audio service: $e');
      _audioHandler = null;
      _isInitialized = true;
      _setupAudioPlayer();
    }
  }

  void _setupAudioPlayer() {
    audioPlayer.playerStateStream.listen((playerState) {
      isPlaying.value = playerState.playing;

      if (playerState.processingState == ProcessingState.completed) {
        _handleSongCompletion();
      }
    });
  }

  /// Apply all equalizer-related settings from provider to the active audio player.
  Future<void> applySettingsFromProvider(dynamic provider) async {
    try {
      final gains = (provider?.gains) ?? [];
      final volume = (provider?.volume) ?? 1.0;
      final preamp = (provider?.preamp) ?? 0.0;
      final speed = (provider?.speed) ?? 1.0;
      final pitch = (provider?.pitch) ?? 1.0;

      await applyEqualizerGains(List<double>.from(gains));
      await applyPlaybackVolume(volume: volume, preampDb: preamp);
      await applyPlaybackSpeed(speed);
      await applyPlaybackPitch(pitch);
    } catch (e) {
      debugPrint('⚠️ Failed to apply settings from provider: $e');
    }
  }

  /// Apply volume and preamp (preamp in dB) to the active audio player.
  Future<void> applyPlaybackVolume({required double volume, double preampDb = 0.0}) async {
    try {
      final gain = pow(10.0, preampDb / 20.0).toDouble();
      double effective = volume * gain;
      if (effective.isNaN || effective.isInfinite) effective = 1.0;
      effective = effective.clamp(0.0, 1.0);
      await audioPlayer.setVolume(effective);
      debugPrint('🔊 Applied volume: $volume, preamp(dB): $preampDb -> effective: $effective');
    } catch (e) {
      debugPrint('⚠️ Failed to apply playback volume: $e');
    }
  }

  /// Apply playback speed (just_audio supports setSpeed)
  Future<void> applyPlaybackSpeed(double speed) async {
    try {
      await audioPlayer.setSpeed(speed);
      debugPrint('⏩ Applied playback speed: $speed');
    } catch (e) {
      debugPrint('⚠️ Failed to set playback speed: $e');
    }
  }

  /// Try to apply pitch. Not all versions/platforms support setPitch; fallback logs.
  Future<void> applyPlaybackPitch(double pitch) async {
    try {
      final player = audioPlayer as dynamic;
      try {
        await player.setPitch(pitch);
        debugPrint('🎚️ Applied pitch: $pitch');
        return;
      } catch (_) {
        debugPrint('ℹ️ Pitch not supported by player');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to apply playback pitch: $e');
    }
  }

  /// Placeholder to apply equalizer band gains. Real implementation requires native DSP or plugin.
  Future<void> applyEqualizerGains(List<double> gains) async {
    try {
      debugPrint('🎛️ applyEqualizerGains called with gains: $gains - forwarding to platform');
      await PlatformEqualizer.setGains(gains);
    } catch (e) {
      debugPrint('⚠️ Failed to apply equalizer gains: $e');
    }
  }

  void _handleSongCompletion() {
    final songList = _isPlayingFromPlaylist ? currentPlaylist.value : songs.value;

    switch (loopMode.value) {
      case LoopMode.one:
        // Repeat same song
        playSong(currentIndex.value, fromPlaylist: _isPlayingFromPlaylist);
        break;
      case LoopMode.all:
        // Next or loop back to start
        if (currentIndex.value < songList.length - 1) {
          playSong(currentIndex.value + 1, fromPlaylist: _isPlayingFromPlaylist);
        } else {
          playSong(0, fromPlaylist: _isPlayingFromPlaylist);
        }
        break;
      case LoopMode.off:
        // Play next song if available
        if (currentIndex.value < songList.length - 1) {
          playSong(currentIndex.value + 1, fromPlaylist: _isPlayingFromPlaylist);
        } else {
          isPlaying.value = false;
          currentIndex.value = -1;
        }
        break;
    }
  }

  Future<void> loadSongs() async {
    try {
      debugPrint('🔍 Starting to query songs with safe wrapper...');

      // Use SafeAudioQuery which has built-in retry logic and error handling
      final fetchedSongs = await SafeAudioQuery.querySongs(
        sortType: null,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
        maxRetries: 3,
      );

      debugPrint('✅ Found ${fetchedSongs.length} songs');

      songs.value = fetchedSongs.map((song) => LocalSongModel(
        id: song.id,
        title: song.title,
        artist: song.artist ?? 'Unknown Artist',
        uri: song.uri ?? '',
        albumArt: song.album ?? '',
        duration: song.duration ?? 0,
      )).toList();

      debugPrint('✅ Songs loaded successfully: ${songs.value.length} tracks');

    } catch (e, stackTrace) {
      debugPrint('❌ Error loading songs: $e');
      debugPrint('Stack trace: $stackTrace');
      songs.value = [];
    }
  }

  Future<bool> playSong(int index, {bool fromPlaylist = false}) async {
    final songList = fromPlaylist ? currentPlaylist.value : songs.value;
    debugPrint('🎵 playSong called - index: $index, fromPlaylist: $fromPlaylist, songList length: ${songList.length}');

    if (index < 0 || index >= songList.length) {
      debugPrint('❌ Invalid index: $index (songList length: ${songList.length})');
      return false;
    }

    try {
      final song = songList[index];

      // Validate song URI
      if (song.uri.isEmpty) {
        debugPrint('❌ Song URI is empty for: ${song.title}');
        return false;
      }

      debugPrint('✅ Playing: ${song.title} (index: $index, fromPlaylist: $fromPlaylist)');
      currentIndex.value = index;
      _isPlayingFromPlaylist = fromPlaylist;

      // Add to recently played history
      try {
        RecentlyPlayedService().addSong(song);
      } catch (e) {
        debugPrint('⚠️ Failed to add to recently played: $e');
      }

      // Check if it's an online song
      final isOnlineSong = song.uri.startsWith('http://') || song.uri.startsWith('https://');
      String playbackUri = song.uri;

      if (isOnlineSong) {
        // Check if song is cached
        try {
          final cachedPath = _cacheService.getCachedFilePath(song.uri);

          if (cachedPath != null) {
            debugPrint('🎵 Using cached file: $cachedPath');
            playbackUri = cachedPath;
          } else {
            debugPrint('🌐 Playing from URL (not cached): ${song.uri}');
            // Cache the song in background (don't wait for it) - only if caching is enabled
            try {
              final isCacheEnabled = await _cacheService.isCacheEnabled();
              if (isCacheEnabled) {
                _cacheService.cacheSong(song).then((cachedPath) {
                  if (cachedPath != null) {
                    debugPrint('✅ Song cached successfully: $cachedPath');
                  }
                }).catchError((e) {
                  debugPrint('⚠️ Failed to cache song: $e');
                });
              } else {
                debugPrint('⚠️ Caching is disabled');
              }
            } catch (e) {
              debugPrint('⚠️ Cache check failed: $e');
            }
          }
        } catch (e) {
          debugPrint('⚠️ Cache service error: $e');
        }
      }

      // Update media item for lock screen and notification (if available)
      if (_audioHandler != null && _isInitialized) {
        try {
          Uri? artUri;
          String? albumName;

          if (song.albumArt.isNotEmpty) {
            if (song.albumArt.startsWith('http')) {
              artUri = Uri.parse(song.albumArt);
              albumName = 'Online';
            } else {
              albumName = song.albumArt;

              try {
                final songs = await audioQuery.querySongs(
                  sortType: SongSortType.TITLE,
                  orderType: OrderType.ASC_OR_SMALLER,
                  uriType: UriType.EXTERNAL,
                );

                final matchingSong = songs.firstWhere(
                  (s) => s.id == song.id,
                  orElse: () => songs.first,
                );

                final albumId = matchingSong.albumId;
                if (albumId != null) {
                  artUri = Uri.parse('content://media/external/audio/albumart/$albumId');
                  debugPrint('✅ Album art URI constructed: $artUri');
                }
              } catch (e) {
                debugPrint('⚠️ Failed to get album art URI: $e');
              }
            }
          }

          await _audioHandler!.updateMediaItem(MediaItem(
            id: song.id.toString(),
            album: albumName ?? 'Unknown Album',
            title: song.title,
            artist: song.artist.isEmpty ? 'Unknown Artist' : song.artist,
            duration: Duration(milliseconds: song.duration),
            artUri: artUri,
          ));

          debugPrint('✅ Media item updated: ${song.title} - ${song.artist}');
          if (artUri != null) {
            debugPrint('✅ Album art URI: $artUri');
          }
        } catch (e) {
          debugPrint('⚠️ Could not update media item: $e');
          try {
            await _audioHandler!.updateMediaItem(MediaItem(
              id: song.id.toString(),
              album: 'Rhythm',
              title: song.title,
              artist: song.artist.isEmpty ? 'Unknown Artist' : song.artist,
              duration: Duration(milliseconds: song.duration),
            ));
          } catch (e2) {
            debugPrint('⚠️ Fallback media item update also failed: $e2');
          }
        }
      }

      // Always use audioPlayer (which points to handler's player or fallback)
      try {
        await audioPlayer.stop();
      } catch (e) {
        debugPrint('⚠️ Error stopping previous playback: $e');
      }

      try {
        final uri = Uri.parse(playbackUri);
        if (uri.scheme.isEmpty && !isOnlineSong) {
          debugPrint('⚠️ Invalid URI scheme, attempting to fix: $playbackUri');
          if (!playbackUri.startsWith('file://') && !playbackUri.startsWith('content://')) {
            playbackUri = 'file://$playbackUri';
          }
        }

        await audioPlayer.setAudioSource(AudioSource.uri(Uri.parse(playbackUri)));
        await _applyPersistedSettings();
        await audioPlayer.play();
        isPlaying.value = true;
        debugPrint('✅ Playing: ${song.title} by ${song.artist}');
        return true;
      } catch (e) {
        debugPrint('❌ Error setting audio source or playing: $e');
        isPlaying.value = false;
        throw Exception('Failed to play song: ${song.title}. Error: $e');
      }
    } catch (e) {
      debugPrint('❌ Error playing song: $e');
      isPlaying.value = false;
      return false;
    }
  }

  // Current online song for mini player display
  final ValueNotifier<LocalSongModel?> currentOnlineSong = ValueNotifier(null);

  // Helper to play a song from a direct URL (for online search)
  Future<bool> playOnlineUrl(String url, {String? title, String? artist, String? imageUrl, int? duration}) async {
    try {
      await audioPlayer.setUrl(url);
      await audioPlayer.play();

      final onlineSong = LocalSongModel(
        id: url.hashCode,
        title: title ?? 'Online Track',
        artist: artist ?? 'Unknown Artist',
        uri: url,
        albumArt: imageUrl ?? '',
        duration: duration ?? 0,
      );

      currentOnlineSong.value = onlineSong;
      _isPlayingFromPlaylist = false;

      currentPlaylist.value = [onlineSong];
      _isPlayingFromPlaylist = true;
      currentIndex.value = 0;
      isPlaying.value = true;

      debugPrint('✅ Playing online URL: $url');
      return true;
    } catch (e) {
      debugPrint('Error playing online url: $e');
      isPlaying.value = false;
      return false;
    }
  }

  Future<void> pauseSong() async {
    await audioPlayer.pause();
    isPlaying.value = false;
  }

  Future<void> resumeSong() async {
    await audioPlayer.play();
    isPlaying.value = true;
  }

  void togglePlayPause() async {
    if (currentIndex.value == -1) return;
    if (isPlaying.value) {
      await pauseSong();
    } else {
      await resumeSong();
    }
  }

  Future<void> nextSong() async {
    final songList = _isPlayingFromPlaylist ? currentPlaylist.value : songs.value;
    debugPrint('🔄 nextSong called - songList length: ${songList.length}, currentIndex: ${currentIndex.value}, isPlayingFromPlaylist: $_isPlayingFromPlaylist');

    if (songList.isEmpty) {
      debugPrint('⚠️ Song list is empty, cannot play next');
      return;
    }

    if (isShuffle.value) {
      final randomIndex = (songList.toList()..shuffle()).indexWhere((_) => true);
      debugPrint('🔀 Shuffle mode - playing random index: $randomIndex');
      await playSong(randomIndex, fromPlaylist: _isPlayingFromPlaylist);
    } else {
      if (currentIndex.value < songList.length - 1) {
        debugPrint('⏭️ Playing next song at index: ${currentIndex.value + 1}');
        await playSong(currentIndex.value + 1, fromPlaylist: _isPlayingFromPlaylist);
      } else if (loopMode.value == LoopMode.all) {
        debugPrint('🔁 Loop mode - restarting from index 0');
        await playSong(0, fromPlaylist: _isPlayingFromPlaylist);
      } else {
        debugPrint('⏹️ End of playlist, no loop');
      }
    }
  }

  ValueNotifier<Set<int>> favorites = ValueNotifier({});

  void toggleFavorite(int songId) {
    final currentFavs = Set<int>.from(favorites.value);
    if (currentFavs.contains(songId)) {
      currentFavs.remove(songId);
    } else {
      currentFavs.add(songId);
    }
    favorites.value = currentFavs;
  }

  Future<void> previousSong() async {
    final songList = _isPlayingFromPlaylist ? currentPlaylist.value : songs.value;
    debugPrint('🔄 previousSong called - songList length: ${songList.length}, currentIndex: ${currentIndex.value}, isPlayingFromPlaylist: $_isPlayingFromPlaylist');

    if (songList.isEmpty) {
      debugPrint('⚠️ Song list is empty, cannot play previous');
      return;
    }

    if (audioPlayer.position.inSeconds > 3) {
      debugPrint('⏮️ Position > 3s, seeking to start');
      await audioPlayer.seek(Duration.zero);
      return;
    }

    if (isShuffle.value) {
      final randomIndex = (songList.toList()..shuffle()).indexWhere((_) => true);
      debugPrint('🔀 Shuffle mode - playing random index: $randomIndex');
      await playSong(randomIndex, fromPlaylist: _isPlayingFromPlaylist);
    } else if (currentIndex.value > 0) {
      debugPrint('⏮️ Playing previous song at index: ${currentIndex.value - 1}');
      await playSong(currentIndex.value - 1, fromPlaylist: _isPlayingFromPlaylist);
    } else if (loopMode.value == LoopMode.all) {
      debugPrint('🔁 Loop mode - playing last song at index: ${songList.length - 1}');
      await playSong(songList.length - 1, fromPlaylist: _isPlayingFromPlaylist);
    } else {
      debugPrint('⏹️ At start of playlist, no loop');
    }
  }

  // Add song to playlist and play
  Future<bool> playFromPlaylist(LocalSongModel song, {List<LocalSongModel>? playlist}) async {
    if (playlist != null && playlist.isNotEmpty) {
      currentPlaylist.value = playlist;
      final index = playlist.indexWhere((s) => s.uri == song.uri);
      if (index != -1) {
        debugPrint('✅ Found song in playlist at index $index, playing...');
        return await playSong(index, fromPlaylist: true);
      } else {
        debugPrint('⚠️ Song not found in playlist, adding and playing...');
        currentPlaylist.value = [...playlist, song];
        return await playSong(currentPlaylist.value.length - 1, fromPlaylist: true);
      }
    } else {
      final existingIndex = currentPlaylist.value.indexWhere((s) => s.uri == song.uri);
      if (existingIndex != -1) {
        debugPrint('✅ Song already in existing playlist at index $existingIndex');
        return await playSong(existingIndex, fromPlaylist: true);
      } else {
        debugPrint('⚠️ Adding song to existing playlist');
        currentPlaylist.value = [...currentPlaylist.value, song];
        return await playSong(currentPlaylist.value.length - 1, fromPlaylist: true);
      }
    }
  }

  // Spotify-style Shuffle
  void toggleShuffle() {
    isShuffle.value = !isShuffle.value;
  }

  // Spotify-style Repeat (off → all → one → off)
  void toggleRepeat() {
    if (loopMode.value == LoopMode.off) {
      loopMode.value = LoopMode.all;
    } else if (loopMode.value == LoopMode.all) {
      loopMode.value = LoopMode.one;
    } else {
      loopMode.value = LoopMode.off;
    }
  }

  void dispose() {
    audioPlayer.dispose();
    if (_audioHandler == null) {
      _fallbackPlayer.dispose();
    }
  }

  static const String _prefsKey = 'equalizer_gains_v1';
  static const String _prefsPreampKey = 'equalizer_preamp_v1';
  static const String _prefsPitchKey = 'equalizer_pitch_v1';
  static const String _prefsSpeedKey = 'equalizer_speed_v1';
  static const String _prefsVolumeKey = 'equalizer_volume_v1';

  Future<void> _applyPersistedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final gainsList = prefs.getStringList(_prefsKey) ?? [];
      final gains = gainsList.map((s) => double.tryParse(s) ?? 0.0).toList();
      if (gains.isNotEmpty) {
        await applyEqualizerGains(gains);
      }
      final preamp = prefs.getDouble(_prefsPreampKey) ?? 0.0;
      final pitch = prefs.getDouble(_prefsPitchKey) ?? 1.0;
      final speed = prefs.getDouble(_prefsSpeedKey) ?? 1.0;
      final volume = prefs.getDouble(_prefsVolumeKey) ?? 1.0;
      await applyPlaybackVolume(volume: volume, preampDb: preamp);
      await applyPlaybackSpeed(speed);
      await applyPlaybackPitch(pitch);
    } catch (e) {
      debugPrint('⚠️ Failed to apply persisted settings: $e');
    }
  }
}

