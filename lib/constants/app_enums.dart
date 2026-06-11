import 'package:flutter/material.dart';

/// 平台枚举 - 支持6大社交平台
enum SocialPlatform {
  xiaohongshu('小红书', '🔴', 'xiaohongshu', Color(0xFFFF2442)),
  douyin('抖音', '🎵', 'douyin', Color(0xFF00F2EA)),
  wechat('公众号', '💚', 'wechat', Color(0xFF07C160)),
  bilibili('B站', '📺', 'bilibili', Color(0xFFFB7299)),
  weibo('微博', '🟠', 'weibo', Color(0xFFFF8200)),
  kuaishou('快手', '🎬', 'kuaishou', Color(0xFFFF4906));

  final String displayName;
  final String emoji;
  final String id;
  final Color accentColor;

  const SocialPlatform(this.displayName, this.emoji, this.id, this.accentColor);
}

/// 内容类型
enum ContentType {
  article('图文内容', 'article'),
  videoScript('视频脚本', 'video_script'),
  titleOptimize('标题优化', 'title_optimize'),
  topicIdea('选题灵感', 'topic_idea'),
  rewrite('多平台改写', 'rewrite');

  final String displayName;
  final String id;

  const ContentType(this.displayName, this.id);
}

/// 创作领域
enum ContentCategory {
  beauty('美妆护肤', '💄'),
  food('美食探店', '🍜'),
  fashion('穿搭时尚', '👗'),
  fitness('健身运动', '💪'),
  travel('旅行出游', '✈️'),
  tech('数码科技', '📱'),
  education('教育学习', '📚'),
  parenting('母婴育儿', '👶'),
  home('家居生活', '🏠'),
  finance('财经理财', '💰'),
  pets('萌宠', '🐕'),
  emotion('情感心理', '💖'),
  career('职场成长', '💼'),
  auto('汽车', '🚗'),
  entertainment('娱乐影视', '🎬');

  final String displayName;
  final String emoji;

  const ContentCategory(this.displayName, this.emoji);
}

/// 用户订阅方案
enum SubscriptionPlan {
  free('免费版', 0, 3),
  basic('基础版', 19.9, -1),
  pro('专业版', 39.9, -1),
  team('团队版', 199, -1);

  final String displayName;
  final double monthlyPrice;
  final int dailyQuota;

  const SubscriptionPlan(this.displayName, this.monthlyPrice, this.dailyQuota);
}
