import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../model/local_song_model.dart';

class RecentlyPlayedService {
  static final RecentlyPlayedService _instance = RecentlyPlayedService._internal();
  factory RecentlyPlayedService() => _instance;
  RecentlyPlayedService._internal();

  static const String _key = 'recently_played_songs';
  static const String _autoClearKey = 'history_auto_clear_period';
  static const String _lastClearKey = 'history_last_clear_date';

  final ValueNotifier<List<LocalSongModel>> recentlyPlayed = ValueNotifier([]);

  Future<void> initialize() async {
    await _loadRecentlyPlayed();
    await _checkAndClearIfNeeded();
  }

  /// Check if history should be auto-cleared based on user settings
  Future<void> _checkAndClearIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoClearPeriod = prefs.getString(_autoClearKey) ?? 'never';

      if (autoClearPeriod == 'never') return;

      final lastClearTimestamp = prefs.getInt(_lastClearKey) ?? 0;
      final lastClearDate = DateTime.fromMillisecondsSinceEpoch(lastClearTimestamp);
      final now = DateTime.now();

      bool shouldClear = false;

      switch (autoClearPeriod) {
        case '1day':
          shouldClear = now.difference(lastClearDate).inDays >= 1;
          break;
        case '1week':
          shouldClear = now.difference(lastClearDate).inDays >= 7;
          break;
        case '1month':
          shouldClear = now.difference(lastClearDate).inDays >= 30;
          break;
        case '3months':
          shouldClear = now.difference(lastClearDate).inDays >= 90;
          break;
      }

      if (shouldClear) {
        await clearHistory();
        await prefs.setInt(_lastClearKey, now.millisecondsSinceEpoch);
        debugPrint('✅ History auto-cleared based on $autoClearPeriod setting');
      }
    } catch (e) {
      debugPrint('Error checking auto-clear: $e');
    }
  }

  /// Get the current auto-clear period setting
  Future<String> getAutoClearPeriod() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_autoClearKey) ?? 'never';
    } catch (e) {
      debugPrint('Error getting auto-clear period: $e');
      return 'never';
    }
  }

  /// Set the auto-clear period
  Future<void> setAutoClearPeriod(String period) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_autoClearKey, period);

      // Set the last clear date to now when changing the setting
      await prefs.setInt(_lastClearKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint('✅ Auto-clear period set to: $period');
    } catch (e) {
      debugPrint('Error setting auto-clear period: $e');
    }
  }

  Future<void> _loadRecentlyPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        final songs = jsonList.map((json) => LocalSongModel.fromJson(json)).toList();
        recentlyPlayed.value = songs;
      }
    } catch (e) {
      debugPrint('Error loading recently played: $e');
      recentlyPlayed.value = [];
    }
  }

  Future<void> addSong(LocalSongModel song) async {
    try {
      // Remove if already exists (to move to top)
      final updatedList = recentlyPlayed.value.where((s) => s.id != song.id).toList();

      // Add to beginning
      updatedList.insert(0, song);

      // No limit - keep all history
      recentlyPlayed.value = updatedList;

      // Save to SharedPreferences
      await _saveRecentlyPlayed();
    } catch (e) {
      debugPrint('Error adding song to recently played: $e');
    }
  }

  /// Remove a song by its id from recently played and persist the change.
  Future<void> removeSongById(int id) async {
    try {
      final updated = recentlyPlayed.value.where((s) => s.id != id).toList();
      recentlyPlayed.value = updated;
      await _saveRecentlyPlayed();
    } catch (e) {
      debugPrint('Error removing song from recently played: $e');
    }
  }

  /// Remove a song at a specific index in the recently played list.
  Future<void> removeSongAt(int index) async {
    try {
      final list = List<LocalSongModel>.from(recentlyPlayed.value);
      if (index >= 0 && index < list.length) {
        list.removeAt(index);
        recentlyPlayed.value = list;
        await _saveRecentlyPlayed();
      }
    } catch (e) {
      debugPrint('Error removing song at index from recently played: $e');
    }
  }

  Future<void> _saveRecentlyPlayed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = recentlyPlayed.value.map((song) => song.toJson()).toList();
      await prefs.setString(_key, json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving recently played: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      recentlyPlayed.value = [];
    } catch (e) {
      debugPrint('Error clearing recently played: $e');
    }
  }

  List<LocalSongModel> getRecentlyPlayed() {
    return recentlyPlayed.value;
  }
}

