import 'package:flutter/material.dart';
import 'notification_player.dart';
import 'bottom_navigation_bar.dart';

class PlayerControlsSection extends StatelessWidget {
  final int activeNavIndex;
  final ValueChanged<int>? onNavItemTapped;

  const PlayerControlsSection({
    Key? key,
    this.activeNavIndex = 0,
    this.onNavItemTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const NotificationPlayer(),
        CustomBottomNavigationBar(
          activeIndex: activeNavIndex,
          onItemTapped: onNavItemTapped,
        ),
      ],
    );
  }
}

