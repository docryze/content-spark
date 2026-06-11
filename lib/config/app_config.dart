import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

export '../constants/app_enums.dart';

/// 应用全局配置
class AppConfig {
  static const String appName = '灵感笔';
  static const String appNameEn = 'ContentSpark';
  static const String version = '1.0.0';

  // GLM API 配置 — 从 .env 文件读取
  static String get glmApiKey {
    // 优先从 .env 读取
    final key = dotenv.env['GLM_API_KEY'] ?? '';
    if (key.isNotEmpty && !key.startsWith('your_')) return key;
    // 回退到编译参数
    return const String.fromEnvironment('GLM_API_KEY', defaultValue: '');
  }

  static String get glmBaseUrl =>
      dotenv.env['GLM_BASE_URL'] ?? 'https://api.z.ai/api/paas/v4';

  static String get glmModel =>
      dotenv.env['GLM_MODEL'] ?? 'glm-4-flash';

  // 主题色
  static const Color primaryColor = Color(0xFF6C5CE7);
  static const Color secondaryColor = Color(0xFFA29BFE);
  static const Color accentColor = Color(0xFFFF6B6B);
  static const Color backgroundColor = Color(0xFFF8F9FE);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF2D3436);
  static const Color textSecondary = Color(0xFF636E72);
}
