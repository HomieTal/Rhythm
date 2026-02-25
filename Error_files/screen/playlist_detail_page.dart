import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../service/audio_controller.dart';
import '../service/imported_playlist_service.dart';
import '../model/local_song_model.dart';
import '../widgets/bottom_mini_player.dart';
import '../widgets/custom_notification.dart';

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
  List<String> _songUris = []; // stored as URIs for local songs
  List<String> _songIds = []; // stored as IDs for online songs
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
      // It's an imported playlist - use song IDs
      setState(() {
        _isImportedPlaylist = true;
        _songIds = importedPlaylist.songIds;
      });
    } else {
      // It's a custom local playlist
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
      // if not found, add new
      list.add({'id': widget.playlistId, 'name': widget.playlistName, 'songs': _songUris, 'createdAt': DateTime.now().toIso8601String()});
    }
    await prefs.setString('custom_playlists', jsonEncode(list));
  }

  Future<void> _addSongsFromPicker() async {
    // Present a modal with available songs from audioController.songs
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

  Future<void> _showAddToPlaylistDialog(String uri) async {
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = prefs.getString('custom_playlists');
    List<dynamic> list = [];
    if (playlistsJson != null) list = jsonDecode(playlistsJson);

    // Map to simple items
    final items = list.map((e) => Map<String, dynamic>.from(e)).toList();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 12), decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(4))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('Add to Playlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
              const SizedBox(height: 8),
              if (items.isEmpty) Padding(padding: const EdgeInsets.all(16), child: Text('No playlists available', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)))
              else ...items.map((pl) {
                return ListTile(
                  title: Text(pl['name'] ?? 'Playlist'),
                  onTap: () async {
                    // add uri to selected playlist if not exists
                    final prefs2 = await SharedPreferences.getInstance();
                    final pj = prefs2.getString('custom_playlists');
                    List<dynamic> l2 = pj != null ? jsonDecode(pj) : [];
                    final idx = l2.indexWhere((p) => (p['id'] ?? '') == (pl['id'] ?? ''));
                    if (idx != -1) {
                      final songsList = List<String>.from((l2[idx]['songs'] ?? []).map((e) => e.toString()));
                      if (!songsList.contains(uri)) {
                        songsList.add(uri);
                        l2[idx]['songs'] = songsList;
                        await prefs2.setString('custom_playlists', jsonEncode(l2));
                        if (mounted) CustomNotification.show(context, message: 'Added to "${l2[idx]['name']}"', icon: Icons.playlist_add, color: Theme.of(context).primaryColor);
                      } else {
                        if (mounted) CustomNotification.show(context, message: 'Song already in "${l2[idx]['name']}"', icon: Icons.info_outline, color: Colors.orange);
                      }
                    }
                    Navigator.pop(context);
                  },
                );
              }).toList(),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _playPlaylist({int startIndex = 0, bool shuffle = false}) async {
    // Build playlist from URIs mapping to LocalSongModel(s) if available in audioController.songs
    final allKnown = _audioController.songs.value;
    final playlist = <LocalSongModel>[];
    for (final uri in _songUris) {
      final found = allKnown.firstWhere((s) => s.uri == uri, orElse: () => LocalSongModel(id: DateTime.now().millisecondsSinceEpoch, title: uri, artist: '', uri: uri, albumArt: '', duration: 0));
      playlist.add(found);
    }

    if (playlist.isEmpty) {
      if (mounted) CustomNotification.show(context, message: 'No playable songs in this playlist', icon: Icons.error_outline, color: Colors.orange);
      return;
    }

    final playListToUse = List<LocalSongModel>.from(playlist);
    int indexToPlay = startIndex.clamp(0, playListToUse.length - 1);
    if (shuffle) {
      playListToUse.shuffle();
      indexToPlay = 0;
    }

    await _audioController.playFromPlaylist(playListToUse[indexToPlay], playlist: playListToUse);
    if (mounted) CustomNotification.show(context, message: 'Playing "${widget.playlistName}"', icon: Icons.play_arrow, color: Theme.of(context).primaryColor);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: BackButton(color: textColor),
        title: Text(widget.playlistName, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(onPressed: () => _playPlaylist(shuffle: true), icon: Icon(Icons.shuffle, color: primary)),
          IconButton(onPressed: () => _playPlaylist(startIndex: 0), icon: Icon(Icons.play_arrow, color: primary)),
          IconButton(onPressed: _addSongsFromPicker, icon: Icon(Icons.playlist_add, color: primary)),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _songUris.isEmpty
                    ? Center(child: Text('No songs in this playlist', style: TextStyle(color: subtitleColor)))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 140),
                        itemCount: _songUris.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final uri = _songUris[idx];
                          final found = _audioController.songs.value.firstWhere((s) => s.uri == uri, orElse: () => LocalSongModel(id: DateTime.now().millisecondsSinceEpoch, title: uri, artist: '', uri: uri, albumArt: '', duration: 0));
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: (() {
                                var artwork = found.albumArt;
                                if (artwork.startsWith('//')) artwork = 'https:$artwork';
                                if (artwork.isNotEmpty && (artwork.startsWith('http') || artwork.startsWith('https'))) {
                                  return Image.network(artwork, width: 52, height: 52, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 52, height: 52, color: primary, child: Icon(Icons.music_note, color: Colors.white)));
                                }
                                // fallback to device artwork via QueryArtworkWidget when available
                                return QueryArtworkWidget(
                                  id: found.id,
                                  type: ArtworkType.AUDIO,
                                  artworkWidth: 52,
                                  artworkHeight: 52,
                                  artworkFit: BoxFit.cover,
                                  nullArtworkWidget: Container(width: 52, height: 52, color: primary, child: Icon(Icons.music_note, color: Colors.white)),
                                );
                              })(),
                            ),
                            title: Text(found.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor)),
                            subtitle: Text(found.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: subtitleColor)),
                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: isDark ? Colors.white70 : Colors.black54, size: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              onSelected: (value) async {
                                if (value == 'play') {
                                  await _playPlaylist(startIndex: idx);
                                } else if (value == 'add') {
                                  await _showAddToPlaylistDialog(uri);
                                } else if (value == 'remove') {
                                  await _removeSongAt(idx);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'play',
                                  child: Row(children: [Icon(Icons.play_arrow, size: 18), SizedBox(width: 8), Text('Play')]),
                                ),
                                PopupMenuItem(
                                  value: 'add',
                                  child: Row(children: [Icon(Icons.playlist_add, size: 18), SizedBox(width: 8), Text('Add to Playlist')]),
                                ),
                                PopupMenuItem(
                                  value: 'remove',
                                  child: Row(children: [Icon(Icons.delete_outline, color: Colors.red, size: 18), SizedBox(width: 8), Text('Remove', style: TextStyle(color: Colors.red))]),
                                ),
                              ],
                            ),
                            onTap: () => _playPlaylist(startIndex: idx),
                          );
                        },
                      ),
          ),
          const BottomMiniPlayer(),
        ],
      ),
    );
  }
}
