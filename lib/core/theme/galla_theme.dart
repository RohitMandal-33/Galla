import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Palette Tokens ─────────────────────────────────────────────────────────────

class GallaPalette {
  // Light Palette
  static const lightCanvas = Color(0xFFF7F4EF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceAlt = Color(0xFFF3EEE6);
  static const lightSurface2 = Color(0xFFF8F5EE);
  static const lightSurfaceElevated = Color(0xFFFAF8F4);
  static const lightInk = Color(0xFF181818);
  static const lightInkSecondary = Color(0xFF3D3D3D);
  static const lightMuted = Color(0xFF787878);
  static const lightFaint = Color(0xFFAEA696);
  static const lightLine = Color(0xFFEAE4DA);
  static const lightLineSoft = Color(0xFFF0EBE2);
  static const lightBrand = Color(0xFF1A3B2E);
  static const lightBrandMid = Color(0xFF2D5A40);
  static const lightBrandSoft = Color(0xFFE6F0EA);
  static const lightGold = Color(0xFFB8962E);
  static const lightGoldSoft = Color(0xFFFDF8EB);
  static const lightMoneyIn = Color(0xFF1B7A3E);
  static const lightMoneyInSoft = Color(0xFFEAF5ED);
  static const lightMoneyOut = Color(0xFFC0392B);
  static const lightMoneyOutSoft = Color(0xFFFDEBEA);
  static const lightUdhaar = Color(0xFFB45309);
  static const lightUdhaarSoft = Color(0xFFFEF3E2);
  static const lightUdhaarSofter = Color(0xFFFEF8EF);
  static const lightBlue = Color(0xFF1D4ED8);
  static const lightBlueSoft = Color(0xFFEFF4FF);

  // Dark Palette — Premium Deep Forest Charcoal
  static const darkCanvas = Color(0xFF0F1411);
  static const darkSurface = Color(0xFF181F1A);
  static const darkSurfaceAlt = Color(0xFF1E2621);
  static const darkSurface2 = Color(0xFF222B25);
  static const darkSurfaceElevated = Color(0xFF27322B);
  static const darkInk = Color(0xFFF1F5F2);
  static const darkInkSecondary = Color(0xFFD0D9D3);
  static const darkMuted = Color(0xFF8F9E94);
  static const darkFaint = Color(0xFF5D6B62);
  static const darkLine = Color(0xFF2D3A31);
  static const darkLineSoft = Color(0xFF232D27);
  static const darkBrand = Color(0xFF2F855A);
  static const darkBrandMid = Color(0xFF38A169);
  static const darkBrandSoft = Color(0xFF162E21);
  static const darkGold = Color(0xFFE5C255);
  static const darkGoldSoft = Color(0xFF2B2411);
  static const darkMoneyIn = Color(0xFF4ADE80);
  static const darkMoneyInSoft = Color(0xFF132D1C);
  static const darkMoneyOut = Color(0xFFF87171);
  static const darkMoneyOutSoft = Color(0xFF311716);
  static const darkUdhaar = Color(0xFFFBBF24);
  static const darkUdhaarSoft = Color(0xFF2F2108);
  static const darkUdhaarSofter = Color(0xFF241A06);
  static const darkBlue = Color(0xFF60A5FA);
  static const darkBlueSoft = Color(0xFF152238);
}

// ── Color System ───────────────────────────────────────────────────────────────

class GallaColors {
  /// Track the current application brightness. Updated dynamically in `MaterialApp.builder`.
  static Brightness currentBrightness = Brightness.light;
  static bool get isDark => currentBrightness == Brightness.dark;

  // Background layers
  static Color get canvas =>
      isDark ? GallaPalette.darkCanvas : GallaPalette.lightCanvas;
  static Color get surface =>
      isDark ? GallaPalette.darkSurface : GallaPalette.lightSurface;
  static Color get surfaceAlt =>
      isDark ? GallaPalette.darkSurfaceAlt : GallaPalette.lightSurfaceAlt;
  static Color get surface2 =>
      isDark ? GallaPalette.darkSurface2 : GallaPalette.lightSurface2;
  static Color get surfaceElevated =>
      isDark ? GallaPalette.darkSurfaceElevated : GallaPalette.lightSurfaceElevated;

  // Text
  static Color get ink => isDark ? GallaPalette.darkInk : GallaPalette.lightInk;
  static Color get inkSecondary =>
      isDark ? GallaPalette.darkInkSecondary : GallaPalette.lightInkSecondary;
  static Color get muted =>
      isDark ? GallaPalette.darkMuted : GallaPalette.lightMuted;
  static Color get faint =>
      isDark ? GallaPalette.darkFaint : GallaPalette.lightFaint;

