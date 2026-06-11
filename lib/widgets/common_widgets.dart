import 'package:flutter/material.dart';
import '../constants/app_enums.dart';
import '../config/app_config.dart';

/// 内容类型图标
IconData getContentTypeIcon(ContentType type) {
  switch (type) {
    case ContentType.article: return Icons.auto_awesome;
    case ContentType.videoScript: return Icons.videocam;
    case ContentType.titleOptimize: return Icons.title;
    case ContentType.topicIdea: return Icons.lightbulb;
    case ContentType.rewrite: return Icons.transform;
  }
}
