import 'dart:async';
import 'dart:convert';
import '../config/app_config.dart';
import '../constants/app_enums.dart';
import 'platform_style_engine.dart';
import 'sse/sse_client.dart';

/// 流式生成事件
class StreamChunk {
  final String delta;
  final bool isDone;
  final String? fullText;
  final String? error;

  const StreamChunk({this.delta = '', this.isDone = false, this.fullText, this.error});
}

/// GLM 流式 API 服务（跨平台：Web + Native）
class GlmStreamService {
  final SseClient _sse = SseClient();

  /// 流式生成内容 — 返回 Stream<StreamChunk>
  Stream<StreamChunk> generateStream({
    required SocialPlatform platform,
    required ContentType contentType,
    required String userInput,
    String? category,
  }) async* {
    final template = PlatformStyleEngine.getTemplate(platform);
    final userMessage = PlatformStyleEngine.buildUserMessage(
      platform: platform,
      contentType: contentType,
      userInput: userInput,
      category: category,
    );

    String fullContent = '';
    bool inMarkdownBlock = false;

    try {
      final sseStream = _sse.postSse(
        url: '${AppConfig.glmBaseUrl}/chat/completions',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppConfig.glmApiKey}',
        },
        body: {
          'model': AppConfig.glmModel,
          'messages': [
            {'role': 'system', 'content': template.systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.85,
          'top_p': 0.9,
          'max_tokens': 4096,
          'stream': true,
        },
      );

      await for (final rawDelta in sseStream) {
        fullContent += rawDelta;

        // 过滤 markdown 代码块包裹
        final displayDelta = _filterDisplay(rawDelta, fullContent, inMarkdownBlock);
        if (displayDelta.wasFiltered) {
          inMarkdownBlock = displayDelta.inBlock;
        }
        if (displayDelta.text.isNotEmpty) {
          yield StreamChunk(delta: displayDelta.text);
        }
      }

      // 流结束，返回清理后的完整文本
      final cleaned = _stripMarkdown(fullContent);
      yield StreamChunk(isDone: true, fullText: cleaned);
    } catch (e) {
      yield StreamChunk(error: '生成失败：$e', isDone: true);
    }
  }

  /// 过滤显示用的增量文本
  _FilterResult _filterDisplay(String delta, String full, bool inBlock) {
    // 检测 ```json 开头
    if (full.contains('```json')) {
      // 已经开始输出 markdown 包裹
      // 检查包裹是否结束（有换行后的内容）
      final afterBlock = full.replaceFirst(RegExp(r'```json\s*\n?'), '');
      if (afterBlock.length > 0 && afterBlock != full) {
        // 包裹标记后的第一个实质内容，返回标记后的部分
        if (full.endsWith(delta)) {
          // delta 包含了 ```json 后的内容
          if (delta.startsWith('```')) {
            // delta 以 ``` 开头，需要去掉
            final cleaned = delta.replaceFirst(RegExp(r'```json\s*\n?'), '');
            return _FilterResult(cleaned, true, true);
          }
        }
        return _FilterResult(delta, true, true);
      }
      return _FilterResult('', true, true);
    }

    if (full.contains('```') && !full.contains('```json')) {
      // 可能是简单的 ``` 包裹
      if (delta == '```' || delta == '``' || delta == '`') {
        return _FilterResult('', true, true);
      }
    }

    // 检查结尾的 ``` 闭合标记
    if (delta.endsWith('```')) {
      return _FilterResult(delta.substring(0, delta.length - 3), false, false);
    }

    return _FilterResult(delta, false, inBlock);
  }

  /// 去除 markdown 代码块包裹
  String _stripMarkdown(String text) {
    var c = text;
    final jsonBlock = RegExp(r'^```json\s*\n?');
    final simpleBlock = RegExp(r'^```\s*\n?');
    if (jsonBlock.hasMatch(c)) {
      c = c.replaceFirst(jsonBlock, '');
    } else if (simpleBlock.hasMatch(c)) {
      c = c.replaceFirst(simpleBlock, '');
    }
    if (c.endsWith('```')) {
      c = c.substring(0, c.length - 3);
    }
    return c.trim();
  }

  /// 尝试解析 JSON
  Map<String, dynamic>? tryParseJson(String text) {
    final cleaned = _stripMarkdown(text);
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

class _FilterResult {
  final String text;
  final bool wasFiltered;
  final bool inBlock;
  const _FilterResult(this.text, this.wasFiltered, this.inBlock);
}
