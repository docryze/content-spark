import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../constants/app_enums.dart';
import '../services/platform_style_engine.dart';

/// 流式生成事件 — 逐字推送给 UI
class StreamChunk {
  final String delta;
  final bool isDone;
  final String? fullText;
  final String? error;

  const StreamChunk({this.delta = '', this.isDone = false, this.fullText, this.error});
}

/// GLM SSE 流式 API 服务
class GlmStreamService {
  late final Dio _dio;
  bool _started = false; // 是否已输出首个有意义内容

  GlmStreamService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.glmBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 180),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConfig.glmApiKey}',
      },
    ));
  }

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

    try {
      final response = await _dio.post<ResponseBody>(
        '/chat/completions',
        data: {
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
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: 180),
        ),
      );

      String fullContent = '';
      String lineBuffer = ''; // 处理 TCP 包分割

      await for (final chunk in response.data!.stream) {
        final text = String.fromCharCodes(chunk);
        lineBuffer += text;

        // 按行处理（SSE 以 \n\n 分隔）
        while (lineBuffer.contains('\n')) {
          final idx = lineBuffer.indexOf('\n');
          final line = lineBuffer.substring(0, idx).trim();
          lineBuffer = lineBuffer.substring(idx + 1);

          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          if (data.isEmpty) continue;

          if (data == '[DONE]') {
            // 过滤 markdown 包裹后输出最终结果
            final cleaned = _stripMarkdown(fullContent);
            yield StreamChunk(isDone: true, fullText: cleaned);
            return;
          }

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List?;
            if (choices == null || choices.isEmpty) continue;

            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            if (delta == null) continue;

            final content = delta['content'] as String? ?? '';
            if (content.isNotEmpty) {
              fullContent += content;

              // 过滤开头的 ```json 或 ``` 包裹
              final displayDelta = _filterDelta(content, fullContent);
              if (displayDelta.isNotEmpty) {
                yield StreamChunk(delta: displayDelta);
              }
            }
          } catch (_) {
            // 忽略非 JSON 行（不完整的 chunk）
          }
        }
      }

      // 处理 buffer 中剩余内容
      if (lineBuffer.trim().startsWith('data: ')) {
        final data = lineBuffer.trim().substring(6).trim();
        if (data == '[DONE]') {
          final cleaned = _stripMarkdown(fullContent);
          yield StreamChunk(isDone: true, fullText: cleaned);
          return;
        }
      }

      final cleaned = _stripMarkdown(fullContent);
      yield StreamChunk(isDone: true, fullText: cleaned);
    } on DioException catch (e) {
      yield StreamChunk(error: _handleError(e), isDone: true);
    } catch (e) {
      yield StreamChunk(error: '生成失败：$e', isDone: true);
    }
  }

  /// 过滤增量文本中的 markdown 代码块标记
  String _filterDelta(String delta, String fullSoFar) {
    // 开头阶段：跳过 ```json\n 和 ```
    if (!_started) {
      final stripped = _stripMarkdown(fullSoFar);
      if (stripped.isEmpty) return '';
      _started = true;
      // 第一次输出：返回已经去掉 markdown 的全部内容
      return stripped;
    }

    // 已经开始输出后，只过滤结尾的 ```
    if (delta == '```' || delta == '`' || delta == '``') return '';
    if (delta.endsWith('```')) {
      return delta.substring(0, delta.length - 3);
    }
    return delta;
  }

  /// 去除 markdown 代码块包裹
  String _stripMarkdown(String text) {
    var c = text;
    // 去除开头的 ```json 或 ```
    if (c.startsWith('```json')) {
      c = c.substring(7);
    } else if (c.startsWith('```')) {
      c = c.substring(3);
    }
    // 去除结尾的 ```
    if (c.endsWith('```')) {
      c = c.substring(0, c.length - 3);
    }
    // 去除开头换行
    while (c.startsWith('\n')) c = c.substring(1);
    return c.trim();
  }

  /// 尝试从文本中解析出 JSON
  Map<String, dynamic>? tryParseJson(String text) {
    final cleaned = _stripMarkdown(text);
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '网络连接超时，请重试';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) return 'API 密钥无效';
        if (code == 429) return '请求太频繁，稍后再试';
        return '服务器错误 ($code)';
      case DioExceptionType.connectionError:
        return '网络连接失败';
      default:
        return '未知错误，请重试';
    }
  }
}
