// =====================================================================
// DarImmo - Thème de l'application (couleurs des maquettes v3 « Sidi Bou Saïd »)
// Source : projet_3eme/design/src/spec.js (TOKENS, mode clair).
// À reprendre dans le squelette officiel (tâche 1.6).
// =====================================================================
import 'package:flutter/material.dart';

abstract final class DarColors {
  static const primary = Color(0xFF1D5FAD); // Bleu Sidi Bou Saïd
  static const primaryDark = Color(0xFF133F75);
  static const primarySoft = Color(0xFFE5EEF9);
  static const accent = Color(0xFFB85A26); // Ocre
  static const bg = Color(0xFFF6F4EF); // Sable clair
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFEFECE5);
  static const text = Color(0xFF14203A);
  static const text2 = Color(0xFF47526A);
  static const muted = Color(0xFF737C8F);
  static const border = Color(0xFFE4DFD4);
  static const success = Color(0xFF17784F);
  static const successSoft = Color(0xFFE2F3EA);
  static const warning = Color(0xFF9A6412);
  static const warningSoft = Color(0xFFFBF1DC);
  static const danger = Color(0xFFC23838);
  static const dangerSoft = Color(0xFFFBE6E4);
}

ThemeData darimmoTheme() {
  OutlineInputBorder bord(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );
  final scheme = ColorScheme.fromSeed(
    seedColor: DarColors.primary,
    primary: DarColors.primary,
    secondary: DarColors.accent,
    surface: DarColors.surface,
    error: DarColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: DarColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: DarColors.bg,
      foregroundColor: DarColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: DarColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: const TextStyle(color: DarColors.muted, fontWeight: FontWeight.w500),
      border: bord(DarColors.border),
      enabledBorder: bord(DarColors.border),
      focusedBorder: bord(DarColors.primary, 1.5),
      errorBorder: bord(DarColors.danger, 1.5),
      focusedErrorBorder: bord(DarColors.danger, 1.5),
      errorStyle: const TextStyle(fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(54),
        foregroundColor: DarColors.text,
        side: const BorderSide(color: DarColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
  );
}
