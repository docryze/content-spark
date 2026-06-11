import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../providers/app_providers.dart';
import '../models/app_models.dart';
import 'result_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('历史记录')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppConfig.deepBg, Color(0xFF0D0F2B)]),
        ),
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppConfig.accentColor)),
          error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppConfig.textSecondary))),
          data: (history) {
            if (history.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📝', style: TextStyle(fontSize: 56)),
                    const SizedBox(height: 16),
                    Text('还没有创作记录', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppConfig.textSecondary)),
                    const SizedBox(height: 8),
                    const Text('去创作你的第一条内容吧！', style: TextStyle(color: AppConfig.textSecondary, fontSize: 14)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: history.length,
              itemBuilder: (_, index) => _HistoryCard(item: history[index]),
            );
          },
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final GenerationResult item;
  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: AppTheme.glassBox(radius: 16),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppConfig.primaryColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(item.platform.emoji, style: const TextStyle(fontSize: 22))),
        ),
        title: Row(
          children: [
            Text(item.platform.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppConfig.accentColor)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: AppConfig.surfaceLight, borderRadius: BorderRadius.circular(6)),
              child: Text(item.contentType.displayName, style: const TextStyle(fontSize: 10, color: AppConfig.textSecondary)),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            item.userInput,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppConfig.textPrimary),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppConfig.textSecondary, size: 20),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultScreen(result: item))),
      ),
    );
  }
}
