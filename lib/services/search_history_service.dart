import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchHistoryService {
  static final SearchHistoryService _instance = SearchHistoryService._internal();
  factory SearchHistoryService() => _instance;
  SearchHistoryService._internal();

  static const String _key = 'search_history';
  static const int _maxItems = 20; // Keep last 20 searched songs

  final ValueNotifier<List<Map<String, dynamic>>> searchHistory = ValueNotifier([]);

  Future<void> initialize() async {
    await _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_key);

      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        searchHistory.value = List<Map<String, dynamic>>.from(jsonList);
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
      searchHistory.value = [];
    }
  }

  Future<void> addSearchedSong(Map<String, dynamic> song) async {
    try {
      // Remove if already exists (to move to top)
      final updatedList = searchHistory.value.where((s) {
        // Compare by title and artist for online songs
        return !(s['title'] == song['title'] && s['artist'] == song['artist']);
      }).toList();

      // Add to beginning
      updatedList.insert(0, song);

      // Limit to max items
      if (updatedList.length > _maxItems) {
        updatedList.removeRange(_maxItems, updatedList.length);
      }

      searchHistory.value = updatedList;

      // Save to SharedPreferences
      await _saveSearchHistory();
    } catch (e) {
      debugPrint('Error adding song to search history: $e');
    }
  }

  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, json.encode(searchHistory.value));
    } catch (e) {
      debugPrint('Error saving search history: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      searchHistory.value = [];
    } catch (e) {
      debugPrint('Error clearing search history: $e');
    }
  }

  List<Map<String, dynamic>> getSearchHistory() {
    return searchHistory.value;
  }
}

