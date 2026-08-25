import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Color System ───────────────────────────────────────────────────────────────

class GallaColors {
  // Background layers
  static const canvas = Color(0xFFF7F4EF); // Warm cream background
  static const surface = Color(0xFFFFFFFF); // Card / sheet surface
  static const surfaceAlt = Color(0xFFF3EEE6); // Subtle alternative surface
  static const surface2 = Color(0xFFF8F5EE); // Nested card / container surface
  static const surfaceElevated = Color(0xFFFAF8F4); // Slightly elevated surface

  // Text
  static const ink = Color(0xFF181818); // Primary text — near black
  static const inkSecondary = Color(0xFF3D3D3D); // Secondary ink
  static const muted = Color(0xFF787878); // Secondary / label text
  static const faint = Color(0xFFAEA696); // Placeholder / disabled

  // Borders & Dividers
  static const line = Color(0xFFEAE4DA);
  static const lineSoft = Color(0xFFF0EBE2);
  static const lineFocus = Color(0xFF1A3B2E);

  // Brand — Deep Forest Green
  static const brand = Color(0xFF1A3B2E); // Dark forest green (main)
  static const brandMid = Color(0xFF2D5A40); // Medium brand for buttons
  static const brandLight = Color(0xFF3D7A57); // Lighter brand for accents
  static const brandSoft = Color(0xFFE6F0EA); // Soft brand background
  static const brandSofter = Color(0xFFF0F7F2); // Very soft brand background

  /// Gradient for hero surfaces (balance card, FAB face).
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF244837), Color(0xFF163326)],
  );

  // Accent — Warm Gold (Trust & Prosperity)
  static const gold = Color(0xFFB8962E);
  static const goldLight = Color(0xFFE8C547);
  static const goldMid = Color(0xFFD4AF37);
  static const goldDark = Color(0xFF8C7018);
  static const goldSoft = Color(0xFFFDF8EB);
  static const goldSofter = Color(0xFFFFFDF5);

  // Income — Green (semantic)
  static const moneyIn = Color(0xFF1B7A3E);
  static const moneyInMid = Color(0xFF22994D);
  static const moneyInSoft = Color(0xFFEAF5ED);
  static const moneyInTag = Color(0xFF1B7A3E);

  // Income/Expense variants for dark (brand) surfaces
  static const moneyInOnDark = Color(0xFF6EDB96);
  static const moneyOutOnDark = Color(0xFFFF9595);

  // Expense — Muted Red (semantic)
  static const moneyOut = Color(0xFFC0392B);
  static const moneyOutMid = Color(0xFFD44333);
  static const moneyOutSoft = Color(0xFFFDEBEA);
  static const moneyOutTag = Color(0xFFC0392B);

  // Udhaar / Pending — Amber (semantic)
  static const udhaar = Color(0xFFB45309); // Deep amber — trust-building
  static const udhaarMid = Color(0xFFCA6A09);
  static const udhaarSoft = Color(0xFFFEF3E2);
  static const udhaarSofter = Color(0xFFFEF8EF);

  // Deprecated — kept for backwards compat
  static const amber = Color(0xFFB45309);
  static const amberSoft = Color(0xFFFEF3E2);

  // Blue — Informational / Secondary
  static const blue = Color(0xFF1D4ED8);
  static const blueMid = Color(0xFF2563EB);
  static const blueSoft = Color(0xFFEFF4FF);

  // Nepal Payment Methods
  static const fonepay = Color(0xFFE51A24);
  static const fonepaySoft = Color(0xFFFDECEE);
  static const esewa = Color(0xFF60BB46);
  static const esewaSoft = Color(0xFFEFF8EC);
  static const khalti = Color(0xFF5C2D91);
  static const khaltiSoft = Color(0xFFF3EDFA);
}

// ── Animations Scale ───────────────────────────────────────────────────────────

class GallaAnimations {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
  static const spring = Cubic(0.175, 0.885, 0.32, 1.275);
  static const easeOut = Curves.easeOutCubic;
}

