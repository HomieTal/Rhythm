import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../model/local_song_model.dart';
import '../widgets/rhythm_dialog.dart';
import '../widgets/custom_notification.dart';

class PlaylistHelper {
  /// Show dialog to add song to playlist
  static Future<void> showAddToPlaylistDialog(
    BuildContext context,
    LocalSongModel song,
  ) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    // Load existing playlists
    final prefs = await SharedPreferences.getInstance();
    final playlistsJson = prefs.getString('playlists') ?? '[]';
    final List<dynamic> playlistList = json.decode(playlistsJson);

    if (!context.mounted) return;

    showRhythmDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.playlist_add_rounded,
                      color: primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add to Playlist',
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  song.title,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                if (playlistList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No playlists yet. Create one first!',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                else
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlistList.length,
                      itemBuilder: (context, index) {
                        final playlist = playlistList[index];
                        final playlistName = playlist['name'] ?? 'Playlist';
                        final songIds = List<String>.from(playlist['songIds'] ?? []);
                        final isAdded = songIds.contains(song.id.toString());

                        return ListTile(
                          leading: Icon(
                            Icons.queue_music_rounded,
                            color: primaryColor,
                          ),
                          title: Text(
                            playlistName,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            '${songIds.length} songs',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          trailing: isAdded
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : null,
                          onTap: isAdded
                              ? null
                              : () async {
                                  // Add song to this playlist
                                  songIds.add(song.id.toString());
                                  playlist['songIds'] = songIds;
                                  await prefs.setString(
                                      'playlists', json.encode(playlistList));

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    CustomNotification.show(
                                      context,
                                      message: 'Added to "$playlistName"',
                                      icon: Icons.check_circle,
                                      color: Colors.green,
                                    );
                                  }
                                },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _showCreatePlaylistDialog(context);
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('New Playlist'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Show dialog to create new playlist
  static Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final TextEditingController nameController = TextEditingController();

    showRhythmDialog(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.playlist_play_rounded,
                  color: primaryColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  'Create Playlist',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              autofocus: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Playlist name',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withAlpha((0.05 * 255).round())
                    : Colors.black.withAlpha((0.05 * 255).round()),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    // Create new playlist
                    final prefs = await SharedPreferences.getInstance();
                    final playlistsJson = prefs.getString('playlists') ?? '[]';
                    final List<dynamic> playlistList = json.decode(playlistsJson);

                    playlistList.add({
                      'name': name,
                      'createdAt': DateTime.now().toIso8601String(),
                      'songIds': <String>[],
                    });

                    await prefs.setString('playlists', json.encode(playlistList));

                    if (context.mounted) {
                      Navigator.pop(context);
                      CustomNotification.show(
                        context,
                        message: 'Created playlist "$name"',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Create',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
