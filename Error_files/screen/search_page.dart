import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/settings/settings_page.dart';
import '/settings/theme_provider.dart';
import '../songsrepo/Saavn/saavn_api.dart';
import '../service/search_history_service.dart';
import '../service/audio_controller.dart';
import 'package:Rhythm/screen/online_album_page.dart';
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import '../widgets/custom_notification.dart';
import '../widgets/rhythm_dialog.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
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

  // 🔍 Fetch songs from Saavn API with fuzzy matching
  Future<void> fetchSongs({String searchQuery = "Arijit Singh"}) async {
    setState(() {
      loading = true;
      songs = [];
    });

    try {
      final Map result = await api.fetchSongSearchResults(searchQuery: searchQuery);
      final List? fetchedSongs = (result['songs'] is List) ? List.from(result['songs']) : null;

      if (fetchedSongs != null && fetchedSongs.isNotEmpty) {
        // Apply fuzzy matching to improve search relevance
        final scoredSongs = fetchedSongs.map((song) {
          final title = (song['name'] ?? song['title'] ?? '').toString().toLowerCase();
          final artist = (song['primaryArtists'] ?? song['artist'] ?? '').toString().toLowerCase();
          final album = (song['album'] ?? '').toString().toLowerCase();
          final query = searchQuery.toLowerCase();

          // Calculate fuzzy match scores
          final titleScore = ratio(query, title);
          final artistScore = ratio(query, artist);
          final albumScore = ratio(query, album);
          final partialTitleScore = partialRatio(query, title);
          final partialArtistScore = partialRatio(query, artist);

          // Weighted score (title matters most)
          final totalScore = (titleScore * 3) +
                            (artistScore * 2) +
                            (albumScore * 1) +
                            (partialTitleScore * 2) +
                            (partialArtistScore * 1.5);

          return {'song': song, 'score': totalScore};
        }).toList();

        // Sort by score (highest first) and filter low scores
        scoredSongs.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

        // Take top results and extract songs
        setState(() {
          songs = scoredSongs
              .where((item) => (item['score'] as double) > 50) // Filter low relevance
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

  // Fetch structured search results (albums, playlists, artists, songs positions)
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

  // Triggered when user types in search box
  void onSearch(String query) {
    // Online
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
    // Use parent scaffold like home_screen.dart
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

    // Return body content directly without wrapping Scaffold since we're embedded in home_screen
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // 🔹 Top Bar
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
                  // Sync / refresh button
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
                  // Settings button
                  IconButton(
                    icon: Icon(Icons.settings, color: iconColor),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsPage()),
                      );
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

  Widget _buildAlbumsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_searchController.text.isEmpty) return _buildSearchHistory();
    if (loading) return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    if (searchedAlbums.isEmpty) return Center(child: Text('No albums found', style: TextStyle(color: Colors.grey)));
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => OnlineAlbumPage(token: token.toString())),
            );
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
                            child: Icon(Icons.album_rounded, color: Colors.white70, size: 36),
                          ),
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey,
                          child: Icon(Icons.album_rounded, color: Colors.white70, size: 36),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        artist.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
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

  Widget _buildSongsTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_searchController.text.isEmpty) return _buildSearchHistory();
    if (loading) return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
    if (songs.isEmpty) return Center(child: Text('No songs found', style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        final textColor = isDark ? Colors.white : Colors.black;
        final subtitleColor = isDark ? Colors.grey : Colors.grey.shade700;

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              song['image'] ?? song['imageUrl'] ?? '',
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.music_note, color: isDark ? Colors.white : Colors.grey),
            ),
          ),
          title: Text(
            song['name'] ?? song['title'] ?? 'Unknown Song',
            style: TextStyle(color: textColor, fontSize: 16),
          ),
          subtitle: Text(
            song['primaryArtists'] ?? song['artist'] ?? 'Unknown Artist',
            style: TextStyle(color: subtitleColor),
          ),
          onTap: () async {
            // Close the keyboard
            FocusScope.of(context).unfocus();

            // Try to get a playable URL from the API response
            String? uri;
            if (song is Map) {
              uri = song['url'] as String? ?? song['perma_url'] as String?;
              // fallback to downloadUrl list if present
              if ((uri == null || uri.isEmpty) && song['downloadUrl'] != null && song['downloadUrl'] is List && (song['downloadUrl'] as List).isNotEmpty) {
                try {
                  final dl = (song['downloadUrl'] as List).last;
                  if (dl is Map && dl['url'] != null) uri = dl['url'] as String;
                } catch (_) {}
              }
            }

            if (uri == null || uri.isEmpty) {
              CustomNotification.show(
                context,
                message: 'No playable URL for this track',
                icon: Icons.error_outline,
                color: Colors.orange,
              );
              return;
            }

            final audioCtrl = AudioController.instance;

            // Helper to normalize URIs into playable absolute URLs
            String normalizeUri(String raw) {
              String u = raw.trim();
              if (u.startsWith('//')) u = 'https:$u';
              if (u.startsWith('http:')) u = u.replaceFirst('http:', 'https:');
              if (!u.startsWith('http')) {
                if (u.startsWith('www.')) u = 'https://$u';
                else if (u.contains('.') && !u.contains(' ')) u = 'https://$u';
              }
              try {
                final parsed = Uri.tryParse(u);
                if (parsed == null || parsed.scheme.isEmpty) u = Uri.encodeFull(u);
              } catch (_) {
                u = Uri.encodeFull(u);
              }
              return u;
            }

            final title = (song['name'] ?? song['title'] ?? 'Unknown Song').toString();
            final artist = (song['primaryArtists'] ?? song['artist'] ?? 'Unknown Artist').toString();
            final image = (song['image'] ?? song['imageUrl'] ?? '') as String? ?? '';

            // Normalize URI to a playable absolute https/http URL
            final normalizedUri = normalizeUri(uri);

            debugPrint('Attempting to play online track: title="$title", uri="$normalizedUri"');

            // Play the song directly with metadata for mini player
            final bool ok = await audioCtrl.playOnlineUrl(
              normalizedUri,
              title: title,
              artist: artist,
              imageUrl: image,
              duration: (song['duration'] is int) ? song['duration'] as int : 0,
            );
            if (!ok) {
              debugPrint('Failed to play URI: $normalizedUri');
              if (context.mounted) {
                CustomNotification.show(
                  context,
                  message: 'Playback failed',
                  icon: Icons.error_outline,
                  color: Colors.red,
                );
              }
            } else {
              // Add to search history
              SearchHistoryService().addSearchedSong({
                'title': title,
                'artist': artist,
                'image': image,
                'uri': normalizedUri,
                'duration': (song['duration'] is int) ? song['duration'] as int : 0,
              });
            }
          },
        );
      },
    );
  }

  // 🎵 Search History Section
  Widget _buildSearchHistory() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return ValueListenableBuilder(
      valueListenable: SearchHistoryService().searchHistory,
      builder: (context, searchHistory, _) {
        if (searchHistory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_rounded,
                  size: 64,
                  color: Colors.grey.withAlpha((0.3 * 255).round()),
                ),
                const SizedBox(height: 16),
                Text(
                  'No search history',
                  style: TextStyle(
                    color: Colors.grey.withAlpha((0.6 * 255).round()),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Songs you search and play will appear here',
                  style: TextStyle(
                    color: Colors.grey.withAlpha((0.4 * 255).round()),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Search History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      showRhythmDialog(
                        context: context,
                        glassy: true,
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Clear Search History?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'This will clear all your searched songs.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withAlpha((0.7 * 255).round()),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha((0.6 * 255).round()),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      SearchHistoryService().clearHistory();
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                    child: const Text(
                                      'Clear',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    child: Text(
                      'Clear',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: searchHistory.length,
                itemBuilder: (context, index) {
                  final song = searchHistory[index];
                  final title = song['title'] ?? 'Unknown Song';
                  final artist = song['artist'] ?? 'Unknown Artist';
                  final image = song['image'] ?? '';

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha((0.2 * 255).round()),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: image.isNotEmpty
                            ? Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.music_note_rounded,
                                  color: primaryColor,
                                  size: 24,
                                ),
                              )
                            : Icon(
                                Icons.music_note_rounded,
                                color: primaryColor,
                                size: 24,
                              ),
                      ),
                    ),
                    title: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                    trailing: Icon(
                      Icons.play_circle_outline_rounded,
                      color: primaryColor,
                      size: 28,
                    ),
                    onTap: () async {
                      final uri = song['uri'] ?? '';
                      if (uri.isEmpty) return;

                      final audioCtrl = AudioController.instance;

                      // Play the song directly with metadata for mini player
                      final bool ok = await audioCtrl.playOnlineUrl(
                        uri,
                        title: title,
                        artist: artist,
                        imageUrl: image,
                        duration: (song['duration'] is int) ? song['duration'] as int : 0,
                      );

                      if (!ok && mounted) {
                        CustomNotification.show(
                          context,
                          message: 'Playback failed',
                          icon: Icons.error_outline,
                          color: Colors.red,
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

