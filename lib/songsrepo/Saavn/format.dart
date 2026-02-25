import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:dart_des/dart_des.dart';
import 'package:rhythm/utils/extentions.dart';

String getImageUrl(String? imageUrl, {String quality = 'high'}) {
  if (imageUrl == null) return '';
  switch (quality) {
    case 'high':
      return imageUrl
          .trim()
          .replaceAll('http:', 'https:')
          .replaceAll('50x50', '500x500')
          .replaceAll('150x150', '500x500');
    case 'medium':
      return imageUrl
          .trim()
          .replaceAll('http:', 'https:')
          .replaceAll('50x50', '150x150')
          .replaceAll('500x500', '150x150');
    case 'low':
      return imageUrl
          .trim()
          .replaceAll('http:', 'https:')
          .replaceAll('150x150', '50x50')
          .replaceAll('500x500', '50x50');
    default:
      return imageUrl
          .trim()
          .replaceAll('http:', 'https:')
          .replaceAll('50x50', '500x500')
          .replaceAll('150x150', '500x500');
  }
}

String decode(String input) {
  const String key = '38346591';
  final DES desECB = DES(key: key.codeUnits);

  final Uint8List encrypted = base64.decode(input);
  final List<int> decrypted = desECB.decrypt(encrypted);
  final String decoded = utf8
      .decode(decrypted)
      .replaceAll(RegExp(r'\.mp4.*'), '.mp4')
      .replaceAll(RegExp(r'\.m4a.*'), '.m4a');
  return decoded.replaceAll('http:', 'https:');
}

Future<List> formatSongsResponse(List responseList, String type) async {
  final List searchedList = [];
  for (int i = 0; i < responseList.length; i++) {
    Map? response;
    switch (type) {
      case 'song':
      case 'album':
      case 'playlist':
      case 'show':
      case 'mix':
        response = await formatSingleSongResponse(responseList[i] as Map);
        break;
      default:
        break;
    }

    if (response != null && response.containsKey('Error')) {
      log('Error at index $i inside FormatSongsResponse: ${response["Error"]}', name: "Format");
    } else {
      if (response != null) {
        searchedList.add(response);
      }
    }
  }
  return searchedList;
}

Future<Map> formatSingleSongResponse(Map response) async {
  try {
    String artists;
    if (response['more_info']?['music'] != null && response['more_info']?['music'] != "") {
      artists = response['more_info']['music'].toString().unescape();
    } else if (response['more_info']?['artistMap']?["primary_artists"] != null) {
      List<String> artistList = [];
      response['more_info']?['artistMap']?["primary_artists"].forEach((element) {
        artistList.add(element['name'].toString().unescape());
      });
      artists = artistList.join(', ');
    } else {
      artists = response['subtitle'].toString().unescape();
    }

    return {
      'id': response['id'],
      'type': response['type'],
      'album': response['album']?.toString().unescape() ?? response['more_info']?['album']?.toString().unescape(),
      'year': response['year'],
      'duration': response['duration'] ?? response['more_info']?['duration'],
      'language': response['language'].toString().capitalize(),
      'genre': response['language'].toString().capitalize(),
      '320kbps': response['320kbps'] ?? response['more_info']?['320kbps'],
      'has_lyrics': response['has_lyrics'] ?? response['more_info']?['has_lyrics'],
      'lyrics_snippet': response['lyrics_snippet']?.toString().unescape() ?? response['more_info']?['lyrics_snippet']?.toString().unescape(),
      'release_date': response['release_date'] ?? response['more_info']?['release_date'],
      'album_id': response['more_info']?['artistMap']?['artists'] != null
          ? (response['more_info']?['artistMap']?['artists'] as List).map((e) => e['id']).toList()
          : ['albumId'],
      'title': response['song']?.toString().unescape() ?? response['title']?.toString().unescape(),
      'artist': artists,
      'image': getImageUrl(response['image'].toString()),
      'perma_url': response['perma_url'],
      'url': (response['encrypted_media_url']?.toString() ?? response['more_info']?['encrypted_media_url']?.toString()) != null
          ? decode((response['encrypted_media_url']?.toString() ?? response['more_info']?['encrypted_media_url']?.toString()) ?? '')
          : null,
    };
  } catch (e) {
    log('Error inside FormatSingleSongResponse: $e', name: "Format");
    return {'Error': e};
  }
}

