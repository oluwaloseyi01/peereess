import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Extension helper — access tokens anywhere via context.appColors
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// Static raw tokens  (never used directly in UI — use AppColors via context)
// ─────────────────────────────────────────────────────────────────────────────
class AppColor {
  AppColor._();

  // ── Brand — Gold / Caramel ramp ───────────────────────────────────────────
  static const Color goldDeep = Color(0xFF7A4B1A); // darkest, headers dark
  static const Color goldPrimary = Color(0xFFB0864C); // main brand (light)
  static const Color goldMid = Color(0xFF9D6E2D); // icons, active states
  static const Color goldLight = Color(0xFFD4A96A); // buttons on dark bg
  static const Color goldSurface = Color(0xFFECD8B4); // icon bg, chips (light)
  static const Color goldDarkSurf = Color(0xFF2E2010); // icon bg, chips (dark)

  // ── Brand — Rose / Blush accent ───────────────────────────────────────────
  static const Color rosePrimary = Color(0xFFDD7394); // gradient, focus ring
  static const Color roseLight = Color(0xFFE8A3B8); // lighter hover
  static const Color roseSurface = Color(0xFFFDE8EF); // chip bg (light)
  static const Color roseDarkSurf = Color(0xFF2E1020); // chip bg (dark)

  // ── Warm neutrals — Light mode ────────────────────────────────────────────
  static const Color bgLight = Color(0xFFFAF6F1); // page bg (warm white)
  static const Color bgLight2 = Color(0xFFD9C2A2); // gradient top (light)
  static const Color cardLight = Color(0xFFFFFFFF); // card surface
  static const Color borderLight = Color(0xFFE2D0B8); // card borders
  static const Color inputBgLight = Color(0xFFE9E2E2); // search bar bg
  static const Color textPrimLight = Color(0xFF1A1208); // headlines
  static const Color textSecLight = Color(0xFF8A8989); // subtitles / captions

  // ── Warm neutrals — Dark mode ─────────────────────────────────────────────
  static const Color bgDark = Color(0xFF1A1510); // page bg
  static const Color bgDark2 = Color(0xFF2C2018); // gradient top (dark)
  static const Color cardDark = Color(0xFF252015); // card surface
  static const Color borderDark = Color(0xFF3D3020); // card borders
  static const Color inputBgDark = Color(0xFF2E2818); // search bar bg
  static const Color textPrimDark = Color(0xFFF5EFE6); // headlines
  static const Color textSecDark = Color(0xFF9E9080); // subtitles / captions

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF2E7D32);
}

