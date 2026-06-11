import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../constants/app_enums.dart';
import '../services/platform_style_engine.dart';
import '../models/app_models.dart';
import 'package:uuid/uuid.dart';

/// GLM API 服务 — 与智谱AI大模型交互
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

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint('[GLM API] $obj'),
    ));
  }

  /// 通用对话接口
  Future<Map<String, dynamic>> _chat(String systemPrompt, String userMessage) async {
    try {
      final response = await _dio.post(
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
        },
      );

      final data = response.data;
      final content = data['choices'][0]['message']['content'] as String;
      
      // 尝试解析JSON — 处理模型可能返回的markdown代码块包裹
      return _parseJsonResponse(content);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 解析模型返回的JSON（兼容markdown代码块包裹）
  Map<String, dynamic> _parseJsonResponse(String content) {
    // 去掉可能的markdown代码块标记
    var cleaned = content.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    try {
      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      // 如果JSON解析失败，包装为统一格式
      return {
        'titles': ['生成内容'],
        'content': cleaned,
        'tags': <String>[],
        'coverText': '',
        'publishTime': '',
      };
    }
  }

  /// 生成内容（核心方法）
  Future<GenerationResult> generateContent({
    required SocialPlatform platform,
    required ContentType contentType,
    required String userInput,
    String? category,
  }) async {
    // 获取平台模板（system prompt）
    final template = PlatformStyleEngine.getTemplate(platform);
    
    // 构建用户消息（不含 system prompt）
    final userMessage = PlatformStyleEngine.buildUserMessage(
      platform: platform,
      contentType: contentType,
      userInput: userInput,
      category: category,
    );

    // 调用 GLM API：system prompt + 用户消息
    final result = await _chat(template.systemPrompt, userMessage);

    // 解析结果
    List<String> titles = [];
    if (result.containsKey('titles')) {
      final titlesRaw = result['titles'];
      if (titlesRaw is List) {
        titles = titlesRaw.map((e) {
          if (e is String) return e;
          if (e is Map) return e['title']?.toString() ?? '';
          return e.toString();
        }).toList();
      }
    }

    List<String> tags = [];
    if (result.containsKey('tags')) {
      final tagsRaw = result['tags'];
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
      content: result['content']?.toString() ?? '',
      tags: tags,
      coverTextSuggestion: result['coverText']?.toString() ?? '',
      publishTimeSuggestion: result['publishTime']?.toString() ?? '',
      createdAt: DateTime.now(),
    );
  }

  /// 生成选题灵感
  Future<List<Map<String, String>>> generateTopicIdeas({
    required SocialPlatform platform,
    required String category,
  }) async {
    final template = PlatformStyleEngine.getTemplate(platform);
    final userMessage = PlatformStyleEngine.buildUserMessage(
      platform: platform,
      contentType: ContentType.topicIdea,
      userInput: category,
    );

    final result = await _chat(template.systemPrompt, userMessage);

    final topics = <Map<String, String>>[];
    if (result.containsKey('topics')) {
      final topicsRaw = result['topics'];
      if (topicsRaw is List) {
        for (final t in topicsRaw) {
          if (t is Map) {
            topics.add({
              'title': t['title']?.toString() ?? '',
              'reason': t['reason']?.toString() ?? '',
              'heat': t['heat']?.toString() ?? '',
              'angle': t['angle']?.toString() ?? '',
            });
          }
        }
      }
    }
    return topics;
  }

  /// 错误处理
  String _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return '网络连接超时，请检查网络后重试';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 401) return 'API密钥无效，请检查配置';
        if (code == 429) return '请求过于频繁，请稍后再试';
        if (code == 500) return '服务器暂时不可用，请稍后重试';
        return '服务器错误 ($code)';
      case DioExceptionType.connectionError:
        return '网络连接失败，请检查网络设置';
      default:
        return '发生未知错误，请重试';
    }
  }
}
