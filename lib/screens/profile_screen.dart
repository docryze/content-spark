import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../constants/app_enums.dart';
import '../providers/app_providers.dart';

/// 个人中心页面
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 用户信息卡
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppConfig.primaryColor,
                  AppConfig.secondaryColor,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    user.nickname.isNotEmpty ? user.nickname[0] : '✨',
                    style: const TextStyle(fontSize: 28, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.nickname,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.plan.displayName,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 使用统计
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _StatCard(
                  title: '今日剩余',
                  value: user.remainingQuota == 999 ? '∞' : '${user.remainingQuota}',
                  subtitle: '次',
                ),
                const SizedBox(width: 12),
                _StatCard(
                  title: '当前方案',
                  value: user.plan.displayName,
                  subtitle: user.plan.monthlyPrice == 0 ? '免费' : '¥${user.plan.monthlyPrice}/月',
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 订阅升级
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '升级方案',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: 8),
          ...SubscriptionPlan.values.where((p) => p != SubscriptionPlan.free).map((plan) {
            return _PlanCard(
              plan: plan,
              isCurrentPlan: user.plan == plan,
              onTap: () => _showUpgradeDialog(context, plan),
            );
          }),

          const SizedBox(height: 16),

          // 设置项
          _SettingsSection(children: [
            _SettingsTile(
              icon: Icons.person_outline,
              title: '修改昵称',
              onTap: () => _showNicknameDialog(context, ref),
            ),
            _SettingsTile(
              icon: Icons.info_outline,
              title: '关于灵感笔',
              trailing: Text('v1.0.0', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: '灵感笔 ContentSpark',
                  applicationVersion: '1.0.0',
                  applicationLegalese: 'AI 社媒内容创作助手\n让 AI 懂每个平台的调性',
                );
              },
            ),
            _SettingsTile(
              icon: Icons.star_outline,
              title: '给我们评分',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('感谢您的支持！')),
                );
              },
            ),
          ]),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('升级为${plan.displayName}'),
        content: Text(
          plan == SubscriptionPlan.basic
              ? '• 无限次内容生成\n• 全部 6 个平台模板\n• 选题灵感功能\n\n价格：¥${plan.monthlyPrice}/月'
              : plan == SubscriptionPlan.pro
                  ? '• 包含基础版全部功能\n• 多平台改写\n• 标题 A/B 测试\n• 创作者风格学习\n\n价格：¥${plan.monthlyPrice}/月'
                  : '• 包含专业版全部功能\n• 5 人团队协作\n• 优先客服支持\n\n价格：¥${plan.monthlyPrice}/月',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('即将开放支付功能，敬请期待！')),
              );
            },
            child: const Text('立即升级'),
          ),
        ],
      ),
    );
  }

  void _showNicknameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '输入新昵称'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(userProfileProvider.notifier).setNickname(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({required this.title, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppConfig.primaryColor)),
                const SizedBox(width: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppConfig.textSecondary)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isCurrentPlan;
  final VoidCallback onTap;

  const _PlanCard({required this.plan, required this.isCurrentPlan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isCurrentPlan ? AppConfig.primaryColor.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentPlan ? AppConfig.primaryColor : Colors.grey.shade200,
            width: isCurrentPlan ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.displayName,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      if (isCurrentPlan) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppConfig.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('当前', style: TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '¥${plan.monthlyPrice}/月',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppConfig.primaryColor),
                  ),
                ],
              ),
            ),
            Icon(
              isCurrentPlan ? Icons.check_circle : Icons.arrow_forward_ios,
              color: isCurrentPlan ? AppConfig.primaryColor : Colors.grey.shade400,
              size: isCurrentPlan ? 24 : 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final List<Widget> children;

  const _SettingsSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('设置', style: Theme.of(context).textTheme.titleSmall),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppConfig.textSecondary),
      title: Text(title),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18, color: AppConfig.textSecondary),
      onTap: onTap,
    );
  }
}
