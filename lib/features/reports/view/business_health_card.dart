import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../domain/models.dart';

class BusinessHealthCard extends ConsumerWidget {
  const BusinessHealthCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final healthAsync = ref.watch(healthReportProvider);

    return healthAsync.when(
      loading: () => Container(
        height: 180,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: GallaColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GallaColors.line),
        ),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (report) {
        final gradeColor = _gradeColor(report.grade);

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: GallaColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: GallaColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: GallaColors.brandSoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.analytics_outlined, color: GallaColors.brand, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        s.businessHealth,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: gradeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${s.healthGrade} ${report.grade.name}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: gradeColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${report.overallScore}/100)',
                          style: TextStyle(fontSize: 11, color: gradeColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Headline
              Text(
                report.headline,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: GallaColors.ink),
              ),
              const SizedBox(height: 2),
              Text(
                report.summary,
                style: const TextStyle(fontSize: 12, color: GallaColors.muted),
              ),
              const SizedBox(height: 16),

              // Metrics Row
              Row(
                children: report.metrics.map((m) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      decoration: BoxDecoration(
                        color: GallaColors.canvas,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: GallaColors.muted, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.value,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: GallaColors.ink),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Actionable AI Insights
              if (report.actionableInsights.isNotEmpty) ...[
                Text(
                  s.actionableInsights,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: GallaColors.muted),
                ),
                const SizedBox(height: 6),
                ...report.actionableInsights.map((insight) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('💡 ', style: TextStyle(fontSize: 12)),
                        Expanded(
                          child: Text(
                            insight,
                            style: const TextStyle(fontSize: 12, height: 1.35, color: GallaColors.ink),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _gradeColor(HealthGrade grade) {
    switch (grade) {
      case HealthGrade.A:
        return GallaColors.moneyIn;
      case HealthGrade.B:
        return const Color(0xFF0D9488);
      case HealthGrade.C:
        return GallaColors.moneyOut;
      case HealthGrade.D:
        return Colors.red.shade700;
    }
  }
}
