import '../constants/app_enums.dart';
import 'platform_style_engine.dart';

/// 跨平台改编 Prompt 引擎 — 为源→目标平台对生成专门改编指令
///
/// 核心能力：
/// - 为 6×5=30 个平台对生成差异化改编 Prompt
/// - 结合源/目标平台的风格特征，生成"桥接"指令
/// - 输出标准 JSON 格式，与 [GlmApiService] 无缝对接
class AdaptEngine {
  AdaptEngine._();

  // ─── 平台风格特征速查表 ───────────────────────────────────────

  /// 各平台核心风格关键词，用于改编 Prompt 中的差异对比
  static const Map<SocialPlatform, _PlatformPersona> _personas = {
    SocialPlatform.xiaohongshu: _PlatformPersona(
      tone: '亲切闺蜜感、真诚分享、略带兴奋',
      structure: '痛点引入→个人体验→分点干货→互动结尾',
      emojiLevel: '极高（每段2-5个）',
      titleStyle: '数字型/悬念型/对比型/痛点型，≤20字',
      lengthGuide: '正文300-1000字',
      keywords: ['绝绝子', 'yyds', '救命', '太绝了', '种草'],
      avoidWords: ['硬广', '术语堆砌', '无个人体验'],
    ),
    SocialPlatform.douyin: _PlatformPersona(
      tone: '高能量、快节奏、极度口语化、网感强',
      structure: '黄金3秒Hook→悬念展开→核心内容分段→互动CTA',
      emojiLevel: '中等（标题1-2个点缀）',
      titleStyle: '悬念反转/挑战型/共鸣型/争议型，20-55字',
      lengthGuide: '口播50-300字（1-3分钟视频）',
      keywords: ['你敢信', '绝了', '上头', '不敢相信', '冲'],
      avoidWords: ['开头拖沓', '节奏慢', '无字幕', '无互动'],
    ),
    SocialPlatform.wechat: _PlatformPersona(
      tone: '专业严谨/温暖走心（按内容灵活切换）',
      structure: '吸睛标题→导语→分小标题论述→总结升华→互动',
      emojiLevel: '极低或不用',
      titleStyle: '信息差型/情绪型/数字型/提问型，14-22字',
      lengthGuide: '正文1500-5000字',
      keywords: ['深度解析', '一文读懂', '值得关注', '思考'],
      avoidWords: ['标题党过度', '排版混乱', '空洞无物'],
    ),
    SocialPlatform.bilibili: _PlatformPersona(
      tone: '有梗有趣有料、二次元底色、弹幕文化',
      structure: '辨识度开场→铺垫→多段核心→金句/反转→三连引导',
      emojiLevel: '低（用文字梗替代：2333、awsl）',
      titleStyle: '番号式/悬念式/挑战式/硬核型，30-80字',
      lengthGuide: '口播/字幕2000-8000字',
      keywords: ['前方高能', '2333', 'awsl', '三连', '投币'],
      avoidWords: ['不尊重弹幕文化', '硬广', '节奏拖沓'],
    ),
    SocialPlatform.weibo: _PlatformPersona(
      tone: '犀利直接、观点鲜明、善用反讽和段子',
      structure: '一句话核心观点→2-3句论据→话题标签互动',
      emojiLevel: '中等（😂👏🤔高频）',
      titleStyle: '热点评析/段子型/情绪型，≤40字',
      lengthGuide: '140字以内最佳（长微博可2000-5000字）',
      keywords: ['话题', '热搜', '怎么说', '细品'],
      avoidWords: ['长篇大论（普通微博）', '水军感', '无观点'],
    ),
    SocialPlatform.kuaishou: _PlatformPersona(
      tone: '极度接地气、真实不做作、老铁文化',
      structure: '直接开场→核心内容简明直接→老铁互动引导',
      emojiLevel: '少量（标题1个或不使用）',
      titleStyle: '直接型/情感型/日常型，15-40字',
      lengthGuide: '口播50-300字',
      keywords: ['老铁', '双击', '不迷路', '安排', '走起'],
      avoidWords: ['过于精致', '装腔作势', '脱离平台调性'],
    ),
  };