// ── Typography ─────────────────────────────────────────────────────────────────
/// Semantic text styles for feature code. Prefer these over hand-written
/// `TextStyle(fontSize: …)` literals so type stays consistent app-wide.
///
/// Title/number roles default to [GallaColors.ink]; caption/label roles to
/// [GallaColors.muted]. Override per-site with `.copyWith(color: …)` — never
/// re-declare size or weight inline.
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
  static final hero = _s(
    38,
    FontWeight.w800,
    -1.2,
    GallaColors.ink,
    height: 1.0,
  );
  static final totalLg = _s(32, FontWeight.w800, -1.0, GallaColors.ink);
  static final total = _s(28, FontWeight.w800, -0.8, GallaColors.ink);
  static final numberXl = _s(24, FontWeight.w800, -0.5, GallaColors.ink);
  static final numberLg = _s(20, FontWeight.w800, -0.3, GallaColors.ink);
  static final numberMd = _s(18, FontWeight.w800, -0.3, GallaColors.ink);
  static final number = _s(16, FontWeight.w800, -0.3, GallaColors.ink);
  static final numberSm = _s(15, FontWeight.w800, -0.3, GallaColors.ink);

  // Titles — ink
  static final screenTitle = _s(22, FontWeight.w800, null, GallaColors.ink);
  static final cardTitle = _s(16, FontWeight.w700, null, GallaColors.ink);
  static final tileTitle = _s(15, FontWeight.w700, -0.1, GallaColors.ink);
  static final subtitle = _s(14, FontWeight.w700, null, GallaColors.ink);
  static final subtitleSm = _s(13, FontWeight.w700, null, GallaColors.ink);

  // Body — ink
  static final bodyStrong = _s(13, FontWeight.w600, null, GallaColors.ink);
  static final body = _s(13, FontWeight.w400, null, GallaColors.ink);

  // Labels & captions — muted unless overridden
  static final chipLabel = _s(12, FontWeight.w700, null, GallaColors.ink);
  static final labelStrong = _s(11, FontWeight.w700, null, GallaColors.ink);
  static final label = _s(12, FontWeight.w600, null, GallaColors.muted);
  static final labelSm = _s(11, FontWeight.w600, null, GallaColors.muted);
  static final caption = _s(12, FontWeight.w400, null, GallaColors.muted);
  static final captionSm = _s(11, FontWeight.w400, null, GallaColors.muted);
  static final badge = _s(10, FontWeight.w700, null, GallaColors.ink);
  static final overline = _s(11, FontWeight.w700, 0.6, GallaColors.muted);
}

// ── Elevation & Shadows ────────────────────────────────────────────────────────

