import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fuzzywuzzy/fuzzywuzzy.dart' as fw;
import '../../model/lyrics_models.dart';

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
      // Only call getLRCNetLyrics if we have all required parameters
      if (artist != null && artist.isNotEmpty &&
          album != null && album.isNotEmpty &&
          duration != null && duration.isNotEmpty) {
        lyrics = await getLRCNetLyrics(title, artist, album, duration);

        if (lyrics.lyricsSynced == null) {
          final temp = await searchSingleLRCNetLyrics(title, artist: artist, album: album);
          final ratio = fw.ratio(
              '${lyrics.title} ${lyrics.artist} ${lyrics.album}',
              '${temp.title} ${temp.artist} ${temp.album}');
          if (ratio <= 90) {
            lyrics = temp;
          }
        }
      } else {
        // If we don't have complete metadata, go straight to search
        log('Missing metadata, using search: title=$title, artist=$artist, album=$album', name: "LRCNetAPI");
        lyrics = await searchSingleLRCNetLyrics(title, artist: artist ?? '', album: album ?? '');
      }
    } catch (e) {
      log('Error in direct fetch: $e, falling back to search', name: "LRCNetAPI");
      lyrics = await searchSingleLRCNetLyrics(title, artist: artist ?? '', album: album ?? '');
    }
  }
  return lyrics;
}

Future<Lyrics> getLRCNetLyricsById(String id) async {
// [IN]
// Field	    Required	Type	  Description
// id	        true	    number	ID of the lyrics record

// [OUT]
// {
//   "id": 3396226,
//   "trackName": "I Want to Live",
//   "artistName": "Borislav Slavov",
//   "albumName": "Baldur's Gate 3 (Original Game Soundtrack)",
//   "duration": 233,
//   "instrumental": false,
//   "plainLyrics": "I feel your breath upon my neck\n...The clock won't stop and this is what we get\n",
//   "syncedLyrics": "[00:17.12] I feel your breath upon my neck\n...[03:20.31] The clock won't stop and this is what we get\n[03:25.72] "
// }

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
      // decode json object response body to map
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
          provider: LyricsProvider.lrcnet);
    } else {
      log("HTTP Error ${response.statusCode}: ${response.body}", name: "LRCNetAPI");
      throw HttpException("Failed to get lyrics: HTTP ${response.statusCode}");
    }
  } catch (e) {
    log("Exception during fetch by ID: $e", name: "LRCNetAPI");
    rethrow;
  }
}

Future<Lyrics> getLRCNetLyrics(
    String title, String artist, String album, String duration) async {
// [IN]
// Field	      Required	Type	  Description
// track_name	  true	    string	Title of the track
// artist_name	true	    string	Name of the artist
// album_name	  true	    string	Name of the album
// duration	    true	    number	Track's duration in seconds

// [OUT]
// {
//   "id": 3396226,
//   "trackName": "I Want to Live",
//   "artistName": "Borislav Slavov",
//   "albumName": "Baldur's Gate 3 (Original Game Soundtrack)",
//   "duration": 233,
//   "instrumental": false,
//   "plainLyrics": "I feel your breath upon my neck\n...The clock won't stop and this is what we get\n",
//   "syncedLyrics": "[00:17.12] I feel your breath upon my neck\n...[03:20.31] The clock won't stop and this is what we get\n[03:25.72] "
// }

  log("LRCLibNet by Title/GET: title='$title', artist='$artist', album='$album', duration='$duration'", name: "LRCNetAPI");

  // URL encode parameters
  final encodedTitle = Uri.encodeComponent(title);
  final encodedArtist = Uri.encodeComponent(artist);
  final encodedAlbum = Uri.encodeComponent(album);

  final url = "$lrcURL$lrcGet?track_name=$encodedTitle&artist_name=$encodedArtist&album_name=$encodedAlbum&duration=$duration";

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
      // decode json object response body to map
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
          provider: LyricsProvider.lrcnet);
    } else {
      log("HTTP Error ${response.statusCode}: ${response.body}", name: "LRCNetAPI");
      throw HttpException("Failed to get lyrics: HTTP ${response.statusCode}");
    }
  } catch (e) {
    log("Exception during direct fetch: $e", name: "LRCNetAPI");
    rethrow;
  }
}

