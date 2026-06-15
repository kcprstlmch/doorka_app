import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const appBackground = Color(0xFFF7F4ED);
const appSurface = Color(0xFFFFFFFF);
const appSurfaceSoft = Color(0xFFFAF9F5);
const appTextPrimary = Color(0xFF172019);
const appTextSecondary = Color(0xFF6A6F68);
const appBorder = Color(0xFFE4E0D7);
const appBorderStrong = Color(0xFFD8D4CA);
const appBrand = Color(0xFF2F5D50);
const appBrandSoft = Color(0xFFE7EFE8);
const appSuccess = Color(0xFF62BE72);
const appInfo = Color(0xFF2563A9);
const appWarning = Color(0xFFF0A202);
const appMuted = Color(0xFF6D6A75);
const appWorkDark = Color(0xFF101512);
const appWorkText = Color(0xFFDDEADF);
const appDanger = Color(0xFFD64545);

ThemeData buildAppTheme() {
  final baseTextTheme = GoogleFonts.interTextTheme();

  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: appBrand,
      brightness: Brightness.light,
      primary: appBrand,
      surface: appSurface,
      error: appDanger,
    ),
    textTheme: baseTextTheme.copyWith(
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: appTextPrimary,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: appTextPrimary,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: appTextPrimary,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: appTextPrimary,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: appTextSecondary,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      labelMedium: baseTextTheme.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: baseTextTheme.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    ),
    scaffoldBackgroundColor: appBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: appSurface,
      foregroundColor: appTextPrimary,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: appTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: appSurface,
      labelStyle: const TextStyle(
        color: appTextSecondary,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: appBorderStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: appBorderStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: appBrand, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: appBrand,
        foregroundColor: appSurface,
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: appTextPrimary,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: appBorderStrong),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    useMaterial3: true,
  );
}
