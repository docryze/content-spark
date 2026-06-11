import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../constants/app_enums.dart';
import '../providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppConfig.deepBg, Color(0xFF0D0F2B)]),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // 用户卡片 — 渐变背景
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppConfig.primaryColor, Color(0xFF5B4BC9)]),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(user.nickname.isNotEmpty ? user.nickname[0] : '✨', style: const TextStyle(fontSize: 28, color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  Text(user.nickname, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                    child: Text(user.plan.displayName, style: const TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 统计
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _statCard('今日剩余', user.remainingQuota == 999 ? '∞' : '${user.remainingQuota}', '次'),
                  const SizedBox(width: 12),
                  _statCard('当前方案', user.plan.displayName, user.plan.monthlyPrice == 0 ? '免费' : '¥${user.plan.monthlyPrice}/月'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 订阅方案
            _section('升级方案'),
            const SizedBox(height: 8),
            ...SubscriptionPlan.values.where((p) => p != SubscriptionPlan.free).map((plan) => _planCard(plan, user.plan == plan)),

            const SizedBox(height: 16),

            // 设置
            _section('设置'),
            _tile(Icons.person_outline_rounded, '修改昵称', onTap: () => _showNicknameDialog(context, ref)),
            _tile(Icons.info_outline_rounded, '关于灵感笔', trailing: 'v1.0.0'),
            _tile(Icons.star_outline_rounded, '给我们评分'),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, String sub) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassBox(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppConfig.accentColor)),
              const SizedBox(width: 2),
              Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(sub, style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary))),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppConfig.textSecondary)),
  );

  Widget _planCard(SubscriptionPlan plan, bool isCurrent) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isCurrent ? AppConfig.primaryColor.withValues(alpha: 0.1) : AppConfig.surfaceDark,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: isCurrent ? AppConfig.primaryColor : AppConfig.glassBorder, width: isCurrent ? 2 : 0.5),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(plan.displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  if (isCurrent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppConfig.primaryColor, borderRadius: BorderRadius.circular(6)),
                      child: const Text('当前', style: TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text('¥${plan.monthlyPrice}/月', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppConfig.accentColor)),
            ],
          ),
        ),
        Icon(isCurrent ? Icons.check_circle : Icons.arrow_forward_ios, color: isCurrent ? AppConfig.primaryColor : AppConfig.textSecondary, size: isCurrent ? 24 : 14),
      ],
    ),
  );

  Widget _tile(IconData icon, String title, {String? trailing, VoidCallback? onTap}) => ListTile(
    leading: Icon(icon, color: AppConfig.textSecondary),
    title: Text(title),
    trailing: trailing != null ? Text(trailing, style: const TextStyle(fontSize: 13, color: AppConfig.textSecondary)) : const Icon(Icons.chevron_right, size: 18, color: AppConfig.textSecondary),
        onTap: onTap,
      );

  void _showNicknameDialog(BuildContext ctx, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: AppConfig.surfaceDark,
      title: const Text('修改昵称', style: TextStyle(color: AppConfig.textPrimary)),
      content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '输入新昵称'), autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
        ElevatedButton(
          onPressed: () {
            if (ctrl.text.trim().isNotEmpty) {
              ref.read(userProfileProvider.notifier).setNickname(ctrl.text.trim());
              Navigator.pop(ctx);
            }
          },
          child: const Text('保存'),
        ),
      ],
    ));
  }
}
