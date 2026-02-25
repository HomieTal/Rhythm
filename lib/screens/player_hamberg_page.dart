import 'package:flutter/material.dart';
import 'package:rhythm/model/local_song_model.dart';
import 'package:rhythm/screens/sleep_timer_page.dart';
import 'package:rhythm/utils/page_transitions.dart';

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
      width: MediaQuery.of(context).size.width * 0.35,
      child: SafeArea(
        child: Column(
          children: [
            // Song Info Card
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
                          backgroundColor: Theme.of(context).primaryColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            // Bottom Controls
            Container(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBottomButton(
                    context,
                    icon: Icons.edit_rounded,
                    onTap: () {},
                  ),
                  _buildBottomButton(
                    context,
                    icon: Icons.home_rounded,
                    onTap: () => Navigator.pop(context),
                    isPrimary: true,
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
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return ListTile(
      leading: Icon(icon, color: textColor.withAlpha((0.7 * 255).round()), size: 20),
      title: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 13),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildBottomButton(
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
          color: isPrimary ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          size: 18,
        ),
      ),
    );
  }

  void _shareSong(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: const Text('Share Song'),
        content: Text('Check out "${song.title}" by ${song.artist}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSongDetails(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text('Song Details', style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Title:', song.title),
            _buildDetailRow('Artist:', song.artist),
            _buildDetailRow('Duration:', '${song.duration ~/ 1000} seconds'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _showArtistInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Artist'),
        content: Text(song.artist),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showFileLocation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('File Location'),
        content: Text(song.uri),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEqualizer(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Equalizer feature coming soon'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _showSleepTimer(BuildContext context) {
    context.pushWithFadeSlide(const SleepTimerPage());
  }

  void _addToPlaylist(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to playlist'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}

