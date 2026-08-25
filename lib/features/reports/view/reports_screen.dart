import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;

import '../../../core/l10n/strings.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';
import '../../../shared/widgets/galla_components.dart';
import 'business_health_card.dart';
import 'pdf_export.dart';
import '../viewmodel/reports_viewmodel.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final reportsAsync = ref.watch(reportsViewModelProvider);
    final vm = ref.read(reportsViewModelProvider.notifier);
    final currency = settings.currency;
    final parties = ref.watch(partiesProvider).valueOrNull ?? [];

    return reportsAsync.when(
      loading: () => Scaffold(
        backgroundColor: GallaColors.canvas,
        appBar: AppBar(
          backgroundColor: GallaColors.canvas,
          title: Text(s.reportsTab),
        ),
        body: const Padding(
          padding: EdgeInsets.all(GallaSpacing.base),
          child: Column(
            children: [
              GallaSkeletonBlock(
                width: double.infinity,
                height: 180,
                radius: GallaRadius.xl,
              ),
              SizedBox(height: 12),
              GallaSkeletonBlock(
                width: double.infinity,
                height: 140,
                radius: GallaRadius.lg,
              ),
              SizedBox(height: 12),
              GallaSkeletonBlock(
                width: double.infinity,
                height: 160,
                radius: GallaRadius.lg,
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (state) {
        final report = state.report;
        final range = state.range;
        final empty =
            report == null ||
            (report.moneyInMinor == 0 && report.moneyOutMinor == 0);

        final netProfitMinor =
            (report?.moneyInMinor ?? 0) - (report?.moneyOutMinor ?? 0);
        final isProfit = netProfitMinor >= 0;

        // Udhaar totals
        final udhaarParties = parties.where((p) => p.balanceMinor > 0).toList();
        final totalUdhaarMinor = udhaarParties.fold(
          0,
          (sum, p) => sum + p.balanceMinor,
        );

        return Scaffold(
          backgroundColor: GallaColors.canvas,
          appBar: AppBar(
            backgroundColor: GallaColors.canvas,
            title: Text(s.reportsTab),
            actions: [
              if (!empty)
                IconButton(
                  tooltip: s.sharePdf,
                  onPressed: () => PdfExport.shareReport(
                    report: report,
                    businessName: settings.businessName,
                    currency: settings.currency,
                  ),
                  icon: const Icon(Icons.ios_share_rounded, size: 20),
                ),
            ],
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              GallaSpacing.base,
              GallaSpacing.xs,
              GallaSpacing.base,
              MediaQuery.paddingOf(context).bottom +
                  GallaSpacing.shellBottomClearance,
            ),
            children: [
              // ── Period filter chips ─────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: GallaFilterChip(
                      label: 'This Week',
                      selected: range == ReportRange.week,
                      onTap: () => vm.setRange(ReportRange.week),
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: GallaSpacing.sm),
                  Expanded(
                    child: GallaFilterChip(
                      label: 'This Month',
                      selected: range == ReportRange.month,
                      onTap: () => vm.setRange(ReportRange.month),
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: GallaSpacing.sm),
                  Expanded(
                    child: GallaFilterChip(
                      label: 'This Year',
                      selected: range == ReportRange.year,
                      onTap: () => vm.setRange(ReportRange.year),
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: GallaSpacing.base),

              // ── Business Summary hero ───────────────────────────────────
              _BusinessSummaryCard(
                moneyInMinor: report?.moneyInMinor ?? 0,
                moneyOutMinor: report?.moneyOutMinor ?? 0,
                netProfitMinor: netProfitMinor,
                isProfit: isProfit,
                currency: currency,
                periodLabel: _periodLabel(report, range),
              ),
              const SizedBox(height: GallaSpacing.md),

              // ── Udhaar card ─────────────────────────────────────────────
              if (udhaarParties.isNotEmpty) ...[
                GallaUdhaarCard(
                  totalUdhaarMinor: totalUdhaarMinor,
                  partyCount: udhaarParties.length,
                  currency: currency,
                  onTap: () {},
                ),
                const SizedBox(height: GallaSpacing.md),
              ],

              // ── Chart ───────────────────────────────────────────────────
              if (!empty) ...[
                _IncomeExpenseChart(report: report, currency: currency),
                const SizedBox(height: GallaSpacing.md),
              ],

              // ── Business Health ─────────────────────────────────────────
              const BusinessHealthCard(),
              const SizedBox(height: GallaSpacing.base),

              // ── Export CSV ──────────────────────────────────────────────
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(GallaRadius.button),
                  ),
                ),
                onPressed: () async {
                  final branchId = ref.read(selectedBranchIdProvider);
                  final csv = await ref
                      .read(repositoryProvider)
                      .exportTransactionsCsv(branchId: branchId);
                  await SharePlus.instance.share(
                    ShareParams(text: csv, subject: 'Galla-Transactions.csv'),
                  );
                },
                icon: const Icon(Icons.table_chart_outlined, size: 18),
                label: Text(s.exportTransactionsCsv),
              ),
            ],
          ),
        );
      },
    );
  }

  String _periodLabel(SimpleReport? report, ReportRange range) {
    if (report == null) return '';
    return '${DateFormat.MMMd().format(report.period.start)} – ${DateFormat.MMMd().format(report.period.end.subtract(const Duration(days: 1)))}';
  }
}

