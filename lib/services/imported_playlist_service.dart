import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:rhythm/model/playlist_model.dart';

class ImportedPlaylistService {
  static final ImportedPlaylistService _instance =
      ImportedPlaylistService._internal();

  factory ImportedPlaylistService() => _instance;
  ImportedPlaylistService._internal() {
    loadImportedPlaylists();
  }

  final ValueNotifier<List<PlaylistModel>> importedPlaylists =
      ValueNotifier([]);
  bool _isLoaded = false;

  // Load imported playlists from storage
  Future<void> loadImportedPlaylists() async {
    if (_isLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? playlistsJson = prefs.getString('imported_playlists');

      if (playlistsJson != null && playlistsJson.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(playlistsJson);
        importedPlaylists.value = decoded
            .map((item) => PlaylistModel.fromJson(item))
            .toList();
      } else {
        importedPlaylists.value = [];
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading imported playlists: $e');
      importedPlaylists.value = [];
      _isLoaded = true;
    }
  }

  // Save imported playlists to storage
  Future<void> _savePlaylists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(
        importedPlaylists.value.map((playlist) => playlist.toJson()).toList(),
      );
      await prefs.setString('imported_playlists', encoded);
    } catch (e) {
      debugPrint('Error saving imported playlists: $e');
    }
  }

  // Add a new imported playlist
  Future<void> addImportedPlaylist(PlaylistModel playlist) async {
    importedPlaylists.value = List.from(importedPlaylists.value)..add(playlist);
    await _savePlaylists();
  }

  // Add multiple imported playlists
  Future<void> addImportedPlaylists(List<PlaylistModel> playlists) async {
    importedPlaylists.value = List.from(importedPlaylists.value)..addAll(playlists);
    await _savePlaylists();
  }

  // Delete imported playlist
  Future<void> deleteImportedPlaylist(String playlistName) async {
    importedPlaylists.value = List.from(importedPlaylists.value)
      ..removeWhere((p) => p.name == playlistName);
    await _savePlaylists();
  }

  // Get all imported playlists
  List<PlaylistModel> getImportedPlaylists() {
    return importedPlaylists.value;
  }

  // Get imported playlist by name
  PlaylistModel? getImportedPlaylistByName(String name) {
    try {
      return importedPlaylists.value.firstWhere((p) => p.name == name);
    } catch (e) {
      return null;
    }
  }

  // Update imported playlist songs
  Future<void> updatePlaylistSongs(String playlistName, List<String> songIds) async {
    final index = importedPlaylists.value.indexWhere((p) => p.name == playlistName);
    if (index != -1) {
      final playlist = importedPlaylists.value[index];
      importedPlaylists.value = List.from(importedPlaylists.value);
      importedPlaylists.value[index] = PlaylistModel(
        name: playlist.name,
        createdAt: playlist.createdAt,
        songIds: songIds,
      );
      await _savePlaylists();
    }
  }

  // Clear all imported playlists
  Future<void> clearAllImportedPlaylists() async {
    importedPlaylists.value = [];
    await _savePlaylists();
  }

  // Get count of imported playlists
  int get importedPlaylistsCount => importedPlaylists.value.length;
}
