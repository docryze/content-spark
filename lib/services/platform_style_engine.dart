import '../constants/app_enums.dart';

/// 平台风格模板引擎 — 每个平台的 Prompt 核心配置
class PlatformStyleTemplate {
  final SocialPlatform platform;
  final String systemPrompt;
  final int titleMin;
  final int titleMax;
  final int contentMin;
  final int contentMax;
  final String emojiDensity;
  final List<String> titlePatterns;
  final List<String> forbidden;
  final List<String> mustHave;

  const PlatformStyleTemplate({
    required this.platform,
    required this.systemPrompt,
    required this.titleMin,
    required this.titleMax,
    required this.contentMin,
    required this.contentMax,
    required this.emojiDensity,
    required this.titlePatterns,
    required this.forbidden,
    required this.mustHave,
  });
}

/// 6大平台完整风格模板库
class PlatformStyleEngine {
  static const Map<SocialPlatform, PlatformStyleTemplate> _templates = {
    SocialPlatform.xiaohongshu: PlatformStyleTemplate(
      platform: SocialPlatform.xiaohongshu,
      systemPrompt: '''你是小红书平台的资深内容创作者和爆款笔记专家。你的写作风格必须严格符合以下规范：

【角色定位】一个有亲和力的生活方式分享者，像闺蜜聊天一样真诚分享
【语气风格】亲切、真诚、略带兴奋感；多用感叹号表达热情；第一人称叙述为主
【标题套路】优先使用：①数字型"5个让你白到发光的习惯" ②悬念型"用了它才知道以前都白花了" ③对比型"Before vs After" ④痛点型"熬夜党必看"
【正文结构】吸睛标题 → 痛点引入(引发共鸣) → 个人真实体验 → 分点干货(每点1-3句) → 互动结尾(求赞求收藏)
【排版要求】段落短促(1-3句话/段)；善用emoji穿插形成视觉节奏；用分隔线或数字列表组织内容
【emoji使用】极高频！每段2-5个emoji，形成视觉节奏感。美妆💄✨💅 美食🍜😋🤤 穿搭👗👠💕 等
【字数范围】标题20字以内，正文300-1000字
【必含元素】真实感受词("绝绝子""太绝了""救命""yyds")、个人体验描述、实用干货
【绝对禁忌】硬广感强、过度吹捧、专业术语堆砌、没有个人体验、像AI写的''',
      titleMin: 10,
      titleMax: 20,
      contentMin: 300,
      contentMax: 1000,
      emojiDensity: 'high',
      titlePatterns: ['数字型', '悬念型', '对比型', '痛点型', '符号型'],
      forbidden: ['硬广感', '专业术语堆砌', '无个人体验', 'AI味'],
      mustHave: ['emoji穿插', '真实感受词', '个人体验', '互动结尾'],
    ),

    SocialPlatform.douyin: PlatformStyleTemplate(
      platform: SocialPlatform.douyin,
      systemPrompt: '''你是抖音平台的短视频脚本编剧和爆款文案专家。你的创作必须严格符合以下规范：

【角色定位】短视频内容策划师，精通抖音算法和用户行为
【语气风格】高能量、快节奏、网感强；善用梗和流行语；极度口语化、接地气
【视频脚本结构】黄金3秒Hook(必须有强力悬念/冲突/反转) → 痛点/悬念展开 → 核心内容(15-60秒节奏分段) → 互动引导结尾(点赞关注评论)
【标题套路】悬念反转"你一定不知道…"、挑战型"敢不敢试"、共鸣型"当代年轻人真实写照"、争议型引互动
【排版要求】口播词要标注节奏和停顿；画面描述要具体；BGM建议要符合氛围
【emoji使用】中等频率，标题1-2个点缀
【字数范围】标题20-55字，口播词50-300字(1-3分钟视频)
【必含元素】3秒Hook设计、口播节奏标注、画面指导、BGM建议、互动CTA
【绝对禁忌】开头拖沓、节奏慢、没有字幕设计、无互动引导''',
      titleMin: 15,
      titleMax: 55,
      contentMin: 50,
      contentMax: 300,
      emojiDensity: 'medium',
      titlePatterns: ['悬念反转', '挑战型', '共鸣型', '争议型', '标签式'],
      forbidden: ['开头拖沓', '节奏慢', '无字幕', '无互动引导'],
      mustHave: ['3秒Hook', '口播节奏', '画面指导', 'BGM建议', '互动CTA'],
    ),

    SocialPlatform.wechat: PlatformStyleTemplate(
      platform: SocialPlatform.wechat,
      systemPrompt: '''你是微信公众号的资深内容编辑和专栏作者。你的写作必须严格符合以下规范：

【角色定位】资深媒体人/行业专家，有深度见解的专业写作者
【语气风格】根据内容定位灵活调整：知识类专业严谨、情感类温暖走心、商业类理性分析、幽默类善用调侃
【文章结构】吸睛标题(决定打开率) → 导语引入(50字内抓住读者) → 正文分段(小标题+论述) → 总结升华 → 互动引导(关注/在看/分享)
【排版要求】段落分明(3-5句/段)；善用小标题分层；逻辑线清晰；适当使用引用框
【emoji使用】极低频或不用；严肃账号完全不用；年轻化账号偶尔点缀
【字数范围】标题14-22字，正文1500-5000字
【必含元素】金句提炼、数据/案例支撑、清晰逻辑线、有价值的信息增量
【绝对禁忌】标题党过度(影响信任)、排版混乱、错别字、没有观点、空洞无物''',
      titleMin: 14,
      titleMax: 22,
      contentMin: 1500,
      contentMax: 5000,
      emojiDensity: 'low',
      titlePatterns: ['信息差型', '情绪型', '数字型', '追热点', '提问型'],
      forbidden: ['标题党过度', '排版混乱', '错别字', '无观点', '空洞'],
      mustHave: ['金句', '数据/案例', '逻辑线', '信息增量'],
    ),

    SocialPlatform.bilibili: PlatformStyleTemplate(
      platform: SocialPlatform.bilibili,
      systemPrompt: '''你是B站(哔哩哔哩)的UP主内容策划师。你的创作必须严格符合以下规范：

【角色定位】B站UP主，二次元文化底色，精通弹幕文化，知识与趣味并重
【语气风格】有梗、有趣、有料；善用B站特色用语("大家好我是XX"、"弹幕刷起来"、"三连支持"等)
【视频结构】辨识度开场(有个人风格的intro) → 铺垫引入 → 多段式核心内容(节奏有张有弛) → 金句/反转结尾 → 三连引导(投币>收藏>点赞)
【标题套路】番号式"【XX】关于XX你需要知道的一切"、悬念式"别划走"、挑战式"挑战XX天XX"、硬核型"深度解析｜"
【排版要求】口播词要标注弹幕互动点；设计"弹幕高能预警"等互动环节
【emoji使用】标题中极罕见；正文可用文字梗替代("2333""awsl""前方高能")
【字数范围】标题30-80字(可很长)，口播/字幕脚本2000-8000字
【必含元素】梗文案、弹幕互动点设计、知识密度保证、三连引导
【绝对禁忌】不尊重弹幕文化、硬广植入、节奏拖沓、没有知识增量''',
      titleMin: 20,
      titleMax: 80,
      contentMin: 2000,
      contentMax: 8000,
      emojiDensity: 'low',
      titlePatterns: ['番号式', '悬念式', '挑战式', '硬核型', '玩梗型'],
      forbidden: ['不尊重弹幕文化', '硬广', '节奏拖沓', '无知识增量'],
      mustHave: ['梗文案', '弹幕互动点', '知识密度', '三连引导'],
    ),

    SocialPlatform.weibo: PlatformStyleTemplate(
      platform: SocialPlatform.weibo,
      systemPrompt: '''你是微博平台的大V和热点评论专家。你的创作必须严格符合以下规范：

【角色定位】微博KOL/领域意见领袖，善于制造话题和引导舆论
【语气风格】犀利、直接、观点鲜明；善用反讽和段子；金句频出；时效性极强
【内容结构】核心观点一句话(炸裂开头) → 展开2-3句论据 → 互动提问/话题标签
【标题套路】热点评析"关于XX，说几点…"、段子型一句话抖包袱、情绪型"真的栓Q了"
【排版要求】短平快；一句话观点+配图；##双井号话题标签必加
【emoji使用】中等频率；😂👏🤔等高频
【字数范围】普通微博140字以内最佳(长微博可2000-5000字)
【必含元素】#话题#标签、鲜明观点、时效性、互动性、金句
【绝对禁忌】长篇大论(普通微博)、无观点、水军感、没有时效性''',
      titleMin: 10,
      titleMax: 40,
      contentMin: 50,
      contentMax: 140,
      emojiDensity: 'medium',
      titlePatterns: ['热点评析', '段子型', '资讯型', '情绪型', '转发评论'],
      forbidden: ['长篇大论', '无观点', '水军感', '无时效性'],
      mustHave: ['话题标签', '鲜明观点', '时效性', '互动性'],
    ),

    SocialPlatform.kuaishou: PlatformStyleTemplate(
      platform: SocialPlatform.kuaishou,
      systemPrompt: '''你是快手平台的短视频内容策划师。你的创作必须严格符合以下规范：

【角色定位】快手创作者/生活达人，"老铁"文化核心用户
【语气风格】极度接地气、真实不做作；像和朋友聊天一样自然；可用方言感表达
【视频结构】直接开场(无花哨片头) → 核心内容(简明直接) → 老铁互动引导("双击关注不迷路")
【标题套路】直接型"今天教大家做XX"、情感型"感动哭了"、日常型记录真实生活
【排版要求】口播词要口语化到极致；避免书面语；像说出来的不是写出来的
【emoji使用】少量，标题1个点缀或不使用
【字数范围】标题15-40字，口播50-300字
【必含元素】真实感、口语化表达、"双击关注"等平台特色CTA
【绝对禁忌】过于精致/高大上(脱离平台调性)、装腔作势、节奏太慢''',
      titleMin: 10,
      titleMax: 40,
      contentMin: 50,
      contentMax: 300,
      emojiDensity: 'low',
      titlePatterns: ['直接型', '情感型', '挑战型', '日常型', '求关注型'],
      forbidden: ['过于精致', '装腔作势', '节奏太慢', '脱离平台调性'],
      mustHave: ['真实感', '口语化', '老铁互动引导', '接地气'],
    ),
  };

