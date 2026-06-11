import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../constants/app_enums.dart';
import '../models/app_models.dart';
import '../providers/app_providers.dart';
import '../services/stream_content_parser.dart';
import '../widgets/post_preview.dart';

/// 全新首页 — 暗色玻璃拟态创意工作台
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _inputController = TextEditingController();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platform = ref.watch(selectedPlatformProvider);
    final contentType = ref.watch(selectedContentTypeProvider);
    final genState = ref.watch(streamGenProvider);
    final user = ref.watch(userProfileProvider);
    final isGenerating = genState.status == GenStatus.generating;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppConfig.deepBg, Color(0xFF0D0F2B)],
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          children: [
            // ===== 顶部 Header =====
            _buildHeader(user, platform),
            const SizedBox(height: 24),

            // ===== 平台选择 — 横向胶囊 =====
            _buildPlatformSelector(platform),
            const SizedBox(height: 20),

            // ===== 内容类型 — 圆角卡片网格 =====
            _buildContentTypeGrid(contentType),
            const SizedBox(height: 20),

            // ===== 灵感输入区 — 毛玻璃输入框 =====
            _buildInputArea(isGenerating),
            const SizedBox(height: 20),

            // ===== 流式输出区 — 打字机效果 =====
            if (genState.status != GenStatus.idle) _buildStreamOutput(genState),

            // ===== 生成按钮 — 渐变发光 =====
            if (genState.status == GenStatus.idle || genState.status == GenStatus.error)
              _buildGenerateButton(isGenerating),
            const SizedBox(height: 12),

            // ===== 配额提示 =====
            _buildQuotaHint(user),
          ],
        ),
      ),
    );
  }

  // ==================== UI 组件 ====================

  Widget _buildHeader(UserProfile user, SocialPlatform platform) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✨', style: TextStyle(fontSize: 28)),
              const SizedBox(height: 4),
              Text('你好，${user.nickname}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppConfig.textPrimary)),
              const SizedBox(height: 2),
              Text(
                AppConfig.disableQuota
                    ? '测试模式 · 无限制'
                    : '剩余 ${user.remainingQuota == 999 ? '∞' : user.remainingQuota} 次',
                style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary),
              ),
            ],
          ),
          // 当前平台胶囊
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppConfig.primaryColor.withValues(alpha: 0.2),
                AppConfig.accentColor.withValues(alpha: 0.1),
              ]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppConfig.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${platform.emoji}  ${platform.displayName}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppConfig.accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformSelector(SocialPlatform selected) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: SocialPlatform.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final p = SocialPlatform.values[index];
          final isActive = p == selected;
          return GestureDetector(
            onTap: () => ref.read(selectedPlatformProvider.notifier).state = p,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: isActive
                  ? AppTheme.glowButton(color: AppConfig.primaryColor)
                  : BoxDecoration(
                      color: AppConfig.surfaceDark,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppConfig.glassBorder),
                    ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Text(
                    p.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                      color: isActive ? Colors.white : AppConfig.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentTypeGrid(ContentType selected) {
    final items = ContentType.values;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: items.map((t) {
          final isActive = t == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => ref.read(selectedContentTypeProvider.notifier).state = t,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isActive ? AppConfig.accentColor.withValues(alpha: 0.12) : AppConfig.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isActive ? AppConfig.accentColor : AppConfig.glassBorder,
                    width: isActive ? 1.5 : 0.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _typeIcon(t),
                      color: isActive ? AppConfig.accentColor : AppConfig.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                        color: isActive ? AppConfig.accentColor : AppConfig.textSecondary,
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

  Widget _buildInputArea(bool isGenerating) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassBox(radius: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4, height: 20,
                  decoration: BoxDecoration(
                    color: AppConfig.accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _inputLabel(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppConfig.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _inputController,
              enabled: !isGenerating,
              maxLines: null,
              minLines: 3,
              style: const TextStyle(color: AppConfig.textPrimary, fontSize: 15, height: 1.6),
              decoration: InputDecoration(
                hintText: _inputHint(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 流式输出区域 — 实时帖子预览
  Widget _buildStreamOutput(StreamGenState state) {
    final hasError = state.status == GenStatus.error;
    final isDone = state.status == GenStatus.done;
    final isGenerating = state.status == GenStatus.generating;
    final platform = ref.read(selectedPlatformProvider);
    final contentType = ref.read(selectedContentTypeProvider);

    // 错误状态
    if (hasError) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppConfig.accentPink.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppConfig.accentPink.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: AppConfig.accentPink, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.errorMessage ?? '生成失败',
                  style: const TextStyle(fontSize: 14, color: AppConfig.accentPink),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 有解析内容 — 使用帖子预览卡片
    if (state.parsedContent != null) {
      final p = state.parsedContent!;
      // 只要解析出了任何有意义的内容就用预览卡片
      if (p.titles.isNotEmpty || p.content.isNotEmpty || p.tags.isNotEmpty || p.topics.isNotEmpty) {
        return Column(
          children: [
            PostPreviewCard(
              parsed: p,
              platform: platform,
              contentType: contentType,
              isGenerating: isGenerating,
              onCopyContent: () => _copyText(p.content),
              onCopyAll: () => _copyText(_formatAllContent(p)),
            ),
            if (isDone) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => ref.read(streamGenProvider.notifier).reset(),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('重新生成'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      }
    }

    // 还没有解析出内容 — 显示加载动画
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassBox(radius: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: platform.accentColor),
            ),
            const SizedBox(width: 12),
            Text(
              'AI 正在构思...',
              style: TextStyle(fontSize: 14, color: platform.accentColor, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /// 格式化全部内容（用于复制）
  String _formatAllContent(StreamContentParser p) {
    final buf = StringBuffer();
    if (p.titles.isNotEmpty) {
      buf.writeln('【标题】');
      for (var i = 0; i < p.titles.length; i++) {
        buf.writeln('${i + 1}. ${p.titles[i]}');
      }
      buf.writeln();
    }
    if (p.content.isNotEmpty) {
      buf.writeln('【正文】');
      buf.writeln(p.content);
      buf.writeln();
    }
    if (p.tags.isNotEmpty) {
      buf.writeln('【标签】${p.tags.map((t) => '#$t').join(' ')}');
    }
    if (p.coverText.isNotEmpty) buf.writeln('\n【封面】${p.coverText}');
    if (p.publishTime.isNotEmpty) buf.writeln('【发布时间】${p.publishTime}');
    return buf.toString();
  }

  Widget _buildGenerateButton(bool isGenerating) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _generate,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: AppTheme.glowButton(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('✨  开始创作', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuotaHint(UserProfile user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppConfig.accentColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppConfig.accentColor.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '描述越具体，生成越精准。例如："夏日油皮防晒霜推荐，学生党平价款"',
                style: TextStyle(fontSize: 12, color: AppConfig.accentColor.withValues(alpha: 0.8), height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== 辅助 ====================

  void _generate() {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入创作主题'), backgroundColor: AppConfig.accentPink, behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final category = ref.read(selectedCategoryProvider);
    ref.read(streamGenProvider.notifier).startGeneration(
      userInput: input,
      category: category.isEmpty ? null : category,
    );
  }

  void _copyText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ 已复制到剪贴板'), duration: Duration(seconds: 1), behavior: SnackBarBehavior.floating),
    );
  }

  String _inputLabel() {
    switch (ref.read(selectedContentTypeProvider)) {
      case ContentType.article: return '描述你想创作的内容';
      case ContentType.videoScript: return '描述你的视频创意';
      case ContentType.titleOptimize: return '粘贴需要优化的标题';
      case ContentType.topicIdea: return '输入你的创作领域';
      case ContentType.rewrite: return '粘贴需要改写的内容';
    }
  }

  String _inputHint() {
    switch (ref.read(selectedContentTypeProvider)) {
      case ContentType.article: return '例如：夏日防晒霜推荐，学生党平价款...';
      case ContentType.videoScript: return '例如：3分钟教你做日式厚蛋烧...';
      case ContentType.titleOptimize: return '粘贴原始标题...';
      case ContentType.topicIdea: return '例如：美妆护肤、数码科技...';
      case ContentType.rewrite: return '粘贴原始内容...';
    }
  }

  IconData _typeIcon(ContentType t) {
    switch (t) {
      case ContentType.article: return Icons.auto_awesome;
      case ContentType.videoScript: return Icons.movie_creation_rounded;
      case ContentType.titleOptimize: return Icons.title_rounded;
      case ContentType.topicIdea: return Icons.lightbulb_rounded;
      case ContentType.rewrite: return Icons.transform_rounded;
    }
  }
}
