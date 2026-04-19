import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_bottom_sheet.dart';

/// "How to use" info sheet shown from collection detail 3-dot menu.
class AppHowToSheet extends StatelessWidget {
  const AppHowToSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AppHowToSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheet(
      title: 'How to Use',
      subtitle: 'Quick guide to FlashMeUp',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _HowToItem(
            icon: Icons.touch_app_rounded,
            title: 'Tap to flip',
            description:
                'Tap any flashcard to reveal the answer with a flip animation. Tap again to flip back.',
          ),
          _HowToItem(
            icon: Icons.swipe_rounded,
            title: 'Swipe to navigate',
            description:
                'Swipe left or right directly on the card — or use the ← → arrow buttons below — to move between cards.',
          ),
          _HowToItem(
            icon: Icons.touch_app_outlined,
            title: 'Long press to manage',
            description:
                'Long press on any card to reveal Edit and Delete options for that card.',
          ),
          _HowToItem(
            icon: Icons.table_rows_rounded,
            title: 'Table view',
            description:
                'Switch to the Table tab using the toggle at the top to see all cards in a compact spreadsheet layout.',
          ),
          _HowToItem(
            icon: Icons.swap_horiz_rounded,
            title: 'Horizontal scroll in table',
            description:
                'In Table view, swipe horizontally to see all columns — Title, Content, Created and Modified dates.',
          ),
          _HowToItem(
            icon: Icons.remove_red_eye_outlined,
            title: 'Back preview (eye icon)',
            description:
                'Tap the eye icon next to the view toggle to show a brief snippet of the answer on the front of each card.',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _HowToItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isLast;

  const _HowToItem({
    required this.icon,
    required this.title,
    required this.description,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 20, color: cs.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 0.5, color: cs.outline),
      ],
    );
  }
}
