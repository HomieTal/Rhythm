import 'package:flutter/material.dart';
import 'appearance.dart';
import 'about.dart';
import 'cache_settings_page.dart';
import 'update_settings_page.dart';
import 'history_export_settings_page.dart';
import '../service/cache_service.dart';
import 'equalizer_page.dart';
import 'import_export_data_page.dart';
import 'lyrics_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with WidgetsBindingObserver {
  String searchQuery = '';
  final CacheService _cacheService = CacheService();
  bool _isCacheEnabled = true;
  int _cacheSizeLimit = 500;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCacheSettings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }


  Future<void> _loadCacheSettings() async {
    await _cacheService.initialize();
    final limit = await _cacheService.getCacheSizeLimit();
    final isEnabled = await _cacheService.isCacheEnabled();
    if (mounted) {
      setState(() {
        _cacheSizeLimit = limit;
        _isCacheEnabled = isEnabled;
      });
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
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              prefixIcon: Icon(
                Icons.search_outlined,
                size: 20,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 0),
        children: [
          _buildSettingTile(
            context,
            icon: Icons.palette_outlined,
            title: "Theme",
            subtitle: "The overall vibe of your player",
            color: Colors.pink.shade300,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppearancePage()),
            ),
          ),
          // Dedicated Equalizer tile (separate from the Theme block)
          _buildSettingTile(
            context,
            icon: Icons.equalizer,
            title: "Equalizer",
            subtitle: "Customize audio frequencies",
            color: Colors.orange.shade300,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EqualizerPage()),
            ),
          ),
          _buildSettingTile(
            context,
            icon: Icons.history,
            title: "History",
            subtitle: "Manage listening history and auto-clear",
            color: Colors.purple.shade300,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryExportSettingsPage(showExport: false)),
            ),
          ),
          _buildSettingTile(
            context,
            icon: Icons.import_export,
            title: "Import & Export",
            subtitle: "Import/Export playlists, favorites, and history",
            color: Colors.blue.shade300,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImportExportDataPage()),
            ),
          ),
          _buildSettingTile(
            context,
            icon: Icons.cloud_download_outlined,
            title: "Cache Settings",
            subtitle: "Manage offline cache for online songs",
            color: Colors.blue.shade300,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CacheSettingsPage(),
              ),
            ),
          ),
          _buildSettingTile(
            context,
            icon: Icons.lyrics, // modern icon available in Material
            title: "Lyrics",
            subtitle: "Enable or disable lyrics fetching in player",
            color: Colors.teal.shade300,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LyricsSettingsPage()),
            ),
          ),
          _buildSettingTile(
            context,
            icon: Icons.system_update_alt,
            title: "Updates",
            subtitle: "Check the latest release and changelog",
            color: Colors.green.shade300,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UpdateSettingsPage(),
              ),
            ),
          ),
          _buildSettingTile(
            context,
            icon: Icons.info_outline,
            title: "About",
            subtitle: null,
            color: Colors.pink.shade300,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutPage()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
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
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: subtitleColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: subtitleColor, size: 24),
          ],
        ),
      ),
    );
  }
}
