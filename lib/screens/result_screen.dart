import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';
import '../constants/app_enums.dart';
import '../models/app_models.dart';
import '../widgets/common_widgets.dart';

/// 生成结果展示页
class ResultScreen extends StatefulWidget {
  final GenerationResult result;

  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTitleIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ 已复制到剪贴板'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyAll() {
    final r = widget.result;
    final selectedTitle = r.titleVariants.isNotEmpty
        ? r.titleVariants[_selectedTitleIndex]
        : '';
    final fullText = '''$selectedTitle

${r.content}

${r.tags.isNotEmpty ? '标签：${r.tags.map((t) => '#$t').join(' ')}' : ''}

${r.coverTextSuggestion.isNotEmpty ? '📝 封面文字：${r.coverTextSuggestion}' : ''}
${r.publishTimeSuggestion.isNotEmpty ? '⏰ 发布时间：${r.publishTimeSuggestion}' : ''}''';
    _copyToClipboard(fullText);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;

    return Scaffold(
      appBar: AppBar(
        title: Text('${r.platform.emoji} ${r.platform.displayName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_rounded),
            tooltip: '复制全部',
            onPressed: _copyAll,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConfig.primaryColor,
          unselectedLabelColor: AppConfig.textSecondary,
          indicatorColor: AppConfig.primaryColor,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
          tabs: const [
            Tab(text: '正文内容'),
            Tab(text: '标题 & 标签'),
            Tab(text: '发布建议'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ===== Tab 1: 正文内容 =====
          _buildContentTab(r),

          // ===== Tab 2: 标题 & 标签 =====
          _buildTitlesAndTagsTab(r),

          // ===== Tab 3: 发布建议 =====
          _buildPublishTipsTab(r),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copyAll,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  label: const Text('复制全部'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('重新生成'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentTab(GenerationResult r) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 选中的标题
          if (r.titleVariants.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppConfig.primaryColor.withValues(alpha: 0.08),
                    AppConfig.secondaryColor.withValues(alpha: 0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📌 选中标题',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppConfig.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    r.titleVariants[_selectedTitleIndex],
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppConfig.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

          // 正文内容
          ResultCard(
            label: '正文内容',
            content: r.content,
            onCopy: () => _copyToClipboard(r.content),
          ),
        ],
      ),
    );
  }

  Widget _buildTitlesAndTagsTab(GenerationResult r) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题变体
          const Text(
            '标题变体',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppConfig.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          ...List.generate(r.titleVariants.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TitleVariantCard(
                index: index,
                title: r.titleVariants[index],
                isSelected: index == _selectedTitleIndex,
                onTap: () => setState(() => _selectedTitleIndex = index),
                onCopy: () => _copyToClipboard(r.titleVariants[index]),
              ),
            );
          }),

          const SizedBox(height: 20),

          // 标签
          if (r.tags.isNotEmpty) ...[
            const Text(
              '推荐标签',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppConfig.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: r.tags.map((tag) {
                return GestureDetector(
                  onTap: () => _copyToClipboard('#$tag'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppConfig.primaryColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppConfig.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '#$tag',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppConfig.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _copyToClipboard(r.tags.map((t) => '#$t').join(' ')),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy_rounded, size: 14, color: AppConfig.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      '复制全部标签',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppConfig.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPublishTipsTab(GenerationResult r) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (r.coverTextSuggestion.isNotEmpty)
            ResultCard(
              label: '🖼️ 封面文字建议',
              content: r.coverTextSuggestion,
              onCopy: () => _copyToClipboard(r.coverTextSuggestion),
            ),
          if (r.publishTimeSuggestion.isNotEmpty) ...[
            const SizedBox(height: 12),
            ResultCard(
              label: '⏰ 最佳发布时间',
              content: r.publishTimeSuggestion,
            ),
          ],
          const SizedBox(height: 20),
          // 平台特色提示
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppConfig.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConfig.primaryColor.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(r.platform.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '${r.platform.displayName}发布小贴士',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppConfig.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _getPlatformTips(r.platform),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: AppConfig.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getPlatformTips(SocialPlatform platform) {
    switch (platform) {
      case SocialPlatform.xiaohongshu:
        return '• 封面是第一印象，务必高颜值+大字标题\n'
            '• 首图建议使用 3:4 比例\n'
            '• 标题和首图的关键词影响搜索排名\n'
            '• 发布后及时回复评论提升互动率\n'
            '• 善用收藏引导："建议先收藏再看"';
      case SocialPlatform.douyin:
        return '• 前3秒决定完播率，必须强力Hook\n'
            '• 视频时长 15-60秒 为黄金区间\n'
            '• 字幕要大且居中，确保静音也能看\n'
            '• BGM 选择热门音乐增加推荐权重\n'
            '• 引导评论互动（提问/争议观点）';
      case SocialPlatform.wechat:
        return '• 标题决定打开率，14-22字为最佳\n'
            '• 首图尺寸 900×383px\n'
            '• 文章前50字决定阅读完成率\n'
            '• 排版留白，段落不超过5行\n'
            '• 引导"在看"和"分享"比点赞更重要';
      case SocialPlatform.bilibili:
        return '• 封面信息密度要高，角色+大字标题\n'
            '• 视频前15秒要建立期待感\n'
            '• 设计弹幕互动点（"前方高能""2333"）\n'
            '• 引导三连（投币>收藏>点赞）\n'
            '• 标题可以很长，善用【】标注系列';
      case SocialPlatform.weibo:
        return '• 140字以内最易被阅读和转发\n'
            '• #话题# 标签1-3个最佳\n'
            '• 配图九宫格比单图互动率高3倍\n'
            '• 热点时效性极强，速度>一切\n'
            '• 金句+截图是最易引发转发的格式';
      case SocialPlatform.kuaishou:
        return '• 越真实越接地气，越有流量\n'
            '• "老铁"互动引导要自然不生硬\n'
            '• 同城流量是重要入口\n'
            '• 直播+短视频联动效果最佳\n'
            '• 发布时间以 11:00-13:00、19:00-22:00 为佳';
    }
  }
}