// ─────────────────────────────────────────────────────────────────────────────
// ThemeExtension — use these in widgets via context.appColors
// ─────────────────────────────────────────────────────────────────────────────
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.primary,
    required this.primaryDeep,
    required this.primaryLight,
    required this.primarySurface,
    required this.accent,
    required this.accentLight,
    required this.accentSurface,
    required this.background,
    required this.backgroundTop,
    required this.card,
    required this.inputBg,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.navBar,
    required this.iconColor,
    required this.iconButtonBg,
    required this.focusBorder,
    required this.stepActive,
    required this.stepDone,
    required this.stepInactive,
    required this.headerGradient,
    required this.backgroundGradient,
  });

  // Brand
  final Color primary; // gold mid — icons, active text
  final Color primaryDeep; // gold deep — dark header
  final Color primaryLight; // gold light — buttons on dark
  final Color primarySurface; // gold surface — chip bg, icon bg

  // Accent (rose/blush)
  final Color accent; // rose — gradient, focus rings
  final Color accentLight; // rose light — hover
  final Color accentSurface; // rose surface — badge bg

  // Neutral
  final Color background;
  final Color backgroundTop; // gradient top colour
  final Color card;
  final Color inputBg;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color navBar;
  final Color iconColor;
  final Color iconButtonBg;

  // States
  final Color focusBorder; // focused input ring
  final Color stepActive; // stepper active dot
  final Color stepDone; // stepper done dot
  final Color stepInactive; // stepper inactive dot

  // Gradients
  final LinearGradient headerGradient;
  final LinearGradient backgroundGradient;

  // ── Light scheme ─────────────────────────────────────────────────────────
  static const AppColors light = AppColors(
    primary: AppColor.goldMid,
    primaryDeep: AppColor.goldDeep,
    primaryLight: AppColor.goldLight,
    primarySurface: AppColor.goldSurface,
    accent: AppColor.rosePrimary,
    accentLight: AppColor.roseLight,
    accentSurface: AppColor.roseSurface,
    background: AppColor.bgLight,
    backgroundTop: AppColor.bgLight2,
    card: AppColor.cardLight,
    inputBg: AppColor.inputBgLight,
    border: AppColor.borderLight,
    textPrimary: AppColor.textPrimLight,
    textSecondary: AppColor.textSecLight,
    navBar: AppColor.cardLight,
    iconColor: AppColor.goldMid,
    iconButtonBg: AppColor.goldSurface,
    focusBorder: AppColor.rosePrimary,
    stepActive: AppColor.goldPrimary,
    stepDone: AppColor.goldPrimary,
    stepInactive: Color(0xFFE0D0BC),
    headerGradient: LinearGradient(
      colors: [AppColor.goldDeep, AppColor.goldPrimary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [AppColor.bgLight2, AppColor.bgLight],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  // ── Dark scheme ──────────────────────────────────────────────────────────
  static const AppColors dark = AppColors(
    primary: AppColor.goldLight,
    primaryDeep: AppColor.goldDeep,
    primaryLight: AppColor.goldLight,
    primarySurface: AppColor.goldDarkSurf,
    accent: AppColor.roseLight,
    accentLight: AppColor.rosePrimary,
    accentSurface: AppColor.roseDarkSurf,
    background: AppColor.bgDark,
    backgroundTop: AppColor.bgDark2,
    card: AppColor.cardDark,
    inputBg: AppColor.inputBgDark,
    border: AppColor.borderDark,
    textPrimary: AppColor.textPrimDark,
    textSecondary: AppColor.textSecDark,
    navBar: Color(0xFF1E1810),
    iconColor: AppColor.goldLight,
    iconButtonBg: AppColor.goldDarkSurf,
    focusBorder: AppColor.roseLight,
    stepActive: AppColor.goldLight,
    stepDone: AppColor.goldLight,
    stepInactive: Color(0xFF3D3020),
    headerGradient: LinearGradient(
      colors: [Color(0xFF1A0E05), AppColor.goldDeep],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    backgroundGradient: LinearGradient(
      colors: [AppColor.bgDark2, AppColor.bgDark],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  // ── ThemeExtension boilerplate ────────────────────────────────────────────
  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryDeep,
    Color? primaryLight,
    Color? primarySurface,
    Color? accent,
    Color? accentLight,
    Color? accentSurface,
    Color? background,
    Color? backgroundTop,
    Color? card,
    Color? inputBg,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? navBar,
    Color? iconColor,
    Color? iconButtonBg,
    Color? focusBorder,
    Color? stepActive,
    Color? stepDone,
    Color? stepInactive,
    LinearGradient? headerGradient,
    LinearGradient? backgroundGradient,
  }) =>
      AppColors(
        primary: primary ?? this.primary,
        primaryDeep: primaryDeep ?? this.primaryDeep,
        primaryLight: primaryLight ?? this.primaryLight,
        primarySurface: primarySurface ?? this.primarySurface,
        accent: accent ?? this.accent,
        accentLight: accentLight ?? this.accentLight,
        accentSurface: accentSurface ?? this.accentSurface,
        background: background ?? this.background,
        backgroundTop: backgroundTop ?? this.backgroundTop,
        card: card ?? this.card,
        inputBg: inputBg ?? this.inputBg,
        border: border ?? this.border,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        navBar: navBar ?? this.navBar,
        iconColor: iconColor ?? this.iconColor,
        iconButtonBg: iconButtonBg ?? this.iconButtonBg,
        focusBorder: focusBorder ?? this.focusBorder,
        stepActive: stepActive ?? this.stepActive,
        stepDone: stepDone ?? this.stepDone,
        stepInactive: stepInactive ?? this.stepInactive,
        headerGradient: headerGradient ?? this.headerGradient,
        backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDeep: Color.lerp(primaryDeep, other.primaryDeep, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primarySurface: Color.lerp(primarySurface, other.primarySurface, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      accentSurface: Color.lerp(accentSurface, other.accentSurface, t)!,
      background: Color.lerp(background, other.background, t)!,
      backgroundTop: Color.lerp(backgroundTop, other.backgroundTop, t)!,
      card: Color.lerp(card, other.card, t)!,
      inputBg: Color.lerp(inputBg, other.inputBg, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
      iconColor: Color.lerp(iconColor, other.iconColor, t)!,
      iconButtonBg: Color.lerp(iconButtonBg, other.iconButtonBg, t)!,
      focusBorder: Color.lerp(focusBorder, other.focusBorder, t)!,
      stepActive: Color.lerp(stepActive, other.stepActive, t)!,
      stepDone: Color.lerp(stepDone, other.stepDone, t)!,
      stepInactive: Color.lerp(stepInactive, other.stepInactive, t)!,
      headerGradient: headerGradient, // gradients lerp separately if needed
      backgroundGradient: backgroundGradient,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ThemeData builders — pass into MaterialApp
// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColor.bgLight,
        cardColor: AppColor.cardLight,
        primaryColor: AppColor.goldMid,
        colorScheme: const ColorScheme.light(
          primary: AppColor.goldMid,
          secondary: AppColor.rosePrimary,
          surface: AppColor.cardLight,
          error: AppColor.error,
        ),
        extensions: const [AppColors.light],
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColor.bgDark,
        cardColor: AppColor.cardDark,
        primaryColor: AppColor.goldLight,
        colorScheme: const ColorScheme.dark(
          primary: AppColor.goldLight,
          secondary: AppColor.roseLight,
          surface: AppColor.cardDark,
          error: AppColor.error,
        ),
        extensions: const [AppColors.dark],
      );
}
