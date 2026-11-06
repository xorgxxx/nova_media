import 'package:flutter/material.dart';

/// The AS Vault palette: deep royal red on near-black graphite, with muted
/// section accents (no neon, no oversaturated gradients).
class Accents {
  static const brand = Color(0xFFC22C43);

  static const video = Color(0xFFD6515B);
  static const photo = Color(0xFFB9828C);
  static const music = Color(0xFF8D6A9E);

  static const danger = Color(0xFFE2555C);
}

class AppTheme {
  static const _darkSurface = Color(0xFF0A0A0D);
  static const _darkContainer = Color(0xFF14141A);
  static const _darkContainerHigh = Color(0xFF1B1B23);
  static const _darkOutline = Color(0xFF2C2C36);
  static const _darkOnSurface = Color(0xFFF3F0F2);
  static const _darkVariant = Color(0xFFA9A3AB);

  static const _lightSurface = Color(0xFFF7F4F5);
  static const _lightContainer = Color(0xFFFFFFFF);
  static const _lightContainerHigh = Color(0xFFF0EAEC);
  static const _lightOutline = Color(0xFFE0D6D9);
  static const _lightOnSurface = Color(0xFF191318);
  static const _lightVariant = Color(0xFF6E636A);

  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? _darkSurface : _lightSurface;
    final container = isDark ? _darkContainer : _lightContainer;
    final containerHigh = isDark ? _darkContainerHigh : _lightContainerHigh;
    final outline = isDark ? _darkOutline : _lightOutline;
    final onSurface = isDark ? _darkOnSurface : _lightOnSurface;
    final variant = isDark ? _darkVariant : _lightVariant;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: Accents.brand,
      onPrimary: Colors.white,
      primaryContainer: isDark ? const Color(0xFF3A1119) : const Color(0xFFF7DDE1),
      onPrimaryContainer: isDark ? const Color(0xFFF8DDE2) : const Color(0xFF4A0D17),
      secondary: isDark ? const Color(0xFFD3AFB6) : const Color(0xFF7E4A55),
      onSecondary: isDark ? const Color(0xFF3A141C) : Colors.white,
      secondaryContainer: isDark ? const Color(0xFF2A1A1E) : const Color(0xFFF0DFE2),
      onSecondaryContainer: isDark ? const Color(0xFFF0DADF) : const Color(0xFF3A141C),
      tertiary: isDark ? const Color(0xFFB9A0C6) : const Color(0xFF6B4B7A),
      onTertiary: isDark ? const Color(0xFF2A1733) : Colors.white,
      error: Accents.danger,
      onError: Colors.white,
      errorContainer: isDark ? const Color(0xFF3A1216) : const Color(0xFFFBE0E1),
      onErrorContainer: isDark ? const Color(0xFFFFDADB) : const Color(0xFF5A1116),
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: containerHigh,
      onSurfaceVariant: variant,
      outline: outline,
      outlineVariant: isDark ? const Color(0xFF1F1F27) : const Color(0xFFEDE6E8),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? const Color(0xFFF3F0F2) : const Color(0xFF191318),
      onInverseSurface: isDark ? const Color(0xFF191318) : const Color(0xFFF3F0F2),
      inversePrimary: isDark ? const Color(0xFF8E2434) : const Color(0xFFF5B7C1),
      surfaceTint: Accents.brand,
    );

    final base = ThemeData(useMaterial3: true, brightness: brightness);
    final textTheme = base.textTheme
        .apply(bodyColor: onSurface, displayColor: onSurface)
        .copyWith(
          displaySmall: base.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -1.0,
            height: 1.05,
          ),
          headlineMedium: base.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.6,
          ),
          headlineSmall: base.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
          titleLarge: base.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
          titleMedium: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          titleSmall: base.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          labelSmall: base.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.4,
            fontWeight: FontWeight.w600,
          ),
          bodySmall: base.textTheme.bodySmall?.copyWith(height: 1.35),
          bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.4),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: surface,
      canvasColor: surface,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
      }),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: onSurface),
        iconTheme: IconThemeData(color: onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF0D0D11) : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Accents.brand.withAlpha(isDark ? 46 : 28),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? Accents.brand : variant,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            letterSpacing: 0.2,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? Accents.brand : variant,
          );
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: container,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        titleTextStyle: textTheme.titleLarge?.copyWith(color: onSurface),
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: variant, height: 1.45),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: container,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: container,
        showDragHandle: true,
        dragHandleColor: outline,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: containerHigh,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          textStyle: textTheme.titleSmall,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22),
          textStyle: textTheme.titleSmall,
          side: BorderSide(color: outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.titleSmall,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          highlightColor: Accents.brand.withAlpha(isDark ? 36 : 22),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          side: WidgetStatePropertyAll(BorderSide(color: outline)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return Accents.brand.withAlpha(isDark ? 56 : 30);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return isDark ? const Color(0xFFF3C9D0) : Accents.brand;
            }
            return variant;
          }),
          textStyle: WidgetStatePropertyAll(
            textTheme.labelLarge?.copyWith(letterSpacing: 0.1),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: variant,
        textColor: onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 3,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        strokeWidth: 2.6,
      ),
      dividerTheme: DividerThemeData(color: outlineVariant, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: containerHigh,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Accents.brand, width: 1.4),
        ),
      ),
    );
  }
}

/// Re-tints the colour scheme of the subtree with a section accent.
class SectionTheme extends StatelessWidget {
  const SectionTheme({super.key, required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final on = ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final scheme = cs.copyWith(
      primary: accent,
      onPrimary: on,
      secondaryContainer: Color.alphaBlend(accent.withAlpha(46), cs.surface),
      onSecondaryContainer: cs.onSurface,
      surfaceTint: accent,
    );
    return Theme(
      data: theme.copyWith(
        colorScheme: scheme,
        navigationBarTheme: theme.navigationBarTheme.copyWith(
          indicatorColor: accent.withAlpha(
            theme.brightness == Brightness.dark ? 46 : 28,
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 24,
              color: selected ? accent : cs.onSurfaceVariant,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return theme.textTheme.labelSmall?.copyWith(
              letterSpacing: 0.2,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? accent : cs.onSurfaceVariant,
            );
          }),
        ),
      ),
      child: child,
    );
  }
}
