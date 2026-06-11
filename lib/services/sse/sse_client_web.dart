/// Web 端 SSE 实现 — 使用 dart:html HttpRequest + onProgress
library;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

/// Web 端 SSE 客户端
class SseClient {
  /// 发起 SSE POST 请求
  /// 使用 HttpRequest + onProgress 实现增量读取
  Stream<String> postSse({
    required String url,
    required Map<String, String> headers,
    required Map<String, dynamic> body,
  }) {
    final controller = StreamController<String>();

    final xhr = HttpRequest();
    xhr.open('POST', url);
    xhr.responseType = 'text';

    // 设置请求头
    headers.forEach((key, value) {
      xhr.setRequestHeader(key, value);
    });

    int lastLength = 0;

    // onProgress 事件：每次有新数据到达时触发
    xhr.onProgress.listen((_) {
      try {
        final text = xhr.responseText ?? '';
        if (text.length > lastLength) {
          final delta = text.substring(lastLength);
          lastLength = text.length;
          _parseSseDelta(delta, controller);
        }
      } catch (_) {}
    });

    // onLoad：请求完成
    xhr.onLoad.listen((_) {
      // 确保最后一批数据也发送
      try {
        final text = xhr.responseText ?? '';
        if (text.length > lastLength) {
          final delta = text.substring(lastLength);
          _parseSseDelta(delta, controller);
        }
      } catch (_) {}
      controller.close();
    });

    xhr.onError.listen((_) {
      if (!controller.isClosed) {
        controller.addError('网络请求失败');
        controller.close();
      }
    });

    xhr.send(jsonEncode(body));
    return controller.stream;
  }

  /// 解析 SSE 增量文本
  void _parseSseDelta(String delta, StreamController<String> controller) {
    final lines = delta.split('\n');
    for (final line in lines) {
      if (!line.startsWith('data: ')) continue;
      final data = line.substring(6).trim();
      if (data.isEmpty || data == '[DONE]') continue;

      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        final choices = json['choices'] as List?;
        if (choices == null || choices.isEmpty) continue;
        final deltaObj = choices[0]['delta'] as Map<String, dynamic>?;
        if (deltaObj == null) continue;
        final content = deltaObj['content'] as String? ?? '';
        if (content.isNotEmpty) {
          controller.add(content);
        }
      } catch (_) {
        // 不完整 JSON 行，跳过
      }
    }
  }
}
