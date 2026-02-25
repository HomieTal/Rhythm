import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../service/recently_played_service.dart';
import '../model/playlist_model.dart';
import '../widgets/rhythm_dialog.dart';
import '../widgets/custom_notification.dart';

class HistoryExportSettingsPage extends StatefulWidget {
  final bool showExport;
  const HistoryExportSettingsPage({super.key, this.showExport = false});

  @override
  State<HistoryExportSettingsPage> createState() => _HistoryExportSettingsPageState();
}

class _HistoryExportSettingsPageState extends State<HistoryExportSettingsPage> {
  String _autoClearPeriod = 'never';
  final RecentlyPlayedService _historyService = RecentlyPlayedService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final period = await _historyService.getAutoClearPeriod();
    setState(() {
      _autoClearPeriod = period;
      _isLoading = false;
    });
  }

  Future<void> _updateAutoClearPeriod(String period) async {
    await _historyService.setAutoClearPeriod(period);
    setState(() {
      _autoClearPeriod = period;
    });

    if (mounted) {
      CustomNotification.show(
        context,
        message: 'Auto-clear set to: ${_getPeriodLabel(period)}',
        icon: Icons.schedule,
        color: Theme.of(context).primaryColor,
      );
    }
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case '1day':
        return 'Every Day';
      case '1week':
        return 'Every Week';
      case '1month':
        return 'Every Month';
      case '3months':
        return 'Every 3 Months';
      case 'never':
      default:
        return 'Never';
    }
  }

  Future<void> _exportHistory() async {
    try {
      final history = _historyService.getRecentlyPlayed();

      if (history.isEmpty) {
        if (mounted) {
          CustomNotification.show(
            context,
            message: 'No history to export',
            icon: Icons.info_outline,
            color: Colors.orange,
          );
        }
        return;
      }

      final data = {
        'type': 'listening_history',
        'exported_at': DateTime.now().toIso8601String(),
        'songs': history.map((song) => {
          'title': song.title,
          'artist': song.artist,
          'duration': song.duration,
        }).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/rhythm_history_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Rhythm Listening History (${history.length} songs)',
      );

      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Exported ${history.length} songs',
          icon: Icons.check_circle,
          color: Colors.green,
        );
      }
    } catch (e) {
      debugPrint('Error exporting history: $e');
      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Export failed: $e',
          icon: Icons.error_outline,
          color: Colors.red,
        );
      }
    }
  }

  Future<void> _exportFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favIds = prefs.getStringList('favorite_songs') ?? [];

      if (favIds.isEmpty) {
        if (mounted) {
          CustomNotification.show(
            context,
            message: 'No favorites to export',
            icon: Icons.info_outline,
            color: Colors.orange,
          );
        }
        return;
      }

      final data = {
        'type': 'favorites',
        'exported_at': DateTime.now().toIso8601String(),
        'song_ids': favIds,
        'count': favIds.length,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/rhythm_favorites_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Rhythm Favorites (${favIds.length} songs)',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${favIds.length} favorites'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error exporting favorites: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showPlaylistExportDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    try {
      final prefs = await SharedPreferences.getInstance();
      final playlistsJson = prefs.getString('playlists') ?? '[]';
      final List<dynamic> playlistList = json.decode(playlistsJson);
      final playlists = playlistList.map((json) => PlaylistModel.fromJson(json)).toList();

      if (playlists.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No playlists to export')),
          );
        }
        return;
      }

      if (!mounted) return;

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
                    color: Theme.of(context).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Export Playlist',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Choose a playlist to export:',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = playlists[index];
                    return ListTile(
                      leading: Icon(
                        Icons.queue_music_rounded,
                        color: Theme.of(context).primaryColor,
                      ),
                      title: Text(
                        playlist.name,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        '${playlist.songIds.length} songs',
                        style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _exportPlaylist(playlist);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing playlist dialog: $e');
    }
  }

  Future<void> _exportPlaylist(PlaylistModel playlist) async {
    try {
      final data = {
        'type': 'playlist',
        'name': playlist.name,
        'created_at': playlist.createdAt.toIso8601String(),
        'exported_at': DateTime.now().toIso8601String(),
        'song_ids': playlist.songIds,
        'count': playlist.songIds.length,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/rhythm_playlist_${playlist.name}_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Rhythm Playlist: ${playlist.name} (${playlist.songIds.length} songs)',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported playlist: ${playlist.name}'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error exporting playlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.showExport ? 'Export' : 'History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (!widget.showExport) ...[
                  // History Auto-Clear Section
                  _buildSectionHeader('Listening History', Icons.history),
                  const SizedBox(height: 12),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-Clear History',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Automatically delete listening history after a set period',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildPeriodChip('never', 'Never'),
                            _buildPeriodChip('1day', '1 Day'),
                            _buildPeriodChip('1week', '1 Week'),
                            _buildPeriodChip('1month', '1 Month'),
                            _buildPeriodChip('3months', '3 Months'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                if (widget.showExport) ...[
                  _buildSectionHeader('Export Data', Icons.upload_file),
                  const SizedBox(height: 12),
                  _buildExportTile(
                    icon: Icons.history_rounded,
                    title: 'Export Listening History',
                    subtitle: 'Export all your listening history as JSON',
                    color: Colors.blue,
                    onTap: _exportHistory,
                  ),
                  const SizedBox(height: 8),
                  _buildExportTile(
                    icon: Icons.favorite_rounded,
                    title: 'Export Favorites',
                    subtitle: 'Export your favorite songs',
                    color: Colors.red,
                    onTap: _exportFavorites,
                  ),
                  const SizedBox(height: 8),
                  _buildExportTile(
                    icon: Icons.playlist_play_rounded,
                    title: 'Export Playlists',
                    subtitle: 'Export created playlists',
                    color: Colors.purple,
                    onTap: _showPlaylistExportDialog,
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _buildPeriodChip(String value, String label) {
    final isSelected = _autoClearPeriod == value;
    final primaryColor = Theme.of(context).primaryColor;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _updateAutoClearPeriod(value);
        }
      },
      selectedColor: primaryColor.withAlpha((0.3 * 255).round()),
      checkmarkColor: primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : null,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildExportTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}
