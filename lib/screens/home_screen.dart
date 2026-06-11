import 'dart:convert';
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

/// 首页 — 三模式创作工作台
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _inputCtl = TextEditingController();
  final _scrollCtl = ScrollController();

  @override
  void dispose() {
    _inputCtl.dispose();
    _scrollCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(selectedModeProvider);
    final genState = ref.watch(streamGenProvider);
    final hasResult = genState.status != GenStatus.idle;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConfig.deepBg, Color(0xFF0D0F2B)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollCtl,
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            child: Column(children: [
              _buildHeader(),
              const SizedBox(height: 20),
              // 模式切换
              _buildModeTabs(mode),
              const SizedBox(height: 20),
              // 内容区
              if (!hasResult) ...[
                if (mode == CreateMode.create) _buildCreateMode(),
                if (mode == CreateMode.adapt) _buildAdaptMode(),
                if (mode == CreateMode.deai) _buildDeaiMode(),
              ],
              // 结果区
              if (hasResult) ...[
                _buildResultHeader(genState),
                const SizedBox(height: 16),
                _buildResultContent(genState),
                const SizedBox(height: 16),
                if (genState.status == GenStatus.done)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: () => ref.read(streamGenProvider.notifier).reset(),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('重新生成'),
                    ),
                  ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  // ==================== Header ====================

  Widget _buildHeader() {
    final user = ref.watch(userProfileProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        const Text('✨', style: TextStyle(fontSize: 28)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('你好，${user.nickname}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppConfig.textPrimary)),
            Text(
              AppConfig.disableQuota ? '测试模式 · 无限制' : '剩余 ${user.remainingQuota} 次',
              style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary),
            ),
          ]),
        ),
      ]),
    );
  }

  // ==================== 模式切换 ====================

  Widget _buildModeTabs(CreateMode selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: CreateMode.values.map((m) {
        final isActive = m == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              ref.read(selectedModeProvider.notifier).state = m;
              ref.read(streamGenProvider.notifier).reset();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? AppConfig.accentColor.withValues(alpha: 0.15) : AppConfig.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isActive ? AppConfig.accentColor : AppConfig.glassBorder, width: isActive ? 1.5 : 0.5),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(m.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 6),
                Text(
                  m.displayName,
                  style: TextStyle(fontSize: 13, fontWeight: isActive ? FontWeight.w800 : FontWeight.w500, color: isActive ? AppConfig.accentColor : AppConfig.textSecondary),
                ),
              ]),
            ),
          ),
        );
      }).toList()),
    );
  }

  // ==================== 创作模式 ====================

  Widget _buildCreateMode() {
    final platform = ref.watch(selectedPlatformProvider);
    final contentType = ref.watch(selectedContentTypeProvider);
    final isGen = ref.watch(streamGenProvider).status == GenStatus.generating;

    return Column(children: [
      _buildPlatformSelector(platform),
      const SizedBox(height: 16),
      _buildContentTypeGrid(contentType),
      const SizedBox(height: 16),
      _buildInputBox('描述你想创作的内容', '例如：夏日防晒霜推荐，学生党平价款...'),
      const SizedBox(height: 16),
      _buildGenButton('✨  开始创作', _doCreate, disabled: isGen),
    ]);
  }

  // ==================== 改编模式 ====================

  Widget _buildAdaptMode() {
    final sourcePlatform = ref.watch(selectedPlatformProvider);
    final targets = ref.watch(targetPlatformsProvider);

    return Column(children: [
      // 源平台
      _sectionLabel('📋 选择源平台'),
      const SizedBox(height: 8),
      _buildPlatformSelector(sourcePlatform),
      const SizedBox(height: 16),

      // 粘贴原文
      _sectionLabel('📝 粘贴原文'),
      const SizedBox(height: 8),
      _buildInputBox('粘贴你已有的内容', '例如：小红书笔记、抖音文案、公众号文章...'),
      const SizedBox(height: 16),

      // 目标平台多选
      _sectionLabel('🎯 目标平台（可多选）'),
      const SizedBox(height: 8),
      _buildTargetCheckboxes(targets),
      const SizedBox(height: 16),

      _buildGenButton('🔄  开始改编', _doAdapt, disabled: targets.isEmpty),
    ]);
  }

  // ==================== 去AI味模式 ====================

  Widget _buildDeaiMode() {
    final genState = ref.watch(streamGenProvider);
    final isDetecting = genState.status == GenStatus.generating;
    final hasDetected = genState.status == GenStatus.done && genState.streamedText.contains('score');

    return Column(children: [
      _sectionLabel('🧹 粘贴待检测文本'),
      const SizedBox(height: 8),
      _buildInputBox('粘贴你想检测的文本', '粘贴任何 AI 生成的文本，帮你检测和去除 AI 痕迹...'),
      const SizedBox(height: 16),

      if (!hasDetected)
        _buildGenButton('🔍  检测 AI 痕迹', _doDetect, disabled: isDetecting),

      if (hasDetected) ...[
        _buildDeaiScore(genState),
        const SizedBox(height: 16),
        _buildGenButton('✍️  人性化改写', _doRewrite),
      ],
    ]);
  }

  Widget _buildDeaiScore(StreamGenState state) {
    // 尝试解析检测结果
    int score = 50;
    String summary = '';
    try {
      final json = _tryParse(state.streamedText);
      if (json != null) {
        score = (json['score'] as num?)?.toInt() ?? 50;
        summary = json['summary'] as String? ?? '';
      }
    } catch (_) {}

    final color = score < 30 ? AppConfig.accentColor : score < 60 ? Colors.amber : AppConfig.accentPink;
    final label = score < 30 ? '真人风格' : score < 60 ? '部分AI痕迹' : 'AI味较重';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassBox(radius: 20),
      child: Column(children: [
        Row(children: [
          // 评分圆环
          SizedBox(
            width: 64, height: 64,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 64, height: 64,
                child: CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 5,
                  backgroundColor: AppConfig.surfaceLight,
                  color: color,
                ),
              ),
              Text('$score', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI 味指数', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppConfig.textPrimary)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
              if (summary.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(summary, style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary, height: 1.4)),
              ],
            ]),
          ),
        ]),
      ]),
    );
  }

  // ==================== 结果展示 ====================

  Widget _buildResultHeader(StreamGenState state) {
    final mode = ref.read(selectedModeProvider);
    final platform = ref.read(selectedPlatformProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        GestureDetector(
          onTap: () => ref.read(streamGenProvider.notifier).reset(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppConfig.surfaceDark, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppConfig.glassBorder)),
            child: const Icon(Icons.arrow_back_ios_new, size: 16, color: AppConfig.textPrimary),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [platform.accentColor.withValues(alpha: 0.2), platform.accentColor.withValues(alpha: 0.05)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: platform.accentColor.withValues(alpha: 0.3)),
          ),
          child: Text('${mode.emoji}  ${mode.displayName}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: platform.accentColor)),
        ),
        const Spacer(),
        if (state.status == GenStatus.generating)
          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: platform.accentColor)),
        if (state.status == GenStatus.done)
          const Icon(Icons.check_circle, color: AppConfig.accentColor, size: 18),
      ]),
    );
  }

  Widget _buildResultContent(StreamGenState state) {
    final mode = ref.read(selectedModeProvider);

    // 错误
    if (state.status == GenStatus.error) {
      return _errorCard(state.errorMessage ?? '生成失败');
    }

    // 去 AI 味改写结果 — 纯文本
    if (mode == CreateMode.deai && state.status == GenStatus.done) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: AppTheme.glassBox(radius: 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('✨ 改写结果', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppConfig.accentColor)),
            const SizedBox(height: 12),
            SelectableText(state.streamedText, style: const TextStyle(fontSize: 14, height: 2.0, color: AppConfig.textPrimary)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _actionBtn(Icons.copy_rounded, '复制结果', () => _copy(state.streamedText))),
            ]),
          ]),
        ),
      );
    }

    // 创作模式 / 改编模式 — 帖子预览
    if (state.parsedContent != null) {
      final p = state.parsedContent!;
      if (p.titles.isNotEmpty || p.content.isNotEmpty || p.tags.isNotEmpty) {
        final platform = ref.read(selectedPlatformProvider);
        final contentType = ref.read(selectedContentTypeProvider);
        return PostPreviewCard(
          parsed: p,
          platform: platform,
          contentType: contentType,
          isGenerating: state.status == GenStatus.generating,
          onCopyContent: () => _copy(p.content),
          onCopyAll: () => _copy(_formatAll(p)),
        );
      }
    }

    // 加载中
    final platform = ref.read(selectedPlatformProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassBox(radius: 20),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: platform.accentColor)),
          const SizedBox(width: 12),
          Text('AI 正在构思...', style: TextStyle(fontSize: 14, color: platform.accentColor, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ==================== 通用组件 ====================

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Container(width: 3, height: 14, decoration: BoxDecoration(color: AppConfig.accentColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppConfig.textSecondary)),
      ]),
    );
  }

  Widget _buildPlatformSelector(SocialPlatform selected) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: SocialPlatform.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = SocialPlatform.values[i];
          final active = p == selected;
          return GestureDetector(
            onTap: () => ref.read(selectedPlatformProvider.notifier).state = p,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: active
                  ? AppTheme.glowButton(color: p.accentColor)
                  : BoxDecoration(color: AppConfig.surfaceDark, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppConfig.glassBorder)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(p.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(p.displayName, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? Colors.white : AppConfig.textSecondary)),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentTypeGrid(ContentType selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: ContentType.values.map((t) {
        final active = t == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => ref.read(selectedContentTypeProvider.notifier).state = t,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: active ? AppConfig.accentColor.withValues(alpha: 0.12) : AppConfig.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: active ? AppConfig.accentColor : AppConfig.glassBorder, width: active ? 1.5 : 0.5),
              ),
              child: Column(children: [
                Icon(t.icon, color: active ? AppConfig.accentColor : AppConfig.textSecondary, size: 18),
                const SizedBox(height: 4),
                Text(t.displayName, style: TextStyle(fontSize: 9, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? AppConfig.accentColor : AppConfig.textSecondary)),
              ]),
            ),
          ),
        );
      }).toList()),
    );
  }

  Widget _buildInputBox(String label, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.glassBox(radius: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 3, height: 16, decoration: BoxDecoration(color: AppConfig.accentColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppConfig.textPrimary)),
          ]),
          const SizedBox(height: 10),
          TextField(
            controller: _inputCtl,
            maxLines: null, minLines: 3,
            style: const TextStyle(color: AppConfig.textPrimary, fontSize: 14, height: 1.5),
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTargetCheckboxes(List<SocialPlatform> selected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: SocialPlatform.values.map((p) {
          final active = selected.contains(p);
          return GestureDetector(
            onTap: () {
              final list = [...selected];
              if (active) { list.remove(p); } else { list.add(p); }
              ref.read(targetPlatformsProvider.notifier).state = list;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: active ? p.accentColor.withValues(alpha: 0.12) : AppConfig.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: active ? p.accentColor : AppConfig.glassBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(active ? Icons.check_circle : Icons.circle_outlined, size: 16, color: active ? p.accentColor : AppConfig.textSecondary),
                const SizedBox(width: 6),
                Text('${p.emoji} ${p.displayName}', style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? p.accentColor : AppConfig.textSecondary)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGenButton(String text, VoidCallback onTap, {bool disabled = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Opacity(
          opacity: disabled ? 0.5 : 1,
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: AppTheme.glowButton(),
            child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: AppConfig.surfaceLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppConfig.glassBorder)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: AppConfig.textSecondary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppConfig.textPrimary)),
        ]),
      ),
    );
  }

  Widget _errorCard(String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppConfig.accentPink.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppConfig.accentPink.withValues(alpha: 0.3))),
        child: Row(children: [
          const Icon(Icons.error_outline, color: AppConfig.accentPink, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: const TextStyle(fontSize: 14, color: AppConfig.accentPink))),
        ]),
      ),
    );
  }

  // ==================== 操作逻辑 ====================

  void _doCreate() {
    final input = _inputCtl.text.trim();
    if (input.isEmpty) { _snack('请输入创作主题'); return; }
    ref.read(streamGenProvider.notifier).startGeneration(userInput: input);
    _scrollToBottom();
  }

  void _doAdapt() {
    final input = _inputCtl.text.trim();
    if (input.isEmpty) { _snack('请粘贴原文内容'); return; }
    final targets = ref.read(targetPlatformsProvider);
    if (targets.isEmpty) { _snack('请选择目标平台'); return; }
    final source = ref.read(selectedPlatformProvider);
    // 取第一个目标平台
    final target = targets.first;
    ref.read(streamGenProvider.notifier).startCustomStream(
      systemPrompt: '你是资深社媒运营专家，精通各大平台内容风格差异。请将以下内容从${source.displayName}风格改写为${target.displayName}风格。',
      userPrompt: input,
    );
    _scrollToBottom();
  }

  void _doDetect() {
    final input = _inputCtl.text.trim();
    if (input.isEmpty) { _snack('请粘贴待检测文本'); return; }
    ref.read(streamGenProvider.notifier).detectAI(input);
    _scrollToBottom();
  }

  void _doRewrite() {
    final input = _inputCtl.text.trim();
    ref.read(streamGenProvider.notifier).rewriteAI(content: input);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_scrollCtl.hasClients) {
        _scrollCtl.animateTo(_scrollCtl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _snack('✅ 已复制到剪贴板');
  }

  String _formatAll(StreamContentParser p) {
    final buf = StringBuffer();
    if (p.titles.isNotEmpty) { buf.writeln('【标题】'); for (var i = 0; i < p.titles.length; i++) { buf.writeln('${i + 1}. ${p.titles[i]}'); } buf.writeln(); }
    if (p.content.isNotEmpty) { buf.writeln('【正文】'); buf.writeln(p.content); buf.writeln(); }
    if (p.tags.isNotEmpty) { buf.writeln('【标签】${p.tags.map((t) => '#$t').join(' ')}'); }
    if (p.coverText.isNotEmpty) buf.writeln('\n【封面】${p.coverText}');
    if (p.publishTime.isNotEmpty) buf.writeln('【发布时间】${p.publishTime}');
    return buf.toString();
  }

  Map<String, dynamic>? _tryParse(String text) {
    try { return jsonDecode(text) as Map<String, dynamic>; } catch (_) { return null; }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating));
  }
}
