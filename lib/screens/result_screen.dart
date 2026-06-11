import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../models/app_models.dart';

/// 生成结果详情页（从历史记录进入）
class ResultScreen extends StatefulWidget {
  final GenerationResult result;
  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int _selectedTitle = 0;

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Scaffold(
      appBar: AppBar(title: Text('${r.platform.emoji} ${r.platform.displayName}')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConfig.deepBg, Color(0xFF0D0F2B)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 标题选择
            if (r.titleVariants.isNotEmpty) ...[
              const Text('📌 标题', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppConfig.accentColor)),
              const SizedBox(height: 10),
              ...List.generate(r.titleVariants.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTitle = i),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: i == _selectedTitle ? AppConfig.primaryColor.withValues(alpha: 0.15) : AppConfig.surfaceDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: i == _selectedTitle ? AppConfig.primaryColor : AppConfig.glassBorder,
                        width: i == _selectedTitle ? 2 : 0.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                            color: i == _selectedTitle ? AppConfig.primaryColor : AppConfig.surfaceLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(child: Text('${i+1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: i == _selectedTitle ? Colors.white : AppConfig.textSecondary))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(r.titleVariants[i], style: TextStyle(fontSize: 14, fontWeight: i == _selectedTitle ? FontWeight.w700 : FontWeight.w500))),
                      ],
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 16),
            ],
            // 正文
            const Text('📝 正文', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppConfig.accentColor)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassBox(radius: 18),
              child: SelectableText(r.content, style: const TextStyle(fontSize: 14, height: 1.8, color: AppConfig.textPrimary)),
            ),
            // 标签
            if (r.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('🏷️ 标签', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppConfig.accentColor)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: r.tags.map((t) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConfig.accentColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppConfig.accentColor.withValues(alpha: 0.2)),
                  ),
                  child: Text('#$t', style: const TextStyle(fontSize: 12, color: AppConfig.accentColor)),
                )).toList(),
              ),
            ],
            // 封面 & 时间建议
            if (r.coverTextSuggestion.isNotEmpty || r.publishTimeSuggestion.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.glassBox(radius: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (r.coverTextSuggestion.isNotEmpty) Text('🖼️ 封面：${r.coverTextSuggestion}', style: const TextStyle(fontSize: 13, color: AppConfig.textPrimary)),
                    if (r.publishTimeSuggestion.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('⏰ 发布：${r.publishTimeSuggestion}', style: const TextStyle(fontSize: 13, color: AppConfig.textPrimary)),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
