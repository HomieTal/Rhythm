import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

/// Safe wrapper for on_audio_query to handle "Reply already submitted" crashes
class SafeAudioQuery {
  static final OnAudioQuery _audioQuery = OnAudioQuery();

  /// Safely query songs with retry logic and error handling
  static Future<List<SongModel>> querySongs({
    SongSortType? sortType,
    OrderType? orderType,
    UriType? uriType,
    bool? ignoreCase,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        debugPrint('🔍 Querying songs... (Attempt ${retryCount + 1}/$maxRetries)');

        // Add delay between retries to avoid race conditions
        if (retryCount > 0) {
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        }

        final songs = await _audioQuery.querySongs(
          sortType: sortType,
          orderType: orderType ?? OrderType.ASC_OR_SMALLER,
          uriType: uriType ?? UriType.EXTERNAL,
          ignoreCase: ignoreCase ?? true,
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('⏱️ Query songs timeout');
            return [];
          },
        );

        debugPrint('✅ Successfully queried ${songs.length} songs');
        return songs;

      } catch (e, stackTrace) {
        retryCount++;
        debugPrint('❌ Error querying songs (Attempt $retryCount/$maxRetries): $e');

        // Check if it's the "Reply already submitted" error
        if (e.toString().contains('Reply already submitted') ||
            e.toString().contains('IllegalStateException') ||
            e.toString().contains('PlatformException')) {
          debugPrint('🔧 Detected on_audio_query plugin error, retrying...');

          if (retryCount >= maxRetries) {
            debugPrint('❌ Max retries reached, returning empty list');
            return [];
          }

          // Wait longer before retry for this specific error
          await Future.delayed(Duration(seconds: 1 * retryCount));
          continue;
        }

        // For other errors, log and return empty list
        debugPrint('❌ Non-retryable error: $e');
        debugPrint('Stack trace: $stackTrace');
        return [];
      }
    }

    return [];
  }

  /// Get the underlying OnAudioQuery instance for direct access
  static OnAudioQuery get instance => _audioQuery;
}

