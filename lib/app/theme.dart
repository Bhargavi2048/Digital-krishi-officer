import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Agricultural Color Palette
  static const Color primaryGreen = Color(0xFF2E7D32); // Forest/Krishi Green
  static const Color darkGreen = Color(0xFF1B5E20);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color surfaceGreen = Color(0xFFF1F8E9);
  static const Color accentGold = Color(0xFFFFA000); // Harvest Gold
  static const Color earthBrown = Color(0xFF6D4C41);
  static const Color warningOrange = Color(0xFFE65100);
  static const Color dangerRed = Color(0xFFC62828);

  // Light Theme
  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen,
        primary: primaryGreen,
        secondary: const Color(0xFF388E3C),
        tertiary: accentGold,
        surface: const Color(0xFFF9FAF9),
        error: dangerRed,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F8F6),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1B381F),
          fontSize: 20,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1B381F),
          fontSize: 24,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 15,
          color: const Color(0xFF263238),
          height: 1.45,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 13.5,
          color: const Color(0xFF455A64),
          height: 1.4,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B381F),
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1B381F),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1B381F)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1.5,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          minimumSize: const Size.fromHeight(50),
          side: const BorderSide(color: primaryGreen, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dangerRed),
        ),
        labelStyle: TextStyle(color: Colors.grey.shade700, fontSize: 14),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryGreen,
        unselectedItemColor: Color(0xFF78909C),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
      ),
    );
  }

  // Dark Theme (Comfortable night mode for rural settings)
  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lightGreen,
        primary: const Color(0xFF81C784),
        secondary: const Color(0xFFA5D6A7),
        tertiary: accentGold,
        surface: const Color(0xFF1E2B20),
        brightness: Brightness.dark,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF121B13),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: const Color(0xFFE8F5E9),
          fontSize: 20,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          color: const Color(0xFFE8F5E9),
          fontSize: 24,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 15,
          color: const Color(0xFFECEFF1),
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 13.5,
          color: const Color(0xFFCFD8DC),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF172218),
        foregroundColor: const Color(0xFFE8F5E9),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFE8F5E9),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1B281D),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E2B20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF172218),
        selectedItemColor: Color(0xFF81C784),
        unselectedItemColor: Color(0xFF90A4AE),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // High-Contrast Outdoor Field Theme (Maximum sunlight visibility in open fields)
  static ThemeData get outdoorTheme {
    const Color outdoorBg = Color(0xFF000000);
    const Color outdoorCard = Color(0xFF0D0D0D);
    const Color outdoorYellow = Color(0xFFFFD600);
    const Color outdoorGreen = Color(0xFF00E676);
    const Color outdoorWhite = Color(0xFFFFFFFF);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: outdoorYellow,
        onPrimary: Color(0xFF000000),
        secondary: outdoorGreen,
        onSecondary: Color(0xFF000000),
        tertiary: outdoorYellow,
        onTertiary: Color(0xFF000000),
        error: Color(0xFFFF1744),
        onError: outdoorWhite,
        surface: outdoorCard,
        onSurface: outdoorWhite,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: outdoorBg,
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.poppins(
          fontWeight: FontWeight.w800,
          color: outdoorWhite,
          fontSize: 20,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontWeight: FontWeight.w800,
          color: outdoorYellow,
          fontSize: 24,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: outdoorWhite,
          height: 1.45,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: outdoorWhite,
          height: 1.4,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: outdoorBg,
        foregroundColor: outdoorYellow,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 19,
          fontWeight: FontWeight.w800,
          color: outdoorYellow,
        ),
        iconTheme: const IconThemeData(color: outdoorYellow),
      ),
      cardTheme: CardThemeData(
        color: outdoorCard,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: outdoorYellow, width: 2.2),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: outdoorYellow,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: outdoorYellow,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: outdoorYellow, width: 2.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: outdoorCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outdoorYellow, width: 2.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outdoorYellow, width: 2.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: outdoorGreen, width: 2.5),
        ),
        labelStyle: const TextStyle(color: outdoorYellow, fontSize: 15, fontWeight: FontWeight.bold),
        hintStyle: const TextStyle(color: Color(0xFFB0BEC5), fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: outdoorBg,
        selectedItemColor: outdoorYellow,
        unselectedItemColor: outdoorWhite,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 11.5),
      ),
    );
  }
}
