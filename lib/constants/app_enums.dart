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
  article('图文内容', Icons.auto_awesome),
  videoScript('视频脚本', Icons.movie_creation_rounded),
  titleOptimize('标题优化', Icons.title_rounded),
  topicIdea('选题灵感', Icons.lightbulb_rounded),
  rewrite('多平台改写', Icons.transform_rounded);

  final String displayName;
  final IconData icon;

  const ContentType(this.displayName, this.icon);
}

/// 创作模式（V2 新增）
enum CreateMode {
  create('创作', '✍️', Icons.edit_rounded),
  adapt('改编', '🔄', Icons.swap_horiz_rounded),
  deai('去AI味', '🧹', Icons.auto_fix_high_rounded);

  final String displayName;
  final String emoji;
  final IconData icon;

  const CreateMode(this.displayName, this.emoji, this.icon);
}

/// 内容品类
enum ContentCategory {
  beauty('美妆护肤'),
  food('美食探店'),
  tech('数码科技'),
  fashion('穿搭时尚'),
  fitness('运动健身'),
  travel('旅行出游'),
  education('教育学习'),
  baby('母婴育儿'),
  pet('萌宠'),
  home('家居装修'),
  finance('财经理财'),
  emotion('情感生活'),
  workplace('职场干货'),
  entertainment('影视娱乐'),
  game('游戏电竞');

  final String displayName;
  const ContentCategory(this.displayName);
}

/// 热点来源平台
enum HotSource {
  weibo('微博热搜', '🟠', Color(0xFFFF8200)),
  baidu('百度热搜', '🔵', Color(0xFF4E6EF2)),
  zhihu('知乎热榜', '🔵', Color(0xFF0066FF)),
  douyin('抖音热榜', '🎵', Color(0xFF00F2EA));

  final String displayName;
  final String emoji;
  final Color color;

  const HotSource(this.displayName, this.emoji, this.color);
}

/// 订阅方案
enum SubscriptionPlan {
  free('免费版', 0, 5, false, false, false),
  basic('基础版', 19.9, 999, true, false, false),
  pro('专业版', 39.9, 999, true, true, true),
  team('团队版', 199, 999, true, true, true);

  final String displayName;
  final double monthlyPrice;
  final int dailyQuota;
  final bool allPlatforms;
  final bool adaptMode;
  final bool deaiMode;

  const SubscriptionPlan(
    this.displayName,
    this.monthlyPrice,
    this.dailyQuota,
    this.allPlatforms,
    this.adaptMode,
    this.deaiMode,
  );
}