  // Borders & Dividers
  static Color get line =>
      isDark ? GallaPalette.darkLine : GallaPalette.lightLine;
  static Color get lineSoft =>
      isDark ? GallaPalette.darkLineSoft : GallaPalette.lightLineSoft;

  // Brand — Deep Forest Green in light, vivid emerald in dark
  static Color get brand =>
      isDark ? GallaPalette.darkBrand : GallaPalette.lightBrand;
  static Color get brandMid =>
      isDark ? GallaPalette.darkBrandMid : GallaPalette.lightBrandMid;
  static Color get brandSoft =>
      isDark ? GallaPalette.darkBrandSoft : GallaPalette.lightBrandSoft;

  static LinearGradient get heroGradient => isDark
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1F4D36), Color(0xFF132B1E)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF244837), Color(0xFF163326)],
        );

  // Accent — Warm Gold (Trust & Prosperity)
  static Color get gold =>
      isDark ? GallaPalette.darkGold : GallaPalette.lightGold;
  static const goldLight = Color(0xFFE8C547);
  static const goldDark = Color(0xFF8C7018);
  static Color get goldSoft =>
      isDark ? GallaPalette.darkGoldSoft : GallaPalette.lightGoldSoft;

  // Income — Green (semantic)
  static Color get moneyIn =>
      isDark ? GallaPalette.darkMoneyIn : GallaPalette.lightMoneyIn;
  static Color get moneyInSoft =>
      isDark ? GallaPalette.darkMoneyInSoft : GallaPalette.lightMoneyInSoft;

  // Income/Expense variants for dark (brand) surfaces
  static const moneyInOnDark = Color(0xFF6EDB96);
  static const moneyOutOnDark = Color(0xFFFF9595);

  // Expense — Muted Red (semantic)
  static Color get moneyOut =>
      isDark ? GallaPalette.darkMoneyOut : GallaPalette.lightMoneyOut;
  static Color get moneyOutSoft =>
      isDark ? GallaPalette.darkMoneyOutSoft : GallaPalette.lightMoneyOutSoft;

  // Udhaar / Pending — Amber (semantic)
  static Color get udhaar =>
      isDark ? GallaPalette.darkUdhaar : GallaPalette.lightUdhaar;
  static Color get udhaarSoft =>
      isDark ? GallaPalette.darkUdhaarSoft : GallaPalette.lightUdhaarSoft;
  static Color get udhaarSofter =>
      isDark ? GallaPalette.darkUdhaarSofter : GallaPalette.lightUdhaarSofter;

  // Deprecated — kept for backwards compat
  static Color get amber => udhaar;

  // Blue — Informational / Secondary
  static Color get blue =>
      isDark ? GallaPalette.darkBlue : GallaPalette.lightBlue;
  static Color get blueSoft =>
      isDark ? GallaPalette.darkBlueSoft : GallaPalette.lightBlueSoft;
}

// ── Animations Scale ───────────────────────────────────────────────────────────

class GallaAnimations {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
}

// ── Typography ─────────────────────────────────────────────────────────────────
/// Semantic text styles for feature code. Prefer these over hand-written
/// `TextStyle(fontSize: …)` literals so type stays consistent app-wide.
class GallaType {
  static TextStyle _s(
    double size,
    FontWeight weight,
    double? ls,
    Color color, {
    double? height,
  }) => GoogleFonts.outfit(
    fontSize: size,
    fontWeight: weight,
    letterSpacing: ls,
    height: height,
    color: color,
  );

  // Display numbers — w800, tight tracking
  static TextStyle get hero =>
      _s(38, FontWeight.w800, -1.2, GallaColors.ink, height: 1.0);
  static TextStyle get totalLg => _s(32, FontWeight.w800, -1.0, GallaColors.ink);
  static TextStyle get total => _s(28, FontWeight.w800, -0.8, GallaColors.ink);
  static TextStyle get numberXl => _s(24, FontWeight.w800, -0.5, GallaColors.ink);
  static TextStyle get numberLg => _s(20, FontWeight.w800, -0.3, GallaColors.ink);
  static TextStyle get numberMd => _s(18, FontWeight.w800, -0.3, GallaColors.ink);
  static TextStyle get number => _s(16, FontWeight.w800, -0.3, GallaColors.ink);
  static TextStyle get numberSm => _s(15, FontWeight.w800, -0.3, GallaColors.ink);

