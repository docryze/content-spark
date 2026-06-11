import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../constants/app_enums.dart';
import '../services/platform_style_engine.dart';

/// 流式生成事件 — 逐字推送给 UI
class StreamChunk {
  final String delta;         // 本次增量文本
  final bool isDone;          // 是否完成
  final String? fullText;     // 完成时的完整文本
  final String? error;        // 错误信息

  const StreamChunk({this.delta = '', this.isDone = false, this.fullText, this.error});
}

/// GLM SSE 流式 API 服务
class GlmStreamService {
  late final Dio _dio;

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
      // 使用 SSE (Server-Sent Events) 流式请求
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
          'stream': true, // 关键：开启流式
        },
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: const Duration(seconds: 180),
        ),
      );

      final buffer = StringBuffer();
      String fullContent = '';

      await for (final chunk in response.data!.stream) {
        final text = String.fromCharCodes(chunk);
        // SSE 格式：data: {...}\n\n
        final lines = text.split('\n');

        for (final line in lines) {
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();

          if (data == '[DONE]') {
            // 流结束，尝试解析完整 JSON
            final parsed = _tryParseJson(fullContent);
            yield StreamChunk(
              isDone: true,
              fullText: fullContent,
              delta: '',
            );
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
              yield StreamChunk(delta: content);
            }
          } catch (_) {
            // 忽略非 JSON 行
          }
        }
      }

      // 流自然结束
      yield StreamChunk(isDone: true, fullText: fullContent);
    } on DioException catch (e) {
      yield StreamChunk(error: _handleError(e), isDone: true);
    } catch (e) {
      yield StreamChunk(error: '生成失败：$e', isDone: true);
    }
  }

  /// 尝试从流式文本中解析出 JSON 结构
  Map<String, dynamic>? _tryParseJson(String text) {
    var cleaned = text.trim();
    for (final pfx in ['```json', '```']) {
      if (cleaned.startsWith(pfx)) cleaned = cleaned.substring(pfx.length);
    }
    if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
    cleaned = cleaned.trim();
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
