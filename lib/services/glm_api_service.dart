import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../constants/app_enums.dart';
import '../services/platform_style_engine.dart';
import '../models/app_models.dart';
import 'package:uuid/uuid.dart';

/// GLM API 服务 — 支持 SSE 流式响应
class GlmApiService {
  late final Dio _dio;
  final _uuid = const Uuid();

  GlmApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.glmBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppConfig.glmApiKey}',
      },
    ));
  }

  /// SSE 流式对话 — 返回 Stream<String> 实时推送文本片段
  Stream<String> chatStream({
    required String systemPrompt,
    required String userMessage,
  }) async* {
    try {
      final response = await _dio.post<ResponseBody>(
        '/chat/completions',
        data: {
          'model': AppConfig.glmModel,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userMessage},
          ],
          'temperature': 0.85,
          'top_p': 0.9,
          'max_tokens': 4096,
          'stream': true,
        },
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'text/event-stream',
          },
        ),
      );

      final stream = response.data?.stream;
      if (stream == null) {
        yield '错误：无法建立流式连接';
        return;
      }

      String buffer = '';
      await for (final chunk in stream) {
        buffer += utf8.decode(chunk, allowMalformed: true);
        
        // 按行解析 SSE
        final lines = buffer.split('\n');
        buffer = lines.removeLast(); // 保留最后一个不完整的行

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty || trimmed.startsWith(':')) continue;
          if (trimmed == 'data: [DONE]') return;

          if (trimmed.startsWith('data: ')) {
            final jsonStr = trimmed.substring(6);
            try {
              final json = jsonDecode(jsonStr) as Map<String, dynamic>;
              final choices = json['choices'] as List?;
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'] as Map<String, dynamic>?;
                final content = delta?['content'] as String?;
                if (content != null && content.isNotEmpty) {
                  yield content;
                }
              }
            } catch (_) {
              // 忽略解析失败的行
            }
          }
        }
      }
    } on DioException catch (e) {
      yield '错误：${_handleDioError(e)}';
    }
  }

  /// 流式生成内容 — 返回实时文本流，最终自动解析为完整结果
  Stream<StreamGenerationState> generateContentStream({
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

    String fullText = '';
    
    // 发射加载状态
    yield StreamGenerationState(
      status: StreamStatus.streaming,
      rawText: '',
    );

    await for (final chunk in chatStream(
      systemPrompt: template.systemPrompt,
      userMessage: userMessage,
    )) {
      if (chunk.startsWith('错误：')) {
        yield StreamGenerationState(
          status: StreamStatus.error,
          rawText: fullText,
          errorMessage: chunk,
        );
        return;
      }
      
      fullText += chunk;
      yield StreamGenerationState(
        status: StreamStatus.streaming,
        rawText: fullText,
      );
    }

    // 流结束，解析最终结果
    final result = _parseFullResponse(fullText, platform, contentType, userInput);
    yield StreamGenerationState(
      status: StreamStatus.done,
      rawText: fullText,
      result: result,
    );
  }

  /// 非流式生成（兼容旧接口）
  Future<GenerationResult> generateContent({
    required SocialPlatform platform,
    required ContentType contentType,
    required String userInput,
    String? category,
  }) async {
    final template = PlatformStyleEngine.getTemplate(platform);
    final userMessage = PlatformStyleEngine.buildUserMessage(
      platform: platform,
      contentType: contentType,
      userInput: userInput,
      category: category,
    );

    final buffer = StringBuffer();
    await for (final chunk in chatStream(
      systemPrompt: template.systemPrompt,
      userMessage: userMessage,
    )) {
      buffer.write(chunk);
    }
    return _parseFullResponse(buffer.toString(), platform, contentType, userInput);
  }

  /// 解析完整响应为 GenerationResult
  GenerationResult _parseFullResponse(
    String content,
    SocialPlatform platform,
    ContentType contentType,
    String userInput,
  ) {
    final parsed = _parseJsonResponse(content);
    
    List<String> titles = [];
    if (parsed.containsKey('titles')) {
      final titlesRaw = parsed['titles'];
      if (titlesRaw is List) {
        titles = titlesRaw.map((e) {
          if (e is String) return e;
          if (e is Map) return e['title']?.toString() ?? '';
          return e.toString();
        }).toList();
      }
    }

    List<String> tags = [];
    if (parsed.containsKey('tags')) {
      final tagsRaw = parsed['tags'];
      if (tagsRaw is List) {
        tags = tagsRaw.map((e) => e.toString()).toList();
      }
    }

    return GenerationResult(
      id: _uuid.v4(),
      platform: platform,
      contentType: contentType,
      userInput: userInput,
      titleVariants: titles,
      content: parsed['content']?.toString() ?? content,
      tags: tags,
      coverTextSuggestion: parsed['coverText']?.toString() ?? '',
      publishTimeSuggestion: parsed['publishTime']?.toString() ?? '',
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> _parseJsonResponse(String content) {
    var cleaned = content.trim();
    for (final prefix in ['```json', '```']) {
      if (cleaned.startsWith(prefix)) cleaned = cleaned.substring(prefix.length);
    }
    if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
    cleaned = cleaned.trim();
    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (_) {
      return {'content': cleaned, 'titles': <String>[], 'tags': <String>[]};
    }
  }

  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '网络连接超时，请重试';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) return 'API密钥无效';
        if (code == 429) return '请求过于频繁，稍后再试';
        return '服务器错误 ($code)';
      case DioExceptionType.connectionError:
        return '网络连接失败';
      default:
        return '未知错误，请重试';
    }
  }
}

/// 流式生成状态
enum StreamStatus { streaming, done, error }

class StreamGenerationState {
  final StreamStatus status;
  final String rawText;
  final GenerationResult? result;
  final String? errorMessage;

  const StreamGenerationState({
    required this.status,
    required this.rawText,
    this.result,
    this.errorMessage,
  });
}
