import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../constants/app_enums.dart';
import '../providers/app_providers.dart';
import '../services/hot_topics_service.dart';

/// 热点中心 — 实时热搜 + 一键生成
class HotTopicsScreen extends ConsumerStatefulWidget {
  const HotTopicsScreen({super.key});
  @override
  ConsumerState<HotTopicsScreen> createState() => _HotTopicsScreenState();
}

class _HotTopicsScreenState extends ConsumerState<HotTopicsScreen> {
  HotSource _source = HotSource.weibo;
  ContentCategory? _category;
  List<HotTopic> _topics = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final svc = HotTopicsService();
    final topics = await svc.fetchTopics(_source);
    if (mounted) setState(() { _topics = topics; _loading = false; });
  }

  List<HotTopic> get _filtered {
    if (_category == null) return _topics;
    return _topics.where((t) => t.category == _category).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppConfig.deepBg, Color(0xFF0D0F2B)]),
        ),
        child: SafeArea(
          child: Column(children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                const Text('🔥', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 10),
                const Text('热点中心', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppConfig.textPrimary)),
                const Spacer(),
                GestureDetector(
                  onTap: _load,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppConfig.surfaceDark, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppConfig.glassBorder)),
                    child: const Icon(Icons.refresh_rounded, size: 18, color: AppConfig.textSecondary),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // 来源 Tab
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: HotSource.values.map((s) {
                final active = s == _source;
                return Expanded(
                  child: GestureDetector(
                    onTap: () { setState(() => _source = s); _load(); },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: active ? s.color.withValues(alpha: 0.15) : AppConfig.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: active ? s.color : AppConfig.glassBorder),
                      ),
                      child: Text(
                        '${s.emoji} ${s.displayName}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? s.color : AppConfig.textSecondary),
                      ),
                    ),
                  ),
                );
              }).toList()),
            ),
            const SizedBox(height: 12),

            // 品类筛选
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _categoryChip(null, '全部'),
                  ...ContentCategory.values.map((c) => _categoryChip(c, c.displayName)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 热搜列表
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppConfig.accentColor))
                  : items.isEmpty
                      ? const Center(child: Text('暂无数据', style: TextStyle(color: AppConfig.textSecondary)))
                      : RefreshIndicator(
                          color: _source.color,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.only(bottom: 100),
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 6),
                            itemBuilder: (_, i) => _topicCard(items[i], i),
                          ),
                        ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _categoryChip(ContentCategory? cat, String label) {
    final active = _category == cat;
    return GestureDetector(
      onTap: () => setState(() => _category = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppConfig.accentColor.withValues(alpha: 0.12) : AppConfig.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppConfig.accentColor : AppConfig.glassBorder),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? AppConfig.accentColor : AppConfig.textSecondary)),
      ),
    );
  }

  Widget _topicCard(HotTopic t, int index) {
    final rank = index + 1;
    final rankColor = rank <= 3 ? _source.color : AppConfig.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => _onTopicTap(t),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.glassBox(radius: 16),
          child: Row(children: [
            // 排名
            SizedBox(
              width: 28,
              child: Text('$rank', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: rankColor)),
            ),
            const SizedBox(width: 12),
            // 内容
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConfig.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Text(t.hotValue, style: const TextStyle(fontSize: 11, color: AppConfig.textSecondary)),
                  if (t.tag != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: _source.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                      child: Text(t.tag!, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _source.color)),
                    ),
                  ],
                ]),
              ]),
            ),
            const SizedBox(width: 8),
            // 生成按钮
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: _source.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.auto_awesome, size: 12, color: _source.color),
                const SizedBox(width: 4),
                Text('生成', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _source.color)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _onTopicTap(HotTopic topic) {
    // 切换到创作页面并自动填入热点主题
    ref.read(selectedModeProvider.notifier).state = CreateMode.create;
    // 导航到创作 Tab
    // 通过 event bus 或直接 setState of parent
    // 简单做法：直接使用 ScaffoldMessenger
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🔥 已选择：${topic.title}'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
