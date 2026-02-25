import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../service/import_export_service.dart';
import '../service/favorites_service.dart';
import '../service/recently_played_service.dart';
import '../service/imported_playlist_service.dart';
import '../service/metadata_matcher_service.dart';
import '../model/local_song_model.dart';
import '../model/playlist_model.dart';
import '../widgets/custom_notification.dart';
import '../widgets/rhythm_dialog.dart';

class ImportExportDataPage extends StatefulWidget {
  const ImportExportDataPage({super.key});

  @override
  State<ImportExportDataPage> createState() => _ImportExportDataPageState();
}

class _ImportExportDataPageState extends State<ImportExportDataPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImportExportService _importExportService = ImportExportService();
  final FavoritesService _favoritesService = FavoritesService();
  final RecentlyPlayedService _historyService = RecentlyPlayedService();
  final ImportedPlaylistService _importedPlaylistService =
      ImportedPlaylistService();
  final MetadataMatcherService _metadataMatcherService =
      MetadataMatcherService();

  bool _isExporting = false;
  bool _isImporting = false;
  double _importProgress = 0.0;

  // Export format options
  String _selectedExportFormat = 'json';
  bool _encryptExport = true;
  String _encryptionPassword = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: const Text('Import & Export Data'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Import'),
            Tab(text: 'Export'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildImportTab(),
              _buildExportTab(),
            ],
          ),
          // Show progress overlay when importing
          if (_isImporting)
            Container(
              color: Colors.black.withAlpha((0.7 * 255).round()),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2A2A2A)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        value: _importProgress,
                        color: Theme.of(context).primaryColor,
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Matching songs with Saavn...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_importProgress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExportTab() {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Export Options'),
          const SizedBox(height: 16),
          _buildFormatSelector(),
          const SizedBox(height: 24),
          _buildEncryptionSection(),
          const SizedBox(height: 24),
          _buildExportButton(),
          const SizedBox(height: 32),
          _buildSectionTitle('Export Individual Items'),
          const SizedBox(height: 16),
          _buildExportItemCard('Export Favorites', Icons.favorite, () {
            _exportFavorites();
          }),
          const SizedBox(height: 12),
          _buildExportItemCard('Export Playlists', Icons.playlist_play, () {
            _exportPlaylists();
          }),
          const SizedBox(height: 12),
          _buildExportItemCard('Export History', Icons.history, () {
            _exportHistory();
          }),
        ],
      ),
    );
  }

  Widget _buildImportTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Import from File Formats'),
          const SizedBox(height: 16),
          _buildImportFormatCard('JSON (Encrypted)', 'json', _importFromJson),
          const SizedBox(height: 12),
          _buildImportFormatCard('M3U Playlist', 'm3u', _importFromFile),
          const SizedBox(height: 12),
          _buildImportFormatCard('M3U8 Playlist', 'm3u8', _importFromFile),
          const SizedBox(height: 12),
          _buildImportFormatCard('PLS Playlist', 'pls', _importFromFile),
          const SizedBox(height: 12),
          _buildImportFormatCard('WPL (Windows Playlist)', 'wpl', _importFromFile),
          const SizedBox(height: 12),
          _buildImportFormatCard('XSPF Playlist', 'xspf', _importFromFile),
          const SizedBox(height: 12),
          _buildImportFormatCard('CSV', 'csv', _importFromFile),
          const SizedBox(height: 12),
          _buildImportFormatCard('Database', 'db', _importFromDatabase),
          const SizedBox(height: 12),
          _buildImportFormatCard('SQLite', 'sqlite', _importFromDatabase),
          const SizedBox(height: 12),
          _buildImportFormatCard('Text File', 'txt', _importFromFile),
          const SizedBox(height: 12),
          _buildImportFormatCard('XML', 'xml', _importFromFile),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Export Format',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFormatChip('json', 'JSON'),
              _buildFormatChip('m3u', 'M3U'),
              _buildFormatChip('m3u8', 'M3U8'),
              _buildFormatChip('pls', 'PLS'),
              _buildFormatChip('wpl', 'WPL'),
              _buildFormatChip('xspf', 'XSPF'),
              _buildFormatChip('csv', 'CSV'),
              _buildFormatChip('txt', 'TXT'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormatChip(String value, String label) {
    final isSelected = _selectedExportFormat == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedExportFormat = value;
        });
      },
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF404040)
          : Colors.grey.shade300,
      selectedColor: Colors.pink.shade300,
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : Colors.black,
      ),
    );
  }

  Widget _buildEncryptionSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Encrypt Export',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Switch(
                value: _encryptExport,
                onChanged: (value) {
                  setState(() {
                    _encryptExport = value;
                  });
                },
                activeThumbColor: Colors.pink.shade300,
              ),
            ],
          ),
          if (_encryptExport) ...[
            const SizedBox(height: 12),
            TextField(
              onChanged: (value) {
                setState(() {
                  _encryptionPassword = value;
                });
              },
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter encryption password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3A3A3A)
                    : Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep this password safe to decrypt your data later',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isExporting ? null : _handleExport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pink.shade300,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: _isExporting
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Export All Data',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildExportItemCard(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.pink.shade300),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }


  Widget _buildImportFormatCard(String title, String format, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2A2A2A)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(Icons.upload_file, color: Colors.blue.shade300),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);
    try {
      // Get all data
      final favorites = _favoritesService.favorites.value;
      final history = _historyService.getRecentlyPlayed();

      String content;

      if (_selectedExportFormat == 'json') {
        // For JSON, use encrypted export
        if (_encryptExport) {
          if (_encryptionPassword.isEmpty) {
            if (mounted) {
              CustomNotification.show(
                context,
                message: 'Please enter encryption password',
                icon: Icons.lock_outline,
                color: Colors.orange,
              );
            }
            return;
          }
          content = await _importExportService.exportAllData(
            favorites: favorites,
            playlists: [],
            history: history,
            password: _encryptionPassword,
          );
        } else {
          content = await _importExportService.exportAllData(
            favorites: favorites,
            playlists: [],
            history: history,
            password: 'rhythm_default',
          );
        }
      } else {
        // Export favorites to specified format
        content = _getExportContent(favorites);
      }

      final fileName =
          'rhythm_export_${DateTime.now().millisecondsSinceEpoch}.$_selectedExportFormat';
      final file = await _importExportService.saveExportFile(content, fileName);

      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Exported to ${file.path}',
          icon: Icons.check_circle,
          color: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Export failed: $e',
          icon: Icons.error_outline,
          color: Colors.red,
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  String _getExportContent(List<LocalSongModel> songs) {
    switch (_selectedExportFormat) {
      case 'm3u':
        return _importExportService.exportToM3U(songs);
      case 'm3u8':
        return _importExportService.exportToM3U8(songs);
      case 'pls':
        return _importExportService.exportToPLS(songs);
      case 'wpl':
        return _importExportService.exportToWPL(songs);
      case 'xspf':
        return _importExportService.exportToXSPF(songs, 'Rhythm Playlist');
      case 'csv':
        return _importExportService.exportToCSV(songs);
      case 'txt':
        return _importExportService.exportToTXT(songs);
      default:
        return '';
    }
  }

  Future<void> _exportFavorites() async {
    CustomNotification.show(
      context,
      message: 'Exporting favorites...',
      icon: Icons.favorite,
      color: Colors.pink,
    );
    // Implementation for favorites export
  }

  Future<void> _exportPlaylists() async {
    CustomNotification.show(
      context,
      message: 'Exporting playlists...',
      icon: Icons.playlist_play,
      color: Colors.blue,
    );
    // Implementation for playlists export
  }

  Future<void> _exportHistory() async {
    CustomNotification.show(
      context,
      message: 'Exporting history...',
      icon: Icons.history,
      color: Colors.purple,
    );
    // Implementation for history export
  }


  Future<void> _importFromJson() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileContent = await file.readAsString();

        // Show password dialog if encrypted
        if (!mounted) return;
        _showPasswordDialog('Enter Decryption Password', (password) async {
          try {
            final imported =
                await _importExportService.importFromEncryptedJson(
              fileContent,
              password: password,
            );

            if (imported['success'] == true && mounted) {
              // Save imported playlists
              final importedPlaylists = imported['playlists'] as List;
              if (importedPlaylists.isNotEmpty) {
                await _importedPlaylistService
                    .addImportedPlaylists(importedPlaylists.cast<PlaylistModel>());
              }

              CustomNotification.show(
                context,
                message:
                    'Imported ${(imported['favorites'] as List).length} items, ${importedPlaylists.length} playlists',
                icon: Icons.check_circle,
                color: Colors.green,
              );
            }
          } catch (e) {
            if (mounted) {
              CustomNotification.show(
                context,
                message: 'Import failed: $e',
                icon: Icons.error_outline,
                color: Colors.red,
              );
            }
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      CustomNotification.show(
        context,
        message: 'Error: $e',
        icon: Icons.error_outline,
        color: Colors.red,
      );
    }
  }

  Future<void> _importFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['m3u', 'm3u8', 'pls', 'csv', 'txt', 'xspf'],
      );

      if (result == null || result.files.single.path == null) return;

      setState(() {
        _isImporting = true;
        _importProgress = 0.0;
      });

      final file = File(result.files.single.path!);
      final content = await file.readAsString();
      final extension = result.files.single.extension ?? '';

      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Extracting metadata from file...',
          icon: Icons.search,
          color: Colors.blue,
        );
      }

      // Extract metadata from file
      final extractedSongs = await _metadataMatcherService.extractMetadataFromFile(
        content,
        extension,
      );

      if (extractedSongs.isEmpty) {
        if (mounted) {
          CustomNotification.show(
            context,
            message: 'No songs found in file',
            icon: Icons.warning,
            color: Colors.orange,
          );
        }
        setState(() => _isImporting = false);
        return;
      }

      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Found ${extractedSongs.length} songs. Matching with Saavn...',
          icon: Icons.cloud_sync,
          color: Colors.blue,
        );
      }

      // Match songs with Saavn database
      final matchedSongs = await _metadataMatcherService.matchSongsBatch(
        extractedSongs,
        onProgress: (current, total) {
          setState(() {
            _importProgress = current / total;
          });
        },
      );

      // Count successful matches
      final successfulMatches = matchedSongs.where((s) => s['matched'] != false).length;

      if (mounted) {
        // Show import summary dialog
        _showImportSummaryDialog(
          totalSongs: extractedSongs.length,
          matchedSongs: successfulMatches,
          onSavePlaylist: () async {
            await _saveImportedPlaylist(matchedSongs, result.files.single.name);
          },
        );
      }

      setState(() => _isImporting = false);

    } catch (e) {
      setState(() => _isImporting = false);

      if (!mounted) return;
      CustomNotification.show(
        context,
        message: 'Error importing file: $e',
        icon: Icons.error_outline,
        color: Colors.red,
      );
    }
  }

  Future<void> _saveImportedPlaylist(
    List<Map<String, dynamic>> songs,
    String fileName,
  ) async {
    try {
      // Remove file extension from name
      final playlistName = fileName.replaceAll(RegExp(r'\.(m3u|m3u8|pls|csv|txt|xspf)$'), '');

      // Extract song IDs from matched songs
      // Saavn songs use 'token' or 'id' field for identification
      final songIds = songs
          .where((s) => s['matched'] != false) // Only include successfully matched songs
          .map((s) {
            // Try different possible ID fields
            if (s['token'] != null) return s['token'].toString();
            if (s['id'] != null) return s['id'].toString();
            if (s['perma_url'] != null) {
              // Extract ID from permalink if available
              final url = s['perma_url'].toString();
              final match = RegExp(r'/([^/]+)/?$').firstMatch(url);
              if (match != null) return match.group(1) ?? '';
            }
            return '';
          })
          .where((id) => id.isNotEmpty)
          .toList();

      if (songIds.isEmpty) {
        if (mounted) {
          CustomNotification.show(
            context,
            message: 'No valid songs to save. All songs failed to match.',
            icon: Icons.warning,
            color: Colors.orange,
            duration: const Duration(seconds: 3),
          );
        }
        return;
      }

      // Create playlist with correct parameters
      final playlist = PlaylistModel(
        name: playlistName,
        createdAt: DateTime.now(),
        songIds: songIds,
      );

      // Save to imported playlists service
      await _importedPlaylistService.addImportedPlaylist(playlist);

      if (mounted) {
        CustomNotification.show(
          context,
          message: 'Playlist "$playlistName" created with ${songIds.length} songs',
          icon: Icons.check_circle,
          color: Colors.green,
          duration: const Duration(seconds: 3),
        );

        // Navigate back or refresh the UI
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error saving imported playlist: $e');
      if (!mounted) return;
      CustomNotification.show(
        context,
        message: 'Error saving playlist: $e',
        icon: Icons.error_outline,
        color: Colors.red,
      );
    }
  }

  void _showImportSummaryDialog({
    required int totalSongs,
    required int matchedSongs,
    required VoidCallback onSavePlaylist,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final primaryColor = Theme.of(context).primaryColor;

    showRhythmDialog(
      context: context,
      glassy: true,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              matchedSongs > 0 ? Icons.check_circle : Icons.info,
              color: matchedSongs > 0 ? Colors.green : Colors.orange,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Import Summary',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withAlpha((0.05 * 255).round())
                    : Colors.black.withAlpha((0.03 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildSummaryRow('Total Songs', '$totalSongs', textColor),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Matched with Saavn',
                    '$matchedSongs',
                    Colors.green,
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'Not Matched',
                    '${totalSongs - matchedSongs}',
                    Colors.orange,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              matchedSongs > 0
                  ? 'Would you like to save this as a playlist?'
                  : 'No songs were matched. Try a different file.',
              style: TextStyle(color: textColor.withAlpha((0.8 * 255).round())),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                if (matchedSongs > 0) ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onSavePlaylist();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Save Playlist',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: valueColor.withAlpha((0.7 * 255).round()),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Future<void> _importFromDatabase() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite', 'sqlite3'],
      );

      if (result != null && result.files.single.path != null) {
        if (mounted) {
          CustomNotification.show(
            context,
            message: 'Database import initiated',
            icon: Icons.storage,
            color: Colors.blue,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      CustomNotification.show(
        context,
        message: 'Error: $e',
        icon: Icons.error_outline,
        color: Colors.red,
      );
    }
  }


  void _showPasswordDialog(String title, Function(String) onSubmit) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    showRhythmDialog(
      context: context,
      glassy: true,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withAlpha((0.1 * 255).round())
                    : Colors.black.withAlpha((0.05 * 255).round()),
              ),
              style: TextStyle(color: textColor),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onSubmit(controller.text);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Submit', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

