import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
// Nav item data model
// ─────────────────────────────────────────────

class FmuNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FmuNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const fmuNavItems = [
  FmuNavItem(
    icon: Icons.play_circle_outline_rounded,
    activeIcon: Icons.play_circle_rounded,
    label: 'Review',
  ),
  FmuNavItem(
    icon: Icons.library_books_outlined,
    activeIcon: Icons.library_books_rounded,
    label: 'Library',
  ),
  FmuNavItem(
    icon: Icons.insert_chart_outlined,
    activeIcon: Icons.insert_chart_rounded,
    label: 'Stats',
  ),
  FmuNavItem(
    icon: Icons.settings_outlined,
    activeIcon: Icons.settings_rounded,
    label: 'Config',
  ),
];

// ─────────────────────────────────────────────
// Bottom navigation bar
// ─────────────────────────────────────────────

class AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabTapped;

  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabTapped,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) {
        HapticFeedback.selectionClick();
        onTabTapped(i);
      },
      destinations: fmuNavItems
          .map((item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.activeIcon),
                label: item.label,
              ))
          .toList(),
    );
  }
}
