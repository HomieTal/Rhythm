import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:Rhythm/service/audio_controller.dart';
import 'package:Rhythm/screen/player_screen.dart';

class ArtistsPage extends StatefulWidget {
  const ArtistsPage({super.key});

  @override
  State<ArtistsPage> createState() => _ArtistsPageState();
}

class _ArtistsPageState extends State<ArtistsPage> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioController _audioController = AudioController.instance;
  List<ArtistModel> _artists = [];
  bool _isLoading = true;
  String _sortBy = 'A-Z';

  @override
  void initState() {
    super.initState();
    _loadArtists();
    _ensureSongsLoaded();
  }

  Future<void> _ensureSongsLoaded() async {
    if (_audioController.songs.value.isEmpty) {
      debugPrint('🔄 Loading songs in AudioController...');
      await _audioController.loadSongs();
    }
  }

  Future<void> _loadArtists() async {
    setState(() => _isLoading = true);

    try {
      final artists = await _audioQuery.queryArtists(
        sortType: ArtistSortType.ARTIST,
        orderType: OrderType.ASC_OR_SMALLER,
      );

      if (mounted) {
        setState(() {
          _artists = artists;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading artists: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<ArtistModel> _getSortedArtists() {
    final artists = List<ArtistModel>.from(_artists);

    switch (_sortBy) {
      case 'A-Z':
        artists.sort((a, b) {
          final aName = a.artist;
          final bName = b.artist;
          return aName.toLowerCase().compareTo(bName.toLowerCase());
        });
        break;
      case 'Z-A':
        artists.sort((a, b) {
          final aName = a.artist;
          final bName = b.artist;
          return bName.toLowerCase().compareTo(aName.toLowerCase());
        });
        break;
      case 'Most Songs':
        artists.sort((a, b) {
          final aTracks = a.numberOfTracks ?? 0;
          final bTracks = b.numberOfTracks ?? 0;
          return bTracks.compareTo(aTracks);
        });
        break;
      case 'Recent':
        artists.sort((a, b) => b.id.compareTo(a.id));
        break;
    }

    return artists;
  }

  void _showSortOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                    ? Colors.white.withAlpha((0.3 * 255).round())
                    : Colors.black.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ...['A-Z', 'Z-A', 'Most Songs', 'Recent'].map((option) {
                return ListTile(
                  leading: Icon(
                    _sortBy == option ? Icons.check_circle : Icons.circle_outlined,
                    color: _sortBy == option
                      ? Theme.of(context).primaryColor
                      : (isDark ? Colors.white70 : Colors.black54),
                  ),
                  title: Text(
                    option,
                    style: TextStyle(
                      color: _sortBy == option
                        ? Theme.of(context).primaryColor
                        : (isDark ? Colors.white : Colors.black87),
                      fontWeight: _sortBy == option ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    setState(() => _sortBy = option);
                    Navigator.pop(context);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final sortedArtists = _getSortedArtists();

    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter/Sort Bar
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withAlpha((0.05 * 255).round())
                      : Colors.black.withAlpha((0.05 * 255).round()),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withAlpha((0.1 * 255).round())
                        : Colors.black.withAlpha((0.1 * 255).round()),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_rounded,
                            size: 20,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${sortedArtists.length} Artists',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: _showSortOptions,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Row(
                                children: [
                                  Text(
                                    _sortBy,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.sort_rounded,
                                    size: 20,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Artists Grid or Empty State
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : sortedArtists.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFF00bcd4).withAlpha((0.2 * 255).round()),
                                      const Color(0xFF0097a7).withAlpha((0.2 * 255).round()),
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 72,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'No Artists Yet',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Your artist collection will appear here',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.white38 : Colors.black38,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: sortedArtists.length,
                          itemBuilder: (context, index) {
                            final artist = sortedArtists[index];
                            return _buildArtistCard(artist);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistCard(ArtistModel artist) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () async {
        // Get all songs from audio controller
        final allSongs = _audioController.songs.value;

        // Filter songs where artist name appears anywhere in the artist field
        // This will include songs where they are primary artist or co-singer
        final artistName = artist.artist.toLowerCase();
        final artistSongs = allSongs.where((song) {
          final songArtist = song.artist.toLowerCase();
          return songArtist.contains(artistName);
        }).toList();

        debugPrint('🎤 Artist: ${artist.artist}');
        debugPrint('🎵 Found ${artistSongs.length} songs containing artist name');

        if (artistSongs.isNotEmpty && mounted) {
          // Play the first song from this artist
          final firstSongIndex = allSongs.indexWhere(
            (s) => s.id == artistSongs.first.id,
          );

          if (firstSongIndex != -1) {
            await _audioController.playSong(firstSongIndex);
            debugPrint('▶️ Playing: ${artistSongs.first.title}');

            // Navigate to player screen
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerScreen(
                    song: artistSongs.first,
                    index: firstSongIndex,
                  ),
                ),
              );
            }
          }
        } else {
          debugPrint('❌ No songs found for ${artist.artist}');
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withAlpha((0.05 * 255).round())
              : Colors.black.withAlpha((0.05 * 255).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withAlpha((0.1 * 255).round())
                : Colors.black.withAlpha((0.1 * 255).round()),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Artist Artwork (circular)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor.withAlpha((0.1 * 255).round()),
              ),
              child: ClipOval(
                child: QueryArtworkWidget(
                  id: artist.id,
                  type: ArtworkType.ARTIST,
                  artworkWidth: 120,
                  artworkHeight: 120,
                  artworkFit: BoxFit.cover,
                  nullArtworkWidget: Container(
                    color: Theme.of(context).primaryColor.withAlpha((0.2 * 255).round()),
                    child: Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 60,
                        color: Theme.of(context).primaryColor.withAlpha((0.5 * 255).round()),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Artist Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Text(
                    artist.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${artist.numberOfTracks ?? 0} ${(artist.numberOfTracks ?? 0) == 1 ? 'song' : 'songs'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}