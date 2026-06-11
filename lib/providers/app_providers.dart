import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_enums.dart';
import '../models/app_models.dart';
import '../services/glm_stream_service.dart';
import '../services/storage_service.dart';

/// Storage 单例
final storageProvider = FutureProvider<StorageService>((ref) async {
  final service = StorageService();
  await service.init();
  return service;
});

/// 流式 API 服务
final streamApiProvider = Provider<GlmStreamService>((ref) => GlmStreamService());

/// 当前平台
final selectedPlatformProvider = StateProvider<SocialPlatform>((ref) => SocialPlatform.xiaohongshu);

/// 当前内容类型
final selectedContentTypeProvider = StateProvider<ContentType>((ref) => ContentType.article);

/// 当前领域
final selectedCategoryProvider = StateProvider<String>((ref) => '');

/// 用户 Profile
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier(ref);
});

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final Ref _ref;
  UserProfileNotifier(this._ref) : super(UserProfile(id: 'local_user')) {
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await _ref.read(storageProvider.future);
      state = state.copyWith(
        nickname: s.getNickname(),
        plan: s.getPlan(),
        usedQuotaToday: s.getUsedQuotaToday(),
      );
    } catch (_) {}
  }

  Future<void> useQuota() async {
    final s = await _ref.read(storageProvider.future);
    await s.incrementUsedQuota();
    state = state.copyWith(usedQuotaToday: state.usedQuotaToday + 1);
  }

  Future<void> setNickname(String n) async {
    final s = await _ref.read(storageProvider.future);
    await s.setNickname(n);
    state = state.copyWith(nickname: n);
  }

  Future<void> setPlan(SubscriptionPlan p) async {
    final s = await _ref.read(storageProvider.future);
    await s.setPlan(p);
    state = state.copyWith(plan: p);
  }
}

// ==================== 流式生成状态 ====================

enum GenStatus { idle, generating, done, error }

class StreamGenState {
  final GenStatus status;
  final String streamedText;     // 已流式到达的文本
  final String? errorMessage;
  final GenerationResult? finalResult; // 完成后解析的结构化结果

  const StreamGenState({
    this.status = GenStatus.idle,
    this.streamedText = '',
    this.errorMessage,
    this.finalResult,
  });

  StreamGenState copyWith({
    GenStatus? status,
    String? streamedText,
    String? errorMessage,
    GenerationResult? finalResult,
  }) =>
      StreamGenState(
        status: status ?? this.status,
        streamedText: streamedText ?? this.streamedText,
        errorMessage: errorMessage ?? this.errorMessage,
        finalResult: finalResult ?? this.finalResult,
      );
}

/// 流式生成 Notifier
final streamGenProvider = StateNotifierProvider<StreamGenNotifier, StreamGenState>((ref) {
  return StreamGenNotifier(ref);
});

class StreamGenNotifier extends StateNotifier<StreamGenState> {
  final Ref _ref;
  StreamSubscription? _sub;

  StreamGenNotifier(this._ref) : super(const StreamGenState());

  /// 开始流式生成
  Future<void> startGeneration({required String userInput, String? category}) async {
    // 检查配额
    final user = _ref.read(userProfileProvider);
    if (!user.canGenerate) {
      state = const StreamGenState(
        status: GenStatus.error,
        errorMessage: '今日免费次数已用完',
      );
      return;
    }

    state = const StreamGenState(status: GenStatus.generating);
    final api = _ref.read(streamApiProvider);
    final platform = _ref.read(selectedPlatformProvider);
    final contentType = _ref.read(selectedContentTypeProvider);

    String accumulated = '';

    final stream = api.generateStream(
      platform: platform,
      contentType: contentType,
      userInput: userInput,
      category: category,
    );

    await for (final chunk in stream) {
      if (chunk.error != null) {
        state = StreamGenState(status: GenStatus.error, errorMessage: chunk.error);
        return;
      }
      if (chunk.delta.isNotEmpty) {
        accumulated += chunk.delta;
        state = StreamGenState(
          status: GenStatus.generating,
          streamedText: accumulated,
        );
      }
      if (chunk.isDone) {
        // 解析最终 JSON
        final parsed = _parseResult(accumulated, platform, contentType, userInput);
        // 保存历史
        if (parsed != null) {
          try {
            final s = await _ref.read(storageProvider.future);
            await s.saveGeneration(parsed);
          } catch (_) {}
        }
        await _ref.read(userProfileProvider.notifier).useQuota();
        state = StreamGenState(
          status: GenStatus.done,
          streamedText: accumulated,
          finalResult: parsed,
        );
      }
    }
  }

  GenerationResult? _parseResult(String raw, SocialPlatform p, ContentType t, String input) {
    final parsed = _tryParseJson(raw);
    if (parsed == null) return null;

    List<String> titles = [];
    if (parsed['titles'] is List) {
      titles = (parsed['titles'] as List).map((e) {
        if (e is String) return e;
        if (e is Map) return e['title']?.toString() ?? '';
        return '';
      }).toList();
    }
    List<String> tags = [];
    if (parsed['tags'] is List) {
      tags = (parsed['tags'] as List).map((e) => e.toString()).toList();
    }

    return GenerationResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      platform: p,
      contentType: t,
      userInput: input,
      titleVariants: titles,
      content: parsed['content']?.toString() ?? raw,
      tags: tags,
      coverTextSuggestion: parsed['coverText']?.toString() ?? '',
      publishTimeSuggestion: parsed['publishTime']?.toString() ?? '',
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic>? _tryParseJson(String text) {
    var c = text.trim();
    for (final p in ['```json', '```']) {
      if (c.startsWith(p)) c = c.substring(p.length);
    }
    if (c.endsWith('```')) c = c.substring(0, c.length - 3);
    c = c.trim();
    try {
      return jsonDecode(c) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  void reset() {
    state = const StreamGenState();
  }
}

/// 历史记录
final historyProvider = FutureProvider<List<GenerationResult>>((ref) async {
  final s = await ref.read(storageProvider.future);
  return s.getHistory();
});
