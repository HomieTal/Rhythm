import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart';
import 'format.dart';

class SaavnAPI {
  Map<String, String> headers = {};
  String baseUrl = 'www.jiosaavn.com';
  String apiStr = '/api.php?_format=json&_marker=0&api_version=4&ctx=web6dot0';
  Map<String, String> endpoints = {
    'homeData': '__call=webapi.getLaunchData',
    'topSearches': '__call=content.getTopSearches',
    'fromToken': '__call=webapi.get',
    'featuredRadio': '__call=webradio.createFeaturedStation',
    'artistRadio': '__call=webradio.createArtistStation',
    'entityRadio': '__call=webradio.createEntityStation',
    'radioSongs': '__call=webradio.getSong',
    'songDetails': '__call=song.getDetails',
    'playlistDetails': '__call=playlist.getDetails',
    'albumDetails': '__call=content.getAlbumDetails',
    'getResults': '__call=search.getResults',
    'albumResults': '__call=search.getAlbumResults',
    'artistResults': '__call=search.getArtistResults',
    'playlistResults': '__call=search.getPlaylistResults',
    'getReco': '__call=reco.getreco',
    'getAlbumReco': '__call=reco.getAlbumReco',
    'artistOtherTopSongs': '__call=search.artistOtherTopSongs',
  };

  Future<Response> getResponse(String params, {bool usev4 = false}) async {
    Uri url;
    String param = params;
    if (!usev4) {
      param.replaceAll('&api_version=4', '');
    }
    url = Uri.parse('https://$baseUrl$apiStr&$param');
    final String languageHeader = 'L=Hindi';
    headers = {
      'cookie': languageHeader,
      'Accept': 'application/json, text/plain, */*',
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36',
    };
    return get(url, headers: headers).onError((error, stackTrace) {
      return Response(
        {
          'status': 'failure',
          'error': error.toString(),
        }.toString(),
        404,
      );
    });
  }

  Future<Map> fetchSongSearchResults({
    required String searchQuery,
    int count = 20,
    int page = 1,
  }) async {
    final String params =
        "p=$page&q=$searchQuery&n=$count&${endpoints['getResults']}";

    try {
      final res = await getResponse(params, usev4: true);
      if (res.statusCode == 200) {
        final Map getMain = json.decode(res.body) as Map;
        final List responseList = getMain['results'] as List;
        return {
          'songs': await formatSongsResponse(responseList, 'song'),
          'error': '',
        };
      } else {
        return {
          'songs': List.empty(),
          'error': res.body,
        };
      }
    } catch (e) {
      log('Error in fetchSongSearchResults: $e');
      return {
        'songs': List.empty(),
        'error': e,
      };
    }
  }

  Future<List<Map>> fetchSearchResults(String searchQuery) async {
    final Map<String, List> result = {};
    final Map<int, String> position = {};
    List searchedAlbumList = [];
    List searchedPlaylistList = [];
    List searchedArtistList = [];
    List searchedTopQueryList = [];

    final String params =
        '__call=autocomplete.get&cc=in&includeMetaTags=1&query=$searchQuery';

    final res = await getResponse(params, usev4: false);
    try {
      if (res.statusCode == 200) {
        final getMain = json.decode(res.body);
        final List albumResponseList = getMain['albums']['data'] as List;
        position[getMain['albums']['position'] as int] = 'Albums';

        final List playlistResponseList = getMain['playlists']['data'] as List;
        position[getMain['playlists']['position'] as int] = 'Playlists';

        final List artistResponseList = getMain['artists']['data'] as List;
        position[getMain['artists']['position'] as int] = 'Artists';

        final List topQuery = getMain['topquery']['data'] as List;

        searchedAlbumList = await formatAlbumResponse(albumResponseList, 'album');
        if (searchedAlbumList.isNotEmpty) {
          result['Albums'] = searchedAlbumList;
        }

        searchedPlaylistList = await formatAlbumResponse(playlistResponseList, 'playlist');
        if (searchedPlaylistList.isNotEmpty) {
          result['Playlists'] = searchedPlaylistList;
        }

        searchedArtistList = await formatAlbumResponse(artistResponseList, 'artist');
        if (searchedArtistList.isNotEmpty) {
          result['Artists'] = searchedArtistList;
        }

        if (topQuery.isNotEmpty) {
          position[getMain['topquery']['position'] as int] = 'Top Result';
          position[getMain['songs']['position'] as int] = 'Songs';

          switch (topQuery[0]['type'] as String) {
            case 'artist':
              searchedTopQueryList = await formatAlbumResponse(topQuery, 'artist');
              break;
            case 'album':
              searchedTopQueryList = await formatAlbumResponse(topQuery, 'album');
              break;
            case 'playlist':
              searchedTopQueryList = await formatAlbumResponse(topQuery, 'playlist');
              break;
            default:
              break;
          }
          if (searchedTopQueryList.isNotEmpty) {
            result['Top Result'] = searchedTopQueryList;
          }
        }
      }
    } catch (e) {
      log('Failed to fetch data - $e');
    }
    return [result, position];
  }

  Future<Map<String, dynamic>> fetchAlbumDetails(String token) async {
    final param = '${endpoints['albumDetails']!}&albumid=$token';
    final response = await getResponse(param, usev4: true);
    if (response.statusCode == 200) {
      final Map getMain = json.decode(response.body) as Map;
      final List songsList = (getMain['songs'] ?? getMain['list']) as List? ?? [];
      final Map albumDetails = getMain;
      final List songs = await formatSongsResponse(songsList, 'song');
      return {
        'albumDetails': albumDetails,
        'songs': songs,
      };
    } else {
      log("Request failed with status: ${response.statusCode}");
      return {
        'albumDetails': {"error": "error"},
        'songs': List.empty(),
      };
    }
  }

  Future<List> getTopSearches() async {
    final response = await get(Uri.parse(
        "https://www.jiosaavn.com/api.php?__call=content.getTopSearches"));
    if (response.statusCode == 200) {
      return json.decode(response.body) as List;
    } else {
      log("Request failed with status: ${response.statusCode}");
      return ["error"];
    }
  }
}

