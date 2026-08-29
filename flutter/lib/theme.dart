import 'package:flutter/material.dart';

/// Soft clay / liquid-glass inspired light theme.
/// Rounded surfaces, gentle shadows, friendly pastels.
class AppTheme {
  static const Color clayBg = Color(0xFFF4F6FA);
  static const Color claySurface = Color(0xFFFFFFFF);
  static const Color clayAccent = Color(0xFF6C8EF5);
  static const Color clayAccentSoft = Color(0xFFE8EEFF);
  static const Color clayText = Color(0xFF1A1D26);
  static const Color clayMuted = Color(0xFF6B7280);
  static const Color claySuccess = Color(0xFF34D399);
  static const Color clayBorder = Color(0xFFE5E9F2);

  static ThemeData get light {
    final base = ColorScheme.fromSeed(
      seedColor: clayAccent,
      brightness: Brightness.light,
      surface: claySurface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: base.copyWith(
        primary: clayAccent,
        surface: claySurface,
        onSurface: clayText,
      ),
      scaffoldBackgroundColor: clayBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: clayText,
      ),
      cardTheme: CardTheme(
        color: claySurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: clayBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: claySurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: clayBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: clayBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: clayAccent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: clayMuted),
        hintStyle: const TextStyle(color: clayMuted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: clayAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontWeight: FontWeight.w700,
          color: clayText,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          fontWeight: FontWeight.w600,
          color: clayText,
        ),
        bodyMedium: TextStyle(color: clayText, height: 1.4),
        bodySmall: TextStyle(color: clayMuted),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: claySurface,
        indicatorColor: clayAccentSoft,
        labelTextStyle: WidgetStatePropertyAll(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        elevation: 0,
        height: 68,
      ),
    );
  }
}

/// Soft elevated clay card with gentle outer glow.
class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.claySurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.clayBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C8EF5).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}