  // Titles — ink
  static TextStyle get screenTitle =>
      _s(22, FontWeight.w800, null, GallaColors.ink);
  static TextStyle get cardTitle => _s(16, FontWeight.w700, null, GallaColors.ink);
  static TextStyle get tileTitle =>
      _s(15, FontWeight.w700, -0.1, GallaColors.ink);
  static TextStyle get subtitle => _s(14, FontWeight.w700, null, GallaColors.ink);
  static TextStyle get subtitleSm =>
      _s(13, FontWeight.w700, null, GallaColors.ink);

  // Body — ink
  static TextStyle get bodyStrong =>
      _s(13, FontWeight.w600, null, GallaColors.ink);
  static TextStyle get body => _s(13, FontWeight.w400, null, GallaColors.ink);

  // Labels & captions — muted unless overridden
  static TextStyle get chipLabel =>
      _s(12, FontWeight.w700, null, GallaColors.ink);
  static TextStyle get labelStrong =>
      _s(11, FontWeight.w700, null, GallaColors.ink);
  static TextStyle get label => _s(12, FontWeight.w600, null, GallaColors.muted);
  static TextStyle get labelSm => _s(11, FontWeight.w600, null, GallaColors.muted);
  static TextStyle get caption => _s(12, FontWeight.w400, null, GallaColors.muted);
  static TextStyle get captionSm =>
      _s(11, FontWeight.w400, null, GallaColors.muted);
  static TextStyle get badge => _s(10, FontWeight.w700, null, GallaColors.ink);
}

// ── Elevation & Shadows ────────────────────────────────────────────────────────

class GallaElevation {
  static List<BoxShadow> get card => GallaColors.isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF1A3B2E).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: const Color(0xFF1A3B2E).withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ];

  static List<BoxShadow> get hero => GallaColors.isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ]
      : [
          BoxShadow(
            color: const Color(0xFF1A3B2E).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ];

  static List<BoxShadow> get sheet => [
    BoxShadow(
      color: Colors.black.withValues(alpha: GallaColors.isDark ? 0.45 : 0.12),
      blurRadius: 30,
      offset: const Offset(0, -6),
    ),
  ];
}

// ── Spacing Scale ──────────────────────────────────────────────────────────────

class GallaSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;

  // Semantic spacing
  static const double cardPadding = 18;
  static const double bottomNavHeight = 64;

  /// Vertical clearance tab content must keep from the screen bottom so the
  /// last items never sit under the center-docked FAB, its protrusion above
  /// the bottom bar, or its glow. Combine with MediaQuery bottom padding.
  static const double shellBottomClearance = bottomNavHeight + 56;
}

// ── Radius Scale ───────────────────────────────────────────────────────────────

class GallaRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 100;

  // Semantic radii
  static const double card = 16;
  static const double button = 14;
  static const double chip = 8;
  static const double bottomSheet = 24;
}

// ── Theme Builders ─────────────────────────────────────────────────────────────

ThemeData buildGallaTheme({Brightness brightness = Brightness.light}) {
  return brightness == Brightness.dark
      ? buildGallaDarkTheme()
      : buildGallaLightTheme();
}

ThemeData buildGallaLightTheme() {
  return _buildTheme(
    isDark: false,
    canvas: GallaPalette.lightCanvas,
    surface: GallaPalette.lightSurface,
    surfaceAlt: GallaPalette.lightSurfaceAlt,
    surface2: GallaPalette.lightSurface2,
    ink: GallaPalette.lightInk,
    muted: GallaPalette.lightMuted,
    faint: GallaPalette.lightFaint,
    line: GallaPalette.lightLine,
    lineSoft: GallaPalette.lightLineSoft,
    brand: GallaPalette.lightBrand,
    brandSoft: GallaPalette.lightBrandSoft,
    moneyIn: GallaPalette.lightMoneyIn,
    moneyOut: GallaPalette.lightMoneyOut,
    udhaar: GallaPalette.lightUdhaar,
  );
}

ThemeData buildGallaDarkTheme() {
  return _buildTheme(
    isDark: true,
    canvas: GallaPalette.darkCanvas,
    surface: GallaPalette.darkSurface,
    surfaceAlt: GallaPalette.darkSurfaceAlt,
    surface2: GallaPalette.darkSurface2,
    ink: GallaPalette.darkInk,
    muted: GallaPalette.darkMuted,
    faint: GallaPalette.darkFaint,
    line: GallaPalette.darkLine,
    lineSoft: GallaPalette.darkLineSoft,
    brand: GallaPalette.darkBrand,
    brandSoft: GallaPalette.darkBrandSoft,
    moneyIn: GallaPalette.darkMoneyIn,
    moneyOut: GallaPalette.darkMoneyOut,
    udhaar: GallaPalette.darkUdhaar,
  );
}