  // ─── 公共 API ────────────────────────────────────────────────

  /// 生成改编 system prompt
  ///
  /// [source] 源平台（内容原始风格）
  /// [target] 目标平台（改编后的风格）
  static String buildSystemPrompt({
    required SocialPlatform source,
    required SocialPlatform target,
  }) {
    // 同平台不需要改编
    if (source == target) {
      final t = PlatformStyleEngine.getTemplate(target);
      return t.systemPrompt;
    }

    final src = _personas[source]!;
    final tgt = _personas[target]!;
    final tgtTemplate = PlatformStyleEngine.getTemplate(target);

    return '''你是一位跨平台内容改编专家。你的任务是将一段源自「${source.displayName}」平台的内容，改编为完全符合「${target.displayName}」平台风格的新内容。

【改编核心原则】
1. **保留核心信息**：原文的关键数据、观点、知识点必须完整保留
2. **彻底换皮**：语气、排版、emoji、标题套路、互动方式必须 100% 切换为目标平台风格
3. **消除源平台痕迹**：不能出现源平台特有的用语或格式残留

【源平台（${source.displayName}）风格特征 — 需要剥离】
- 语气：${src.tone}
- 结构：${src.structure}
- emoji密度：${src.emojiLevel}
- 标题风格：${src.titleStyle}
- 篇幅：${src.lengthGuide}
- 特征词：${src.keywords.join('、')}
- 禁忌：${src.avoidWords.join('、')}

【目标平台（${target.displayName}）风格要求 — 必须对齐】
${tgtTemplate.systemPrompt}

【改编检查清单】
改编完成前请逐项自检：
□ 标题是否使用了${target.displayName}的套路（${tgt.titleStyle}）？
□ 语气是否从"${src.tone}"切换为"${tgt.tone}"？
□ emoji密度是否从"${src.emojiLevel}"调整为"${tgt.emojiLevel}"？
□ 篇幅是否符合${target.displayName}的要求（${tgt.lengthGuide}）？
□ 是否植入了目标平台特征词（${tgt.keywords.take(3).join('、')}等）？
□ 是否彻底消除了源平台特有的表达方式？
□ 结尾是否使用了${target.displayName}的互动引导方式？''';
  }

  /// 生成改编 user message（传给 AI 的 user role 部分）
  ///
  /// [source] 源平台
  /// [target] 目标平台
  /// [sourceContent] 原始内容（标题 + 正文）
  /// [category] 可选品类提示
  static String buildUserMessage({
    required SocialPlatform source,
    required SocialPlatform target,
    required String sourceContent,
    String? category,
  }) {
    final categoryHint =
        category != null ? '你专注的创作领域是：$category。\n' : '';

    if (source == target) {
      return '''$categoryHint
请优化以下${target.displayName}内容，使其更加符合平台风格：

原始内容：
$sourceContent

请严格按照以下JSON格式输出（不要加markdown代码块标记，不要输出其他任何内容）：
{"titles": ["改编后标题1", "改编后标题2", "改编后标题3"], "content": "改编后的完整正文", "tags": ["标签1", "标签2", "标签3", "标签4", "标签5"], "coverText": "封面文字建议", "publishTime": "最佳发布时间建议", "adaptNotes": "改编说明（简述主要改动点）"}''';
    }

    return '''$categoryHint
请将以下${source.displayName}风格的内容，改编为符合${target.displayName}平台风格的版本。

原始内容（${source.displayName}风格）：
$sourceContent

请严格按照以下JSON格式输出（不要加markdown代码块标记，不要输出其他任何内容）：
{"titles": ["改编后标题1", "改编后标题2", "改编后标题3"], "content": "改编后的完整正文（必须完全符合${target.displayName}风格）", "tags": ["标签1", "标签2", "标签3", "标签4", "标签5"], "coverText": "封面文字建议", "publishTime": "最佳发布时间建议", "adaptNotes": "改编说明（简述从${source.displayName}到${target.displayName}做了哪些关键调整）"}''';
  }