Future<List<Lyrics>> searchLRCNetLyrics(
  String q, {
  String? trackName,
  String? artistName,
  String? albumName,
}) async {
// [IN]
//   Field	    Required	    Type	  Description
//    q	        conditional	  string	Search for keyword present in ANY fields (track's title, artist name or album name)
// track_name	  conditional	  string	Search for keyword in track's title
// artist_name	false	        string	Search for keyword in track's artist name
// album_name	  false	        string	Search for keyword in track's album name

// [OUT]
// JSON array of the lyrics records with the following parameters:
// id, trackName, artistName, albumName, duration, instrumental,
// plainLyrics and syncedLyrics.

  log("LRCLibNet by Search: q='$q', track='$trackName', artist='$artistName', album='$albumName'", name: "LRCNetAPI");

  // Build query string properly
  String queryString = q;
  if (artistName != null && artistName.isNotEmpty) {
    queryString += ' $artistName';
  }
  if (albumName != null && albumName.isNotEmpty) {
    queryString += ' $albumName';
  }

  // URL encode the query
  final encodedQuery = Uri.encodeComponent(queryString.trim());

  // Build additional fields
  final fields = <String>[];
  if (trackName != null && trackName.isNotEmpty) {
    fields.add("track_name=${Uri.encodeComponent(trackName)}");
  }
  if (artistName != null && artistName.isNotEmpty) {
    fields.add("artist_name=${Uri.encodeComponent(artistName)}");
  }

  final fieldsString = fields.isNotEmpty ? '&${fields.join('&')}' : '';
  final url = "$lrcURL$lrcSearch?q=$encodedQuery$fieldsString";

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
      // decode json object response body to map
      final resUTF = utf8.decode(response.bodyBytes);
      final data = json.decode(resUTF);

      if (data is List) {
        log("Found ${data.length} results", name: "LRCNetAPI");

        return List<Lyrics>.from(data.map((lyrics) => Lyrics(
            artist: lyrics['artistName'] ?? 'Unknown Artist',
            title: lyrics['trackName'] ?? 'Unknown Title',
            lyricsPlain: lyrics['plainLyrics'] ?? "No Lyrics Found!",
            lyricsSynced: lyrics["syncedLyrics"],
            id: lyrics['id']?.toString() ?? '0',
            album: lyrics['albumName'],
            duration: lyrics['duration']?.toString() ?? '0',
            provider: LyricsProvider.lrcnet)));
      } else {
        log("Unexpected response format: $data", name: "LRCNetAPI");
        return [];
      }
    } else {
      log("HTTP Error ${response.statusCode}: ${response.body}", name: "LRCNetAPI");
      throw HttpException("Failed to get lyrics: HTTP ${response.statusCode}");
    }
  } catch (e) {
    log("Exception during search: $e", name: "LRCNetAPI");
    rethrow;
  }
}

Future<Lyrics> searchSingleLRCNetLyrics(
  String q, {
  String? track,
  String? artist,
  String? album,
}) async {
  log("LRCLibNet by Search Single: q='$q', artist='$artist', album='$album'", name: "LRCNetAPI");

  // Clean up empty strings
  final cleanArtist = (artist != null && artist.isNotEmpty) ? artist : null;
  final cleanAlbum = (album != null && album.isNotEmpty) ? album : null;

  Lyrics lyrics;
  Lyrics? synced;
  final List<Lyrics> lyricsList =
      await searchLRCNetLyrics(q, artistName: cleanArtist, albumName: cleanAlbum);

  if (lyricsList.isEmpty) {
    log("No lyrics found for: $q", name: "LRCNetAPI");
    throw const HttpException("No lyrics found");
  }

  log("Found ${lyricsList.length} results", name: "LRCNetAPI");

  // Build query for fuzzy matching
  String query = q;
  if (cleanArtist != null) query += ' $cleanArtist';
  if (cleanAlbum != null) query += ' $cleanAlbum';

  // Find synced lyrics if available
  final List<Lyrics> syncedList =
      lyricsList.where((element) => element.lyricsSynced != null).toList();

  if (syncedList.isNotEmpty) {
    log("Found ${syncedList.length} synced lyrics", name: "LRCNetAPI");
    try {
      final result = fw.extractOne(
        query: query,
        choices: syncedList.map((e) {
          return '${e.title} ${e.artist} ${e.album ?? ''}';
        }).toList(),
      );
      synced = syncedList[result.index];
      log('Best synced match (score: ${result.score}): ${synced.title} - ${synced.artist}', name: "LRCNetAPI");
    } catch (e) {
      log('Error finding synced match: $e', name: "LRCNetAPI");
    }
  }

  // Find best overall match
  try {
    final result = fw.extractOne(
      query: query,
      choices: lyricsList.map((e) {
        return '${e.title} ${e.artist} ${e.album ?? ''}';
      }).toList(),
    );
    lyrics = lyricsList[result.index];
    log('Best overall match (score: ${result.score}): ${lyrics.title} - ${lyrics.artist}', name: "LRCNetAPI");
  } catch (e) {
    log('Error finding best match, using first result: $e', name: "LRCNetAPI");
    lyrics = lyricsList.first;
  }

  // Prefer synced lyrics if similarity is good
  if (synced != null) {
    try {
      final ratio = fw.ratio(
        '${synced.title} ${synced.artist} ${synced.album ?? ''}',
        '${lyrics.title} ${lyrics.artist} ${lyrics.album ?? ''}',
      );
      log("Similarity ratio: $ratio", name: "LRCNetAPI");
      if (ratio >= 80) {
        lyrics = synced;
        log("Using synced lyrics", name: "LRCNetAPI");
      }
    } catch (e) {
      log('Error calculating ratio: $e', name: "LRCNetAPI");
    }
  }

  return lyrics;
}
