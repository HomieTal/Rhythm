import 'dart:async';
import 'package:flutter/foundation.dart';
import '../songsrepo/Saavn/saavn_api.dart';

/// Service to match imported song metadata with Saavn database
class MetadataMatcherService {
  static final MetadataMatcherService _instance = MetadataMatcherService._internal();
  factory MetadataMatcherService() => _instance;
  MetadataMatcherService._internal();

  final SaavnAPI _saavnApi = SaavnAPI();

  /// Match a single song with Saavn metadata
  Future<Map<String, dynamic>?> matchSong({
    required String title,
    required String artist,
    String? album,
  }) async {
    try {
      // Clean and prepare search query
      final searchQuery = _prepareSearchQuery(title, artist);

      // Search in Saavn database
      final result = await _saavnApi.querySongsSearch(searchQuery, maxResults: 5);

      if (result['songs'] != null && result['songs'] is List) {
        final List songs = result['songs'] as List;

        if (songs.isEmpty) {
          debugPrint('⚠️ No match found for: $title - $artist');
          return null;
        }

        // Find best match using fuzzy matching
        final bestMatch = _findBestMatch(
          title: title,
          artist: artist,
          album: album,
          candidates: songs,
        );

        if (bestMatch != null) {
          debugPrint('✅ Matched: $title -> ${bestMatch['title']}');
          return bestMatch;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error matching song "$title": $e');
      return null;
    }
  }

  /// Match multiple songs in batch
  Future<List<Map<String, dynamic>>> matchSongsBatch(
    List<Map<String, String>> songs, {
    Function(int, int)? onProgress,
  }) async {
    final List<Map<String, dynamic>> matchedSongs = [];

    for (int i = 0; i < songs.length; i++) {
      final song = songs[i];
      final title = song['title'] ?? '';
      final artist = song['artist'] ?? '';
      final album = song['album'];

      if (title.isEmpty) continue;

      // Call progress callback
      onProgress?.call(i + 1, songs.length);

      // Try to match with Saavn
      final match = await matchSong(
        title: title,
        artist: artist,
        album: album,
      );

      if (match != null) {
        matchedSongs.add(match);
      } else {
        // If no match, create a fallback entry with original metadata
        matchedSongs.add({
          'title': title,
          'artist': artist,
          'album': album ?? 'Unknown Album',
          'image': '',
          'url': '',
          'matched': false,
        });
      }

      // Add small delay to avoid rate limiting
      await Future.delayed(const Duration(milliseconds: 300));
    }

    return matchedSongs;
  }

  /// Prepare search query by cleaning and combining title and artist
  String _prepareSearchQuery(String title, String artist) {
    // Remove common suffixes and prefixes
    String cleanTitle = title
        .replaceAll(RegExp(r'\(.*?\)'), '') // Remove parentheses content
        .replaceAll(RegExp(r'\[.*?\]'), '') // Remove brackets content
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();

    String cleanArtist = artist
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Combine title and artist for better search
    if (cleanArtist.isNotEmpty && cleanArtist.toLowerCase() != 'unknown artist') {
      return '$cleanTitle $cleanArtist';
    }

    return cleanTitle;
  }

  /// Find best match from candidates using similarity scoring
  Map<String, dynamic>? _findBestMatch({
    required String title,
    required String artist,
    String? album,
    required List candidates,
  }) {
    if (candidates.isEmpty) return null;

    double bestScore = 0.0;
    Map<String, dynamic>? bestMatch;

    for (final candidate in candidates) {
      final candidateTitle = (candidate['title'] ?? '').toString().toLowerCase();
      final candidateArtist = (candidate['primaryArtists'] ?? '').toString().toLowerCase();
      final candidateAlbum = (candidate['album'] ?? '').toString().toLowerCase();

      // Calculate similarity score
      double score = 0.0;

      // Title similarity (most important - 60%)
      score += _calculateSimilarity(title.toLowerCase(), candidateTitle) * 0.6;

      // Artist similarity (30%)
      if (artist.isNotEmpty && artist.toLowerCase() != 'unknown artist') {
        score += _calculateSimilarity(artist.toLowerCase(), candidateArtist) * 0.3;
      } else {
        score += 0.3; // Give benefit if no artist info
      }

      // Album similarity (10%)
      if (album != null && album.isNotEmpty && album.toLowerCase() != 'unknown album') {
        score += _calculateSimilarity(album.toLowerCase(), candidateAlbum) * 0.1;
      } else {
        score += 0.1; // Give benefit if no album info
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = candidate as Map<String, dynamic>;
      }
    }

    // Only return match if score is above threshold (70%)
    if (bestScore >= 0.7) {
      return bestMatch;
    }

    return null;
  }

  /// Calculate simple string similarity (0.0 to 1.0)
  double _calculateSimilarity(String str1, String str2) {
    if (str1 == str2) return 1.0;
    if (str1.isEmpty || str2.isEmpty) return 0.0;

    // Check if one contains the other
    if (str1.contains(str2) || str2.contains(str1)) {
      final shorter = str1.length < str2.length ? str1 : str2;
      final longer = str1.length >= str2.length ? str1 : str2;
      return shorter.length / longer.length;
    }

    // Calculate Levenshtein distance based similarity
    final distance = _levenshteinDistance(str1, str2);
    final maxLength = str1.length > str2.length ? str1.length : str2.length;

    return 1.0 - (distance / maxLength);
  }

  /// Calculate Levenshtein distance between two strings
  int _levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;

    final List<List<int>> d = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );

    for (int i = 0; i <= len1; i++) {
      d[i][0] = i;
    }

    for (int j = 0; j <= len2; j++) {
      d[0][j] = j;
    }

    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        d[i][j] = [
          d[i - 1][j] + 1, // deletion
          d[i][j - 1] + 1, // insertion
          d[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return d[len1][len2];
  }

  /// Extract songs metadata from various playlist formats
  Future<List<Map<String, String>>> extractMetadataFromFile(
    String content,
    String fileExtension,
  ) async {
    final List<Map<String, String>> songs = [];

    try {
      switch (fileExtension.toLowerCase()) {
        case 'm3u':
        case 'm3u8':
          songs.addAll(_parseM3U(content));
          break;
        case 'pls':
          songs.addAll(_parsePLS(content));
          break;
        case 'csv':
          songs.addAll(_parseCSV(content));
          break;
        case 'txt':
          songs.addAll(_parseTXT(content));
          break;
        case 'xspf':
          songs.addAll(_parseXSPF(content));
          break;
        default:
          debugPrint('⚠️ Unsupported file format: $fileExtension');
      }
    } catch (e) {
      debugPrint('❌ Error extracting metadata: $e');
    }

    return songs;
  }

  /// Parse M3U/M3U8 playlist format
  List<Map<String, String>> _parseM3U(String content) {
    final List<Map<String, String>> songs = [];
    final lines = content.split('\n');

    String? currentTitle;
    String? currentArtist;

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.startsWith('#EXTINF:')) {
        // Extract title and artist from EXTINF line
        // Format: #EXTINF:duration,Artist - Title
        final parts = trimmed.substring(8).split(',');
        if (parts.length > 1) {
          final info = parts[1].trim();
          if (info.contains(' - ')) {
            final split = info.split(' - ');
            currentArtist = split[0].trim();
            currentTitle = split.sublist(1).join(' - ').trim();
          } else {
            currentTitle = info;
            currentArtist = 'Unknown Artist';
          }
        }
      } else if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
        // This is a file path or URL
        if (currentTitle != null) {
          songs.add({
            'title': currentTitle,
            'artist': currentArtist ?? 'Unknown Artist',
            'path': trimmed,
          });
        }
        currentTitle = null;
        currentArtist = null;
      }
    }

