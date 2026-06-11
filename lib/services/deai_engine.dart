/// AI去AI味检测+改写引擎
///
/// 提供两个核心方法：
/// - [buildDetectPrompt]：检测文本中的AI痕迹，输出含 score 和 paragraphs 数组的 JSON
/// - [buildRewritePrompt]：将AI味重的文本人性化改写，输出纯文本
class DeaiEngine {
  DeaiEngine._();

  // ─── 检测 Prompt ───────────────────────────────────────────────

  /// 构建 AI 痕迹检测 Prompt（system + user 分离，适配 GLM API 风格）
  ///
  /// 返回 `{system: ..., user: ...}`，可直接传入 GLM chat/completions 接口。
  /// AI 返回 JSON 格式：
  /// ```json
  /// {
  ///   "score": 0-100,
  ///   "summary": "整体评价",
  ///   "paragraphs": [
  ///     {
  ///       "index": 0,
  ///       "text": "原文段落摘要",
  ///       "aiScore": 0-100,
  ///       "issues": ["具体问题1", "具体问题2"],
  ///       "suggestion": "修改建议"
  ///     }
  ///   ]
  /// }
  /// ```
  static PromptPair buildDetectPrompt(String content) {
    const system = '''你是一位专业的「AI痕迹检测专家」，专门分析文本是否由AI生成以及AI味道的浓重程度。你需要像一位经验丰富的编辑那样，用专业但敏锐的眼光审视每一段文字。

【你的核心能力】
你能识别出以下AI写作的典型痕迹：
1. **过度完美的结构**：每个段落都是"总-分-总"，缺乏人类写作的自然随意感
2. **空洞的修饰词堆砌**："值得注意的是"、"总的来说"、"不可忽视的是"、"至关重要"等AI标志性过渡语
3. **缺乏真实感**：没有个人经历细节、没有具体的感官描述、没有"犯错"的自然表达
4. **排比式罗列**：大量使用"首先…其次…最后…"、"一方面…另一方面…"等机械式排比
5. **过度积极/正面**：缺少负面情绪、矛盾心理、犹豫不定等真实人类情感
6. **信息密度过于均匀**：每段字数相近、节奏感单一，缺乏人类写作时详略得当的自然变化
7. **缺乏口语化表达**：没有俚语、没有不规范的语法、没有"接地气"的表达
8. **万能式结尾**：以"让我们…"、"希望本文能…"等套路结尾
9. **emoji/标点过于规律**：emoji分布过于均匀，感叹号使用过于一致
10. **缺乏个性化**：读起来像是"谁都能写出来的话"，没有个人独特视角

【评分标准】
- 0-20：几乎无AI痕迹，像真人写的
- 21-40：轻微AI感，某些表达略显生硬
- 41-60：明显AI痕迹，结构/用词有明显套路
- 61-80：高度疑似AI，多个维度都有AI特征
- 81-100：几乎确定是AI生成，典型的"AI味"

你必须严格按JSON格式输出，不要加markdown代码块标记，不要输出任何其他内容。''';

    final user = '''请分析以下文本的AI痕迹，逐段评估并给出总分：

---
$content
---

请严格按照以下JSON格式输出（不要加markdown代码块标记，不要输出其他任何内容）：
{"score": <0-100的整数，整体AI味道评分>, "summary": "<100字以内的整体评价>", "paragraphs": [<段落索引，从0开始>, {"index": 0, "text": "<该段落的简要引用或概括>", "aiScore": <0-100>, "issues": ["<具体问题1>", "<具体问题2>"], "suggestion": "<修改建议>"}]}''';

    return PromptPair(system: system, user: user);
  }

  // ─── 改写 Prompt ───────────────────────────────────────────────

