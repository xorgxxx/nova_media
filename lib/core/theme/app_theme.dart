import 'package:flutter/material.dart';

/// Each section has its own accent colour: this is the visual identity of the app.
class Accents {
  static const video = Color(0xFFFF6B5E);
  static const photo = Color(0xFF2DD4BF);
  static const music = Color(0xFF8B7BFF);
}

class AppTheme {
  static ThemeData dark() => _build(Brightness.dark);
  static ThemeData light() => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: Accents.music,
      brightness: brightness,
      surface: isDark ? const Color(0xFF0E0F17) : const Color(0xFFF6F5FB),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
      }),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor: isDark ? const Color(0xFF151622) : Colors.white,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7),
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
      secondaryContainer: Color.alphaBlend(accent.withAlpha(60), cs.surface),
      onSecondaryContainer: cs.onSurface,
    );
    return Theme(data: theme.copyWith(colorScheme: scheme), child: child);
  }
}
