import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../constants/app_enums.dart';
import '../models/app_models.dart';
import '../services/glm_stream_service.dart';
import '../services/stream_content_parser.dart';
import '../services/storage_service.dart';

/// Storage 单例
final storageProvider = FutureProvider<StorageService>((ref) async {
  final svc = StorageService();
  await svc.init();
  return svc;
});

/// 用户资料
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier(ref);
});

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final Ref _ref;
  UserProfileNotifier(this._ref) : super(UserProfile(id: 'local')) {
    _load();
  }
  Future<void> _load() async {
    try {
      final s = await _ref.read(storageProvider.future);
      state = UserProfile(
        id: 'local',
        nickname: s.getNickname(),
        plan: s.getPlan(),
      );
    } catch (_) {}
  }
  Future<void> useQuota() async {
    state = state.copyWith(usedQuotaToday: state.usedQuotaToday + 1);
    try { final s = await _ref.read(storageProvider.future); await s.incrementUsedQuota(); } catch (_) {}
  }
  Future<void> setPlan(SubscriptionPlan p) async {
    state = state.copyWith(plan: p);
    try { final s = await _ref.read(storageProvider.future); await s.setPlan(p); } catch (_) {}
  }
  Future<void> setNickname(String name) async {
    state = state.copyWith(nickname: name);
    try { final s = await _ref.read(storageProvider.future); await s.setNickname(name); } catch (_) {}
  }
}

/// 历史记录
final historyProvider = FutureProvider<List<GenerationResult>>((ref) async {
  final s = await ref.read(storageProvider.future);
  return s.getHistory();
});

/// 选中平台
final selectedPlatformProvider = StateProvider<SocialPlatform>((ref) => SocialPlatform.xiaohongshu);

/// 选中内容类型
final selectedContentTypeProvider = StateProvider<ContentType>((ref) => ContentType.article);

/// 选中创作模式
final selectedModeProvider = StateProvider<CreateMode>((ref) => CreateMode.create);

/// 选中品类
final selectedCategoryProvider = StateProvider<String>((ref) => '');

/// 改编模式 — 目标平台多选
final targetPlatformsProvider = StateProvider<List<SocialPlatform>>((ref) => [
  SocialPlatform.douyin,
  SocialPlatform.wechat,
]);

// ==================== 流式生成状态 ====================

enum GenStatus { idle, generating, done, error }

class StreamGenState {
  final GenStatus status;
  final String streamedText;
  final String? errorMessage;
  final GenerationResult? finalResult;
  final StreamContentParser? parsedContent;

  const StreamGenState({
    this.status = GenStatus.idle,
    this.streamedText = '',
    this.errorMessage,
    this.finalResult,
    this.parsedContent,
  });

  StreamGenState copyWith({
    GenStatus? status,
    String? streamedText,
    String? errorMessage,
    GenerationResult? finalResult,
    StreamContentParser? parsedContent,
  }) =>
      StreamGenState(
        status: status ?? this.status,
        streamedText: streamedText ?? this.streamedText,
        errorMessage: errorMessage ?? this.errorMessage,
        finalResult: finalResult ?? this.finalResult,
        parsedContent: parsedContent ?? this.parsedContent,
      );
}

/// 流式生成 Notifier
final streamGenProvider = StateNotifierProvider<StreamGenNotifier, StreamGenState>((ref) {
  return StreamGenNotifier(ref);
});

class StreamGenNotifier extends StateNotifier<StreamGenState> {
  final Ref _ref;
  StreamGenNotifier(this._ref) : super(const StreamGenState());

  void reset() => state = const StreamGenState();

  /// 开始流式生成（创作模式）
  Future<void> startGeneration({required String userInput, String? category}) async {
    if (!AppConfig.disableQuota) {
      final user = _ref.read(userProfileProvider);
      if (!user.canGenerate) {
        state = const StreamGenState(status: GenStatus.error, errorMessage: '今日免费次数已用完');
        return;
      }
    }

    state = const StreamGenState(status: GenStatus.generating);
    final api = _ref.read(streamApiProvider);
    final platform = _ref.read(selectedPlatformProvider);
    final contentType = _ref.read(selectedContentTypeProvider);

    String accumulated = '';
    final parser = StreamContentParser();

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
        parser.parse(accumulated);
        state = StreamGenState(
          status: GenStatus.generating,
          streamedText: accumulated,
          parsedContent: parser,
        );
      }
      if (chunk.isDone) {
        final parsed = _parseResult(accumulated, platform, contentType, userInput);
        if (parsed != null) {
          try { final s = await _ref.read(storageProvider.future); await s.saveGeneration(parsed); } catch (_) {}
        }
        if (!AppConfig.disableQuota) {
          await _ref.read(userProfileProvider.notifier).useQuota();
        }
        state = StreamGenState(
          status: GenStatus.done,
          streamedText: accumulated,
          finalResult: parsed,
          parsedContent: parser,
        );
      }
    }
  }

  /// 改编模式 — 流式生成（自定义 prompt）
  Future<void> startCustomStream({
    required String systemPrompt,
    required String userPrompt,
    SocialPlatform? platform,
  }) async {
    state = const StreamGenState(status: GenStatus.generating);
    final api = _ref.read(streamApiProvider);

    String accumulated = '';
    final parser = StreamContentParser();

    final stream = api.customStream(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
    );

    await for (final chunk in stream) {
      if (chunk.error != null) {
        state = StreamGenState(status: GenStatus.error, errorMessage: chunk.error);
        return;
      }
      if (chunk.delta.isNotEmpty) {
        accumulated += chunk.delta;
        parser.parse(accumulated);
        state = StreamGenState(
          status: GenStatus.generating,
          streamedText: accumulated,
          parsedContent: parser,
        );
      }
      if (chunk.isDone) {
        state = StreamGenState(
          status: GenStatus.done,
          streamedText: accumulated,
          parsedContent: parser,
        );
      }
    }
  }

  /// 去 AI 味 — 检测（非流式）
  Future<void> detectAI(String content) async {
    state = const StreamGenState(status: GenStatus.generating);
    final api = _ref.read(streamApiProvider);

    try {
      final result = await api.detectAI(content);
      state = StreamGenState(
        status: GenStatus.done,
        streamedText: result,
      );
    } catch (e) {
      state = StreamGenState(status: GenStatus.error, errorMessage: e.toString());
    }
  }

  /// 去 AI 味 — 改写（流式）
  Future<void> rewriteAI({
    required String content,
    String? issues,
  }) async {
    state = const StreamGenState(status: GenStatus.generating);
    final api = _ref.read(streamApiProvider);

    String accumulated = '';

    final stream = api.rewriteAIStream(content: content, issues: issues);

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
        state = StreamGenState(
          status: GenStatus.done,
          streamedText: accumulated,
        );
      }
    }
  }

  GenerationResult? _parseResult(String raw, SocialPlatform p, ContentType t, String input) {
    try {
      String cleaned = raw.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceAll(RegExp(r'^```\w*\n?'), '').replaceAll(RegExp(r'\n?```$'), '');
      }
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return GenerationResult(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        platform: p,
        contentType: t,
        userInput: input,
        titleVariants: (json['titles'] as List<dynamic>?)?.cast<String>() ?? [],
        content: json['content'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        coverTextSuggestion: json['coverText'] as String? ?? '',
        publishTimeSuggestion: json['publishTime'] as String? ?? '',
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }
}
