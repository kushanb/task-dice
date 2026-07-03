import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens extracted from the TaskDice design handoff.
/// Single source: DESIGN.md — if a value here disagrees with DESIGN.md, stop
/// and reconcile there first.
abstract final class AppColors {
  // Surfaces
  static const background = Color(0xFF101216);
  static const surface = Color(0xFF181B21);
  static const surfaceRaised = Color(0xFF20242C);
  static const surfaceSunken = Color(0xFF101216);
  static const tabBarBackground = Color(0xEB101216); // 92%
  static const scrimSheet = Color(0x8C000000); // 55%
  static const scrimDialog = Color(0x99000000); // 60%

  // Text
  static const textPrimary = Color(0xFFEDEFF2);
  static const textSecondary = Color(0xFFC7CCD4);
  static const textTertiary = Color(0xFF8A919E);
  static const textFaint = Color(0xFF5B616C);

  // Accents + on-inks
  static const green = Color(0xFF35D07F);
  static const onGreen = Color(0xFF0B2417);
  static const amber = Color(0xFFE8B84B);
  static const onAmber = Color(0xFF231A05);
  static const red = Color(0xFFF26D6D);
  static const onRed = Color(0xFF2B0A0A);
  static const redSoftText = Color(0xFFF9B9B9);
  static const grey = Color(0xFF7A828E);

  // Accent tints
  static final greenTint = green.withValues(alpha: .10);
  static final greenTintStrong = green.withValues(alpha: .14);
  static final amberTint = amber.withValues(alpha: .12);
  static final amberTintStrong = amber.withValues(alpha: .14);
  static final redTint = red.withValues(alpha: .07);
  static final redBadgeTint = red.withValues(alpha: .13);

  // Borders (always 1 px)
  static const borderHairline = Color(0x12FFFFFF); // white 7%
  static const borderInput = Color(0x17FFFFFF); // white 9%
  static const borderStrong = Color(0x1FFFFFFF); // white 12%
  static const borderFocused = Color(0x33FFFFFF); // white 20%
  static final borderGreen = green.withValues(alpha: .35);
  static final borderAmber = amber.withValues(alpha: .35);
  static final borderAmberLive = amber.withValues(alpha: .50);
  static final borderRed = red.withValues(alpha: .40);

  // Bars, tracks & charts
  static const track = Color(0x14FFFFFF); // white 8%
  static const barEstimate = Color(0x26FFFFFF); // white 15%
  static const chartDotMuted = Color(0x40FFFFFF); // white 25%

  // Inverse (FAB, toast)
  static const inverseSurface = Color(0xFFEDEFF2);
  static const inverseText = Color(0xFF101216);

  /// Heatmap cell color: `green` at [intensity] 0..1 (alpha ramp).
  static Color heatmap(double intensity) =>
      green.withValues(alpha: intensity.clamp(.05, 1.0));

  // Gradients (160° ≈ top-left → bottom-right, slightly steep)
  static final heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [green.withValues(alpha: .14), green.withValues(alpha: .04)],
  );
  static final levelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [green.withValues(alpha: .12), green.withValues(alpha: .03)],
  );
}

/// Type roles. Instrument Sans for UI; IBM Plex Mono for anything time-shaped
/// or countable (timers, points, ratios, overlines, timestamps).
abstract final class AppText {
  static TextStyle _sans(double size, FontWeight w,
          {double? height, double? spacing, Color color = AppColors.textPrimary}) =>
      GoogleFonts.instrumentSans(
          fontSize: size, fontWeight: w, height: height, letterSpacing: spacing, color: color);

