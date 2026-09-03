import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../domain/models.dart';
import '../../../shared/widgets/galla_components.dart';

enum AnalyticsRange { d7, d14, d30 }

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AnalyticsRange _range = AnalyticsRange.d14;

  int get _days => switch (_range) {
    AnalyticsRange.d7 => 7,
    AnalyticsRange.d14 => 14,
    AnalyticsRange.d30 => 30,
  };

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final txnsAsync = ref.watch(transactionsProvider);
    final parties = ref.watch(partiesProvider).valueOrNull ?? const <Party>[];
    final currency = settings.currency;

    return Scaffold(
      backgroundColor: GallaColors.canvas,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: GallaColors.canvas,
      ),
      body: txnsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          if (all.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(GallaSpacing.xl),
                child: GallaEmptyState(
                  icon: Icons.insights_outlined,
                  headline: 'No data for analytics yet',
                  body:
                      'Sign in with the demo account to load Shree Ganesh Kirana mock data, or add your first sale/expense. Graphs populate instantly.',
                ),
              ),
            );
          }

          final now = DateTime.now();
          final start = DateTime(
            now.year,
            now.month,
            now.day,
          ).subtract(Duration(days: _days - 1));
          final daily = _dailyBuckets(all, start, _days);
          final catData = _categorySplit(all, start);
          final kpis = _kpis(all, start, parties);

          return ListView(
            padding: EdgeInsets.fromLTRB(
              GallaSpacing.base,
              GallaSpacing.sm,
              GallaSpacing.base,
              MediaQuery.paddingOf(context).bottom +
                  GallaSpacing.shellBottomClearance,
            ),
            children: [
              // Range chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip(
                      '7 days',
                      _range == AnalyticsRange.d7,
                      () => setState(() => _range = AnalyticsRange.d7),
                    ),
                    const SizedBox(width: 6),
                    _chip(
                      '14 days',
                      _range == AnalyticsRange.d14,
                      () => setState(() => _range = AnalyticsRange.d14),
                    ),
                    const SizedBox(width: 6),
                    _chip(
                      '30 days',
                      _range == AnalyticsRange.d30,
                      () => setState(() => _range = AnalyticsRange.d30),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GallaSpacing.base),

              // KPI strip
              Row(
                children: [
                  Expanded(
                    child: _KpiCard(
                      label: 'Sales',
                      valueMinor: kpis.sales,
                      color: GallaColors.moneyIn,
                      currency: currency,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiCard(
                      label: 'Expenses',
                      valueMinor: kpis.expenses,
                      color: GallaColors.moneyOut,
                      currency: currency,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _KpiCard(
                      label: 'Net',
                      valueMinor: kpis.net,
                      color: kpis.net >= 0
                          ? GallaColors.brand
                          : GallaColors.moneyOut,
                      currency: currency,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(GallaSpacing.base),
                decoration: BoxDecoration(
                  color: GallaColors.surface,
                  borderRadius: BorderRadius.circular(GallaRadius.lg),
                  border: Border.all(color: GallaColors.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GallaStatBlock(
                        label:
                            'To collect · ${parties.where((p) => p.balanceMinor > 0).length} people',
                        value: Money(
                          parties
                              .where((p) => p.balanceMinor > 0)
                              .fold(0, (s, p) => s + p.balanceMinor),
                          currency: currency,
                        ).formatCompact(),
                        valueColor: GallaColors.udhaar,
                      ),
                    ),
                    Container(width: 1, height: 36, color: GallaColors.line),
                    Expanded(
                      child: GallaStatBlock(
                        label:
                            'To pay · ${parties.where((p) => p.balanceMinor < 0).length} suppliers',
                        value: Money(
                          parties
                              .where((p) => p.balanceMinor < 0)
                              .fold(0, (s, p) => s + p.balanceMinor.abs()),
                          currency: currency,
                        ).formatCompact(),
                        valueColor: GallaColors.moneyOut,
                        alignment: CrossAxisAlignment.end,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: GallaSpacing.base),

              // Line chart — daily net trend + in/out lines
              _ChartCard(
                title: 'Cash pulse',
                subtitle:
                    '${DateFormat.MMMd().format(start)} – ${DateFormat.MMMd().format(now)}',
                child: SizedBox(
                  height: 180,
                  child: _PulseLineChart(daily: daily),
                ),
              ),
              const SizedBox(height: GallaSpacing.md),

              // Bar chart — daily sales vs expenses
              _ChartCard(
                title: 'Daily sales vs expenses',
                subtitle: 'Bars are real entries; zero days stay zero',
                child: SizedBox(
                  height: 160,
                  child: _DailyBarChart(daily: daily, currency: currency),
                ),
              ),
              const SizedBox(height: GallaSpacing.md),

              // Pie — category split
              if (catData.isNotEmpty)
                _ChartCard(
                  title: 'Where money went',
                  subtitle: 'Top expense categories (last $_days days)',
                  child: SizedBox(
                    height: 180,
                    child: _CategoryPie(data: catData, currency: currency),
                  ),
                ),
              if (catData.isEmpty)
                Container(
                  padding: const EdgeInsets.all(GallaSpacing.lg),
                  decoration: BoxDecoration(
                    color: GallaColors.surface,
                    borderRadius: BorderRadius.circular(GallaRadius.lg),
                    border: Border.all(color: GallaColors.lineSoft),
                  ),
                  child: Text(
                    'No categorized expenses in this window — add a category to entries to see the split.',
                    style: GallaType.caption,
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: GallaSpacing.md),

              // Health snapshot — mirrors computeBusinessHealth but lightweight
              _ChartCard(
                title: 'Health snapshot',
                subtitle: kpis.healthLabel,
                child: Column(
                  children: [
                    Row(
                      children: [
                        _HealthDot(
                          label: 'Sales',
                          value: '${(kpis.sales / 100).toStringAsFixed(0)}',
                          color: GallaColors.moneyIn,
                        ),
                        const SizedBox(width: 12),
                        _HealthDot(
                          label: 'Expense ratio',
                          value: kpis.sales == 0
                              ? '—'
                              : '${(kpis.expenses / kpis.sales * 100).toStringAsFixed(0)}%',
                          color: kpis.expenses > kpis.sales
                              ? GallaColors.moneyOut
                              : GallaColors.brand,
                        ),
                        const SizedBox(width: 12),
                        _HealthDot(
                          label: 'Udhaar share',
                          value: kpis.sales == 0
                              ? '—'
                              : '${(kpis.udhaarGiven / (kpis.sales == 0 ? 1 : kpis.sales) * 100).toStringAsFixed(0)}%',
                          color: GallaColors.udhaar,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(kpis.healthHint, style: GallaType.caption),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GallaFilterChip(label: label, selected: selected, onTap: onTap);
  }
}

// ── Models ────────────────────────────────────────────────────────────────

class _Daily {
  _Daily(this.date, this.inMinor, this.outMinor);
  final DateTime date;
  final int inMinor;
  final int outMinor;
  int get netMinor => inMinor - outMinor;
}

class _Kpis {
  _Kpis({
    required this.sales,
    required this.expenses,
    required this.udhaarGiven,
    required this.healthLabel,
    required this.healthHint,
  });
  final int sales;
  final int expenses;
  final int udhaarGiven;
  int get net => sales - expenses;
  final String healthLabel;
  final String healthHint;
}

// ── Helpers ───────────────────────────────────────────────────────────────

List<_Daily> _dailyBuckets(List<Txn> all, DateTime start, int days) {
  final map = <String, _Daily>{};
  for (var i = 0; i < days; i++) {
    final d = start.add(Duration(days: i));
    final key = DateFormat('yyyy-MM-dd').format(d);
    map[key] = _Daily(d, 0, 0);
  }
  for (final t in all) {
    if (t.isWriteOff) continue;
    final d = DateTime(t.occurredAt.year, t.occurredAt.month, t.occurredAt.day);
    if (d.isBefore(start) || d.isAfter(DateTime.now())) continue;
    final key = DateFormat('yyyy-MM-dd').format(d);
    final b = map[key];
    if (b == null) continue;
    if (t.direction == Direction.moneyIn) {
      map[key] = _Daily(b.date, b.inMinor + t.amountMinor, b.outMinor);
    } else {
      map[key] = _Daily(b.date, b.inMinor, b.outMinor + t.amountMinor);
    }
  }
  return map.values.toList()..sort((a, b) => a.date.compareTo(b.date));
}

Map<String, int> _categorySplit(List<Txn> all, DateTime start) {
  final m = <String, int>{};
  for (final t in all) {
    if (t.direction != Direction.moneyOut) continue;
    if (t.occurredAt.isBefore(start)) continue;
    final cat = (t.category ?? 'Other').trim().isEmpty ? 'Other' : t.category!;
    m[cat] = (m[cat] ?? 0) + t.amountMinor;
  }
  // Top 5
  final sorted = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  return {for (final e in sorted.take(5)) e.key: e.value};
}

_Kpis _kpis(List<Txn> all, DateTime start, List<Party> parties) {
  var sales = 0, exp = 0, given = 0;
  for (final t in all) {
    if (t.occurredAt.isBefore(start) || t.isWriteOff) continue;
    if (t.direction == Direction.moneyIn) {
      sales += t.amountMinor;
      if (t.isCredit) given += t.amountMinor;
    } else {
      exp += t.amountMinor;
    }
  }
  final net = sales - exp;
  final margin = sales == 0 ? 0.0 : net / sales * 100;
  String label;
  String hint;
  if (net <= 0 && sales > 0) {
    label = 'Attention — expenses exceeded sales';
    hint =
        'Review purchases and udhaar collection. The pulse chart shows which days drove the loss.';
  } else if (margin > 20) {
    label = 'Healthy — strong margin';
    hint =
        'Over 20% net margin retained. Keep collecting udhaar promptly to hold cash realization.';
  } else if (margin > 0) {
    label = 'Stable — small positive margin';
    hint =
        'Profitable but thin. Watch stock value vs. sales trend in the daily bars.';
  } else {
    label = 'Not enough signal yet';
    hint = 'Add a few more days of sales to see a meaningful trend.';
  }
  return _Kpis(
    sales: sales,
    expenses: exp,
    udhaarGiven: given,
    healthLabel: label,
    healthHint: hint,
  );
}

// ── Chart widgets ────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GallaSpacing.cardPadding),
      decoration: BoxDecoration(
        color: GallaColors.surface,
        borderRadius: BorderRadius.circular(GallaRadius.lg),
        border: Border.all(color: GallaColors.line),
        boxShadow: GallaElevation.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GallaType.subtitle),
          const SizedBox(height: 2),
          Text(subtitle, style: GallaType.captionSm),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.valueMinor,
    required this.color,
    required this.currency,
  });
  final String label;
  final int valueMinor;
  final Color color;
  final String currency;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GallaColors.surface,
        borderRadius: BorderRadius.circular(GallaRadius.md),
        border: Border.all(color: GallaColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GallaType.captionSm),
          const SizedBox(height: 4),
          Text(
            Money(valueMinor, currency: currency).formatCompact(),
            style: GallaType.number.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HealthDot extends StatelessWidget {
  const _HealthDot({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GallaType.captionSm.copyWith(fontSize: 10)),
                Text(value, style: GallaType.labelStrong),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseLineChart extends StatelessWidget {
  const _PulseLineChart({required this.daily});
  final List<_Daily> daily;
  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) return const SizedBox.shrink();
    double maxY = 0;
    double minY = 0;
    for (final d in daily) {
      if (d.inMinor / 100 > maxY) maxY = d.inMinor / 100;
      if (d.outMinor / 100 > maxY) maxY = d.outMinor / 100;
      if (d.netMinor / 100 < minY) minY = d.netMinor / 100;
    }
    maxY = (maxY * 1.2).clamp(10, double.infinity);
    minY = (minY * 1.2).clamp(-maxY, 0);

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: GallaColors.line, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= daily.length) return const SizedBox.shrink();
                if (daily.length > 14 && i % 3 != 0)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('M/d').format(daily[i].date),
                    style: GallaType.captionSm.copyWith(fontSize: 9),
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
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < daily.length; i++)
                FlSpot(i.toDouble(), daily[i].inMinor / 100),
            ],
            isCurved: true,
            color: GallaColors.moneyIn,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: GallaColors.moneyIn.withValues(alpha: 0.08),
            ),
          ),
          LineChartBarData(
            spots: [
              for (var i = 0; i < daily.length; i++)
                FlSpot(i.toDouble(), daily[i].outMinor / 100),
            ],
            isCurved: true,
            color: GallaColors.moneyOut,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
          LineChartBarData(
            spots: [
              for (var i = 0; i < daily.length; i++)
                FlSpot(i.toDouble(), daily[i].netMinor / 100),
            ],
            isCurved: true,
            color: GallaColors.brand,
            barWidth: 1.5,
            dashArray: [4, 3],
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              final d = daily[s.x.toInt()];
              final label = DateFormat('MMM d').format(d.date);
              final isIn = s.barIndex == 0;
              final isOut = s.barIndex == 1;
              final txt = isIn
                  ? 'Sales ${(d.inMinor / 100).toStringAsFixed(0)}'
                  : isOut
                  ? 'Exp ${(d.outMinor / 100).toStringAsFixed(0)}'
                  : 'Net ${(d.netMinor / 100).toStringAsFixed(0)}';
              return LineTooltipItem(
                '$label · $txt',
                GallaType.labelStrong.copyWith(color: Colors.white),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _DailyBarChart extends StatelessWidget {
  const _DailyBarChart({required this.daily, required this.currency});
  final List<_Daily> daily;
  final String currency;
  @override
  Widget build(BuildContext context) {
    double maxY = 0;
    for (final d in daily) {
      if (d.inMinor > maxY) maxY = d.inMinor.toDouble();
      if (d.outMinor > maxY) maxY = d.outMinor.toDouble();
    }
    maxY = (maxY / 100 * 1.25).clamp(10, double.infinity);
    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (g, gi, rod, ri) {
              final d = daily[g.x.toInt()];
              final isIn = ri == 0;
              return BarTooltipItem(
                '${DateFormat('MMM d').format(d.date)} · ${isIn ? "+" : "−"}${Money(isIn ? d.inMinor : d.outMinor, currency: currency).formatCompact()}',
                GallaType.labelStrong.copyWith(color: Colors.white),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 18,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= daily.length) return const SizedBox.shrink();
                if (daily.length > 14 && i % 2 != 0)
                  return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('M/d').format(daily[i].date),
                    style: GallaType.captionSm.copyWith(fontSize: 9),
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
          for (var i = 0; i < daily.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: daily[i].inMinor / 100,
                  color: GallaColors.moneyIn,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
                BarChartRodData(
                  toY: daily[i].outMinor / 100,
                  color: GallaColors.moneyOut,
                  width: 10,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(3),
                  ),
                ),
              ],
              barsSpace: 3,
            ),
        ],
      ),
    );
  }
}

class _CategoryPie extends StatelessWidget {
  const _CategoryPie({required this.data, required this.currency});
  final Map<String, int> data;
  final String currency;
  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0, (a, b) => a + b);
    final colors = [
      GallaColors.moneyOut,
      GallaColors.udhaar,
      GallaColors.brand,
      GallaColors.gold,
      GallaColors.blue,
    ];
    var idx = 0;
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                for (final e in data.entries)
                  PieChartSectionData(
                    value: e.value.toDouble(),
                    title: '${(e.value / total * 100).toStringAsFixed(0)}%',
                    color: colors[idx++ % colors.length],
                    radius: 46,
                    titleStyle: GallaType.badge.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < data.entries.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          data.entries.elementAt(i).key,
                          style: GallaType.labelSm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        Money(
                          data.entries.elementAt(i).value,
                          currency: currency,
                        ).formatCompact(),
                        style: GallaType.labelStrong,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