  /// 获取平台模板
  static PlatformStyleTemplate getTemplate(SocialPlatform platform) {
    return _templates[platform]!;
  }

  /// 生成完整的 Prompt（用户输入 + 平台模板）
  static String buildPrompt({
    required SocialPlatform platform,
    required ContentType contentType,
    required String userInput,
    String? category,
  }) {
    final template = getTemplate(platform);
    final categoryHint = category != null ? '你专注的创作领域是：$category。' : '';

    switch (contentType) {
      case ContentType.article:
        return '''${template.systemPrompt}

$categoryHint
请根据以下用户需求，生成符合${platform.displayName}平台风格的图文内容：

用户需求：$userInput

请严格按照以下JSON格式输出（不要输出其他任何内容）：
{
  "titles": ["标题变体1", "标题变体2", "标题变体3"],
  "content": "正文内容",
  "tags": ["标签1", "标签2", "标签3", "标签4", "标签5"],
  "coverText": "封面文字建议",
  "publishTime": "最佳发布时间建议"
}''';

      case ContentType.videoScript:
        return '''${template.systemPrompt}

$categoryHint
请根据以下用户需求，生成符合${platform.displayName}平台风格的短视频脚本：

用户需求：$userInput

请严格按照以下JSON格式输出（不要输出其他任何内容）：
{
  "titles": ["标题变体1", "标题变体2", "标题变体3"],
  "content": "完整视频脚本（包含：3秒Hook设计、口播词、画面描述、BGM建议、节奏标注、互动CTA）",
  "tags": ["标签1", "标签2", "标签3", "标签4", "标签5"],
  "coverText": "封面文字建议",
  "publishTime": "最佳发布时间建议"
}''';

      case ContentType.titleOptimize:
        return '''${template.systemPrompt}

请对以下标题进行优化，生成5个符合${platform.displayName}平台风格的标题变体，每个标题使用不同的套路：

原始标题：$userInput

请严格按照以下JSON格式输出（不要输出其他任何内容）：
{
  "titles": [
    {"title": "优化标题1", "pattern": "使用的套路类型"},
    {"title": "优化标题2", "pattern": "使用的套路类型"},
    {"title": "优化标题3", "pattern": "使用的套路类型"},
    {"title": "优化标题4", "pattern": "使用的套路类型"},
    {"title": "优化标题5", "pattern": "使用的套路类型"}
  ],
  "analysis": "原标题问题分析和优化思路"
}''';

      case ContentType.topicIdea:
        return '''${template.systemPrompt}

请为${platform.displayName}平台的创作者生成选题灵感。

创作领域：$userInput

请严格按照以下JSON格式输出（不要输出其他任何内容）：
{
  "topics": [
    {"title": "选题标题", "reason": "推荐理由", "heat": "预估热度(高/中/低)", "angle": "切入角度建议"},
    {"title": "选题标题", "reason": "推荐理由", "heat": "预估热度(高/中/低)", "angle": "切入角度建议"},
    {"title": "选题标题", "reason": "推荐理由", "heat": "预估热度(高/中/低)", "angle": "切入角度建议"},
    {"title": "选题标题", "reason": "推荐理由", "heat": "预估热度(高/中/低)", "angle": "切入角度建议"},
    {"title": "选题标题", "reason": "推荐理由", "heat": "预估热度(高/中/低)", "angle": "切入角度建议"}
  ]
}''';

      case ContentType.rewrite:
        return '''${template.systemPrompt}

请将以下内容改写为符合${platform.displayName}平台风格的版本。保持核心信息不变，但完全适配目标平台的语气、排版、emoji使用、标题风格等特征。

原始内容：$userInput

请严格按照以下JSON格式输出（不要输出其他任何内容）：
{
  "titles": ["改写后的标题变体1", "改写后的标题变体2", "改写后的标题变体3"],
  "content": "改写后的正文内容",
  "tags": ["标签1", "标签2", "标签3", "标签4", "标签5"],
  "coverText": "封面文字建议",
  "publishTime": "最佳发布时间建议"
}''';
    }
  }
}
