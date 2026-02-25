import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../model/local_song_model.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _cacheDirectoryName = 'rhythm_audio_cache';
  static const String _cacheMetadataKey = 'cache_metadata';
  static const String _cacheSizeLimitKey = 'cache_size_limit_mb';
  static const String _cacheEnabledKey = 'cache_enabled';
  static const int _defaultCacheSizeMB = 500; // 500 MB default

  Directory? _cacheDirectory;
  final Map<String, CacheMetadata> _cacheMetadata = {};
  int _currentCacheSizeMB = 0;

  // Initialize the cache service
  Future<void> initialize() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      _cacheDirectory = Directory('${directory.path}/$_cacheDirectoryName');

      if (!await _cacheDirectory!.exists()) {
        await _cacheDirectory!.create(recursive: true);
      }

      await _loadCacheMetadata();
      await _calculateCacheSize();

      debugPrint('Cache service initialized: ${_cacheDirectory!.path}');
      debugPrint('Current cache size: $_currentCacheSizeMB MB');
    } catch (e) {
      debugPrint('Error initializing cache service: $e');
    }
  }

  // Get cache size limit in MB
  Future<int> getCacheSizeLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_cacheSizeLimitKey) ?? _defaultCacheSizeMB;
  }

  // Set cache size limit in MB
  Future<void> setCacheSizeLimit(int sizeMB) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_cacheSizeLimitKey, sizeMB);

    // Clean up if current size exceeds new limit
    await _enforcesCacheLimit();
  }

  // Check if cache is enabled
  Future<bool> isCacheEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cacheEnabledKey) ?? true; // Default to enabled
  }

  // Enable or disable cache
  Future<void> setCacheEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cacheEnabledKey, enabled);
    debugPrint('Cache ${enabled ? 'enabled' : 'disabled'}');
  }

  // Get current cache size in MB
  int getCurrentCacheSizeMB() => _currentCacheSizeMB;

  // Get current cache size in bytes
  Future<int> getCurrentCacheSizeBytes() async {
    await _calculateCacheSize();
    return _currentCacheSizeMB * 1024 * 1024;
  }

  // Calculate current cache size
  Future<void> _calculateCacheSize() async {
    if (_cacheDirectory == null || !await _cacheDirectory!.exists()) {
      _currentCacheSizeMB = 0;
      return;
    }

    int totalSize = 0;
    await for (var entity in _cacheDirectory!.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    _currentCacheSizeMB = (totalSize / (1024 * 1024)).ceil();
  }

  // Load cache metadata from shared preferences
  Future<void> _loadCacheMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final metadataJson = prefs.getString(_cacheMetadataKey);

    if (metadataJson != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(metadataJson);
        _cacheMetadata.clear();
        decoded.forEach((key, value) {
          _cacheMetadata[key] = CacheMetadata.fromJson(value);
        });
      } catch (e) {
        debugPrint('Error loading cache metadata: $e');
      }
    }
  }

  // Save cache metadata to shared preferences
  Future<void> _saveCacheMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> encoded = {};
    _cacheMetadata.forEach((key, value) {
      encoded[key] = value.toJson();
    });
    await prefs.setString(_cacheMetadataKey, json.encode(encoded));
  }

  // Generate cache key from URL
  String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Get cached file path for a URL
  String? getCachedFilePath(String url) {
    final cacheKey = _generateCacheKey(url);
    final metadata = _cacheMetadata[cacheKey];

    if (metadata != null && _cacheDirectory != null) {
      final file = File('${_cacheDirectory!.path}/${metadata.fileName}');
      if (file.existsSync()) {
        // Update last accessed time
        metadata.lastAccessed = DateTime.now();
        _saveCacheMetadata();
        return file.path;
      } else {
        // File doesn't exist, remove from metadata
        _cacheMetadata.remove(cacheKey);
        _saveCacheMetadata();
      }
    }

    return null;
  }

  // Check if URL is cached
  bool isCached(String url) {
    return getCachedFilePath(url) != null;
  }

  // Cache a song from URL
  Future<String?> cacheSong(LocalSongModel song, {
    Function(int received, int total)? onProgress,
  }) async {
    if (_cacheDirectory == null) {
      await initialize();
    }

    try {
      final url = song.uri;
      final cacheKey = _generateCacheKey(url);

      // Check if already cached
      final existing = getCachedFilePath(url);
      if (existing != null) {
        debugPrint('Song already cached: ${song.title}');
        return existing;
      }

      debugPrint('Caching song: ${song.title}');

      // Download the file
      final response = await http.Client().send(http.Request('GET', Uri.parse(url)));

      if (response.statusCode != 200) {
        debugPrint('Failed to download song: ${response.statusCode}');
        return null;
      }

      // Determine file extension
      final extension = _getFileExtension(url, response.headers['content-type']);
      final fileName = '$cacheKey$extension';
      final file = File('${_cacheDirectory!.path}/$fileName');

      // Download and save
      final bytes = <int>[];
      int received = 0;
      final total = response.contentLength ?? 0;

      await for (var chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }

      await file.writeAsBytes(bytes);

      // Create metadata
      final metadata = CacheMetadata(
        fileName: fileName,
        originalUrl: url,
        songId: song.id.toString(),
        songTitle: song.title,
        songArtist: song.artist,
        albumArt: song.albumArt,
        fileSizeBytes: bytes.length,
        cachedAt: DateTime.now(),
        lastAccessed: DateTime.now(),
      );

      _cacheMetadata[cacheKey] = metadata;
      await _saveCacheMetadata();
      await _calculateCacheSize();

      // Enforce cache size limit
      await _enforcesCacheLimit();

      debugPrint('Song cached successfully: ${file.path}');
      return file.path;
    } catch (e, stackTrace) {
      debugPrint('Error caching song: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  // Get file extension from URL or content type
  String _getFileExtension(String url, String? contentType) {
    // Try to get from URL first
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();

    if (path.endsWith('.mp3')) return '.mp3';
    if (path.endsWith('.m4a')) return '.m4a';
    if (path.endsWith('.aac')) return '.aac';
    if (path.endsWith('.wav')) return '.wav';
    if (path.endsWith('.flac')) return '.flac';

    // Try content type
    if (contentType != null) {
      if (contentType.contains('mpeg')) return '.mp3';
      if (contentType.contains('mp4')) return '.m4a';
      if (contentType.contains('aac')) return '.aac';
      if (contentType.contains('wav')) return '.wav';
      if (contentType.contains('flac')) return '.flac';
    }

    // Default to .mp3
    return '.mp3';
  }

  // Enforce cache size limit by removing oldest files
  Future<void> _enforcesCacheLimit() async {
    final limitMB = await getCacheSizeLimit();

    while (_currentCacheSizeMB > limitMB && _cacheMetadata.isNotEmpty) {
      // Find oldest accessed file
      CacheMetadata? oldest;
      String? oldestKey;

      _cacheMetadata.forEach((key, metadata) {
        if (oldest == null || metadata.lastAccessed.isBefore(oldest!.lastAccessed)) {
          oldest = metadata;
          oldestKey = key;
        }
      });

      if (oldestKey != null && oldest != null) {
        await _removeCachedFile(oldestKey!);
      } else {
        break;
      }
    }
  }

  // Remove a specific cached file
  Future<void> _removeCachedFile(String cacheKey) async {
    final metadata = _cacheMetadata[cacheKey];
    if (metadata == null) return;

    try {
      final file = File('${_cacheDirectory!.path}/${metadata.fileName}');
      if (await file.exists()) {
        await file.delete();
        debugPrint('Removed cached file: ${metadata.fileName}');
      }

      _cacheMetadata.remove(cacheKey);
      await _saveCacheMetadata();
      await _calculateCacheSize();
    } catch (e) {
      debugPrint('Error removing cached file: $e');
    }
  }

  // Clear all cache
  Future<void> clearCache() async {
    if (_cacheDirectory == null || !await _cacheDirectory!.exists()) {
      return;
    }

    try {
      await _cacheDirectory!.delete(recursive: true);
      await _cacheDirectory!.create();

      _cacheMetadata.clear();
      await _saveCacheMetadata();
      _currentCacheSizeMB = 0;

      debugPrint('Cache cleared successfully');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  // Get all cached songs
  List<CacheMetadata> getCachedSongs() {
    return _cacheMetadata.values.toList()
      ..sort((a, b) => b.lastAccessed.compareTo(a.lastAccessed));
  }

  // Remove specific song from cache
  Future<void> removeSongFromCache(String songId) async {
    String? keyToRemove;

    _cacheMetadata.forEach((key, metadata) {
      if (metadata.songId == songId) {
        keyToRemove = key;
      }
    });

    if (keyToRemove != null) {
      await _removeCachedFile(keyToRemove!);
    }
  }
}

// Cache metadata model
class CacheMetadata {
  final String fileName;
  final String originalUrl;
  final String songId;
  final String songTitle;
  final String songArtist;
  final String albumArt;
  final int fileSizeBytes;
  final DateTime cachedAt;
  DateTime lastAccessed;

  CacheMetadata({
    required this.fileName,
    required this.originalUrl,
    required this.songId,
    required this.songTitle,
    required this.songArtist,
    required this.albumArt,
    required this.fileSizeBytes,
    required this.cachedAt,
    required this.lastAccessed,
  });

  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    'originalUrl': originalUrl,
    'songId': songId,
    'songTitle': songTitle,
    'songArtist': songArtist,
    'albumArt': albumArt,
    'fileSizeBytes': fileSizeBytes,
    'cachedAt': cachedAt.toIso8601String(),
    'lastAccessed': lastAccessed.toIso8601String(),
  };

  factory CacheMetadata.fromJson(Map<String, dynamic> json) => CacheMetadata(
    fileName: json['fileName'],
    originalUrl: json['originalUrl'],
    songId: json['songId'],
    songTitle: json['songTitle'],
    songArtist: json['songArtist'],
    albumArt: json['albumArt'] ?? '',
    fileSizeBytes: json['fileSizeBytes'],
    cachedAt: DateTime.parse(json['cachedAt']),
    lastAccessed: DateTime.parse(json['lastAccessed']),
  );

  String get fileSizeFormatted {
    final kb = fileSizeBytes / 1024;
    final mb = kb / 1024;

    if (mb >= 1) {
      return '${mb.toStringAsFixed(2)} MB';
    } else {
      return '${kb.toStringAsFixed(2)} KB';
    }
  }
}

