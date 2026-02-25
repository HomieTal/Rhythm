import 'package:flutter/material.dart';
import '../screens/local_songs_screen.dart';
import '../screens/library_screen.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int>? onItemTapped;

  const CustomBottomNavigationBar({
    Key? key,
    this.activeIndex = 0,
    this.onItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Home
            _buildNavItem(
              context,
              Icons.home_outlined,
              activeIndex == 0,
              onTap: () {
                onItemTapped?.call(0);
              },
            ),
            // Search
            _buildNavItem(
              context,
              Icons.search,
              activeIndex == 1,
              onTap: () {
                onItemTapped?.call(1);
              },
            ),
            // Library/Library Music
            _buildNavItem(
              context,
              Icons.library_music_outlined,
              activeIndex == 2,
              onTap: () {
                onItemTapped?.call(2);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const LibraryScreen()),
                );
              },
            ),
            // Local Songs/Music
            _buildNavItem(
              context,
              Icons.music_note,
              activeIndex == 3,
              onTap: () {
                onItemTapped?.call(3);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SongsLocalScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF7B4FFF).withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isActive ? const Color(0xFF7B4FFF) : Colors.white.withValues(alpha: 0.6),
          size: 28,
        ),
      ),
    );
  }
}

