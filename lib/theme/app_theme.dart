import 'package:flutter/material.dart';

/// Bevat alle theming voor de AutoMaat app (kleuren, fonts, input‑stijl).
class AppTheme {
  /// Donker thema zoals in de wireframes (achtergrond #1E1E1E, Bayon font).
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1E1E1E),
      fontFamily: 'Bayon',

      // Basisstijl voor alle TextButtons; specifieke knoppen (NEXT) krijgen
      // zo nodig een eigen TextStyle.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            letterSpacing: 4,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),

      // Inputvelden zoals op de wireframe: wit, rond, dunne grijze tekst.
      inputDecorationTheme: InputDecorationTheme(
        // Tekst in het veld (label/hint) lichtgrijs en dun.
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
        // Label blijft in het veld staan, i.p.v. erboven te zweven.
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

        // Hoogte en horizontale ruimte van de velden.
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
      ),

      // Algemene tekst: wit, dun.
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w400),
      ),
    );
  }
}
