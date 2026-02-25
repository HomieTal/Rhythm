import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import '../model/local_song_model.dart';
import '../model/playlist_model.dart';

class ImportExportService {
  static final ImportExportService _instance =
      ImportExportService._internal();
  factory ImportExportService() => _instance;
  ImportExportService._internal();

  // Generate encryption key (you can derive this from a password)
  static String _generateEncryptionKey(String password) {
    // Simple key derivation - in production, use proper KDF
    final bytes = utf8.encode(password);
    final hashedBytes = List<int>.filled(32, 0);
    for (int i = 0; i < bytes.length; i++) {
      hashedBytes[i % 32] = hashedBytes[i % 32] ^ bytes[i];
    }
    return base64Url.encode(hashedBytes).substring(0, 44);
  }

  // Encrypt data
  String encryptData(String plainText, {String password = 'rhythm_default'}) {
    try {
      final key = encrypt.Key.fromBase64(_generateEncryptionKey(password));
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      // Combine IV and encrypted text for decryption
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      debugPrint('Encryption error: $e');
      return plainText;
    }
  }

  // Decrypt data
  String decryptData(String encryptedText,
      {String password = 'rhythm_default'}) {
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) {
        return encryptedText;
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final key = encrypt.Key.fromBase64(_generateEncryptionKey(password));
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decrypted = encrypter.decrypt64(parts[1], iv: iv);
      return decrypted;
    } catch (e) {
      debugPrint('Decryption error: $e');
      return encryptedText;
    }
  }

  // Export all data as encrypted JSON
  Future<String> exportAllData({
    required List<LocalSongModel> favorites,
    required List<PlaylistModel> playlists,
    required List<LocalSongModel> history,
    String password = 'rhythm_default',
  }) async {
    try {
      final data = {
        'version': '1.0',
        'exportedAt': DateTime.now().toIso8601String(),
        'type': 'rhythm_complete_backup',
        'favorites': favorites.map((f) => f.toJson()).toList(),
        'playlists': playlists.map((p) => p.toJson()).toList(),
        'history': history.map((h) => h.toJson()).toList(),
      };

      final jsonString = jsonEncode(data);
      final encrypted = encryptData(jsonString, password: password);

      return encrypted;
    } catch (e) {
      debugPrint('Export error: $e');
      return '';
    }
  }

  // Import data from encrypted JSON
  Future<Map<String, dynamic>> importFromEncryptedJson(
    String encryptedData, {
    String password = 'rhythm_default',
  }) async {
    try {
      final decrypted = decryptData(encryptedData, password: password);
      final data = jsonDecode(decrypted) as Map<String, dynamic>;

      return {
        'success': true,
        'favorites': (data['favorites'] as List?)
                ?.map((f) => LocalSongModel.fromJson(f))
                .toList() ??
            [],
        'playlists': (data['playlists'] as List?)
                ?.map((p) => PlaylistModel.fromJson(p))
                .toList() ??
            [],
        'history': (data['history'] as List?)
                ?.map((h) => LocalSongModel.fromJson(h))
                .toList() ??
            [],
      };
    } catch (e) {
      debugPrint('Import error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Export to M3U format
  String exportToM3U(List<LocalSongModel> songs) {
    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');

    for (var song in songs) {
      buffer.writeln(
          '#EXTINF:${song.duration ~/ 1000},-${song.artist} - ${song.title}');
      buffer.writeln(song.uri);
    }

    return buffer.toString();
  }

  // Export to M3U8 format
  String exportToM3U8(List<LocalSongModel> songs) {
    return exportToM3U(songs); // M3U8 is same as M3U for local files
  }

  // Export to PLS format
  String exportToPLS(List<LocalSongModel> songs) {
    final buffer = StringBuffer();
    buffer.writeln('[playlist]');

    for (int i = 0; i < songs.length; i++) {
      final index = i + 1;
      buffer.writeln('File$index=${songs[i].uri}');
      buffer.writeln('Title$index=${songs[i].artist} - ${songs[i].title}');
      buffer.writeln('Length$index=${songs[i].duration ~/ 1000}');
    }

    buffer.writeln('NumberOfEntries=${songs.length}');
    buffer.writeln('Version=2');

    return buffer.toString();
  }

  // Export to WPL (Windows Playlist) format
  String exportToWPL(List<LocalSongModel> songs) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<smil>');
    buffer.writeln('<head>');
    buffer.writeln(
        '<meta name="Generator" content="Rhythm Music Player" />');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln('<seq>');

    for (var song in songs) {
      buffer.writeln(
          '<media src="${_escapeXml(song.uri)}" name="${_escapeXml(song.title)}" />');
    }

    buffer.writeln('</seq>');
    buffer.writeln('</body>');
    buffer.writeln('</smil>');

    return buffer.toString();
  }

  // Export to XSPF (Spotify playlist) format
  String exportToXSPF(List<LocalSongModel> songs, String playlistName) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<playlist version="1" xmlns="http://xspf.org/ns/0/">');
    buffer.writeln('<title>$playlistName</title>');
    buffer.writeln('<trackList>');

    for (var song in songs) {
      buffer.writeln('<track>');
      buffer.writeln(
          '<title>${_escapeXml(song.title)}</title>');
      buffer.writeln(
          '<creator>${_escapeXml(song.artist)}</creator>');
      buffer.writeln(
          '<location>${_escapeXml(song.uri)}</location>');
      buffer.writeln('</track>');
    }

    buffer.writeln('</trackList>');
    buffer.writeln('</playlist>');

    return buffer.toString();
  }

  // Export to CSV format
  String exportToCSV(List<LocalSongModel> songs) {
    final buffer = StringBuffer();
    buffer.writeln('Title,Artist,Duration,URI');

    for (var song in songs) {
      final duration = (song.duration / 1000).toStringAsFixed(2);
      buffer.writeln(
          '"${_escapeCsv(song.title)}","${_escapeCsv(song.artist)}",$duration,"${_escapeCsv(song.uri)}"');
    }

    return buffer.toString();
  }

  // Export to TXT format
  String exportToTXT(List<LocalSongModel> songs) {
    final buffer = StringBuffer();
    buffer.writeln('Rhythm Music Library Export');
    buffer.writeln(
        'Exported at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Songs: ${songs.length}');
    buffer.writeln('-------------------------------------------');

    for (int i = 0; i < songs.length; i++) {
      buffer.writeln('${i + 1}. ${songs[i].title}');
      buffer.writeln('   Artist: ${songs[i].artist}');
      buffer.writeln('   Duration: ${_formatDuration(songs[i].duration)}');
      buffer.writeln('   Path: ${songs[i].uri}');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  // Save export file
  Future<File> saveExportFile(String content, String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);
      return file;
    } catch (e) {
      debugPrint('Save file error: $e');
      rethrow;
    }
  }

  // Import from file content
  Future<List<LocalSongModel>> importFromM3U(String content) async {
    final songs = <LocalSongModel>[];
    final lines = content.split('\n');

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      // Line should be a file path
      songs.add(LocalSongModel(
        id: songs.length,
        title: line.split('/').last,
        artist: 'Unknown',
        uri: line,
        albumArt: '',
        duration: 0,
      ));
    }

    return songs;
  }

  // Helper methods
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  String _escapeCsv(String text) {
    if (text.contains(',') || text.contains('"') || text.contains('\n')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }

  String _formatDuration(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;

    if (hours > 0) {
      return '$hours:${(minutes % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    }
    return '${minutes % 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  // Fetch Spotify data (requires authentication)
  Future<Map<String, dynamic>> fetchSpotifyData(String spotifyLink) async {
    try {
      // This would require Spotify API integration
      // For now, returning a placeholder structure
      return {
        'type': 'spotify',
        'link': spotifyLink,
        'songs': [],
        'playlists': [],
        'albums': [],
      };
    } catch (e) {
      debugPrint('Spotify fetch error: $e');
      return {};
    }
  }

  // Fetch YouTube data (requires youtube_explode_dart)
  Future<Map<String, dynamic>> fetchYouTubeData(String youtubeLink) async {
    try {
      // This would require youtube_explode_dart integration
      // For now, returning a placeholder structure
      return {
        'type': 'youtube',
        'link': youtubeLink,
        'songs': [],
        'playlists': [],
        'albums': [],
      };
    } catch (e) {
      debugPrint('YouTube fetch error: $e');
      return {};
    }
  }
}

