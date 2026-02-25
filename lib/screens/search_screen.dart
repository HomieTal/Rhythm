import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rhythm/settings/settings_page.dart';
import 'package:rhythm/settings/theme_provider.dart';
import 'package:rhythm/songsrepo/Saavn/saavn_api.dart';
import 'package:rhythm/services/audio_controller.dart';
import 'package:rhythm/model/local_song_model.dart';
import 'package:rhythm/widgets/custom_notification.dart';
import 'package:rhythm/screens/online_album_page.dart';
import 'package:rhythm/utils/page_transitions.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final SaavnAPI api = SaavnAPI();

  List songs = [];
  bool loading = false;
  List<Map> searchedAlbums = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> fetchSongs({String searchQuery = "Arijit Singh"}) async {
    setState(() {
      loading = true;
      songs = [];
    });

    try {
      final Map result = await api.fetchSongSearchResults(searchQuery: searchQuery);
      final List? fetchedSongs = (result['songs'] is List) ? List.from(result['songs']) : null;

      if (fetchedSongs != null && fetchedSongs.isNotEmpty) {
        final scoredSongs = fetchedSongs.map((song) {
          final title = (song['name'] ?? song['title'] ?? '').toString().toLowerCase();
          final artist = (song['primaryArtists'] ?? song['artist'] ?? '').toString().toLowerCase();
          final album = (song['album'] ?? '').toString().toLowerCase();
          final query = searchQuery.toLowerCase();

          final titleScore = ratio(query, title);
          final artistScore = ratio(query, artist);
          final albumScore = ratio(query, album);
          final partialTitleScore = partialRatio(query, title);
          final partialArtistScore = partialRatio(query, artist);

          final totalScore = (titleScore * 3) +
                            (artistScore * 2) +
                            (albumScore * 1) +
                            (partialTitleScore * 2) +
                            (partialArtistScore * 1.5);

          return {'song': song, 'score': totalScore};
        }).toList();

        scoredSongs.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

        setState(() {
          songs = scoredSongs
              .where((item) => (item['score'] as double) > 50)
              .map((item) => item['song'])
              .toList();
          loading = false;
        });
      } else {
        setState(() {
          songs = [];
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        songs = [];
      });
      debugPrint("Error fetching songs: $e");
    }
  }

  Future<void> fetchStructuredSearch(String query) async {
    try {
      final res = await api.fetchSearchResults(query);
      if (res.isNotEmpty) {
        final resultMap = res[0];
        setState(() {
          searchedAlbums = (resultMap['Albums'] != null && resultMap['Albums'] is List)
              ? List<Map>.from(resultMap['Albums'])
              : [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching structured search: $e');
      setState(() {
        searchedAlbums = [];
      });
    }
  }

  void onSearch(String query) {
    if (query.isNotEmpty) {
      fetchSongs(searchQuery: query);
      fetchStructuredSearch(query);
    } else {
      setState(() {
        songs = [];
        searchedAlbums = [];
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      songs = [];
      searchedAlbums = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : Colors.black;
    final iconColor = isDark ? Colors.white : primaryColor;
    final hintColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final useBottomNav = themeProvider.useBottomNav;

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (useBottomNav)
                    IconButton(
                      icon: Icon(Icons.menu, color: iconColor),
                      onPressed: () => scaffold?.openDrawer(),
                    ),
                  if (useBottomNav) const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: onSearch,
                        style: TextStyle(color: textColor),
                        cursorColor: primaryColor,
                        decoration: InputDecoration(
                          hintText: 'Search songs, artists...',
                          hintStyle: TextStyle(color: hintColor),
                          prefixIcon: IconButton(
                            icon: Icon(Icons.close, color: hintColor),
                            onPressed: _clearSearch,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.sync, color: iconColor),
                    onPressed: () async {
                      final q = _searchController.text.trim();
                      if (q.isNotEmpty) {
                        await fetchSongs(searchQuery: q);
                        await fetchStructuredSearch(q);
                      } else {
                        await fetchSongs();
                        await fetchStructuredSearch('');
                      }
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: iconColor),
                    onPressed: () {
                      context.pushWithFadeSlide(const SettingsPage());
                    },
                  ),
                ],
              ),
            ),
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: primaryColor,
              unselectedLabelColor: hintColor,
              indicatorColor: primaryColor,
              tabs: const [
                Tab(text: 'Songs'),
                Tab(text: 'Albums'),
              ],
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSongsTab(),
                  _buildAlbumsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey.withAlpha((0.3 * 255).round())),
            const SizedBox(height: 16),
            Text(
              'Search for songs',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (loading) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (songs.isEmpty) {
      return const Center(child: Text('No songs found', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: songs.length,
      itemBuilder: (context, idx) {
        final song = songs[idx];
        final image = song['image'] ?? '';
        final title = song['title'] ?? song['name'] ?? 'Unknown';
        final artist = song['artist'] ?? song['primaryArtists'] ?? '';

        return InkWell(
          onTap: () => _playSong(song),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: image.toString().isNotEmpty
                      ? Image.network(
                          image.toString(),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 56,
                            height: 56,
                            color: Colors.grey,
                            child: const Icon(Icons.music_note, color: Colors.white70),
                          ),
                        )
                      : Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey,
                          child: const Icon(Icons.music_note, color: Colors.white70),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.play_circle_fill, color: primaryColor, size: 36),
                  onPressed: () => _playSong(song),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlbumsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.album, size: 80, color: Colors.grey.withAlpha((0.3 * 255).round())),
            const SizedBox(height: 16),
            Text(
              'Search for albums',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (loading) {
      return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    }

    if (searchedAlbums.isEmpty) {
      return const Center(child: Text('No albums found', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: searchedAlbums.length,
      itemBuilder: (context, idx) {
        final album = searchedAlbums[idx];
        final image = album['image'] ?? '';
        final title = album['title'] ?? album['album'] ?? 'Album';
        final artist = album['artist'] ?? '';
        final token = album['token'] ?? album['album_id'] ?? album['id'];

        return InkWell(
          onTap: () {
            context.pushWithFadeSlide(OnlineAlbumPage(token: token.toString()));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
            ),
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: image.toString().isNotEmpty
                    ? Image.network(
                        image.toString(),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey,
                          child: const Icon(Icons.album_rounded, color: Colors.white70, size: 36),
                        ),
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey,
                        child: const Icon(Icons.album_rounded, color: Colors.white70, size: 36),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  void _playSong(dynamic song) async {
    final title = song['title'] ?? song['name'] ?? 'Unknown';
    final artist = song['artist'] ?? song['primaryArtists'] ?? 'Unknown Artist';
    final imageUrl = song['image'] ?? '';
    final url = _getDownloadUrl(song);

    if (url.isEmpty) {
      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Unable to play song: Invalid URL',
          icon: Icons.error_outline_rounded,
          color: Colors.red,
        );
      }
      return;
    }

    try {
      final audioCtrl = AudioController.instance;
      final int baseId = DateTime.now().millisecondsSinceEpoch;

      final LocalSongModel currentSong = LocalSongModel(
        id: -baseId,
        title: title,
        artist: artist,
        uri: url,
        albumArt: imageUrl,
        duration: 0,
      );

      final existing = audioCtrl.songs.value;
      int existingIndex = -1;

      for (int i = 0; i < existing.length; i++) {
        if (existing[i].uri == url) {
          existingIndex = i;
          break;
        }
      }

      if (existingIndex != -1) {
        await audioCtrl.playSong(existingIndex);
      } else {
        final updated = List<LocalSongModel>.from(existing)..add(currentSong);
        audioCtrl.songs.value = updated;
        final newIndex = updated.length - 1;
        await audioCtrl.playSong(newIndex);
      }

      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Now playing: $title',
          icon: Icons.play_circle_filled_rounded,
          color: Theme.of(context).primaryColor,
        );
      }
    } catch (e) {
      debugPrint('❌ Error playing song: $e');
      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Error playing song',
          icon: Icons.error_outline_rounded,
          color: Colors.red,
        );
      }
    }
  }

  String _getDownloadUrl(dynamic song) {
    if (song['downloadUrl'] != null) {
      if (song['downloadUrl'] is List && (song['downloadUrl'] as List).isNotEmpty) {
        final downloads = song['downloadUrl'] as List;
        final lastItem = downloads.last;
        if (lastItem is Map && lastItem['url'] != null) {
          return lastItem['url'].toString();
        }
      } else if (song['downloadUrl'] is String) {
        return song['downloadUrl'].toString();
      }
    }
    if (song['url'] != null) return song['url'].toString();
    if (song['media_url'] != null) return song['media_url'].toString();
    return '';
  }
}

