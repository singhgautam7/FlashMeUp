import 'package:flutter/material.dart';
import 'app_text_styles.dart';

// ─────────────────────────────────────────────
// Spacing scale
// ─────────────────────────────────────────────
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

// ─────────────────────────────────────────────
// Radius scale
// ─────────────────────────────────────────────
class AppRadius {
  static const sm = 4.0;   // tags, badges
  static const md = 8.0;   // cards, buttons, inputs — universal
  static const lg = 12.0;  // bottom sheets
  static const xl = 24.0;  // brand icons
  static const full = 999.0;
}

// ─────────────────────────────────────────────
// Dark palette — "Obsidian Vault"
// ─────────────────────────────────────────────
class AppDarkColors {
  static const background   = Color(0xFF000000);
  static const surfaceCard  = Color(0xFF09090B);
  static const surfaceMuted = Color(0xFF18181B);
  static const border       = Color(0xFF27272A);
  static const borderMuted  = Color(0xFF3F3F46);
  static const textPrimary  = Color(0xFFFAFAFA);
  static const textSecondary= Color(0xFFA1A1AA);
  static const primary      = Color(0xFF3B82F6);
  static const primarySubtle= Color(0x1A3B82F6);
  static const success      = Color(0xFF22C55E);
  static const successSubtle= Color(0x1A22C55E);
  static const danger       = Color(0xFFEF4444);
  static const dangerSubtle = Color(0x1AEF4444);
}

// ─────────────────────────────────────────────
// Light palette — "Alabaster Vault"
// ─────────────────────────────────────────────
class AppLightColors {
  static const background   = Color(0xFFFFFFFF);
  static const surfaceCard  = Color(0xFFFAFAFA);
  static const surfaceMuted = Color(0xFFF4F4F5);
  static const border       = Color(0xFFE4E4E7);
  static const borderMuted  = Color(0xFFD4D4D8);
  static const textPrimary  = Color(0xFF09090B);
  static const textSecondary= Color(0xFF71717A);
  static const primary      = Color(0xFF3B82F6);
  static const primarySubtle= Color(0x1A3B82F6);
  static const success      = Color(0xFF16A34A);
  static const successSubtle= Color(0x1A16A34A);
  static const danger       = Color(0xFFDC2626);
  static const dangerSubtle = Color(0x1ADC2626);
}

// ─────────────────────────────────────────────
// Theme builder
// ─────────────────────────────────────────────
class AppTheme {
  static ThemeData dark() {
    final textTheme = AppTextStyles.getTextTheme(ThemeData.dark().textTheme);

    final colorScheme = ColorScheme.dark(
      surface: AppDarkColors.background,
      onSurface: AppDarkColors.textPrimary,
      onSurfaceVariant: AppDarkColors.textSecondary,
      primary: AppDarkColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppDarkColors.primarySubtle,
      onPrimaryContainer: AppDarkColors.primary,
      secondary: AppDarkColors.primary,
      onSecondary: Colors.white,
      tertiary: AppDarkColors.success,
      onTertiary: Colors.white,
      error: AppDarkColors.danger,
      onError: Colors.white,
      errorContainer: AppDarkColors.dangerSubtle,
      onErrorContainer: AppDarkColors.danger,
      surfaceContainer: AppDarkColors.surfaceCard,
      surfaceContainerHigh: AppDarkColors.surfaceMuted,
      outline: AppDarkColors.border,
      outlineVariant: AppDarkColors.borderMuted,
    );

    return _buildTheme(colorScheme, textTheme, Brightness.dark,
      scaffoldBg: AppDarkColors.background,
      cardBg: AppDarkColors.surfaceCard,
      borderColor: AppDarkColors.border,
      inputFill: AppDarkColors.surfaceCard,
      chipBg: AppDarkColors.surfaceMuted,
      navBg: AppDarkColors.surfaceCard,
      indicatorColor: AppDarkColors.primarySubtle,
      popupBg: AppDarkColors.surfaceMuted,
      bottomSheetBg: AppDarkColors.surfaceCard,
    );
  }

  static ThemeData light() {
    final textTheme = AppTextStyles.getTextTheme(ThemeData.light().textTheme);

    final colorScheme = ColorScheme.light(
      surface: AppLightColors.background,
      onSurface: AppLightColors.textPrimary,
      onSurfaceVariant: AppLightColors.textSecondary,
      primary: AppLightColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppLightColors.primarySubtle,
      onPrimaryContainer: AppLightColors.primary,
      secondary: AppLightColors.primary,
      onSecondary: Colors.white,
      tertiary: AppLightColors.success,
      onTertiary: Colors.white,
      error: AppLightColors.danger,
      onError: Colors.white,
      errorContainer: AppLightColors.dangerSubtle,
      onErrorContainer: AppLightColors.danger,
      surfaceContainer: AppLightColors.surfaceCard,
      surfaceContainerHigh: AppLightColors.surfaceMuted,
      outline: AppLightColors.border,
      outlineVariant: AppLightColors.borderMuted,
    );

    return _buildTheme(colorScheme, textTheme, Brightness.light,
      scaffoldBg: AppLightColors.background,
      cardBg: AppLightColors.surfaceCard,
      borderColor: AppLightColors.border,
      inputFill: AppLightColors.surfaceCard,
      chipBg: AppLightColors.surfaceMuted,
      navBg: AppLightColors.surfaceCard,
      indicatorColor: AppLightColors.primarySubtle,
      popupBg: AppLightColors.surfaceMuted,
      bottomSheetBg: AppLightColors.surfaceCard,
    );
  }

  static ThemeData _buildTheme(
    ColorScheme cs,
    TextTheme textTheme,
    Brightness brightness, {
    required Color scaffoldBg,
    required Color cardBg,
    required Color borderColor,
    required Color inputFill,
    required Color chipBg,
    required Color navBg,
    required Color indicatorColor,
    required Color popupBg,
    required Color bottomSheetBg,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      scaffoldBackgroundColor: scaffoldBg,
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: borderColor),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBg,
        indicatorColor: indicatorColor,
        surfaceTintColor: Colors.transparent,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary);
          }
          return IconThemeData(color: cs.onSurfaceVariant);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            );
          }
          return textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        labelStyle: TextStyle(color: cs.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      dividerTheme: DividerThemeData(color: borderColor, thickness: 0.5),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: cs.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBg,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: borderColor),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        side: BorderSide(color: borderColor),
        selectedColor: cs.primaryContainer,
        checkmarkColor: cs.primary,
        showCheckmark: true,
        labelStyle: AppTextStyles.inter.copyWith(
          fontSize: 12,
          color: cs.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bottomSheetBg,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
          side: BorderSide(color: borderColor),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: borderColor),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.onSurface,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return cs.primaryContainer;
            return cardBg;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return cs.primary;
            return cs.onSurfaceVariant;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: borderColor)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return cs.onSurfaceVariant;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return cs.surfaceContainerHigh;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.surfaceContainerHigh,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: popupBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