Future<List<Map>> formatAlbumResponse(List responseList, String type) async {
  final List<Map> searchedAlbumList = [];
  for (int i = 0; i < responseList.length; i++) {
    Map? response;
    switch (type) {
      case 'albumSearched':
        response = await formatSearchedAlbumResponse(responseList[i] as Map);
        break;
      case 'album':
        response = await formatSingleAlbumResponse(responseList[i] as Map);
        break;
      case 'artist':
        response = await formatSingleArtistResponse(responseList[i] as Map);
        break;
      case 'playlist':
        response = await formatSinglePlaylistResponse(responseList[i] as Map);
        break;
    }
    if (response != null && response.containsKey('Error')) {
      log('Error at index $i inside FormatAlbumResponse: ${response["Error"]}', name: "Format");
    } else if (response != null) {
      searchedAlbumList.add(response);
    }
  }
  return searchedAlbumList;
}

Future<Map> formatSearchedAlbumResponse(Map response) async {
  try {
    String? artists;
    if (response['music'] != null) {
      artists = response['music'];
    }
    if (response['subtitle'] != null) {
      artists = response['subtitle'];
    } else {
      List<String> artistList = [];
      if (response['more_info']?['artistMap']?["artists"] != null) {
        response['more_info']?['artistMap']?["artists"].forEach((element) {
          artistList.add(element['name']);
        });
      }
      artists = artistList.join(', ');
    }
    return {
      'id': response['id'] ?? response['albumid'],
      'type': response['type'] ?? "album",
      'album': response['title'].toString().unescape(),
      'year': response['more_info']?['year'] ?? response['year'],
      'language': response['more_info']?['language'] == null
          ? response['language'].toString().capitalize()
          : response['more_info']['language'].toString().capitalize(),
      'title': response['title'].toString().unescape(),
      'artist': artists?.unescape() ?? response['primary_artists'],
      'image': getImageUrl(response['image'].toString()),
      'token': Uri.parse(response['perma_url'] ?? response['url'].toString()).pathSegments.last,
      'perma_url': response['perma_url'] ?? response['url'].toString(),
    };
  } catch (e) {
    log('Error inside formatSearchedAlbumResponse: $e', name: "Format");
    return {'Error': e};
  }
}

Future<Map> formatSingleAlbumResponse(Map response) async {
  try {
    return {
      'id': response['id'] ?? response['albumid'],
      'type': response['type'] ?? "album",
      'album': response['title'].toString().unescape(),
      'year': response['more_info']?['year'] ?? response['year'],
      'title': response['title'].toString().unescape(),
      'artist': response['music']?.toString().unescape() ?? response['more_info']?['music']?.toString().unescape() ?? '',
      'image': getImageUrl(response['image'].toString()),
      'perma_url': response['perma_url'] ?? response['url'].toString(),
    };
  } catch (e) {
    log('Error inside formatSingleAlbumResponse: $e', name: "Format");
    return {'Error': e};
  }
}

Future<Map> formatSinglePlaylistResponse(Map response) async {
  try {
    return {
      'id': response['id'] ?? response['listid'],
      'type': response['type'] ?? "playlist",
      'album': response['title'].toString().unescape(),
      'playlistId': response['listid']?.toString() ?? response['id'],
      'title': response['title']?.toString().unescape() ?? response['listname'].toString().unescape(),
      'artist': response['artist_name']?.join(', ')?.toString().unescape() ?? response['extra']?.toString().unescape(),
      'image': getImageUrl(response['image'].toString()),
      'perma_url': response['perma_url']?.toString().unescape() ?? response['url'].toString(),
    };
  } catch (e) {
    log('Error inside formatSinglePlaylistResponse: $e', name: "Format");
    return {'Error': e};
  }
}

Future<Map> formatSingleArtistResponse(Map response) async {
  try {
    return {
      'id': response['id'] ?? response['artistId'],
      'type': response['type'],
      'album': response['title'] == null ? response['name'].toString().unescape() : response['title'].toString().unescape(),
      'title': response['name']?.toString().unescape() ?? response['title'].toString().unescape(),
      'image': getImageUrl(response['image'].toString()),
      'perma_url': response['perma_url']?.toString() ?? response['url']?.toString(),
    };
  } catch (e) {
    log('Error inside formatSingleArtistResponse: $e', name: "Format");
    return {'Error': e};
  }
}

