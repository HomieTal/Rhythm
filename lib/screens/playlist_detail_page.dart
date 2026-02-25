import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rhythm/services/audio_controller.dart';
import 'package:rhythm/services/imported_playlist_service.dart';
import 'package:rhythm/model/local_song_model.dart';
import 'package:rhythm/widgets/custom_notification.dart';

class PlaylistDetailPage extends StatefulWidget {
  final String playlistId;
  final String playlistName;

  const PlaylistDetailPage({super.key, required this.playlistId, required this.playlistName});

  @override
  State<PlaylistDetailPage> createState() => _PlaylistDetailPageState();
}

class _PlaylistDetailPageState extends State<PlaylistDetailPage> {
  final AudioController _audioController = AudioController.instance;
  final ImportedPlaylistService _importedPlaylistService = ImportedPlaylistService();
  List<String> _songUris = [];
  List<String> _songIds = [];
  bool _loading = true;
  bool _isImportedPlaylist = false;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    setState(() => _loading = true);

    // First check if it's an imported playlist
    final importedPlaylist = _importedPlaylistService.getImportedPlaylistByName(widget.playlistName);

    if (importedPlaylist != null) {
      setState(() {
        _isImportedPlaylist = true;
        _songIds = importedPlaylist.songIds;
      });
    } else {
      setState(() {
        _isImportedPlaylist = false;
      });
      await _loadLocalPlaylist();
    }

    setState(() => _loading = false);
  }

  Future<void> _loadLocalPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = prefs.getString('custom_playlists');
    if (playlistsJson != null) {
      final List<dynamic> decoded = jsonDecode(playlistsJson);
      final list = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      final entry = list.firstWhere((p) => p['id'] == widget.playlistId, orElse: () => {});
      if (entry.isNotEmpty) {
        final songs = (entry['songs'] as List).map((e) => e.toString()).toList();
        setState(() {
          _songUris = songs;
        });
      }
    }
  }

  Future<void> _savePlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = prefs.getString('custom_playlists');
    List<dynamic> list = [];
    if (playlistsJson != null) {
      list = jsonDecode(playlistsJson);
    }
    final idx = list.indexWhere((p) => p['id'] == widget.playlistId);
    if (idx != -1) {
      list[idx]['songs'] = _songUris;
    } else {
      list.add({'id': widget.playlistId, 'name': widget.playlistName, 'songs': _songUris, 'createdAt': DateTime.now().toIso8601String()});
    }
    await prefs.setString('custom_playlists', jsonEncode(list));
  }

  Future<void> _addSongsFromPicker() async {
    final songs = _audioController.songs.value;
    final selected = <String>{};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withAlpha((0.3 * 255).round()), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 12),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Add Songs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: songs.length,
                    itemBuilder: (context, idx) {
                      final s = songs[idx];
                      final isSelected = selected.contains(s.uri);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (v) {
                          setModalState(() {
                            if (v == true) selected.add(s.uri); else selected.remove(s.uri);
                          });
                        },
                        title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(s.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (selected.isNotEmpty) {
                            setState(() {
                              _songUris.addAll(selected.where((u) => !_songUris.contains(u)));
                            });
                            await _savePlaylist();
                            Navigator.pop(context);
                            if (mounted) CustomNotification.show(context, message: 'Added ${selected.length} songs', icon: Icons.playlist_add, color: Theme.of(context).primaryColor);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('ADD'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Future<void> _removeSongAt(int index) async {
    if (index < 0 || index >= _songUris.length) return;
    setState(() {
      _songUris.removeAt(index);
    });
    await _savePlaylist();
  }

  List<LocalSongModel> _getPlaylistSongs() {
    final allSongs = _audioController.songs.value;
    if (_isImportedPlaylist) {
      return _songIds
          .map((id) => allSongs.firstWhere(
                (s) => s.id.toString() == id,
                orElse: () => LocalSongModel(id: 0, title: 'Unknown', artist: 'Unknown', uri: '', albumArt: '', duration: 0),
              ))
          .where((s) => s.id != 0)
          .toList();
    } else {
      return _songUris
          .map((uri) => allSongs.firstWhere(
                (s) => s.uri == uri,
                orElse: () => LocalSongModel(id: 0, title: 'Unknown', artist: 'Unknown', uri: '', albumArt: '', duration: 0),
              ))
          .where((s) => s.id != 0)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).primaryColor;

    final playlistSongs = _getPlaylistSongs();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.arrow_back, color: textColor, size: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.playlistName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${playlistSongs.length} ${playlistSongs.length == 1 ? 'song' : 'songs'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white.withAlpha((0.6 * 255).round())
                                : Colors.black.withAlpha((0.6 * 255).round()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isImportedPlaylist)
                    IconButton(
                      icon: Icon(Icons.add, color: primaryColor),
                      onPressed: _addSongsFromPicker,
                    ),
                ],
              ),
            ),

            // Songs List
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    )
                  : playlistSongs.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.playlist_play_rounded,
                                size: 80,
                                color: isDark
                                    ? Colors.white.withAlpha((0.3 * 255).round())
                                    : Colors.black.withAlpha((0.3 * 255).round()),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'No songs in this playlist',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white.withAlpha((0.6 * 255).round())
                                      : Colors.black.withAlpha((0.6 * 255).round()),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (!_isImportedPlaylist)
                                ElevatedButton.icon(
                                  onPressed: _addSongsFromPicker,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Songs'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewPadding.bottom + 100,
                          ),
                          itemCount: playlistSongs.length,
                          itemBuilder: (context, index) {
                            final song = playlistSongs[index];
                            return _buildSongTile(song, index);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSongTile(LocalSongModel song, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Dismissible(
      key: Key(song.uri),
      direction: _isImportedPlaylist ? DismissDirection.none : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _removeSongAt(index);
        CustomNotification.show(
          context,
          message: 'Song removed from playlist',
          icon: Icons.delete,
          color: Colors.red,
        );
      },
      child: InkWell(
        onTap: () async {
          await _audioController.playFromPlaylist(song, playlist: _getPlaylistSongs());
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // Artwork
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: QueryArtworkWidget(
                    id: song.id,
                    type: ArtworkType.AUDIO,
                    artworkFit: BoxFit.cover,
                    nullArtworkWidget: Container(
                      color: Theme.of(context).primaryColor.withAlpha((0.2 * 255).round()),
                      child: Icon(
                        Icons.music_note,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Title and Artist
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Play icon
              Icon(
                Icons.play_circle_outline,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
