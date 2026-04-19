import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Top app bar for FlashMeUp.
/// Adapted from Kuber's KuberAppBar — no currency/settings provider deps.
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool showBack;
  final double? horizontalPadding;
  final Widget? badge; // e.g. "DRAFT SAVED" chip

  const AppBarWidget({
    super.key,
    this.title,
    this.actions,
    this.showBack = false,
    this.horizontalPadding,
    this.badge,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final padding = horizontalPadding ?? AppSpacing.lg;

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: kToolbarHeight,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Row(
            children: [
              if (showBack) ...[
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: cs.onSurface,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              // Branding or custom title
              if (title == null) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.flash_on_rounded,
                      color: cs.primary,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'FlashMeUp',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: cs.primary,
                    letterSpacing: -0.3,
                  ),
                ),
              ] else
                Text(
                  title!,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: cs.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                badge!,
              ],
              const Spacer(),
              if (actions != null) ...actions!,
            ],
          ),
        ),
      ),
    );
  }
}

/// A small badge chip, e.g. "DRAFT SAVED"
class AppBarBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const AppBarBadge(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final c = color ?? cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: c.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: c,
        ),
      ),
    );
  }
}
