import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../constants/app_enums.dart';
import 'platform_style_engine.dart';
import 'deai_engine.dart';
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

  /// 流式生成内容 — 创作模式
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
    yield* _doStream(template.systemPrompt, userMessage);
  }

  /// 自定义流式 — 改编模式
  Stream<StreamChunk> customStream({
    required String systemPrompt,
    required String userPrompt,
  }) async* {
    yield* _doStream(systemPrompt, userPrompt);
  }

  /// 去 AI 味 — 检测（非流式，同步调用）
  Future<String> detectAI(String content) async {
    final prompt = DeaiEngine.buildDetectPrompt(content);
    return _callApi(prompt.system, prompt.user);
  }

  /// 去 AI 味 — 改写（流式）
  Stream<StreamChunk> rewriteAIStream({
    required String content,
    String? issues,
  }) async* {
    final prompt = DeaiEngine.buildRewritePrompt(content: content, issues: issues != null ? [issues] : null);
    yield* _doStream(prompt.system, prompt.user, outputRaw: true);
  }

  // ==================== 内部方法 ====================

  /// 核心流式调用
  Stream<StreamChunk> _doStream(String systemPrompt, String userPrompt, {bool outputRaw = false}) async* {
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
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.85,
          'top_p': 0.9,
          'max_tokens': 4096,
          'stream': true,
        },
      );

      await for (final rawDelta in sseStream) {
        fullContent += rawDelta;

        if (outputRaw) {
          // 纯文本输出（去AI味改写），不过滤 markdown
          yield StreamChunk(delta: rawDelta);
        } else {
          final displayDelta = _filterDisplay(rawDelta, fullContent, inMarkdownBlock);
          if (displayDelta.wasFiltered) inMarkdownBlock = displayDelta.inBlock;
          if (displayDelta.text.isNotEmpty) {
            yield StreamChunk(delta: displayDelta.text);
          }
        }
      }

      final cleaned = outputRaw ? fullContent.trim() : _stripMarkdown(fullContent);
      yield StreamChunk(isDone: true, fullText: cleaned);
    } catch (e) {
      yield StreamChunk(error: '请求失败：$e', isDone: true);
    }
  }

  /// 非流式 API 调用
  Future<String> _callApi(String systemPrompt, String userPrompt) async {
    // 用 SSE 但只取最终结果
    final completer = Completer<String>();
    String full = '';
    final stream = _doStream(systemPrompt, userPrompt);
    stream.listen(
      (chunk) {
        if (chunk.error != null && !completer.isCompleted) {
          completer.completeError(chunk.error!);
        }
        if (chunk.isDone && !completer.isCompleted) {
          completer.complete(chunk.fullText ?? full);
        }
        full += chunk.delta;
      },
      onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete(full);
      },
    );
    return completer.future;
  }

  /// 过滤 markdown 代码块
  _FilterResult _filterDisplay(String delta, String full, bool inBlock) {
    if (full.contains('```json')) {
      final afterBlock = full.replaceFirst(RegExp(r'```json\s*\n?'), '');
      if (afterBlock.isNotEmpty && afterBlock != full) {
        if (full.endsWith(delta)) {
          if (delta.startsWith('```')) {
            return _FilterResult(delta.replaceFirst(RegExp(r'```json\s*\n?'), ''), true, true);
          }
        }
        return _FilterResult(delta, true, true);
      }
      return _FilterResult('', true, true);
    }
    if (full.contains('```') && !full.contains('```json')) {
      if (delta == '```' || delta == '``' || delta == '`') {
        return _FilterResult('', true, true);
      }
    }
    if (delta.endsWith('```')) {
      return _FilterResult(delta.substring(0, delta.length - 3), false, false);
    }
    return _FilterResult(delta, false, inBlock);
  }

  String _stripMarkdown(String text) {
    var c = text;
    final jsonBlock = RegExp(r'^```json\s*\n?');
    final simpleBlock = RegExp(r'^```\s*\n?');
    if (jsonBlock.hasMatch(c)) {
      c = c.replaceFirst(jsonBlock, '');
    } else if (simpleBlock.hasMatch(c)) {
      c = c.replaceFirst(simpleBlock, '');
    }
    if (c.endsWith('```')) c = c.substring(0, c.length - 3);
    return c.trim();
  }
}

/// Provider 实例
final streamApiProvider = Provider<GlmStreamService>((ref) => GlmStreamService());

class _FilterResult {
  final String text;
  final bool wasFiltered;
  final bool inBlock;
  const _FilterResult(this.text, this.wasFiltered, this.inBlock);
}
