import 'package:flutter/material.dart';

/// Section header used at the top of main screens.
/// Adapted from Kuber's KuberPageHeader — no action button variant here,
/// simpler to just use with label + title + subtitle.
class PageHeader extends StatelessWidget {
  final String? label;   // e.g. "COLLECTION" — uppercase caption above title
  final String title;
  final String? description;
  final IconData? icon;
  final Color? iconColor;

  const PageHeader({
    super.key,
    this.label,
    required this.title,
    this.description,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 28,
                  color: iconColor ?? cs.primary,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(
              description!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 13,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
