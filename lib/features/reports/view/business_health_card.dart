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
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final healthAsync = ref.watch(healthReportProvider);

    return healthAsync.when(
      loading: () => Container(
        height: 180,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: GallaColors.surface,
          borderRadius: BorderRadius.circular(GallaRadius.xl),
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
            borderRadius: BorderRadius.circular(GallaRadius.xl),
            border: Border.all(color: GallaColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: GallaColors.brandSoft,
                      borderRadius: BorderRadius.circular(GallaRadius.md),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: GallaColors.brand,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.businessHealth,
                      style: GallaType.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: gradeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(GallaRadius.sm),
                      ),
                      child: Text(
                        '${s.healthGrade} ${report.grade.name} (${report.overallScore})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GallaType.subtitleSm.copyWith(
                          fontWeight: FontWeight.w800,
                          color: gradeColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Headline
              Text(report.headline, style: GallaType.subtitle),
              const SizedBox(height: 2),
              Text(report.summary, style: GallaType.caption),
              const SizedBox(height: 16),

              // Metrics Row
              Row(
                children: report.metrics.map((m) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: GallaColors.canvas,
                        borderRadius: BorderRadius.circular(GallaRadius.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GallaType.labelSm.copyWith(fontSize: 10),
                          ),
                          const SizedBox(height: 2),
                          Text(m.value, style: GallaType.numberSm),
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
                  style: GallaType.chipLabel.copyWith(color: GallaColors.muted),
                ),
                const SizedBox(height: 6),
                ...report.actionableInsights.map((insight) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.tips_and_updates_outlined,
                          size: 13,
                          color: GallaColors.udhaar,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            insight,
                            style: GallaType.caption.copyWith(
                              height: 1.35,
                              color: GallaColors.ink,
                            ),
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
        return GallaColors.blue;
      case HealthGrade.C:
        return GallaColors.udhaar;
      case HealthGrade.D:
        return GallaColors.moneyOut;
    }
  }
}
