import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

export '../constants/app_enums.dart';

class AppConfig {
  static const String appName = '灵感笔';
  static const String appNameEn = 'ContentSpark';
  static const String version = '1.0.0';

  static String get glmApiKey {
    final key = dotenv.env['GLM_API_KEY'] ?? '';
    if (key.isNotEmpty && !key.startsWith('your_')) return key;
    return const String.fromEnvironment('GLM_API_KEY', defaultValue: '');
  }

  static String get glmBaseUrl =>
      dotenv.env['GLM_BASE_URL'] ?? 'https://api.z.ai/api/paas/v4';

  static String get glmModel =>
      dotenv.env['GLM_MODEL'] ?? 'glm-4-flash';

  // 新暗色系色彩
  static const Color primaryColor = Color(0xFF7C5CFC);
  static const Color accentColor = Color(0xFF00D9A6);
  static const Color accentPink = Color(0xFFFF6B8A);
  static const Color deepBg = Color(0xFF0A0B1A);
  static const Color surfaceDark = Color(0xFF12132B);
  static const Color surfaceLight = Color(0xFF1A1C3F);
  static const Color textPrimary = Color(0xFFF0F0FF);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color glassBorder = Color(0x33FFFFFF);
}
