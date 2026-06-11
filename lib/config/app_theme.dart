import 'package:flutter/material.dart';
import 'app_config.dart';

class AppTheme {
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: AppConfig.primaryColor,
        scaffoldBackgroundColor: AppConfig.deepBg,
        fontFamily: 'PingFang SC',

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppConfig.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          iconTheme: IconThemeData(color: AppConfig.textPrimary, size: 22),
        ),

        cardTheme: CardThemeData(
          color: AppConfig.surfaceDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppConfig.glassBorder, width: 0.5),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConfig.primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
        ),

        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppConfig.accentColor,
            side: const BorderSide(color: AppConfig.accentColor, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppConfig.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppConfig.primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          hintStyle: const TextStyle(color: AppConfig.textSecondary, fontSize: 14),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: AppConfig.surfaceLight,
          selectedColor: AppConfig.primaryColor.withValues(alpha: 0.25),
          labelStyle: const TextStyle(fontSize: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          side: BorderSide.none,
        ),

        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppConfig.surfaceDark,
          selectedItemColor: AppConfig.accentColor,
          unselectedItemColor: AppConfig.textSecondary,
          selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          unselectedLabelStyle: TextStyle(fontSize: 11),
          elevation: 0,
        ),

        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppConfig.textPrimary, letterSpacing: -0.5),
          headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppConfig.textPrimary),
          headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppConfig.textPrimary),
          bodyLarge: TextStyle(fontSize: 16, color: AppConfig.textPrimary, height: 1.6),
          bodyMedium: TextStyle(fontSize: 14, color: AppConfig.textPrimary, height: 1.6),
          bodySmall: TextStyle(fontSize: 12, color: AppConfig.textSecondary),
        ),
      );

  /// 玻璃拟态容器装饰
  static BoxDecoration glassBox({Color? tintColor, double radius = 20}) => BoxDecoration(
        color: (tintColor ?? AppConfig.surfaceDark).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppConfig.glassBorder, width: 0.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.02),
          ],
        ),
      );

  /// 发光按钮装饰
  static BoxDecoration glowButton({Color color = AppConfig.primaryColor}) => BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 4)),
        ],
      );
}
