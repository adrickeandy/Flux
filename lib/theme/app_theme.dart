import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kPrimary  = Color(0xFFE91E8C);
const kBgLight  = Color(0xFFF5F8FF);
const kBgDark   = Color(0xFF070C1A);
const kCardLight = Color(0xFFFFFFFF);
const kCardDark  = Color(0xFF0F1729);

const kGradient = LinearGradient(
  colors: [Color(0xFF833AB4), Color(0xFFfd1d1d), Color(0xFFfcb045)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

ThemeData lightTheme() => ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    primary: kPrimary,
    surface: kBgLight,
    onSurface: const Color(0xFF111827),
  ),
  scaffoldBackgroundColor: kBgLight,
  cardColor: kCardLight,
  textTheme: GoogleFonts.interTextTheme().apply(
    bodyColor: const Color(0xFF111827),
    displayColor: const Color(0xFF111827),
  ),
  inputDecorationTheme: _inputTheme(false),
  useMaterial3: true,
);

ThemeData darkTheme() => ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: kPrimary,
    surface: kBgDark,
    onSurface: const Color(0xFFF0F4FF),
  ),
  scaffoldBackgroundColor: kBgDark,
  cardColor: kCardDark,
  textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
    bodyColor: const Color(0xFFF0F4FF),
    displayColor: const Color(0xFFF0F4FF),
  ),
  inputDecorationTheme: _inputTheme(true),
  useMaterial3: true,
);

InputDecorationTheme _inputTheme(bool dark) => InputDecorationTheme(
  filled: true,
  fillColor: dark ? kCardDark : Colors.white,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: BorderSide.none,
  ),
  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
);