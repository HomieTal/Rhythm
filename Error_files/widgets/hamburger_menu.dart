import 'package:flutter/material.dart';
import 'package:Rhythm/screen/albums_page.dart';
import 'package:Rhythm/screen/artists_page.dart';
import 'package:Rhythm/screen/genres_page.dart';
import 'package:Rhythm/screen/playlists_page.dart';
import 'package:Rhythm/widgets/bottom_mini_player.dart';
import 'package:Rhythm/settings/theme_provider.dart';
import 'package:Rhythm/screen/sleep_timer_page.dart';
import 'package:Rhythm/screen/history_page.dart';
import 'package:Rhythm/screen/fav_page.dart';
import 'package:Rhythm/screen/offline_playlist_page.dart';
import 'package:provider/provider.dart';

class HamburgerMenu extends StatelessWidget {
  const HamburgerMenu({super.key});

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
      width:
      MediaQuery.of(context).size.width *
          0.48, // 48% of screen width to match image
      child: SafeArea(
        child: Column(
          children: [
            // User Profile Section
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
                    backgroundColor: primaryColor.withAlpha(
                      (0.2 * 255).round(),
                    ),
                    child: Icon(
                      Icons.person_rounded,
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
                          'Rhythm',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Music Lover',
                          style: TextStyle(fontSize: 11, color: subtitleColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _buildNavItem(
                    context,
                    icon: Icons.home_rounded,
                    label: 'Home',
                    onTap: () => Navigator.pop(context),
                    isActive: true,
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.album_rounded,
                    label: 'Albums',
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) {
                            final isDark = Theme.of(ctx).brightness == Brightness.dark;
                            final bgColor = isDark ? Colors.black : Colors.white;
                            final fgColor = isDark ? Colors.white : Colors.black87;
                            return Scaffold(
                              backgroundColor: bgColor,
                              appBar: AppBar(
                                backgroundColor: bgColor,
                                foregroundColor: fgColor,
                                title: Text('Albums', style: TextStyle(color: fgColor)),
                              ),
                              body: Stack(
                                children: const [
                                  AlbumsPage(),
                                  BottomMiniPlayer(),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.music_note_rounded,
                    label: 'Tracks',
                    onTap: () {
                      Navigator.pop(context);
                      // Tracks will be shown in the main navigation
                    },
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.person_rounded,
                    label: 'Artists',
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) {
                            final isDark = Theme.of(ctx).brightness == Brightness.dark;
                            final bgColor = isDark ? Colors.black : Colors.white;
                            final fgColor = isDark ? Colors.white : Colors.black87;
                            return Scaffold(
                              backgroundColor: bgColor,
                              appBar: AppBar(
                                backgroundColor: bgColor,
                                foregroundColor: fgColor,
                                title: Text('Artists', style: TextStyle(color: fgColor)),
                              ),
                              body: Stack(
                                children: const [
                                  ArtistsPage(),
                                  BottomMiniPlayer(),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.category_rounded,
                    label: 'Genres',
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GenresPage()),
                      );
                    },
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.playlist_play_rounded,
                    label: 'Playlists',
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) {
                            final isDark = Theme.of(ctx).brightness == Brightness.dark;
                            final bgColor = isDark ? Colors.black : Colors.white;
                            final fgColor = isDark ? Colors.white : Colors.black87;
                            return Scaffold(
                              backgroundColor: bgColor,
                              appBar: AppBar(
                                backgroundColor: bgColor,
                                foregroundColor: fgColor,
                                title: Text('Playlists', style: TextStyle(color: fgColor)),
                              ),
                              body: Stack(
                                children: const [
                                  PlaylistsPage(),
                                  BottomMiniPlayer(),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.history_rounded,
                    label: 'History',
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HistoryPage()),
                      );
                    },
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.favorite_rounded,
                    label: 'Favorites',
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const FavoritesPage(),
                        ),
                      );
                    },
                  ),
                  _buildNavItem(
                    context,
                    icon: Icons.offline_pin_rounded,
                    label: 'Offline',
                    onTap: () {
                      Navigator.of(context).pop(); // Close drawer
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => const OfflinePlaylistPage(),
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
                  // Theme Controls
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildThemeButton(
                              context,
                              icon: Icons.wb_sunny_rounded,
                              isActive:
                              !themeProvider.isDarkMode &&
                                  !themeProvider.useSystemTheme,
                              onTap: () {
                                themeProvider.toggleSystemTheme(false);
                                themeProvider.toggleDarkMode(false);
                              },
                            ),
                            _buildThemeButton(
                              context,
                              icon: Icons.brightness_6_rounded,
                              isActive: themeProvider.useSystemTheme,
                              onTap: () {
                                themeProvider.toggleSystemTheme(true);
                              },
                            ),
                            _buildThemeButton(
                              context,
                              icon: Icons.nightlight_round,
                              isActive:
                              themeProvider.isDarkMode &&
                                  !themeProvider.useSystemTheme,
                              onTap: () {
                                themeProvider.toggleSystemTheme(false);
                                themeProvider.toggleDarkMode(true);
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sleep Timer
                  _buildNavItem(
                    context,
                    icon: Icons.timer_rounded,
                    label: 'Sleep timer',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SleepTimerPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 6),

                  // Bottom Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomIconButton(
                        context,
                        icon: Icons.edit_rounded,
                        onTap: () {
                          // Edit functionality
                        },
                      ),
                      _buildBottomIconButton(
                        context,
                        icon: Icons.disc_full_rounded,
                        onTap: () {
                          // Disc functionality
                        },
                      ),
                      _buildBottomIconButton(
                        context,
                        icon: Icons.home_rounded,
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
        color:
        isActive ? primaryColor : textColor.withAlpha((0.7 * 255).round()),
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

  Widget _buildThemeButton(
      BuildContext context, {
        required IconData icon,
        required bool isActive,
        required VoidCallback onTap,
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
          isActive
              ? primaryColor.withAlpha((0.2 * 255).round())
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color:
          isActive
              ? primaryColor
              : (isDark ? Colors.grey.shade500 : Colors.grey.shade600),
          size: 18,
        ),
      ),
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
          color:
          isPrimary
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87),
          size: 18,
        ),
      ),
    );
  }
}

