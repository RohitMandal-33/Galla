import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;

import '../../../core/l10n/strings.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../data/galla_repository.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../domain/models.dart';
import '../../../shared/widgets/galla_components.dart';
import 'pdf_export.dart';
import '../viewmodel/reports_viewmodel.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final reportsAsync = ref.watch(reportsViewModelProvider);
    final vm = ref.read(reportsViewModelProvider.notifier);
    final currency = settings.currency;
    final parties = ref.watch(partiesProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: GallaColors.canvas,
      appBar: AppBar(
        backgroundColor: GallaColors.canvas,
        title: Text(s.reportsTab),
        actions: [
          IconButton(
            tooltip: 'Analytics',
            icon: const Icon(Icons.insights_rounded, size: 20),
            onPressed: () => context.push('/analytics'),
          ),
          reportsAsync.maybeWhen(
            data: (state) => (state.hasData && state.report != null)
                ? IconButton(
                    tooltip: s.sharePdf,
                    onPressed: () => PdfExport.shareReport(
                      report: state.report!,
                      businessName: settings.businessName,
                      currency: settings.currency,
                    ),
                    icon: const Icon(Icons.ios_share_rounded, size: 20),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: reportsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(GallaSpacing.base),
          child: Column(
            children: [
              GallaSkeletonBlock(
                width: double.infinity,
                height: 160,
                radius: GallaRadius.lg,
              ),
              SizedBox(height: GallaSpacing.md),
              GallaSkeletonBlock(
                width: double.infinity,
                height: 180,
                radius: GallaRadius.lg,
              ),
            ],
          ),
        ),
        error: (e, _) => GallaEmptyState(
          icon: Icons.error_outline_rounded,
          headline: s.saveFailed,
          body: '$e',
          actionLabel: s.undo,
          onAction: () => ref.invalidate(reportsViewModelProvider),
        ),
        data: (state) {
          final report = state.report;
          final range = state.range;
          final netMinor =
              (report?.moneyInMinor ?? 0) - (report?.moneyOutMinor ?? 0);

          // Real udhaar outstanding across all customers.
          final debtors = parties.where((p) => p.balanceMinor > 0).toList()
            ..sort((a, b) => b.balanceMinor.compareTo(a.balanceMinor));
          final totalUdhaarMinor = debtors.fold(
            0,
            (sum, p) => sum + p.balanceMinor,
          );

          return ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              GallaSpacing.base,
              GallaSpacing.xs,
              GallaSpacing.base,
              MediaQuery.paddingOf(context).bottom +
                  GallaSpacing.shellBottomClearance,
            ),
            children: [
              // ── Period chips ───────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _rangeChip(
                      label: s.today,
                      selected: range == ReportRange.today,
                      onTap: () => vm.setRange(ReportRange.today),
                    ),
                    const SizedBox(width: 6),
                    _rangeChip(
                      label: s.thisWeek,
                      selected: range == ReportRange.week,
                      onTap: () => vm.setRange(ReportRange.week),
                    ),
                    const SizedBox(width: 6),
                    _rangeChip(
                      label: s.thisMonth,
                      selected: range == ReportRange.month,
                      onTap: () => vm.setRange(ReportRange.month),
                    ),
                    const SizedBox(width: 6),
                    _rangeChip(
                      label: range == ReportRange.year ? 'This year' : 'Year',
                      selected: range == ReportRange.year,
                      onTap: () => vm.setRange(ReportRange.year),
                    ),
                    const SizedBox(width: 6),
                    _rangeChip(
                      label:
                          range == ReportRange.custom &&
                              state.customStart != null
                          ? '${DateFormat.MMMd().format(state.customStart!)} – ${DateFormat.MMMd().format(state.customEnd!)}'
                          : s.custom,
                      selected: range == ReportRange.custom,
                      onTap: () async {
                        final now = DateTime.now();
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(now.year - 5),
                          lastDate: now,
                          initialDateRange: DateTimeRange(
                            start:
                                state.customStart ??
                                now.subtract(const Duration(days: 7)),
                            end: state.customEnd ?? now,
                          ),
                        );
                        if (picked != null) {
                          vm.setCustomRange(picked.start, picked.end);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GallaSpacing.base),

              // ── Summary ────────────────────────────────────────────────
              _SummaryBlock(
                moneyInMinor: report?.moneyInMinor ?? 0,
                moneyOutMinor: report?.moneyOutMinor ?? 0,
                cashInMinor: report?.cashInMinor ?? 0,
                creditGivenMinor: report?.udhaarGivenMinor ?? 0,
                netMinor: netMinor,
                currency: currency,
                periodLabel: report == null
                    ? ''
                    : '${DateFormat.MMMd().format(report.period.start)} – ${DateFormat.MMMd().format(report.period.end.subtract(const Duration(days: 1)))}',
                s: s,
              ),
              const SizedBox(height: GallaSpacing.base),

              // ── Outstanding udhaar ─────────────────────────────────────
              if (debtors.isNotEmpty) ...[
                GallaUdhaarCard(
                  totalUdhaarMinor: totalUdhaarMinor,
                  partyCount: debtors.length,
                  currency: currency,
                  onTap: () => context.go('/ledger'),
                ),
                const SizedBox(height: GallaSpacing.md),
              ],

              // ── Chart — only real series, only when meaningful ─────────
              if (state.buckets.isNotEmpty && state.txnCount > 0) ...[
                _IncomeExpenseChart(
                  buckets: state.buckets,
                  currency: currency,
                  s: s,
                ),
                const SizedBox(height: GallaSpacing.md),
              ] else if (!state.hasData) ...[
                Container(
                  padding: const EdgeInsets.all(GallaSpacing.xl),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: GallaColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(GallaRadius.lg),
                    border: Border.all(color: GallaColors.lineSoft),
                  ),
                  child: Column(
                    children: [
                      Text(
                        s.noTxnsTitle,
                        style: GallaType.subtitle,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: GallaSpacing.xs),
                      Text(
                        'Record sales and expenses to see reports here.',
                        style: GallaType.body.copyWith(
                          color: GallaColors.muted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: GallaSpacing.md),
              ],

              // ── Analytics shortcut ───────────────────────────────────────
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => context.push('/analytics'),
                icon: const Icon(Icons.insights_rounded, size: 18),
                label: const Text('Open analytics — graphs'),
              ),
              const SizedBox(height: 10),

              // ── Export ─────────────────────────────────────────────────
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _shareCsv(context, ref, s),
                icon: const Icon(Icons.table_chart_outlined, size: 18),
                label: Text(s.exportTransactionsCsv),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _rangeChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GallaFilterChip(label: label, selected: selected, onTap: onTap);
  }

  Future<void> _shareCsv(BuildContext context, WidgetRef ref, S s) async {
    try {
      final branchId = ref.read(selectedBranchIdProvider);
      final csv = await ref
          .read(repositoryProvider)
          .exportTransactionsCsv(branchId: branchId);
      // Share as a REAL file so it can be opened in Excel/Sheets — not as a
      // wall of text in a chat bubble.
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/galla-transactions-${DateFormat('yyyyMMdd-HHmm').format(DateTime.now())}.csv',
      );
      await file.writeAsString(csv);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'text/csv')],
          subject: 'Galla transactions',
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      showGallaSnackBar(ScaffoldMessenger.of(context), s.saveFailed);
    }
  }
}

// ── Numeric summary ────────────────────────────────────────────────────────────

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({
    required this.moneyInMinor,
    required this.moneyOutMinor,
    required this.cashInMinor,
    required this.creditGivenMinor,
    required this.netMinor,
    required this.currency,
    required this.periodLabel,
    required this.s,
  });

  final int moneyInMinor;
  final int moneyOutMinor;
  final int cashInMinor;
  final int creditGivenMinor;
  final int netMinor;
  final String currency;
  final String periodLabel;
  final S s;

  @override
  Widget build(BuildContext context) {
    String m(int v) => Money(v, currency: currency).formatCompact();

    return Container(
      padding: const EdgeInsets.all(GallaSpacing.cardPadding),
      decoration: BoxDecoration(
        color: GallaColors.surface,
        borderRadius: BorderRadius.circular(GallaRadius.card),
        border: Border.all(color: GallaColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: GallaStatBlock(
                  label: s.sales,
                  value: m(moneyInMinor),
                  valueColor: GallaColors.moneyIn,
                ),
              ),
              GallaStatBlock(
                label: s.expenses,
                value: m(moneyOutMinor),
                alignment: CrossAxisAlignment.end,
              ),
            ],
          ),
          const Divider(height: GallaSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: GallaStatBlock(
                  label: 'Cash received',
                  value: m(cashInMinor),
                ),
              ),
              GallaStatBlock(
                label: s.creditGiven,
                value: m(creditGivenMinor),
                valueColor: creditGivenMinor > 0 ? GallaColors.udhaar : null,
                alignment: CrossAxisAlignment.end,
              ),
            ],
          ),
          const Divider(height: GallaSpacing.xl),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('Net result · Sales − Expenses', style: GallaType.caption),
              const Spacer(),
              Text(
                '${netMinor < 0 ? '−' : '+'} ${Money(netMinor.abs(), currency: currency).formatCompact()}',
                style: GallaType.numberLg.copyWith(
                  letterSpacing: -0.5,
                  color: netMinor < 0 ? GallaColors.moneyOut : null,
                ),
              ),
            ],
          ),
          if (periodLabel.isNotEmpty) ...[
            const SizedBox(height: GallaSpacing.sm),
            Text(periodLabel, style: GallaType.captionSm),
          ],
        ],
      ),
    );
  }
}

