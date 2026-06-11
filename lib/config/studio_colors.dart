import 'package:flutter/material.dart';
import '../constants/app_enums.dart';

/// ═══════════════════════════════════════════════════════════════
///  灵感笔 ContentSpark — 暗色创意工作室配色系统
///  Design Direction: Glassmorphism + Per-Platform Accent
/// ═══════════════════════════════════════════════════════════════

class StudioColors {
  StudioColors._();

  // ─── 基础暗色背景 ───────────────────────────────────
  /// 主背景（深海蓝黑，区别于纯黑，保留层次感）
  static const Color background = Color(0xFF0D0D1A);

  /// Surface 层（卡片、弹窗底色，略亮于 background）
  static const Color surface = Color(0xFF161625);

  /// Surface 变体（hover / pressed 态）
  static const Color surfaceVariant = Color(0xFF1E1E32);

  /// 毛玻璃卡片底色（半透明）
  static const Color glassBackground = Color(0x1AFFFFFF); // 10% 白

  /// 毛玻璃边框
  static const Color glassBorder = Color(0x33FFFFFF); // 20% 白

  /// 毛玻璃高光（顶部反光带）
  static const Color glassHighlight = Color(0x0DFFFFFF); // 5% 白

  // ─── 通用前景色 ─────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0F8);
  static const Color textSecondary = Color(0xFF9A9AB0);
  static const Color textTertiary = Color(0xFF6B6B82);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  /// 分割线 / 边框
  static const Color divider = Color(0xFF2A2A3C);

  /// 禁用态
  static const Color disabled = Color(0xFF3A3A50);

  /// 成功 / 错误 / 警告
  static const Color success = Color(0xFF00D68F);
  static const Color error = Color(0xFFFF4D6A);
  static const Color warning = Color(0xFFFFAA2C);

  // ─── 每个平台的专属主题色 ─────────────────────────────

  /// 小红书 #FE2C55 — 玫红
  static const Color xiaohongshu = Color(0xFFFE2C55);

  /// 抖音 #00F2EA — 青色
  static const Color douyin = Color(0xFF00F2EA);

  /// 公众号 #07C160 — 绿色
  static const Color wechat = Color(0xFF07C160);

  /// B站 #FB7299 — 粉色
  static const Color bilibili = Color(0xFFFB7299);

  /// 微博 #FF8200 — 橙色
  static const Color weibo = Color(0xFFFF8200);

  /// 快手 #FF4906 — 红橙
  static const Color kuaishou = Color(0xFFFF4906);

  /// 默认 accent（未选平台时）
  static const Color defaultAccent = Color(0xFF8B7CF6); // 紫色调，创意感

  // ─── 平台色映射 ─────────────────────────────────────

  /// 根据 [SocialPlatform] 获取专属主题色
  static Color platformColor(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.xiaohongshu:
        return xiaohongshu;
      case SocialPlatform.douyin:
        return douyin;
      case SocialPlatform.wechat:
        return wechat;
      case SocialPlatform.bilibili:
        return bilibili;
      case SocialPlatform.weibo:
        return weibo;
      case SocialPlatform.kuaishou:
        return kuaishou;
    }
  }

  /// 获取平台色的「柔和版」（用于背景 tint、低饱和场景）
  static Color platformColorSoft(SocialPlatform platform) {
    return platformColor(platform).withOpacity(0.15);
  }

  /// 获取平台色的「光晕版」（用于 glow / shadow）
  static Color platformGlow(SocialPlatform platform) {
    return platformColor(platform).withOpacity(0.35);
  }

  /// 获取平台色的「渐变终点色」（与主色搭配的渐变副色）
  static Color platformGradientEnd(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.xiaohongshu:
        return const Color(0xFFFF6B81); // 浅玫红
      case SocialPlatform.douyin:
        return const Color(0xFF7B61FF); // 紫色（抖音标志色组合）
      case SocialPlatform.wechat:
        return const Color(0xFF4CD964); // 浅绿
      case SocialPlatform.bilibili:
        return const Color(0xFF9B59B6); // 淡紫
      case SocialPlatform.weibo:
        return const Color(0xFFFFC048); // 金黄
      case SocialPlatform.kuaishou:
        return const Color(0xFFFF6B35); // 橙红
    }
  }
}