    return songs;
  }

  /// Parse PLS playlist format
  List<Map<String, String>> _parsePLS(String content) {
    final List<Map<String, String>> songs = [];
    final lines = content.split('\n');
    final Map<int, Map<String, String>> tempSongs = {};

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.startsWith('File')) {
        final match = RegExp(r'File(\d+)=(.+)').firstMatch(trimmed);
        if (match != null) {
          final index = int.parse(match.group(1)!);
          tempSongs[index] = {'path': match.group(2)!};
        }
      } else if (trimmed.startsWith('Title')) {
        final match = RegExp(r'Title(\d+)=(.+)').firstMatch(trimmed);
        if (match != null) {
          final index = int.parse(match.group(1)!);
          final title = match.group(2)!;

          tempSongs[index] = tempSongs[index] ?? {};

          if (title.contains(' - ')) {
            final split = title.split(' - ');
            tempSongs[index]!['artist'] = split[0].trim();
            tempSongs[index]!['title'] = split.sublist(1).join(' - ').trim();
          } else {
            tempSongs[index]!['title'] = title;
            tempSongs[index]!['artist'] = 'Unknown Artist';
          }
        }
      }
    }

    // Convert to list
    for (final entry in tempSongs.values) {
      if (entry['title'] != null) {
        songs.add({
          'title': entry['title']!,
          'artist': entry['artist'] ?? 'Unknown Artist',
          'path': entry['path'] ?? '',
        });
      }
    }

    return songs;
  }

  /// Parse CSV format (title, artist, album)
  List<Map<String, String>> _parseCSV(String content) {
    final List<Map<String, String>> songs = [];
    final lines = content.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Skip header row if present
      if (i == 0 && (line.toLowerCase().contains('title') || line.toLowerCase().contains('song'))) {
        continue;
      }

      final parts = line.split(',');
      if (parts.isNotEmpty) {
        songs.add({
          'title': parts[0].trim().replaceAll('"', ''),
          'artist': parts.length > 1 ? parts[1].trim().replaceAll('"', '') : 'Unknown Artist',
          'album': parts.length > 2 ? parts[2].trim().replaceAll('"', '') : '',
        });
      }
    }

    return songs;
  }

  /// Parse simple text format (one song per line)
  List<Map<String, String>> _parseTXT(String content) {
    final List<Map<String, String>> songs = [];
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.contains(' - ')) {
        final split = trimmed.split(' - ');
        songs.add({
          'title': split.sublist(1).join(' - ').trim(),
          'artist': split[0].trim(),
        });
      } else {
        songs.add({
          'title': trimmed,
          'artist': 'Unknown Artist',
        });
      }
    }

    return songs;
  }

  /// Parse XSPF (XML Shareable Playlist Format)
  List<Map<String, String>> _parseXSPF(String content) {
    final List<Map<String, String>> songs = [];

    // Simple XML parsing for XSPF
    final trackPattern = RegExp(r'<track>(.*?)</track>', dotAll: true);
    final titlePattern = RegExp(r'<title>(.*?)</title>');
    final creatorPattern = RegExp(r'<creator>(.*?)</creator>');
    final albumPattern = RegExp(r'<album>(.*?)</album>');

    final tracks = trackPattern.allMatches(content);

    for (final track in tracks) {
      final trackContent = track.group(1) ?? '';

      final titleMatch = titlePattern.firstMatch(trackContent);
      final creatorMatch = creatorPattern.firstMatch(trackContent);
      final albumMatch = albumPattern.firstMatch(trackContent);

      if (titleMatch != null) {
        songs.add({
          'title': titleMatch.group(1)!,
          'artist': creatorMatch?.group(1) ?? 'Unknown Artist',
          'album': albumMatch?.group(1) ?? '',
        });
      }
    }

    return songs;
  }
}

