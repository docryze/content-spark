import 'dart:convert';

/// 流式内容增量解析器
/// 从不完整的 JSON 文本中实时提取已到达的字段
class StreamContentParser {
  List<String> titles = [];
  String content = '';
  List<String> tags = [];
  String coverText = '';
  String publishTime = '';
  String analysis = '';
  List<Map<String, String>> topics = [];

  /// 尝试从累积文本中增量解析
  void parse(String rawText) {
    final cleaned = _stripMarkdown(rawText);
    if (cleaned.isEmpty) return;

    // 优先尝试完整 JSON 解析
    try {
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      _extractFromFullJson(json);
      return;
    } catch (_) {}

    // JSON 不完整 — 用正则增量提取
    _extractTitles(cleaned);
    _extractContent(cleaned);
    _extractTags(cleaned);
    _extractCoverText(cleaned);
    _extractPublishTime(cleaned);
    _extractTopics(cleaned);
    _extractAnalysis(cleaned);
  }

  void _extractFromFullJson(Map<String, dynamic> json) {
    if (json['titles'] is List) {
      titles = (json['titles'] as List).map((e) {
        if (e is String) return e;
        if (e is Map) return e['title']?.toString() ?? '';
        return '';
      }).where((e) => e.isNotEmpty).toList();
    }
    if (json['content'] is String) content = json['content'] as String;
    if (json['tags'] is List) {
      tags = (json['tags'] as List).map((e) => e.toString()).toList();
    }
    if (json['coverText'] is String) coverText = json['coverText'] as String;
    if (json['publishTime'] is String) publishTime = json['publishTime'] as String;
    if (json['analysis'] is String) analysis = json['analysis'] as String;
    if (json['topics'] is List) {
      topics = (json['topics'] as List).map((e) {
        if (e is Map) {
          return {
            'title': e['title']?.toString() ?? '',
            'reason': e['reason']?.toString() ?? '',
            'heat': e['heat']?.toString() ?? '',
            'angle': e['angle']?.toString() ?? '',
          };
        }
        return <String, String>{};
      }).where((e) => e['title']!.isNotEmpty).toList();
    }
  }

  /// 增量提取 titles 数组
  void _extractTitles(String text) {
    final match = RegExp(r'"titles"\s*:\s*\[(.*?)\]', dotAll: true).firstMatch(text);
    if (match != null) {
      final arrayStr = match.group(1) ?? '';
      final items = RegExp(r'"([^"]*)"').allMatches(arrayStr);
      titles = items.map((m) => m.group(1) ?? '').where((e) => e.isNotEmpty).toList();
    }
  }

  /// 增量提取 content（处理转义）
  void _extractContent(String text) {
    final match = RegExp(r'"content"\s*:\s*"((?:[^"\\]|\\.)*)"', dotAll: true).firstMatch(text);
    if (match != null) {
      var raw = match.group(1) ?? '';
      raw = _unescape(raw);
      content = raw;
    }
  }

  /// 增量提取 tags
  void _extractTags(String text) {
    final match = RegExp(r'"tags"\s*:\s*\[(.*?)\]', dotAll: true).firstMatch(text);
    if (match != null) {
      final arrayStr = match.group(1) ?? '';
      final items = RegExp(r'"([^"]*)"').allMatches(arrayStr);
      tags = items.map((m) => m.group(1) ?? '').where((e) => e.isNotEmpty).toList();
    }
  }

  void _extractCoverText(String text) {
    final match = RegExp(r'"coverText"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(text);
    if (match != null) {
      coverText = _unescape(match.group(1) ?? '');
    }
  }

  void _extractPublishTime(String text) {
    final match = RegExp(r'"publishTime"\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(text);
    if (match != null) {
      publishTime = _unescape(match.group(1) ?? '');
    }
  }

  void _extractAnalysis(String text) {
    final match = RegExp(r'"analysis"\s*:\s*"((?:[^"\\]|\\.)*)"', dotAll: true).firstMatch(text);
    if (match != null) {
      analysis = _unescape(match.group(1) ?? '');
    }
  }

  void _extractTopics(String text) {
    final match = RegExp(r'"topics"\s*:\s*\[(.*)\]', dotAll: true).firstMatch(text);
    if (match == null) return;
    final arrayStr = match.group(1) ?? '';
    final objMatches = RegExp(r'\{([^}]*)\}').allMatches(arrayStr);
    topics = objMatches.map((m) {
      final obj = m.group(1) ?? '';
      return {
        'title': _extractFieldValue(obj, 'title'),
        'reason': _extractFieldValue(obj, 'reason'),
        'heat': _extractFieldValue(obj, 'heat'),
        'angle': _extractFieldValue(obj, 'angle'),
      };
    }).where((e) => e['title']!.isNotEmpty).toList();
  }

  String _extractFieldValue(String obj, String field) {
    final m = RegExp('"$field"\\s*:\\s*"((?:[^"\\\\]|\\\\.)*)"').firstMatch(obj);
    return m != null ? _unescape(m.group(1) ?? '') : '';
  }

  String _unescape(String s) {
    return s
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\"', '"')
        .replaceAll(r'\\', '\\')
        .replaceAll(r'\t', '\t');
  }

  String _stripMarkdown(String text) {
    var c = text.trim();
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
