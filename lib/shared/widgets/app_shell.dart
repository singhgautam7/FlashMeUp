import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Outer scaffold shell that owns the bottom navigation bar.
/// Nav bar is hidden when on any sub-route (collection detail, add/edit, etc.).
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    // Determine visibility: only show nav bar on the three root tabs
    final path = GoRouterState.of(context).uri.path;
    final isRootTab = path == '/collections' ||
        path == '/tags' ||
        path == '/settings';

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: isRootTab
          ? Container(
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: cs.outline, width: 0.5)),
              ),
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: (index) {
                  HapticFeedback.selectionClick();
                  navigationShell.goBranch(
                    index,
                    initialLocation:
                        index == navigationShell.currentIndex,
                  );
                },
                backgroundColor: cs.surfaceContainer,
                surfaceTintColor: Colors.transparent,
                indicatorColor: cs.primaryContainer,
                indicatorShape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppRadius.md),
                ),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.library_books_outlined),
                    selectedIcon: Icon(Icons.library_books_rounded),
                    label: 'Collections',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.label_outline_rounded),
                    selectedIcon: Icon(Icons.label_rounded),
                    label: 'Tags',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings_rounded),
                    label: 'Settings',
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
