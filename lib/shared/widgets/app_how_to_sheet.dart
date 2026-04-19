import 'package:flutter/material.dart';

import 'app_button.dart';

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
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LEARN MORE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'How Flashcards Work',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 20, color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Text(
                'Flashcards help memorize and understand your study material quickly.',
                style: TextStyle(
                  fontSize: 15,
                  color: cs.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),

            // Flexible list constraint so it doesn't try to take full screen
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: const [
                    _HowToItem(
                      icon: Icons.touch_app_rounded,
                      title: 'Tap to flip',
                      description:
                          'Tap any flashcard to reveal the answer with a natural flip animation. Tap again to flip back.',
                    ),
                    _HowToItem(
                      icon: Icons.swipe_rounded,
                      title: 'Swipe to navigate',
                      description:
                          'Swipe left or right directly on the card — or use the ← → arrow buttons — to move between cards.',
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
                          'Switch to the Table tab using the top toggle to see all cards in a compact spreadsheet layout.',
                    ),
                  ],
                ),
              ),
            ),

            // Footer Action
            Padding(
              padding: const EdgeInsets.all(24),
              child: AppButton(
                label: 'Got it',
                type: AppButtonType.primary,
                fullWidth: true,
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowToItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HowToItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: cs.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