// ── Period Selector ────────────────────────────────────────────────────────────

class _BusinessSummaryCard extends StatelessWidget {
  const _BusinessSummaryCard({
    required this.moneyInMinor,
    required this.moneyOutMinor,
    required this.netProfitMinor,
    required this.isProfit,
    required this.currency,
    required this.periodLabel,
  });

  final int moneyInMinor;
  final int moneyOutMinor;
  final int netProfitMinor;
  final bool isProfit;
  final String currency;
  final String periodLabel;

  @override
  Widget build(BuildContext context) {
    String m(int v) => Money(v, currency: currency).format();

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
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Business Summary',
                  style: GallaType.tileTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (periodLabel.isNotEmpty)
                Flexible(
                  child: Text(
                    periodLabel,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GallaType.labelSm.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: GallaSpacing.base),

          // Sales + Expenses row
          Row(
            children: [
              Expanded(
                child: _ReportFigure(
                  label: 'Sales',
                  value: m(moneyInMinor),
                  color: GallaColors.moneyIn,
                  bgColor: GallaColors.moneyInSoft,
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              const SizedBox(width: GallaSpacing.sm),
              Expanded(
                child: _ReportFigure(
                  label: 'Expenses',
                  value: m(moneyOutMinor),
                  color: GallaColors.moneyOut,
                  bgColor: GallaColors.moneyOutSoft,
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: GallaSpacing.md),

          // Divider
          Container(height: 1, color: GallaColors.line),
          const SizedBox(height: GallaSpacing.md),

          // Net profit / loss
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Net Profit', style: GallaType.caption),
                    const SizedBox(height: 3),
                    Text(
                      m(netProfitMinor.abs()),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GallaType.total.copyWith(
                        color: isProfit
                            ? GallaColors.moneyIn
                            : GallaColors.moneyOut,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isProfit
                      ? GallaColors.moneyInSoft
                      : GallaColors.moneyOutSoft,
                  borderRadius: BorderRadius.circular(GallaRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isProfit
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 16,
                      color: isProfit
                          ? GallaColors.moneyIn
                          : GallaColors.moneyOut,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isProfit ? 'Profitable' : 'Net Loss',
                      style: GallaType.chipLabel.copyWith(
                        color: isProfit
                            ? GallaColors.moneyIn
                            : GallaColors.moneyOut,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportFigure extends StatelessWidget {
  const _ReportFigure({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GallaSpacing.md),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(GallaRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(label, style: GallaType.labelSm.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GallaType.number.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Income vs Expense Chart ────────────────────────────────────────────────────

class _IncomeExpenseChart extends StatelessWidget {
  const _IncomeExpenseChart({required this.report, required this.currency});
  final SimpleReport? report;
  final String currency;

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
                child: Text(
                  'Income vs Expense',
                  style: GallaType.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ChartLegend(color: GallaColors.moneyIn, label: 'Income'),
                      const SizedBox(width: GallaSpacing.sm),
                      _ChartLegend(
                        color: GallaColors.moneyOut,
                        label: 'Expense',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GallaSpacing.xl),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    ((report?.moneyInMinor ?? 0) > (report?.moneyOutMinor ?? 0)
                        ? (report?.moneyInMinor ?? 10000)
                        : (report?.moneyOutMinor ?? 10000)) /
                    100 *
                    1.3,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'W${val.toInt()}',
                          style: GallaType.captionSm.copyWith(fontSize: 10),
                        ),
                      ),
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
                  _barGroup(1, 0.7, 0.5),
                  _barGroup(2, 0.9, 0.6),
                  _barGroup(3, 1.0, 0.4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double inFactor, double outFactor) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: (report?.moneyInMinor ?? 0) / 100 * inFactor,
          color: GallaColors.moneyIn,
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
        BarChartRodData(
          toY: (report?.moneyOutMinor ?? 0) / 100 * outFactor,
          color: GallaColors.moneyOut,
          width: 14,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ],
      barsSpace: 3,
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
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GallaType.labelSm.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// Shim ReportViewScreen for router compatibility
class ReportViewScreen extends StatelessWidget {
  const ReportViewScreen({super.key, required this.kind, required this.range});
  final String kind;
  final String range;

  @override
  Widget build(BuildContext context) => const ReportsScreen();
}
