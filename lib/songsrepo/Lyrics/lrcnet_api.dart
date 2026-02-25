import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:rhythm/model/lyrics_models.dart';

const String lrcURL = "https://lrclib.net/";
const String lrcSearch = "api/search";
const String lrcGet = "api/get";
const Duration apiTimeout = Duration(seconds: 10);

// Main function for LRCNetAPI
Future<Lyrics> getLRCNetAPILyrics(
  String title, {
  String? artist,
  String? album,
  String? duration,
  String? id,
}) async {
  Lyrics lyrics;
  if (id != null) {
    lyrics = await getLRCNetLyricsById(id);
  } else {
    try {
      // Try to get by title and artist
      lyrics = await searchSingleLRCNetLyrics(
        title,
        artistName: artist ?? '',
        albumName: album ?? '',
      );
    } catch (e) {
      log('Error searching LRC: $e', name: "LRCNetAPI");
      // Return empty lyrics on error
      lyrics = Lyrics(
        id: '0',
        artist: artist ?? 'Unknown',
        title: title,
        lyricsPlain: '',
        provider: LyricsProvider.lrcnet,
      );
    }
  }
  return lyrics;
}

Future<Lyrics> getLRCNetLyricsById(String id) async {
  log("LRCLibNet by ID: $id", name: "LRCNetAPI");

  try {
    final response = await http.get(Uri.parse("$lrcURL$lrcGet/$id")).timeout(
      apiTimeout,
      onTimeout: () {
        log("Request timed out after ${apiTimeout.inSeconds}s", name: "LRCNetAPI");
        throw const HttpException("Request timed out");
      },
    );

    log("Response status: ${response.statusCode}", name: "LRCNetAPI");

    if (response.statusCode == 200) {
      final responseUTF = utf8.decode(response.bodyBytes);
      final data = json.decode(responseUTF);

      return Lyrics(
        artist: data['artistName'] ?? 'Unknown Artist',
        title: data['trackName'] ?? 'Unknown Title',
        lyricsPlain: data['plainLyrics'] ?? '',
        lyricsSynced: data["syncedLyrics"],
        id: data['id']?.toString() ?? '0',
        album: data['albumName'],
        duration: data['duration']?.toString() ?? '0',
        provider: LyricsProvider.lrcnet,
      );
    } else {
      log("HTTP Error ${response.statusCode}: ${response.body}", name: "LRCNetAPI");
      throw HttpException("Failed to get lyrics: HTTP ${response.statusCode}");
    }
  } catch (e) {
    log("Exception during fetch by ID: $e", name: "LRCNetAPI");
    rethrow;
  }
}

Future<Lyrics> searchSingleLRCNetLyrics(
  String title, {
  String artistName = '',
  String albumName = '',
}) async {
  log("LRCLibNet search: title='$title', artist='$artistName', album='$albumName'", name: "LRCNetAPI");

  final encodedTitle = Uri.encodeComponent(title);
  final encodedArtist = Uri.encodeComponent(artistName);
  final encodedAlbum = Uri.encodeComponent(albumName);

  String url = "$lrcURL$lrcSearch?track_name=$encodedTitle";
  if (artistName.isNotEmpty) url += "&artist_name=$encodedArtist";
  if (albumName.isNotEmpty) url += "&album_name=$encodedAlbum";

  log("API URL: $url", name: "LRCNetAPI");

  try {
    final response = await http.get(Uri.parse(url)).timeout(
      apiTimeout,
      onTimeout: () {
        log("Request timed out after ${apiTimeout.inSeconds}s", name: "LRCNetAPI");
        throw const HttpException("Request timed out");
      },
    );

    log("Response status: ${response.statusCode}", name: "LRCNetAPI");

    if (response.statusCode == 200) {
      final responseUTF = utf8.decode(response.bodyBytes);
      final data = json.decode(responseUTF);

      if (data is List && data.isNotEmpty) {
        final firstResult = data[0];
        return Lyrics(
          artist: firstResult['artistName'] ?? 'Unknown Artist',
          title: firstResult['trackName'] ?? 'Unknown Title',
          lyricsPlain: firstResult['plainLyrics'] ?? '',
          lyricsSynced: firstResult["syncedLyrics"],
          id: firstResult['id']?.toString() ?? '0',
          album: firstResult['albumName'],
          duration: firstResult['duration']?.toString() ?? '0',
          provider: LyricsProvider.lrcnet,
        );
      } else {
        log("No lyrics found for: $title", name: "LRCNetAPI");
        return Lyrics(
          id: '0',
          artist: artistName,
          title: title,
          lyricsPlain: '',
          provider: LyricsProvider.lrcnet,
        );
      }
    } else {
      log("HTTP Error ${response.statusCode}", name: "LRCNetAPI");
      throw HttpException("Failed to search lyrics: HTTP ${response.statusCode}");
    }
  } catch (e) {
    log("Exception during search: $e", name: "LRCNetAPI");
    rethrow;
  }
}

Future<List<Lyrics>> searchLRCNetLyrics(
  String title, {
  String artistName = '',
  String albumName = '',
}) async {
  log("LRCLibNet list search: title='$title', artist='$artistName', album='$albumName'", name: "LRCNetAPI");

  final encodedTitle = Uri.encodeComponent(title);
  final encodedArtist = Uri.encodeComponent(artistName);
  final encodedAlbum = Uri.encodeComponent(albumName);

  String url = "$lrcURL$lrcSearch?track_name=$encodedTitle";
  if (artistName.isNotEmpty) url += "&artist_name=$encodedArtist";
  if (albumName.isNotEmpty) url += "&album_name=$encodedAlbum";

  log("API URL: $url", name: "LRCNetAPI");

  try {
    final response = await http.get(Uri.parse(url)).timeout(
      apiTimeout,
      onTimeout: () {
        log("Request timed out after ${apiTimeout.inSeconds}s", name: "LRCNetAPI");
        throw const HttpException("Request timed out");
      },
    );

    log("Response status: ${response.statusCode}", name: "LRCNetAPI");

    if (response.statusCode == 200) {
      final responseUTF = utf8.decode(response.bodyBytes);
      final data = json.decode(responseUTF);

      if (data is List) {
        return data.map((item) {
          return Lyrics(
            artist: item['artistName'] ?? 'Unknown Artist',
            title: item['trackName'] ?? 'Unknown Title',
            lyricsPlain: item['plainLyrics'] ?? '',
            lyricsSynced: item["syncedLyrics"],
            id: item['id']?.toString() ?? '0',
            album: item['albumName'],
            duration: item['duration']?.toString() ?? '0',
            provider: LyricsProvider.lrcnet,
          );
        }).toList();
      } else {
        log("Unexpected response format", name: "LRCNetAPI");
        return [];
      }
    } else {
      log("HTTP Error ${response.statusCode}", name: "LRCNetAPI");
      throw HttpException("Failed to search lyrics: HTTP ${response.statusCode}");
    }
  } catch (e) {
    log("Exception during list search: $e", name: "LRCNetAPI");
    return [];
  }
}

