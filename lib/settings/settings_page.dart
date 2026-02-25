import 'package:flutter/material.dart';
import 'package:rhythm/utils/page_transitions.dart';
import 'appearance.dart';
import 'about.dart';
import 'update_settings_page.dart';
import 'lyrics_settings_page.dart';
import 'cache_settings_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String searchQuery = '';

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
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            onTap: () {
              context.pushWithFadeSlide(const AppearancePage());
            },
          ),
          _buildSettingTile(
            context,
            icon: Icons.notifications_outlined,
            title: "Notifications",
            subtitle: "Manage your notification preferences",
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: Icons.storage_outlined,
            title: "Cache Settings",
            subtitle: "Manage storage and cached data",
            onTap: () {
              context.pushWithFadeSlide(const CacheSettingsPage());
            },
          ),
          _buildSettingTile(
            context,
            icon: Icons.equalizer_outlined,
            title: "Equalizer",
            subtitle: "Fine-tune your audio experience",
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: Icons.lyrics_outlined,
            title: "Lyrics",
            subtitle: "Configure lyrics display settings",
            onTap: () {
              context.pushWithFadeSlide(const LyricsSettingsPage());
            },
          ),
          _buildSettingTile(
            context,
            icon: Icons.import_export_outlined,
            title: "Import/Export Data",
            subtitle: "Backup and restore your data",
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: Icons.history_outlined,
            title: "History",
            subtitle: "Manage your listening history",
            onTap: () {},
          ),
          _buildSettingTile(
            context,
            icon: Icons.system_update_outlined,
            title: "Updates",
            subtitle: "Check for new versions",
            onTap: () {
              context.pushWithFadeSlide(const UpdateSettingsPage());
            },
          ),
          _buildSettingTile(
            context,
            icon: Icons.info_outline,
            title: "About",
            subtitle: "Version and developer info",
            onTap: () {
              context.pushWithFadeSlide(const AboutPage());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    if (searchQuery.isNotEmpty &&
        !title.toLowerCase().contains(searchQuery) &&
        !subtitle.toLowerCase().contains(searchQuery)) {
      return const SizedBox.shrink();
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: primaryColor.withAlpha((0.1 * 255).round()),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: primaryColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: subtitleColor, fontSize: 13),
      ),
      trailing: Icon(Icons.chevron_right, color: subtitleColor),
      onTap: onTap,
    );
  }
}

