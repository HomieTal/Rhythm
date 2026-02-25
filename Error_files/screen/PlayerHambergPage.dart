import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../model/local_song_model.dart';
import 'package:Rhythm/settings/equalizer_page.dart';
import 'package:Rhythm/screen/sleep_timer_page.dart';

class PlayerHambergPage extends StatelessWidget {
  final LocalSongModel song;

  const PlayerHambergPage({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Drawer(
      backgroundColor: backgroundColor,
      width: MediaQuery.of(context).size.width * 0.35, // 35% of screen width (more compact)
      child: SafeArea(
        child: Column(
          children: [
            // Song Info Card - Compact Profile Style
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: primaryColor.withAlpha((0.2 * 255).round()),
                    child: Icon(
                      Icons.music_note_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Menu Options
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _buildNavItem(
                    context,
                    icon: Icons.share_rounded,
                    label: 'Share',
                    onTap: () => _shareSong(context),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.info_outline_rounded,
                    label: 'Song Details',
                    onTap: () => _showSongDetails(context),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.person_outline_rounded,
                    label: 'Artist',
                    onTap: () => _showArtistInfo(context),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.folder_outlined,
                    label: 'File Location',
                    onTap: () => _showFileLocation(context),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.equalizer_rounded,
                    label: 'Equalizer',
                    onTap: () => _showEqualizer(context),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.timer_rounded,
                    label: 'Sleep timer',
                    onTap: () => _showSleepTimer(context),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.playlist_add_rounded,
                    label: 'Add to Playlist',
                    onTap: () => _addToPlaylist(context),
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.favorite_rounded,
                    label: 'Favorites',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Added to favorites'),
                          backgroundColor: primaryColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Bottom Controls
            Container(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  // Bottom Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomIconButton(
                        context,
                        icon: Icons.favorite_outline_rounded,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Added to favorites'),
                              backgroundColor: primaryColor,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      _buildBottomIconButton(
                        context,
                        icon: Icons.share_rounded,
                        onTap: () => _shareSong(context),
                      ),
                      _buildBottomIconButton(
                        context,
                        icon: Icons.close_rounded,
                        onTap: () {
                          Navigator.pop(context);
                        },
                        isPrimary: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
      BuildContext context, {
        required IconData icon,
        required String label,
        required VoidCallback onTap,
        bool isActive = false,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return ListTile(
      leading: Icon(
        icon,
        color: isActive ? primaryColor : textColor.withAlpha((0.7 * 255).round()),
        size: 20,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isActive ? primaryColor : textColor,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          fontSize: 13,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildBottomIconButton(
      BuildContext context, {
        required IconData icon,
        required VoidCallback onTap,
        bool isPrimary = false,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isPrimary ? primaryColor : cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isPrimary
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87),
          size: 18,
        ),
      ),
    );
  }

  void _shareSong(BuildContext context) {
    try {
      Share.share(
        'Check out this song: ${song.title} by ${song.artist}',
        subject: 'Song Recommendation',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not share song'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSongDetails(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Song Details',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context,
                    'Title',
                    song.title.split('/').last,
                  ),
                  _buildDetailRow(context, 'Artist', song.artist),
                  _buildDetailRow(
                    context,
                    'Duration',
                    _formatDuration(song.duration),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showArtistInfo(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Artist: ${song.artist}'),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showFileLocation(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File Location',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                song.uri,
                style: TextStyle(
                  color: textColor.withAlpha((0.7 * 255).round()),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showEqualizer(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EqualizerPage()),
    );
  }

  void _showSleepTimer(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SleepTimerPage()),
    );
  }

  void _addToPlaylist(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Playlist feature coming soon!'),
        backgroundColor: primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: textColor.withAlpha((0.7 * 255).round()),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }
}