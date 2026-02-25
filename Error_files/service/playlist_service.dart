import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class PlaylistService {
  PlaylistService._();
  static final PlaylistService instance = PlaylistService._();

  // Each album is stored as a map with token as key
  final Map<String, Map<String, dynamic>> _albums = {};
  final Map<String, List<dynamic>> _albumSongs = {};
  // Notifier to allow UI to react when online albums change
  final ValueNotifier<int> albumsVersion = ValueNotifier<int>(0);

  Future<void> loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final albumsJson = prefs.getString('online_albums');
    final songsJson = prefs.getString('online_album_songs');
    if (albumsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(albumsJson);
      _albums.clear();
      decoded.forEach((k, v) {
        _albums[k] = Map<String, dynamic>.from(v);
      });
    }
    if (songsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(songsJson);
      _albumSongs.clear();
      decoded.forEach((k, v) {
        _albumSongs[k] = List<dynamic>.from(v);
      });
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('online_albums', jsonEncode(_albums));
    await prefs.setString('online_album_songs', jsonEncode(_albumSongs));
    // bump version so listeners refresh
    albumsVersion.value++;
  }

  // Add album and its songs to playlist
  void addAlbumToPlaylist(String token, Map albumDetails, List songs) {
    _albums[token] = Map<String, dynamic>.from(albumDetails);
    _albumSongs[token] = List.from(songs);
    _saveToStorage();
  }

  // Remove album from playlist
  void removeAlbumFromPlaylist(String token) {
    _albums.remove(token);
    _albumSongs.remove(token);
    _saveToStorage();
  }

  // Check if album is in playlist
  bool isAlbumInPlaylist(String token) {
    return _albums.containsKey(token);
  }

  // Get all albums in playlist
  List<Map<String, dynamic>> getAlbums() {
    return _albums.values.toList();
  }

  // Get songs for an album
  List<dynamic> getSongsForAlbum(String token) {
    return _albumSongs[token] ?? [];
  }
}
