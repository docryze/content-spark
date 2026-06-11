import 'package:flutter/material.dart';
import '../constants/app_enums.dart';
import '../config/app_config.dart';

/// 平台选择芯片组件
class PlatformSelector extends StatelessWidget {
  final SocialPlatform selected;
  final ValueChanged<SocialPlatform> onChanged;

  const PlatformSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: SocialPlatform.values.map((platform) {
          final isSelected = platform == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(platform),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppConfig.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppConfig.primaryColor : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: AppConfig.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(platform.emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      platform.displayName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppConfig.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 内容类型图标映射
IconData getContentTypeIcon(ContentType type) {
  switch (type) {
    case ContentType.article: return Icons.article;
    case ContentType.videoScript: return Icons.videocam;
    case ContentType.titleOptimize: return Icons.title;
    case ContentType.topicIdea: return Icons.lightbulb;
    case ContentType.rewrite: return Icons.transform;
  }
}

/// 内容类型选择卡片
class ContentTypeGrid extends StatelessWidget {
  final ContentType selected;
  final ValueChanged<ContentType> onChanged;

  const ContentTypeGrid({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: ContentType.values.map((type) {
          final isSelected = type == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppConfig.primaryColor.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppConfig.primaryColor : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      getContentTypeIcon(type),
                      color: isSelected ? AppConfig.primaryColor : AppConfig.textSecondary,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppConfig.primaryColor : AppConfig.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 创作领域选择器
class CategorySelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const CategorySelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: ContentCategory.values.map((cat) {
          final isSelected = cat.displayName == selected;
          return GestureDetector(
            onTap: () => onChanged(isSelected ? '' : cat.displayName),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppConfig.primaryColor.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppConfig.primaryColor : Colors.grey.shade200,
              ),
            ),
            child: Text(
              '${cat.emoji} ${cat.displayName}',
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppConfig.primaryColor : AppConfig.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
      ),
    );
  }
}

/// 生成结果卡片
class ResultCard extends StatelessWidget {
  final String label;
  final String content;
  final VoidCallback? onCopy;

  const ResultCard({
    super.key,
    required this.label,
    required this.content,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppConfig.primaryColor,
                ),
              ),
              if (onCopy != null)
                GestureDetector(
                  onTap: onCopy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppConfig.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '复制',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppConfig.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            content,
            style: const TextStyle(fontSize: 14, height: 1.7, color: AppConfig.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// 标题变体选择卡片
class TitleVariantCard extends StatelessWidget {
  final int index;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onCopy;

  const TitleVariantCard({
    super.key,
    required this.index,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppConfig.primaryColor.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppConfig.primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? AppConfig.primaryColor : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppConfig.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: AppConfig.textPrimary,
                ),
              ),
            ),
            if (onCopy != null)
              GestureDetector(
                onTap: onCopy,
                child: Icon(Icons.copy_rounded, size: 16, color: Colors.grey.shade400),
              ),
          ],
        ),
      ),
    );
  }
}
