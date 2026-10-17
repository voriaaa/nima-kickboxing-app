import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF05070D);
  static const surface = Color(0xFF0C1322);
  static const surface2 = Color(0xFF121C33);
  static const line = Color(0xFF1C2A4A);
  static const blue = Color(0xFF2E7BFF);
  static const blueDeep = Color(0xFF0F3FA8);
  static const cyan = Color(0xFF6FE7FF);
  static const gold = Color(0xFFFFC23D);
  static const text = Color(0xFFE8F0FF);
  static const muted = Color(0xFF8391AE);
  static const danger = Color(0xFFFF4D5E);
  static const success = Color(0xFF3DDC97);
  static const warn = Color(0xFFFFB547);
}

/// Display font for English headings and numbers (BEBAS).
TextStyle display(double size, {Color color = AppColors.text, double spacing = 2}) =>
    TextStyle(
      fontFamily: 'BebasNeue',
      fontSize: size,
      color: color,
      letterSpacing: spacing,
      height: 1,
    );

/// Angular card shape used across the app.
const cutShape = BeveledRectangleBorder(
  borderRadius: BorderRadius.only(
    topLeft: Radius.circular(14),
    bottomRight: Radius.circular(14),
    topRight: Radius.circular(3),
    bottomLeft: Radius.circular(3),
  ),
  side: BorderSide(color: AppColors.line),
);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.blue,
    onPrimary: Colors.white,
    secondary: AppColors.cyan,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    primaryContainer: AppColors.blueDeep,
    onPrimaryContainer: Colors.white,
    secondaryContainer: AppColors.surface2,
    onSecondaryContainer: AppColors.text,
    surfaceContainerHighest: AppColors.surface2,
    outline: AppColors.muted,
    outlineVariant: AppColors.line,
    error: AppColors.danger,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: 'Vazirmatn',
    scaffoldBackgroundColor: AppColors.bg,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: AppColors.text,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: cutShape,
      margin: EdgeInsets.symmetric(vertical: 6),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.blue.withValues(alpha: 0.22),
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 12,
          fontWeight:
              s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w400,
          color: s.contains(WidgetState.selected) ? AppColors.cyan : AppColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? AppColors.cyan : AppColors.muted,
        ),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.cyan,
      unselectedLabelColor: AppColors.muted,
      indicatorColor: AppColors.cyan,
      dividerColor: AppColors.line,
      labelStyle: TextStyle(fontFamily: 'Vazirmatn', fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontFamily: 'Vazirmatn'),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
            fontFamily: 'Vazirmatn', fontWeight: FontWeight.w700, fontSize: 15),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.cyan,
        side: const BorderSide(color: AppColors.blue),
        shape: const BeveledRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.blue,
      foregroundColor: Colors.white,
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surface2,
      selectedColor: AppColors.blue,
      side: const BorderSide(color: AppColors.line),
      labelStyle: const TextStyle(fontFamily: 'Vazirmatn', color: AppColors.text),
      shape: const BeveledRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.line)),
      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.line)),
      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.blue, width: 1.5)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surface2,
      contentTextStyle: TextStyle(fontFamily: 'Vazirmatn', color: AppColors.text),
    ),
  );
}

/// Section heading: a slanted blue bar, a Persian title and a small English kicker.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.kicker, this.trailing});

  final String title;
  final String? kicker;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform(
            transform: Matrix4.skewX(-0.35),
            child: Container(width: 6, height: 22, color: AppColors.blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kicker != null)
                  Text(kicker!, style: display(13, color: AppColors.cyan, spacing: 3)),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Small angular label, e.g. a level or a punch number.
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color = AppColors.blue, this.filled = false});

  final String text;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: ShapeDecoration(
        color: filled ? color : color.withValues(alpha: 0.14),
        shape: BeveledRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(5)),
          side: BorderSide(color: color.withValues(alpha: 0.7)),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }
}

/// Dark panel with a subtle blue diagonal glow, used behind the fighter.
class ArenaBox extends StatelessWidget {
  const ArenaBox({super.key, required this.child, this.height = 260});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const ShapeDecoration(
        shape: cutShape,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1630), Color(0xFF05070D), Color(0xFF0A1226)],
        ),
      ),
      child: ClipPath(
        clipper: const ShapeBorderClipper(shape: cutShape),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _StripesPainter())),
            Positioned.fill(child: child),
          ],
        ),
      ),
    );
  }
}

class _StripesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = AppColors.blue.withValues(alpha: 0.05)
      ..strokeWidth = 18;
    for (var x = -size.height; x < size.width; x += 70) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
