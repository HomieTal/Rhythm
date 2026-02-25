import 'package:shared_preferences/shared_preferences.dart';

import '../../model/lyrics_models.dart';
import 'lrcnet_api.dart';

class LyricsRepository {
  static const _prefsKey = 'lyrics_enabled';
  static Future<bool> _lyricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefsKey) ?? true;
  }

  static Future<Lyrics> getLyrics(
    String title,
    String artist, {
    String? album,
    Duration? duration,
    LyricsProvider provider = LyricsProvider.none,
  }) async {
    // Respect user preference
    if (!await _lyricsEnabled()) {
      return Lyrics(
        id: '0',
        artist: artist,
        title: title,
        lyricsPlain: '',
        provider: LyricsProvider.none,
      );
    }

    Lyrics result;
    try {
      switch (provider) {
        case LyricsProvider.lrcnet:
          result = await getLRCNetAPILyrics(
            title,
            artist: artist,
            album: album,
            duration: duration?.inSeconds.toString(),
          );
          break;
        default:
          result = await getLRCNetAPILyrics(
            title,
            artist: artist,
            album: album,
            duration: duration?.inSeconds.toString(),
          );
      }
    } catch (e) {
      result = await getLRCNetAPILyrics(
        title,
        artist: artist,
      );
    }
    return result;
  }

  static Future<List<Lyrics>> searchLyrics(
    String title,
    String artist, {
    String? album,
    Duration? duration,
    LyricsProvider provider = LyricsProvider.none,
  }) async {
    if (!await _lyricsEnabled()) {
      return [];
    }

    List<Lyrics> result;
    try {
      switch (provider) {
        case LyricsProvider.lrcnet:
          result = await searchLRCNetLyrics(
            title,
            artistName: artist,
            albumName: album,
          );
          break;
        default:
          result = await searchLRCNetLyrics(
            title,
            artistName: artist,
            albumName: album,
          );
      }
    } catch (e) {
      result = await searchLRCNetLyrics(
        title,
        artistName: artist,
        albumName: album,
      );
    }
    return result;
  }
}