class GallaElevation {
  static List<BoxShadow> card = [
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

  static List<BoxShadow> hero = [
    BoxShadow(
      color: const Color(0xFF1A3B2E).withValues(alpha: 0.22),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> sheet = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
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
  static const double sectionGap = 20;
  static const double cardPadding = 18;
  static const double tileVertical = 10;
  static const double pageHorizontal = 16;
  static const double bottomNavHeight = 64;
  static const double fabSize = 62;

  /// Vertical clearance tab content must keep from the screen bottom so the
  /// last items never sit under the center-docked FAB, its protrusion above
  /// the bottom bar, or its glow. Combine with MediaQuery bottom padding.
  static const double shellBottomClearance = bottomNavHeight + 56;
}

// ── Radius Scale ───────────────────────────────────────────────────────────────

class GallaRadius {
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 100;

  // Semantic radii
  static const double card = 16;
  static const double button = 14;
  static const double chip = 8;
  static const double bottomSheet = 24;
  static const double avatar = 100;
  static const double badge = 8;
}

// ── Theme Builder ──────────────────────────────────────────────────────────────

ThemeData buildGallaTheme() {
  final base = GoogleFonts.outfitTextTheme();

  final textTheme = base.copyWith(
    // Hero financial number — cash on hand, large balance
    displayLarge: GoogleFonts.outfit(
      fontSize: 42,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.5,
      height: 1.0,
      color: GallaColors.ink,
    ),
    // Large financial number — section totals
    displayMedium: GoogleFonts.outfit(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      height: 1.05,
      color: GallaColors.ink,
    ),
    // Medium financial number — card amounts
    displaySmall: GoogleFonts.outfit(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      height: 1.1,
      color: GallaColors.ink,
    ),
    // Page / section titles
    headlineMedium: GoogleFonts.outfit(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: GallaColors.ink,
    ),
    headlineSmall: GoogleFonts.outfit(
      fontSize: 19,
      fontWeight: FontWeight.w700,
      color: GallaColors.ink,
    ),
    titleLarge: GoogleFonts.outfit(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: GallaColors.ink,
    ),
    titleMedium: GoogleFonts.outfit(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: GallaColors.ink,
    ),
    titleSmall: GoogleFonts.outfit(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: GallaColors.ink,
    ),
    bodyLarge: GoogleFonts.outfit(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: GallaColors.ink,
    ),
    bodyMedium: GoogleFonts.outfit(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: GallaColors.muted,
    ),
    bodySmall: GoogleFonts.outfit(
      fontSize: 11,
      fontWeight: FontWeight.w400,
      color: GallaColors.muted,
    ),
    labelLarge: GoogleFonts.outfit(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
      color: GallaColors.ink,
    ),
    labelMedium: GoogleFonts.outfit(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: GallaColors.muted,
    ),
    labelSmall: GoogleFonts.outfit(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: GallaColors.muted,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: GallaColors.brand,
      onPrimary: Colors.white,
      secondary: GallaColors.moneyIn,
      onSecondary: Colors.white,
      tertiary: GallaColors.udhaar,
      surface: GallaColors.surface,
      onSurface: GallaColors.ink,
      surfaceContainerHighest: GallaColors.surfaceAlt,
      outline: GallaColors.line,
      outlineVariant: GallaColors.lineSoft,
      error: GallaColors.moneyOut,
    ),
    scaffoldBackgroundColor: GallaColors.canvas,
    textTheme: textTheme,

    // ── App Bar ─────────────────────────────────────────────────────────────
    appBarTheme: AppBarTheme(
      backgroundColor: GallaColors.canvas,
      foregroundColor: GallaColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: GallaColors.ink,
      ),
    ),

    // ── Cards ───────────────────────────────────────────────────────────────
    cardTheme: CardThemeData(
      color: GallaColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GallaRadius.card),
        side: const BorderSide(color: GallaColors.line, width: 1),
      ),
    ),

    // ── Inputs ──────────────────────────────────────────────────────────────
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: GallaColors.surface,
      hintStyle: GoogleFonts.outfit(color: GallaColors.faint, fontSize: 14),
      labelStyle: GoogleFonts.outfit(color: GallaColors.muted, fontSize: 14),
      floatingLabelStyle: GoogleFonts.outfit(
        color: GallaColors.brand,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GallaRadius.md),
        borderSide: const BorderSide(color: GallaColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GallaRadius.md),
        borderSide: const BorderSide(color: GallaColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(GallaRadius.md),
        borderSide: const BorderSide(color: GallaColors.brand, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),

    // ── Buttons ─────────────────────────────────────────────────────────────
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: GallaColors.brand,
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
        foregroundColor: GallaColors.brand,
        side: const BorderSide(color: GallaColors.brand, width: 1.5),
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
        foregroundColor: GallaColors.brand,
        textStyle: GoogleFonts.outfit(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    ),

    // ── Bottom Navigation ────────────────────────────────────────────────────
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: GallaColors.surface,
      elevation: 0,
      height: GallaSpacing.bottomNavHeight,
      indicatorColor: Colors.transparent,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? GallaColors.brand
              : GallaColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? GallaColors.brand
              : GallaColors.muted,
          size: 22,
        ),
      ),
    ),

    // ── Bottom Sheet ─────────────────────────────────────────────────────────
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: GallaColors.surface,
      modalBackgroundColor: GallaColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GallaRadius.bottomSheet),
        ),
      ),
      showDragHandle: false,
      elevation: 0,
      modalElevation: 0,
    ),

    // ── Misc ─────────────────────────────────────────────────────────────────
    dividerColor: GallaColors.line,
    dividerTheme: const DividerThemeData(
      color: GallaColors.line,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: GallaColors.brand,
      contentTextStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GallaRadius.md),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: GallaColors.surfaceAlt,
      selectedColor: GallaColors.brandSoft,
      labelStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w500),
      side: const BorderSide(color: GallaColors.line),
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
