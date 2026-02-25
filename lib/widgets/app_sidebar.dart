import 'package:flutter/material.dart';

class AppSidebar extends StatefulWidget {
  final Function(int)? onPageChanged;

  const AppSidebar({super.key, this.onPageChanged});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  String _activeSection = 'Quick picks';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      width: 80,
      color: backgroundColor,
      child: Column(
        children: [
          const Spacer(),
          // Quick Picks -> Home (index 0)
          _buildSidebarItem(
            context,
            icon: Icons.auto_awesome,
            label: 'Quick picks',
            isActive: _activeSection == 'Quick picks',
            onTap: () {
              setState(() => _activeSection = 'Quick picks');
              widget.onPageChanged?.call(0);
            },
            primaryColor: primaryColor,
            textColor: textColor,
          ),

          const SizedBox(height: 20),

          // Discover -> Search (index 1)
          _buildSidebarItem(
            context,
            icon: Icons.explore_outlined,
            label: 'Discover',
            isActive: _activeSection == 'Discover',
            onTap: () {
              setState(() => _activeSection = 'Discover');
              widget.onPageChanged?.call(1);
            },
            primaryColor: primaryColor,
            textColor: textColor,
          ),

          const SizedBox(height: 20),

          // Library -> Library (index 2)
          _buildSidebarItem(
            context,
            icon: Icons.library_music_outlined,
            label: 'Library',
            isActive: _activeSection == 'Library',
            onTap: () {
              setState(() => _activeSection = 'Library');
              widget.onPageChanged?.call(2);
            },
            primaryColor: primaryColor,
            textColor: textColor,
          ),

          const SizedBox(height: 20),

          // Playlists -> Page 3
          _buildSidebarItem(
            context,
            icon: Icons.playlist_play_rounded,
            label: 'Playlists',
            isActive: _activeSection == 'Playlists',
            onTap: () {
              setState(() => _activeSection = 'Playlists');
              widget.onPageChanged?.call(3);
            },
            primaryColor: primaryColor,
            textColor: textColor,
          ),

          const SizedBox(height: 20),

          // Artists -> Page 4
          _buildSidebarItem(
            context,
            icon: Icons.person_outline,
            label: 'Artists',
            isActive: _activeSection == 'Artists',
            onTap: () {
              setState(() => _activeSection = 'Artists');
              widget.onPageChanged?.call(4);
            },
            primaryColor: primaryColor,
            textColor: textColor,
          ),

          const SizedBox(height: 20),

          // Albums -> Page 5
          _buildSidebarItem(
            context,
            icon: Icons.album_outlined,
            label: 'Albums',
            isActive: _activeSection == 'Albums',
            onTap: () {
              setState(() => _activeSection = 'Albums');
              widget.onPageChanged?.call(5);
            },
            primaryColor: primaryColor,
            textColor: textColor,
          ),

          const SizedBox(height: 20),

          // Local -> Page 6
          _buildSidebarItem(
            context,
            icon: Icons.folder_outlined,
            label: 'Local',
            isActive: _activeSection == 'Local',
            onTap: () {
              setState(() => _activeSection = 'Local');
              widget.onPageChanged?.call(6);
            },
            primaryColor: primaryColor,
            textColor: textColor,
          ),

          const Spacer(),

          // Sleep Timer -> Page 7
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: InkWell(
              onTap: () {
                setState(() => _activeSection = 'Sleep Timer');
                widget.onPageChanged?.call(7);
              },
              child: SizedBox(
                width: 80,
                child: Icon(
                  Icons.timer_outlined,
                  color: _activeSection == 'Sleep Timer' ? primaryColor : textColor.withAlpha((0.6 * 255).round()),
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool isActive = false,
    VoidCallback? onTap,
    required Color primaryColor,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rotated text
            RotatedBox(
              quarterTurns: -1,
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? primaryColor : textColor.withAlpha((0.6 * 255).round()),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Icon on the right - only shown when active
            if (isActive)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

