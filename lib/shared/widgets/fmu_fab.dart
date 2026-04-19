import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Rounded-square FAB used across screens.
/// Supports extended (icon + label) mode.
class FmuFab extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? label;
  final String? tooltip;

  const FmuFab({
    super.key,
    this.onPressed,
    this.icon = Icons.add_rounded,
    this.label,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (label != null) {
      return Tooltip(
        message: tooltip ?? '',
        child: FloatingActionButton.extended(
          onPressed: onPressed,
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          icon: Icon(icon, size: 20),
          label: Text(
            label!,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: tooltip ?? '',
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Icon(icon, size: 24),
      ),
    );
  }
}
