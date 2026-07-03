import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_tokens.dart';

/// Builds the app-wide [ThemeData] from the tokens in app_tokens.dart.
/// TaskDice is a single fixed dark theme — there is no light variant.
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.dark(
    primary: AppColors.green,
    onPrimary: AppColors.onGreen,
    secondary: AppColors.amber,
    onSecondary: AppColors.onAmber,
    error: AppColors.red,
    onError: AppColors.onRed,
    surface: AppColors.background,
    onSurface: AppColors.textPrimary,
    surfaceContainerLowest: AppColors.background,
    surfaceContainer: AppColors.surface,
    surfaceContainerHigh: AppColors.surfaceRaised,
    onSurfaceVariant: AppColors.textTertiary,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.borderHairline,
    inverseSurface: AppColors.inverseSurface,
    onInverseSurface: AppColors.inverseText,
    scrim: AppColors.scrimSheet,
  );

  final textTheme = TextTheme(
    displayLarge: AppText.timerDisplay,
    displayMedium: AppText.timerMedium,
    headlineMedium: AppText.ringValue,
    titleLarge: AppText.pageTitle,
    titleMedium: AppText.cardTitle,
    titleSmall: AppText.taskTitle,
    bodyLarge: AppText.itemTitle,
    bodyMedium: AppText.body,
    bodySmall: AppText.meta,
    labelLarge: AppText.button,
    labelMedium: AppText.caption,
    labelSmall: AppText.overline,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: textTheme,
    splashFactory: NoSplash.splashFactory, // design uses press-scale, not ripples
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: AppText.pageTitle,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.rCard),
        side: const BorderSide(color: AppColors.borderHairline),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: AppText.itemTitle.copyWith(color: AppColors.textFaint),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s14, vertical: AppSpacing.s12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.rButton),
        borderSide: const BorderSide(color: AppColors.borderInput),
      ),
      // Focus stays quiet: brighter hairline, never the green accent.
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.rButton),
        borderSide: const BorderSide(color: AppColors.borderFocused),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.rButton),
        borderSide: const BorderSide(color: AppColors.borderInput),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.onGreen,
        textStyle: AppText.button,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s18, vertical: AppSpacing.s12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.rButton),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textSecondary,
        backgroundColor: AppColors.surfaceRaised,
        textStyle: AppText.buttonSecondary,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.rButton),
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      modalBackgroundColor: AppColors.surface,
      modalBarrierColor: AppColors.scrimSheet,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadii.rSheet)),
        side: BorderSide(color: AppColors.borderStrong),
      ),
      showDragHandle: true,
      dragHandleColor: Color(0x33FFFFFF),
      dragHandleSize: Size(36, 4),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      barrierColor: AppColors.scrimDialog,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.rCardHero),
        side: const BorderSide(color: AppColors.borderStrong),
      ),
      titleTextStyle: AppText.cardTitle,
      contentTextStyle: AppText.body,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.inverseSurface,
      contentTextStyle: AppText.chipBold
          .copyWith(fontSize: 13, color: AppColors.inverseText),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.rButton),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.inverseSurface,
      foregroundColor: AppColors.inverseText,
      elevation: 0,
      shape: CircleBorder(),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceRaised,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.rButton),
        side: const BorderSide(color: AppColors.borderStrong),
      ),
      textStyle: AppText.itemTitle.copyWith(fontSize: 13),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderHairline,
      thickness: 1,
      space: 1,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.tabBarBackground,
      selectedItemColor: AppColors.green,
      unselectedItemColor: AppColors.textFaint,
      selectedLabelStyle: AppText.tabLabel,
      unselectedLabelStyle: AppText.tabLabel,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