ThemeData _buildTheme({
  required bool isDark,
  required Color canvas,
  required Color surface,
  required Color surfaceAlt,
  required Color surface2,
  required Color ink,
  required Color muted,
  required Color faint,
  required Color line,
  required Color lineSoft,
  required Color brand,
  required Color brandSoft,
  required Color moneyIn,
  required Color moneyOut,
  required Color udhaar,
}) {
  final base = GoogleFonts.outfitTextTheme();

  final textTheme = base.copyWith(
    displayLarge: GoogleFonts.outfit(
      fontSize: 42,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.5,
      height: 1.0,
      color: ink,
    ),
    displayMedium: GoogleFonts.outfit(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      height: 1.05,
      color: ink,
    ),
    displaySmall: GoogleFonts.outfit(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.1,
      color: ink,
    ),
    headlineMedium: GoogleFonts.outfit(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: ink,
    ),
    headlineSmall: GoogleFonts.outfit(
      fontSize: 19,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    titleLarge: GoogleFonts.outfit(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: ink,
    ),
    titleMedium: GoogleFonts.outfit(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
    titleSmall: GoogleFonts.outfit(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: ink,
    ),
    bodyLarge: GoogleFonts.outfit(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: ink,
    ),
    bodyMedium: GoogleFonts.outfit(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: muted,
    ),
    bodySmall: GoogleFonts.outfit(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: muted,
    ),
    labelLarge: GoogleFonts.outfit(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
      color: ink,
    ),
    labelMedium: GoogleFonts.outfit(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: muted,
    ),
    labelSmall: GoogleFonts.outfit(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: muted,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    colorScheme: isDark
        ? ColorScheme.dark(
            primary: brand,
            onPrimary: Colors.white,
            secondary: moneyIn,
            onSecondary: canvas,
            tertiary: udhaar,
            surface: surface,
            onSurface: ink,
            surfaceContainerHighest: surfaceAlt,
            outline: line,
            outlineVariant: lineSoft,
            error: moneyOut,
          )
        : ColorScheme.light(
            primary: brand,
            onPrimary: Colors.white,
            secondary: moneyIn,
            onSecondary: Colors.white,
            tertiary: udhaar,
            surface: surface,
            onSurface: ink,
            surfaceContainerHighest: surfaceAlt,
            outline: line,
            outlineVariant: lineSoft,
            error: moneyOut,
          ),
    scaffoldBackgroundColor: canvas,
    textTheme: textTheme,

    // ── App Bar ─────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),

    // ── Cards ───────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GallaRadius.card),
        side: BorderSide(color: line, width: 1),
      ),
    ),

    // ── Inputs ──────────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: GoogleFonts.outfit(color: faint, fontSize: 14),
      labelStyle: GoogleFonts.outfit(color: muted, fontSize: 14),
      floatingLabelStyle: GoogleFonts.outfit(
        color: brand,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GallaRadius.md),
        borderSide: BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GallaRadius.md),
        borderSide: BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GallaRadius.md),
        borderSide: BorderSide(color: brand, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),

    // ── Buttons ─────────────────────────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GallaRadius.button),
        ),
        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: brand,
        side: BorderSide(color: brand, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GallaRadius.button),
        ),
        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: brand,
        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),

    // ── Bottom Navigation ────────────────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      elevation: 0,
      height: GallaSpacing.bottomNavHeight,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected) ? brand : muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? brand : muted,
          size: 22,
        ),
      ),
    ),

    // ── Bottom Sheet ─────────────────────────────────────────────────────────
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      modalBackgroundColor: surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GallaRadius.bottomSheet),
        ),
      ),
      showDragHandle: false,
      elevation: 0,
      modalElevation: 0,
    ),

    // ── Misc ─────────────────────────────────────────────────────────────────
    dividerColor: line,
    dividerTheme: DividerThemeData(
      color: line,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: isDark ? GallaPalette.darkSurfaceElevated : brand,
      contentTextStyle: GoogleFonts.outfit(
        color: isDark ? GallaPalette.darkInk : Colors.white,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GallaRadius.md),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceAlt,
      selectedColor: brandSoft,
      labelStyle: GoogleFonts.outfit(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: ink,
      ),
      side: BorderSide(color: line),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GallaRadius.chip),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: GallaSpacing.base,
        vertical: GallaSpacing.xs,
      ),
    ),
  );
}
