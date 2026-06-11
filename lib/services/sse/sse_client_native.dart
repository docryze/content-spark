/// 原生端 SSE 实现 — 使用 Dio ResponseBody stream
library;

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';

/// 原生端 SSE 客户端
class SseClient {
  /// 发起 SSE POST 请求
  Stream<String> postSse({
    required String url,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) async* {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 180),
    ));

    final response = await dio.post<ResponseBody>(
      url,
      data: body,
      options: Options(
        responseType: ResponseType.stream,
        headers: headers,
        receiveTimeout: const Duration(seconds: 180),
      ),
    );

    String lineBuffer = '';

    await for (final chunk in response.data!.stream) {
      // UTF-8 解码
      final text = utf8.decode(chunk, allowMalformed: true);
      lineBuffer += text;

      while (lineBuffer.contains('\n')) {
        final idx = lineBuffer.indexOf('\n');
        final line = lineBuffer.substring(0, idx).trim();
        lineBuffer = lineBuffer.substring(idx + 1);

        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data.isEmpty || data == '[DONE]') continue;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          final choices = json['choices'] as List?;
          if (choices == null || choices.isEmpty) continue;
          final delta = choices[0]['delta'] as Map<String, dynamic>?;
          if (delta == null) continue;
          final content = delta['content'] as String? ?? '';
          if (content.isNotEmpty) {
            yield content;
          }
        } catch (_) {
          // 不完整 JSON 行
        }
      }
    }
  }
}