  /// 一次性生成完整 Prompt（兼容旧接口，合并 system + user）
  static String buildFullPrompt({
    required SocialPlatform source,
    required SocialPlatform target,
    required String sourceContent,
    String? category,
  }) {
    return '${buildSystemPrompt(source: source, target: target)}\n\n${buildUserMessage(source: source, target: target, sourceContent: sourceContent, category: category)}';
  }

  /// 获取源→目标平台的改编难度评估
  ///
  /// 返回 [AdaptDifficulty] 用于 UI 展示或 quota 计算
  static AdaptDifficulty assessDifficulty({
    required SocialPlatform source,
    required SocialPlatform target,
  }) {
    if (source == target) return AdaptDifficulty.trivial;

    // 定义平台"族群"：同族群内改编较简单
    _PlatformFamily srcFamily = _familyOf(source);
    _PlatformFamily tgtFamily = _familyOf(target);

    if (srcFamily == tgtFamily) return AdaptDifficulty.easy;

    // 长内容→短内容 或 短内容→长内容 属于 hard
    final srcLen = PlatformStyleEngine.getTemplate(source).contentMax;
    final tgtLen = PlatformStyleEngine.getTemplate(target).contentMax;
    final ratio = (tgtLen / srcLen);
    if (ratio > 5 || ratio < 0.2) return AdaptDifficulty.hard;

    return AdaptDifficulty.medium;
  }

  /// 获取所有支持的源→目标平台对（排除同平台）
  static List<AdaptPair> allPairs() {
    final pairs = <AdaptPair>[];
    for (final source in SocialPlatform.values) {
      for (final target in SocialPlatform.values) {
        if (source != target) {
          pairs.add(AdaptPair(source: source, target: target));
        }
      }
    }
    return pairs;
  }

  // ─── 内部工具 ────────────────────────────────────────────────

  static _PlatformFamily _familyOf(SocialPlatform p) {
    switch (p) {
      case SocialPlatform.xiaohongshu:
      case SocialPlatform.weibo:
        return _PlatformFamily.shortSocial; // 短内容社交
      case SocialPlatform.douyin:
      case SocialPlatform.kuaishou:
        return _PlatformFamily.shortVideo; // 短视频
      case SocialPlatform.wechat:
      case SocialPlatform.bilibili:
        return _PlatformFamily.longForm; // 长内容
    }
  }
}

// ─── 数据模型 ──────────────────────────────────────────────────

/// 平台风格特征
class _PlatformPersona {
  final String tone;
  final String structure;
  final String emojiLevel;
  final String titleStyle;
  final String lengthGuide;
  final List<String> keywords;
  final List<String> avoidWords;

  const _PlatformPersona({
    required this.tone,
    required this.structure,
    required this.emojiLevel,
    required this.titleStyle,
    required this.lengthGuide,
    required this.keywords,
    required this.avoidWords,
  });
}

/// 平台族群（用于评估改编难度）
enum _PlatformFamily { shortSocial, shortVideo, longForm }

/// 改编难度
enum AdaptDifficulty {
  trivial('无需改编', '同平台优化', 0),
  easy('简单', '同族群平台，风格相近', 1),
  medium('中等', '跨族群改编，需要较大调整', 2),
  hard('困难', '篇幅差异大，需深度重构', 3);

  final String label;
  final String description;
  final int level;
  const AdaptDifficulty(this.label, this.description, this.level);
}

/// 源→目标平台对
class AdaptPair {
  final SocialPlatform source;
  final SocialPlatform target;

  const AdaptPair({required this.source, required this.target});

  /// 唯一标识：sourceId→targetId
  String get key => '${source.id}->${target.id}';

  /// 显示标签：小红书→抖音
  String get label => '${source.displayName}→${target.displayName}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptPair && source == other.source && target == other.target;

  @override
  int get hashCode => Object.hash(source, target);

  @override
  String toString() => 'AdaptPair($label)';
}
