import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color scheme
  static const Color primaryColor = Color(0xFF0944B9);
  static const Color secondaryColor = Color(0xFF23AEDB);
  static const Color accentColor = Color(0xFF1D61E7);
  static const Color backgroundColor = Colors.white;
  static const Color errorColor = Color(0xFFD32F2F);

  // Text colors
  static const Color textPrimaryColor = Color(0xFF212121);
  static const Color textSecondaryColor = Color(0xFF757575);

  // Light theme
  static ThemeData lightTheme = ThemeData(
    // Color scheme
    primaryColor: primaryColor,
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
    ),
    scaffoldBackgroundColor: backgroundColor,

    // AppBar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
    ),

    // Text theme
    textTheme: TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimaryColor,
      ),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: textPrimaryColor),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondaryColor),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: textSecondaryColor),
    ),

    // Button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromARGB(255, 248, 248, 248),
      selectedItemColor: primaryColor,
      unselectedItemColor: Color.fromARGB(255, 112, 112, 112),
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),

    useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData();
}
