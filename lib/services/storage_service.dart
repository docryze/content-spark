import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_models.dart';
import '../constants/app_enums.dart';

/// 本地存储服务 — 生成历史 + 用户配置
class StorageService {
  static const _historyKey = 'generation_history';
  static const _quotaDateKey = 'quota_reset_date';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ==================== 生成历史 ====================

  /// 保存生成结果到历史
  Future<void> saveGeneration(GenerationResult result) async {
    final history = await getHistory();
    history.insert(0, result); // 最新的在前
    // 最多保留100条
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }
    final jsonList = history.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_historyKey, jsonList);
  }

  /// 获取全部历史记录
  Future<List<GenerationResult>> getHistory() async {
    final jsonList = _prefs.getStringList(_historyKey) ?? [];
    return jsonList.map((jsonStr) {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return GenerationResult.fromJson(json);
    }).toList();
  }

  /// 删除单条历史
  Future<void> deleteGeneration(String id) async {
    final history = await getHistory();
    history.removeWhere((e) => e.id == id);
    final jsonList = history.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_historyKey, jsonList);
  }

  /// 清空历史
  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }

  // ==================== 用户配额 ====================

  /// 获取今日已用次数
  int getUsedQuotaToday() {
    final savedDate = _prefs.getString(_quotaDateKey);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (savedDate != today) {
      // 新的一天，重置配额
      _prefs.setString(_quotaDateKey, today);
      _prefs.setInt('used_quota', 0);
      return 0;
    }
    return _prefs.getInt('used_quota') ?? 0;
  }

  /// 增加使用次数
  Future<void> incrementUsedQuota() async {
    final current = getUsedQuotaToday();
    await _prefs.setInt('used_quota', current + 1);
  }

  // ==================== 用户配置 ====================

  /// 获取用户昵称
  String getNickname() => _prefs.getString('nickname') ?? '创作者';

  /// 保存用户昵称
  Future<void> setNickname(String name) async {
    await _prefs.setString('nickname', name);
  }

  /// 获取订阅方案
  SubscriptionPlan getPlan() {
    final planStr = _prefs.getString('plan') ?? 'free';
    return SubscriptionPlan.values.firstWhere(
      (p) => p.name == planStr,
      orElse: () => SubscriptionPlan.free,
    );
  }

  /// 保存订阅方案
  Future<void> setPlan(SubscriptionPlan plan) async {
    await _prefs.setString('plan', plan.name);
  }
}