  /// 构建 人性化改写 Prompt（system + user 分离，适配 GLM API 风格）
  ///
  /// 返回 `{system: ..., user: ...}`，可直接传入 GLM chat/completions 接口。
  /// AI 返回纯文本（人性化改写后的内容），无 JSON 包裹。
  ///
  /// 可选参数：
  /// - [targetStyle]：目标风格（如"小红书"、"微信公众号"等），用于匹配平台调性
  /// - [issues]：检测环节发现的具体问题列表，用于针对性改写
  static PromptPair buildRewritePrompt({
    required String content,
    String? targetStyle,
    List<String>? issues,
  }) {
    const system = '''你是一位顶级的「文本人性化改写专家」。你的唯一目标是把带有AI味道的文字改写得像真人写的。

【你的改写原则】
1. **注入个人视角**：加入第一人称感受、个人经历片段、主观评价——哪怕是"我觉得""说实话""讲真"
2. **打破完美结构**：不要每段都"总-分-总"，可以有突兀的转折、可以啰嗦、可以简短到只有一句话的段落
3. **使用口语化表达**：用日常口语替代书面用语——"超级"代替"非常"，"贼"代替"极其"，"绝了"代替"令人赞叹"
4. **加入不完美**：允许轻微的重复、允许自问自答、允许跑题一小段再拉回来
5. **删除AI味词汇**：严禁使用"值得注意的是"、"总的来说"、"不可忽视"、"至关重要"、"让我们"、"希望本文"等AI标志性表达
6. **调整节奏**：长短句交替，不要句式统一；有些地方可以一口气说很长，有些地方突然很短
7. **真实情感波动**：可以有吐槽、可以有犹豫、可以有"算了不说了"这种真实感
8. **个性化收尾**：不要用"总结"式结尾，可以是一个感受、一个反问、一个emoji、甚至一句玩笑

【改写禁忌】
- ❌ 不能改变原文的核心信息和关键数据
- ❌ 不能凭空编造事实
- ❌ 不能只是简单替换同义词（那是最低级的改写）
- ❌ 不能丢失原文的层次和逻辑
- ❌ 输出纯文本，不要用JSON格式，不要加markdown代码块标记

你输出的内容应该让读者觉得"这就是一个真人在跟我说话"。''';

    final styleHint =
        targetStyle != null ? '\n目标平台/风格：$targetStyle' : '';
    final issuesHint = (issues != null && issues.isNotEmpty)
        ? '\n\n已检测到的AI痕迹问题（请针对性改写）：\n${issues.map((e) => '• $e').join('\n')}'
        : '';

    final user = '''请将以下文本改写为更像真人写的版本：$styleHint$issuesHint

---
$content
---

直接输出改写后的纯文本内容，不要加任何格式标记、不要加前缀说明、不要加JSON包裹。''';

    return PromptPair(system: system, user: user);
  }

  // ─── 便捷方法 ──────────────────────────────────────────────────

  /// 将 [buildDetectPrompt] 的结果转为 GLM API messages 数组
  static List<Map<String, String>> detectMessages(String content) {
    final p = buildDetectPrompt(content);
    return [
      {'role': 'system', 'content': p.system},
      {'role': 'user', 'content': p.user},
    ];
  }

  /// 将 [buildRewritePrompt] 的结果转为 GLM API messages 数组
  static List<Map<String, String>> rewriteMessages({
    required String content,
    String? targetStyle,
    List<String>? issues,
  }) {
    final p = buildRewritePrompt(
      content: content,
      targetStyle: targetStyle,
      issues: issues,
    );
    return [
      {'role': 'system', 'content': p.system},
      {'role': 'user', 'content': p.user},
    ];
  }
}

/// Prompt 对，包含 system prompt 和 user message
class PromptPair {
  final String system;
  final String user;

  const PromptPair({required this.system, required this.user});

  /// 转为 GLM API messages 数组
  List<Map<String, String>> toMessages() => [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ];

  @override
  String toString() => 'PromptPair(system: ${system.length} chars, user: ${user.length} chars)';
}
