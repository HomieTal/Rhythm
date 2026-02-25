import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:rhythm/model/local_song_model.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal() {
    // Auto-load favorites when service is first created
    loadFavorites();
  }

  final ValueNotifier<List<LocalSongModel>> favorites = ValueNotifier([]);
  bool _isLoaded = false;

  // Load favorites from storage
  Future<void> loadFavorites() async {
    if (_isLoaded) return; // Prevent multiple loads

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString('favorites');

      if (favoritesJson != null && favoritesJson.isNotEmpty) {
        final List<dynamic> decoded = json.decode(favoritesJson);
        favorites.value = decoded
            .map((item) => LocalSongModel.fromJson(item))
            .toList();
      } else {
        favorites.value = [];
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      favorites.value = [];
      _isLoaded = true;
    }
  }

  // Save favorites to storage
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = json.encode(
        favorites.value.map((song) => song.toJson()).toList(),
      );
      await prefs.setString('favorites', encoded);
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(LocalSongModel song) async {
    final index = favorites.value.indexWhere((s) => s.id == song.id);

    if (index != -1) {
      // Remove from favorites
      favorites.value = List.from(favorites.value)..removeAt(index);
    } else {
      // Add to favorites
      favorites.value = List.from(favorites.value)..add(song);
    }

    await _saveFavorites();
  }

  // Check if song is favorite
  bool isFavorite(int songId) {
    return favorites.value.any((song) => song.id == songId);
  }

  // Get favorites count
  int get favoritesCount => favorites.value.length;
}