// ── Real income-vs-expense time series ─────────────────────────────────────────

class _IncomeExpenseChart extends StatelessWidget {
  const _IncomeExpenseChart({
    required this.buckets,
    required this.currency,
    required this.s,
  });

  final List<ReportBucket> buckets;
  final String currency;
  final S s;

  double get _maxMajor {
    var maxMinor = 0;
    for (final b in buckets) {
      if (b.inMinor > maxMinor) maxMinor = b.inMinor;
      if (b.outMinor > maxMinor) maxMinor = b.outMinor;
    }
    return (maxMinor / 100) * 1.25;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GallaSpacing.cardPadding),
      decoration: BoxDecoration(
        color: GallaColors.surface,
        borderRadius: BorderRadius.circular(GallaRadius.card),
        border: Border.all(color: GallaColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Income vs Expense', style: GallaType.subtitle),
              ),
              _ChartLegend(color: GallaColors.moneyIn, label: s.sales),
              const SizedBox(width: GallaSpacing.sm),
              _ChartLegend(color: GallaColors.moneyOut, label: s.expenses),
            ],
          ),
          const SizedBox(height: GallaSpacing.xl),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _maxMajor <= 0 ? 10 : _maxMajor,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, gi, rod, ri) {
                      final bucketIndex = group.x.toInt();
                      if (bucketIndex < 0 || bucketIndex >= buckets.length) {
                        return null;
                      }
                      final b = buckets[bucketIndex];
                      final isIn = ri == 0;
                      final v = isIn ? b.inMinor : b.outMinor;
                      return BarTooltipItem(
                        '${b.label} · ${isIn ? "+" : "−"}${Money(v, currency: currency).formatCompact()}',
                        GallaType.labelStrong.copyWith(color: Colors.white),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (val, meta) {
                        final i = val.toInt();
                        if (i < 0 || i >= buckets.length) {
                          return const SizedBox.shrink();
                        }
                        // Thin out labels when there are many buckets.
                        if (buckets.length > 10 && i % 3 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            buckets[i].label,
                            style: GallaType.captionSm.copyWith(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: GallaColors.line, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (var i = 0; i < buckets.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: buckets[i].inMinor / 100,
                          color: GallaColors.moneyIn,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                        BarChartRodData(
                          toY: buckets[i].outMinor / 100,
                          color: GallaColors.moneyOut,
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(3),
                          ),
                        ),
                      ],
                      barsSpace: 3,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: GallaType.labelSm),
      ],
    );
  }
}