  static TextStyle _mono(double size, FontWeight w,
          {double? spacing, Color color = AppColors.textPrimary}) =>
      GoogleFonts.ibmPlexMono(
          fontSize: size,
          fontWeight: w,
          letterSpacing: spacing,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()]);

  // Mono roles
  static final timerDisplay = _mono(64, FontWeight.w600, spacing: -1.28);
  static final timerMedium = _mono(32, FontWeight.w600);
  static final ringValueLarge = _mono(30, FontWeight.w600);
  static final ringValue = _mono(24, FontWeight.w600);
  static final statValue = _mono(20, FontWeight.w600);
  static final statValueSmall = _mono(18, FontWeight.w600);
  static final monoValue = _mono(14, FontWeight.w600);
  static final monoBody = _mono(13, FontWeight.w500);
  static final monoCaption = _mono(11.5, FontWeight.w500);
  static final overline =
      _mono(11, FontWeight.w600, spacing: 1.32); // uppercase, +0.12em

  // Sans roles
  static final pageTitle = _sans(24, FontWeight.w700, spacing: -0.24);
  static final focusTitle = _sans(19, FontWeight.w600, height: 1.35);
  static final cardTitle = _sans(17, FontWeight.w700);
  static final heroTitle = _sans(16.5, FontWeight.w600);
  static final taskTitle = _sans(14.5, FontWeight.w600);
  static final itemTitle = _sans(14, FontWeight.w500);
  static final body = _sans(13.5, FontWeight.w400,
      height: 1.5, color: AppColors.textTertiary);
  static final meta =
      _sans(12, FontWeight.w400, color: AppColors.textTertiary);
  static final caption =
      _sans(11.5, FontWeight.w400, color: AppColors.textFaint);
  static final micro =
      _sans(10.5, FontWeight.w400, color: AppColors.textFaint);

  // Buttons & chips
  static final buttonLarge = _sans(17, FontWeight.w700);
  static final button = _sans(14, FontWeight.w700);
  static final buttonSecondary =
      _sans(13.5, FontWeight.w600, color: AppColors.textSecondary);
  static final chip = _sans(12, FontWeight.w500);
  static final chipBold = _sans(11.5, FontWeight.w600);
  static final tabLabel = _sans(12, FontWeight.w600);
}

/// Spacing scale, named by pixel value.
abstract final class AppSpacing {
  static const s2 = 2.0;
  static const s4 = 4.0;
  static const s6 = 6.0;
  static const s8 = 8.0;
  static const s10 = 10.0;
  static const s12 = 12.0;
  static const s14 = 14.0;
  static const s16 = 16.0;
  static const s18 = 18.0;
  static const s20 = 20.0;
  static const s24 = 24.0;

  /// Standard screen padding: 20 horizontal, 12 top.
  static const screen = EdgeInsets.fromLTRB(20, 12, 20, 0);

  /// Bottom padding on scrollables so content clears tab bar + FAB.
  static const scrollBottom = 120.0;
}

abstract final class AppRadii {
  static const rBadge = 6.0;
  static const rChip = 8.0;
  static const rInput = 10.0;
  static const rButton = 12.0;
  static const rCardSmall = 14.0;
  static const rCard = 16.0;
  static const rCardProminent = 18.0;
  static const rCardHero = 20.0;
  static const rSheet = 26.0;
  static const rDice = 28.0;
  static const rPill = 999.0;
}

abstract final class AppShadows {
  /// FAB, toast.
  static const floating = [
    BoxShadow(color: Color(0x80000000), offset: Offset(0, 8), blurRadius: 24),
  ];

  /// Dice, popovers (energy check-in).
  static const overlay = [
    BoxShadow(color: Color(0x66000000), offset: Offset(0, 12), blurRadius: 32),
  ];
}

abstract final class AppMotion {
  static const emphasized = Cubic(0.22, 1.0, 0.36, 1.0);
  static const popIn = Duration(milliseconds: 300);
  static const sheetUp = Duration(milliseconds: 300);
  static const toastUp = Duration(milliseconds: 300);
  static const toastHold = Duration(milliseconds: 2400);
  static const breathe = Duration(seconds: 2);
  static const diceShake = Duration(milliseconds: 500);
  static const rollDuration = Duration(milliseconds: 1450);
  static const rollNameCycle = Duration(milliseconds: 110);
  static const ringFill = Duration(milliseconds: 800);
  static const barFill = Duration(milliseconds: 500);
  static const pressScale = 0.97;
}
