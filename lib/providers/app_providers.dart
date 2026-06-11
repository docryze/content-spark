import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_enums.dart';
import '../models/app_models.dart';
import '../services/glm_api_service.dart';
import '../services/storage_service.dart';

/// Storage Service 单例
final storageProvider = FutureProvider<StorageService>((ref) async {
  final service = StorageService();
  await service.init();
  return service;
});

/// GLM API Service 单例
final glmApiProvider = Provider<GlmApiService>((ref) {
  return GlmApiService();
});

/// 当前选中平台
final selectedPlatformProvider = StateProvider<SocialPlatform>(
  (ref) => SocialPlatform.xiaohongshu,
);

/// 当前选中内容类型
final selectedContentTypeProvider = StateProvider<ContentType>(
  (ref) => ContentType.article,
);

/// 当前选中领域
final selectedCategoryProvider = StateProvider<String>((ref) => '');

/// 用户 Profile
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier(ref);
});

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final Ref _ref;
  
  UserProfileNotifier(this._ref) : super(UserProfile(id: 'local_user')) {
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final storage = await _ref.read(storageProvider.future);
      final usedQuota = storage.getUsedQuotaToday();
      final plan = storage.getPlan();
      final nickname = storage.getNickname();
      state = state.copyWith(
        nickname: nickname,
        plan: plan,
        usedQuotaToday: usedQuota,
      );
    } catch (e) {
      // 首次使用，保持默认
    }
  }

  Future<void> useQuota() async {
    final storage = await _ref.read(storageProvider.future);
    await storage.incrementUsedQuota();
    state = state.copyWith(usedQuotaToday: state.usedQuotaToday + 1);
  }

  Future<void> setNickname(String name) async {
    final storage = await _ref.read(storageProvider.future);
    await storage.setNickname(name);
    state = state.copyWith(nickname: name);
  }

  Future<void> setPlan(SubscriptionPlan plan) async {
    final storage = await _ref.read(storageProvider.future);
    await storage.setPlan(plan);
    state = state.copyWith(plan: plan);
  }
}

/// AI 生成状态
enum GenerationStatus { idle, loading, success, error }

class GenerationState {
  final GenerationStatus status;
  final GenerationResult? result;
  final String? errorMessage;

  const GenerationState({
    this.status = GenerationStatus.idle,
    this.result,
    this.errorMessage,
  });

  GenerationState copyWith({
    GenerationStatus? status,
    GenerationResult? result,
    String? errorMessage,
  }) =>
      GenerationState(
        status: status ?? this.status,
        result: result ?? this.result,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

/// 内容生成 Notifier
final generationProvider =
    StateNotifierProvider<GenerationNotifier, GenerationState>((ref) {
  return GenerationNotifier(ref);
});

class GenerationNotifier extends StateNotifier<GenerationState> {
  final Ref _ref;

  GenerationNotifier(this._ref) : super(const GenerationState());

  /// 执行内容生成
  Future<void> generate({
    required String userInput,
    String? category,
  }) async {
    // 检查配额
    final user = _ref.read(userProfileProvider);
    if (!user.canGenerate) {
      state = const GenerationState(
        status: GenerationStatus.error,
        errorMessage: '今日免费次数已用完，升级为付费版可无限使用',
      );
      return;
    }

    state = const GenerationState(status: GenerationStatus.loading);

    try {
      final platform = _ref.read(selectedPlatformProvider);
      final contentType = _ref.read(selectedContentTypeProvider);
      final api = _ref.read(glmApiProvider);

      final result = await api.generateContent(
        platform: platform,
        contentType: contentType,
        userInput: userInput,
        category: category,
      );

      // 保存到历史
      final storage = await _ref.read(storageProvider.future);
      await storage.saveGeneration(result);

      // 消耗配额
      await _ref.read(userProfileProvider.notifier).useQuota();

      state = GenerationState(status: GenerationStatus.success, result: result);
    } catch (e) {
      state = GenerationState(
        status: GenerationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void reset() {
    state = const GenerationState(status: GenerationStatus.idle);
  }
}

/// 历史记录 Provider
final historyProvider = FutureProvider<List<GenerationResult>>((ref) async {
  final storage = await ref.read(storageProvider.future);
  return storage.getHistory();
});
