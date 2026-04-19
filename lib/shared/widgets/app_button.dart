import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

enum AppButtonType {
  primary,  // filled blue
  normal,   // neutral surface
  outline,  // bordered
  danger,   // red outline
  ghost,    // text only (for Discard, Cancel)
}

/// Reusable button component for FlashMeUp.
/// Adapted from Kuber's AppButton — same API, no Kuber references.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool iconAfterLabel;
  final bool fullWidth;
  final double? width;
  final double height;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = AppButtonType.normal,
    this.icon,
    this.iconAfterLabel = false,
    this.fullWidth = false,
    this.width,
    this.height = 52,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final Color backgroundColor;
    final Color foregroundColor;
    final BorderSide? borderSide;

    switch (type) {
      case AppButtonType.primary:
        backgroundColor = cs.primary;
        foregroundColor = Colors.white;
        borderSide = null;
      case AppButtonType.normal:
        backgroundColor = cs.surfaceContainerHigh;
        foregroundColor = cs.onSurface;
        borderSide = BorderSide(color: cs.outline.withValues(alpha: 0.1));
      case AppButtonType.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = cs.onSurface;
        borderSide = BorderSide(color: cs.outline.withValues(alpha: 0.3));
      case AppButtonType.danger:
        backgroundColor = Colors.transparent;
        foregroundColor = cs.error;
        borderSide = BorderSide(color: cs.error.withValues(alpha: 0.5));
      case AppButtonType.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = cs.onSurfaceVariant;
        borderSide = null;
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: borderSide ?? BorderSide.none,
      ),
      disabledBackgroundColor: backgroundColor.withValues(alpha: 0.12),
      disabledForegroundColor: foregroundColor.withValues(alpha: 0.38),
    );

    final content = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        else if (icon != null && !iconAfterLabel) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: foregroundColor,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (!isLoading && icon != null && iconAfterLabel) ...[
          const SizedBox(width: 8),
          Icon(icon, size: 18),
        ],
      ],
    );

    return SizedBox(
      width: fullWidth ? double.infinity : width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: content,
      ),
    );
  }
}
