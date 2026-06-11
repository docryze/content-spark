import '../constants/app_enums.dart';

/// AI 生成结果模型
class GenerationResult {
  final String id;
  final SocialPlatform platform;
  final ContentType contentType;
  final String userInput;
  final List<String> titleVariants;
  final String content;
  final List<String> tags;
  final String coverTextSuggestion;
  final String publishTimeSuggestion;
  final DateTime createdAt;

  GenerationResult({
    required this.id,
    required this.platform,
    required this.contentType,
    required this.userInput,
    required this.titleVariants,
    required this.content,
    required this.tags,
    required this.coverTextSuggestion,
    required this.publishTimeSuggestion,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'platform': platform.id,
    'contentType': contentType.name,
    'userInput': userInput,
    'titleVariants': titleVariants,
    'content': content,
    'tags': tags,
    'coverTextSuggestion': coverTextSuggestion,
    'publishTimeSuggestion': publishTimeSuggestion,
    'createdAt': createdAt.toIso8601String(),
  };

  factory GenerationResult.fromJson(Map<String, dynamic> json) =>
      GenerationResult(
        id: json['id'] as String,
        platform: SocialPlatform.values.firstWhere(
          (p) => p.id == json['platform'],
          orElse: () => SocialPlatform.xiaohongshu,
        ),
        contentType: ContentType.values.firstWhere(
          (t) => t.name == json['contentType'],
          orElse: () => ContentType.article,
        ),
        userInput: json['userInput'] as String,
        titleVariants: List<String>.from(json['titleVariants'] as List),
        content: json['content'] as String,
        tags: List<String>.from(json['tags'] as List),
        coverTextSuggestion: json['coverTextSuggestion'] as String? ?? '',
        publishTimeSuggestion: json['publishTimeSuggestion'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// 用户模型
class UserProfile {
  final String id;
  final String nickname;
  final SubscriptionPlan plan;
  final int usedQuotaToday;
  final DateTime? quotaResetDate;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    this.nickname = '创作者',
    this.plan = SubscriptionPlan.free,
    this.usedQuotaToday = 0,
    this.quotaResetDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get remainingQuota {
    if (plan.dailyQuota == -1) return 999;
    return (plan.dailyQuota - usedQuotaToday).clamp(0, plan.dailyQuota);
  }

  bool get canGenerate => remainingQuota > 0;

  UserProfile copyWith({
    String? nickname,
    SubscriptionPlan? plan,
    int? usedQuotaToday,
    DateTime? quotaResetDate,
  }) =>
      UserProfile(
        id: id,
        nickname: nickname ?? this.nickname,
        plan: plan ?? this.plan,
        usedQuotaToday: usedQuotaToday ?? this.usedQuotaToday,
        quotaResetDate: quotaResetDate ?? this.quotaResetDate,
        createdAt: createdAt,
      );
}
