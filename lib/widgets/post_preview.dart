import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../constants/app_enums.dart';
import '../services/stream_content_parser.dart';

/// 社交平台帖子实时预览
/// 流式输出时实时渲染为真实帖子样式，而不是原始 JSON
class PostPreviewCard extends StatelessWidget {
  final StreamContentParser parsed;
  final SocialPlatform platform;
  final ContentType contentType;
  final bool isGenerating;
  final VoidCallback? onCopyAll;
  final VoidCallback? onCopyContent;

  const PostPreviewCard({
    super.key,
    required this.parsed,
    required this.platform,
    required this.contentType,
    this.isGenerating = false,
    this.onCopyAll,
    this.onCopyContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppConfig.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppConfig.glassBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === 帖子头部 ===
          _buildPostHeader(),

          // === 分割线 ===
          Container(height: 0.5, color: AppConfig.glassBorder),

          // === 内容区域 ===
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题区域
                if (parsed.titles.isNotEmpty) ...[
                  _buildTitles(),
                  const SizedBox(height: 16),
                ],

                // 选题灵感（特殊类型）
                if (contentType == ContentType.topicIdea && parsed.topics.isNotEmpty)
                  ..._buildTopicCards(),

                // 正文内容
                if (parsed.content.isNotEmpty) ...[
                  _buildContent(),
                  const SizedBox(height: 16),
                ],

                // 标签区域
                if (parsed.tags.isNotEmpty) ...[
                  _buildTags(),
                  const SizedBox(height: 14),
                ],

                // 封面 + 发布建议
                if (parsed.coverText.isNotEmpty || parsed.publishTime.isNotEmpty)
                  _buildMetaInfo(),

                // 标题优化分析
                if (parsed.analysis.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildAnalysis(),
                ],

                // 生成中指示器
                if (isGenerating) _buildTypingIndicator(),

                // 生成完成后的操作栏
                if (!isGenerating && parsed.content.isNotEmpty) _buildActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 帖子头部 — 模拟真实平台的帖子头
  Widget _buildPostHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            platform.accentColor.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.topRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: [
          // 平台头像
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [platform.accentColor, platform.accentColor.withValues(alpha: 0.7)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(platform.emoji, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: platform.accentColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${contentType.displayName} · ${isGenerating ? "生成中..." : "刚刚"}',
                  style: const TextStyle(fontSize: 11, color: AppConfig.textSecondary),
                ),
              ],
            ),
          ),
          // 状态标识
          if (isGenerating)
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: platform.accentColor,
              ),
            )
          else
            const Icon(Icons.check_circle, color: AppConfig.accentColor, size: 18),
        ],
      ),
    );
  }

  /// 标题区域 — 卡片式展示
  Widget _buildTitles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, decoration: BoxDecoration(color: platform.accentColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('推荐标题', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppConfig.textSecondary)),
          ],
        ),
        const SizedBox(height: 10),
        ...List.generate(parsed.titles.length, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: GestureDetector(
            onTap: () => _copy(parsed.titles[i]),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: i == 0 ? platform.accentColor.withValues(alpha: 0.08) : AppConfig.surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: i == 0 ? platform.accentColor.withValues(alpha: 0.3) : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: i == 0 ? platform.accentColor : AppConfig.surfaceDark,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w800,
                          color: i == 0 ? Colors.white : AppConfig.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      parsed.titles[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
                        color: AppConfig.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  Icon(Icons.copy_rounded, size: 14, color: AppConfig.textSecondary.withValues(alpha: 0.5)),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }

  /// 正文内容 — 像真实帖子正文一样渲染
  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 3, height: 14, decoration: BoxDecoration(color: platform.accentColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            const Text('正文内容', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppConfig.textSecondary)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppConfig.surfaceLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SelectableText(
            parsed.content,
            style: const TextStyle(
              fontSize: 14.5,
              height: 2.0,
              color: AppConfig.textPrimary,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }

  /// 标签 — 彩色胶囊
  Widget _buildTags() {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: parsed.tags.map((tag) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: platform.accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: platform.accentColor.withValues(alpha: 0.2)),
        ),
        child: Text(
          '#$tag',
          style: TextStyle(fontSize: 12, color: platform.accentColor, fontWeight: FontWeight.w600),
        ),
      )).toList(),
    );
  }

  /// 封面 + 发布建议
  Widget _buildMetaInfo() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConfig.accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppConfig.accentColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (parsed.coverText.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🖼️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(child: Text('封面文字：${parsed.coverText}', style: const TextStyle(fontSize: 13, color: AppConfig.textPrimary, height: 1.5))),
              ],
            ),
          if (parsed.publishTime.isNotEmpty) ...[
            if (parsed.coverText.isNotEmpty) const SizedBox(height: 6),
            Row(
              children: [
                const Text('⏰', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text('建议发布：${parsed.publishTime}', style: const TextStyle(fontSize: 13, color: AppConfig.textPrimary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 标题优化分析
  Widget _buildAnalysis() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppConfig.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 优化分析', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppConfig.primaryColor)),
          const SizedBox(height: 6),
          Text(parsed.analysis, style: const TextStyle(fontSize: 13, color: AppConfig.textPrimary, height: 1.6)),
        ],
      ),
    );
  }

  /// 选题灵感卡片
  List<Widget> _buildTopicCards() {
    return parsed.topics.asMap().entries.map((entry) {
      final i = entry.key;
      final t = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: i == 0 ? platform.accentColor.withValues(alpha: 0.08) : AppConfig.surfaceLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: i == 0 ? platform.accentColor.withValues(alpha: 0.25) : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: t['heat'] == '高' ? AppConfig.accentPink.withValues(alpha: 0.15) : AppConfig.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '🔥 ${t['heat'] ?? ''}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: t['heat'] == '高' ? AppConfig.accentPink : AppConfig.accentColor),
                    ),
                  ),
                  const Spacer(),
                  Text('#${i + 1}', style: const TextStyle(fontSize: 11, color: AppConfig.textSecondary)),
                ],
              ),
              const SizedBox(height: 8),
              Text(t['title'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppConfig.textPrimary)),
              if (t['reason']!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('💡 ${t['reason']}', style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary, height: 1.4)),
              ],
              if (t['angle']!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('🎯 ${t['angle']}', style: const TextStyle(fontSize: 12, color: AppConfig.accentColor, height: 1.4)),
              ],
            ],
          ),
        ),
      );
    }).toList();
  }

  /// 打字指示器
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: platform.accentColor),
          ),
          const SizedBox(width: 8),
          Text(
            'AI 正在输出...',
            style: TextStyle(fontSize: 11, color: platform.accentColor.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  /// 操作按钮栏
  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: _actionButton(Icons.copy_rounded, '复制正文', () => onCopyContent?.call()),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionButton(Icons.select_all_rounded, '复制全部', () => onCopyAll?.call()),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppConfig.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppConfig.glassBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: AppConfig.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppConfig.textPrimary)),
          ],
        ),
      ),
    );
  }

  void _copy(String text) {
    // 由外部处理
  }
}
