import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_config.dart';
import '../providers/app_providers.dart';
import '../models/app_models.dart';

/// 历史记录页面
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('历史记录')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('加载失败：$e', style: const TextStyle(color: AppConfig.textSecondary)),
            ],
          ),
        ),
        data: (history) {
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📝', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    '还没有创作记录',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppConfig.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '去创作你的第一条内容吧！',
                    style: TextStyle(color: AppConfig.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return _HistoryCard(
                item: item,
                index: index,
              ).animate().fadeIn(
                    duration: 200.ms,
                    delay: (index * 30).ms,
                  );
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final GenerationResult item;
  final int index;

  const _HistoryCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppConfig.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(item.platform.emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
        title: Row(
          children: [
            Text(
              item.platform.displayName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppConfig.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.contentType.displayName,
                style: const TextStyle(fontSize: 10, color: AppConfig.textSecondary),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.userInput,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppConfig.textPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              _formatDate(item.createdAt),
              style: const TextStyle(fontSize: 11, color: AppConfig.textSecondary),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppConfig.textSecondary, size: 20),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _HistoryDetailScreen(item: item),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return '刚刚';
    if (diff.inHours < 1) return '${diff.inMinutes}分钟前';
    if (diff.inDays < 1) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${date.month}月${date.day}日';
  }
}

class _HistoryDetailScreen extends StatelessWidget {
  final GenerationResult item;

  const _HistoryDetailScreen({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${item.platform.emoji} ${item.platform.displayName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 用户输入
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '原始需求',
                    style: TextStyle(fontSize: 12, color: AppConfig.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(item.userInput, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 标题变体
            if (item.titleVariants.isNotEmpty) ...[
              const Text(
                '📌 标题变体',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConfig.primaryColor),
              ),
              const SizedBox(height: 8),
              ...item.titleVariants.map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(fontWeight: FontWeight.w700)),
                        Expanded(child: Text(t, style: const TextStyle(fontSize: 14, height: 1.5))),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
            ],

            // 正文
            const Text(
              '📝 正文内容',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConfig.primaryColor),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SelectableText(
                item.content,
                style: const TextStyle(fontSize: 14, height: 1.8),
              ),
            ),

            // 标签
            if (item.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                '🏷️ 标签',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConfig.primaryColor),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: item.tags.map((t) => Chip(
                  label: Text('#$t', style: const TextStyle(fontSize: 12)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
