import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../constants/app_enums.dart';
import '../providers/app_providers.dart';
import '../widgets/common_widgets.dart' show PlatformSelector, ContentTypeGrid, CategorySelector, getContentTypeIcon;
import 'result_screen.dart';

/// 创作工作台 — App 核心页面
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _inputController = TextEditingController();
  bool _showCategory = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _generate() {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入你想创作的内容主题'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final category = ref.read(selectedCategoryProvider);
    ref.read(generationProvider.notifier).generate(
          userInput: input,
          category: category.isEmpty ? null : category,
        );
  }

  @override
  Widget build(BuildContext context) {
    final platform = ref.watch(selectedPlatformProvider);
    final contentType = ref.watch(selectedContentTypeProvider);
    final category = ref.watch(selectedCategoryProvider);
    final genState = ref.watch(generationProvider);
    final userProfile = ref.watch(userProfileProvider);

    // 监听生成结果，成功后跳转
    ref.listen<GenerationState>(generationProvider, (prev, next) {
      if (next.status == GenerationStatus.success && next.result != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResultScreen(result: next.result!),
          ),
        );
      } else if (next.status == GenerationStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage ?? '生成失败'),
            backgroundColor: AppConfig.accentColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          children: [
            // ===== Header =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✨ 灵感笔',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '今日剩余 ${userProfile.remainingQuota == 999 ? '∞' : userProfile.remainingQuota} 次',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppConfig.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${platform.emoji} ${platform.displayName}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppConfig.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ===== 平台选择 =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '选择目标平台',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 10),
            PlatformSelector(
              selected: platform,
              onChanged: (p) => ref.read(selectedPlatformProvider.notifier).state = p,
            ),

            const SizedBox(height: 20),

            // ===== 内容类型 =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '创作类型',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 10),
            ContentTypeGrid(
              selected: contentType,
              onChanged: (t) => ref.read(selectedContentTypeProvider.notifier).state = t,
            ),

            const SizedBox(height: 20),

            // ===== 创作领域 =====
            GestureDetector(
              onTap: () => setState(() => _showCategory = !_showCategory),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '创作领域（可选）',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showCategory ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppConfig.textSecondary,
                    ),
                    if (category.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppConfig.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppConfig.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_showCategory) ...[
              const SizedBox(height: 10),
              CategorySelector(
                selected: category,
                onChanged: (c) => ref.read(selectedCategoryProvider.notifier).state = c,
              ),
            ],

            const SizedBox(height: 20),

            // ===== 输入区 =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getInputHint(contentType),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    constraints: const BoxConstraints(minHeight: 120),
                    child: TextField(
                      controller: _inputController,
                      maxLines: null,
                      minLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: _getInputPlaceholder(contentType, platform),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ===== 生成按钮 =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: genState.status == GenerationStatus.loading
                      ? null
                      : _generate,
                  child: genState.status == GenerationStatus.loading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('AI 正在创作中...'),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              getContentTypeIcon(contentType),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(_getButtonText(contentType)),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ===== 快捷提示 =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '提示：描述越具体，AI 生成的内容越精准。例如"夏日户外防晒霜推荐，适合油性皮肤"',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInputHint(ContentType type) {
    switch (type) {
      case ContentType.article:
        return '📝 输入你想创作的主题';
      case ContentType.videoScript:
        return '🎬 输入视频主题或灵感';
      case ContentType.titleOptimize:
        return '✏️ 输入需要优化的标题';
      case ContentType.topicIdea:
        return '💡 输入你的创作领域';
      case ContentType.rewrite:
        return '🔄 粘贴需要改写的内容';
    }
  }

  String _getInputPlaceholder(ContentType type, SocialPlatform platform) {
    switch (type) {
      case ContentType.article:
        return '例如：夏日防晒霜推荐，平价好用的学生党必备';
      case ContentType.videoScript:
        return '例如：3分钟教你做日式厚蛋烧';
      case ContentType.titleOptimize:
        return '粘贴你的原始标题，AI 帮你优化...';
      case ContentType.topicIdea:
        return '例如：美妆护肤、数码科技、美食探店...';
      case ContentType.rewrite:
        return '粘贴你想改写为${platform.displayName}风格的内容...';
    }
  }

  String _getButtonText(ContentType type) {
    switch (type) {
      case ContentType.article:
        return '生成内容';
      case ContentType.videoScript:
        return '生成脚本';
      case ContentType.titleOptimize:
        return '优化标题';
      case ContentType.topicIdea:
        return '获取灵感';
      case ContentType.rewrite:
        return '智能改写';
    }
  }
}
