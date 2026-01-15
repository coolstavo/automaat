import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      fontFamily: 'Bayon',

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            letterSpacing: 4,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(
          color: Color(0xFFBBBBBB),
          fontWeight: FontWeight.w400,
          letterSpacing: 2,
          fontSize: 12,
        ),
        hintStyle: const TextStyle(
          color: Color(0xFFBBBBBB),
          fontWeight: FontWeight.w400,
          letterSpacing: 2,
          fontSize: 12,
        ),

        floatingLabelBehavior: FloatingLabelBehavior.never,

        filled: true,
        fillColor: Colors.white,

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white, width: 0.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.white, width: 1.0),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
      ),

      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
      ),
    );
  }
}
