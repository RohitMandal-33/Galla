import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';

enum ReportRange { today, week, month, year, custom }

/// One bucket of a real time-series (a day, a calendar week or a month).
class ReportBucket {
  const ReportBucket({
    required this.label,
    required this.start,
    required this.end,
    required this.inMinor,
    required this.outMinor,
  });

  final String label;
  final DateTime start;
  final DateTime end;
  final int inMinor;
  final int outMinor;
}

class ReportsState {
  const ReportsState({
    this.range = ReportRange.month,
    this.customStart,
    this.customEnd,
    this.report,
    this.buckets = const [],
    this.txnCount = 0,
  });

  final ReportRange range;

  /// Only used when [range] == custom.
  final DateTime? customStart;
  final DateTime? customEnd;

  final SimpleReport? report;
  final List<ReportBucket> buckets;
  final int txnCount;

  bool get hasData => report != null && txnCount > 0;

  ReportsState copyWith({
    ReportRange? range,
    DateTime? customStart,
    DateTime? customEnd,
    SimpleReport? report,
    List<ReportBucket>? buckets,
    int? txnCount,
  }) {
    return ReportsState(
      range: range ?? this.range,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      report: report ?? this.report,
      buckets: buckets ?? this.buckets,
      txnCount: txnCount ?? this.txnCount,
    );
  }
}

class ReportsViewModel extends AsyncNotifier<ReportsState> {
  @override
  Future<ReportsState> build() async {
    final txns = await ref.watch(transactionsProvider.future);
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final selection = ref.watch(reportsRangeProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final period =
        _periodFor(selection.range, today, selection.start, selection.end) ??
        _periodFor(ReportRange.month, today, null, null)!;

    final repo = ref.read(repositoryProvider);
    final report = repo.buildReport(txns, period, settings.taxRatePct);

    // Real time-series buckets for the chart, built from actual entries.
    // Empty windows are included so quiet days read honestly as zero.
    final buckets = _buildBuckets(txns, period, selection.range);

    final inPeriod = txns
        .where(
          (t) =>
              !t.occurredAt.isBefore(period.start) &&
              t.occurredAt.isBefore(period.end),
        )
        .length;

    return ReportsState(
      range: selection.range,
      customStart: selection.range == ReportRange.custom
          ? selection.start
          : null,
      customEnd: selection.range == ReportRange.custom ? selection.end : null,
      report: report,
      buckets: buckets,
      txnCount: inPeriod,
    );
  }

  ReportPeriod? _periodFor(
    ReportRange range,
    DateTime today,
    DateTime? customStart,
    DateTime? customEnd,
  ) {
    return switch (range) {
      ReportRange.today => ReportPeriod(
        start: today,
        end: today.add(const Duration(days: 1)),
        label: 'Today',
      ),
      // Week starts Sunday — common for Nepali retail calendars.
      ReportRange.week => ReportPeriod(
        start: today.subtract(Duration(days: today.weekday % 7)),
        end: today.add(const Duration(days: 1)),
        label: 'This week',
      ),
      ReportRange.month => ReportPeriod(
        start: DateTime(today.year, today.month, 1),
        end: today.month == 12
            ? DateTime(today.year + 1, 1, 1)
            : DateTime(today.year, today.month + 1, 1),
        label: 'This month',
      ),
      ReportRange.year => ReportPeriod(
        start: DateTime(today.year),
        end: DateTime(today.year + 1),
        label: 'This year',
      ),
      ReportRange.custom =>
        customStart != null && customEnd != null
            ? ReportPeriod(
                start: DateTime(
                  customStart.year,
                  customStart.month,
                  customStart.day,
                ),
                end: DateTime(
                  customEnd.year,
                  customEnd.month,
                  customEnd.day,
                ).add(const Duration(days: 1)),
                label:
                    '${customStart.day}/${customStart.month} – ${customEnd.day}/${customEnd.month}',
              )
            : null,
    };
  }

  /// Buckets sized to the range: daily for a week (or short custom ranges),
  /// weekly within a month, monthly for a year.
  List<ReportBucket> _buildBuckets(
    List<Txn> txns,
    ReportPeriod period,
    ReportRange range,
  ) {
    switch (range) {
      case ReportRange.today:
        return const [];
      case ReportRange.week:
        return _fixedDaily(txns, period.start, 7);
      case ReportRange.month:
        return _weeklyInMonth(txns, period.start, period.end);
      case ReportRange.year:
        return _monthlyInYear(txns, period.start);
      case ReportRange.custom:
        final days = period.end.difference(period.start).inDays;
        if (days <= 0) return const [];
        if (days <= 31) {
          return _fixedDaily(txns, period.start, days);
        }
        return _weeklySpan(txns, period.start, period.end);
    }
  }

  List<ReportBucket> _aggregate(
    List<Txn> txns,
    List<(DateTime, DateTime, String)> windows,
  ) {
    return windows.map((w) {
      final (start, end, label) = w;
      var inMinor = 0;
      var outMinor = 0;
      for (final t in txns) {
        if (t.isWriteOff) continue;
        if (t.occurredAt.isBefore(start) || !t.occurredAt.isBefore(end)) {
          continue;
        }
        if (t.direction == Direction.moneyIn) {
          inMinor += t.amountMinor;
        } else {
          outMinor += t.amountMinor;
        }
      }
      return ReportBucket(
        label: label,
        start: start,
        end: end,
        inMinor: inMinor,
        outMinor: outMinor,
      );
    }).toList();
  }

  List<ReportBucket> _fixedDaily(List<Txn> txns, DateTime start, int days) {
    final windows = <(DateTime, DateTime, String)>[];
    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    for (var i = 0; i < days; i++) {
      final d = start.add(Duration(days: i));
      // Skip future days — an empty bar for tomorrow is noise, not data.
      if (d.isAfter(DateTime.now())) break;
      windows.add((
        DateTime(d.year, d.month, d.day),
        DateTime(d.year, d.month, d.day + 1),
        dayLabels[d.weekday % 7],
      ));
    }
    return _aggregate(txns, windows);
  }

  List<ReportBucket> _weeklyInMonth(
    List<Txn> txns,
    DateTime monthStart,
    DateTime monthEnd,
  ) {
    final windows = <(DateTime, DateTime, String)>[];
    var cursor = monthStart;
    var week = 1;
    while (cursor.isBefore(monthEnd)) {
      final nextSunday = cursor.weekday == DateTime.sunday
          ? cursor.add(const Duration(days: 7))
          : cursor.add(Duration(days: 7 - cursor.weekday));
      final end = nextSunday.isBefore(monthEnd) ? nextSunday : monthEnd;
      windows.add((cursor, end, 'W$week'));
      cursor = end;
      week++;
    }
    return _aggregate(txns, windows);
  }

  List<ReportBucket> _weeklySpan(List<Txn> txns, DateTime start, DateTime end) {
    final windows = <(DateTime, DateTime, String)>[];
    var cursor = start;
    var week = 1;
    while (cursor.isBefore(end)) {
      final next = cursor.add(const Duration(days: 7));
      final wEnd = next.isBefore(end) ? next : end;
      windows.add((cursor, wEnd, 'W$week'));
      cursor = next;
      week++;
    }
    return _aggregate(txns, windows);
  }

  List<ReportBucket> _monthlyInYear(List<Txn> txns, DateTime yearStart) {
    final months = List.generate(12, (i) => i);
    final currentMonth = DateTime.now().month;
    final windows = <(DateTime, DateTime, String)>[];
    for (final m in months.where((m) => m < currentMonth)) {
      final start = DateTime(yearStart.year, m + 1);
      final end = DateTime(yearStart.year, m + 2, 1);
      windows.add((start, end, DateFormatLike.shortMonth(m)));
    }
    return _aggregate(txns, windows);
  }

  void setRange(ReportRange range) {
    ref.read(reportsRangeProvider.notifier).state = RangeSelection(
      range: range,
    );
  }

  void setCustomRange(DateTime start, DateTime end) {
    ref.read(reportsRangeProvider.notifier).state = RangeSelection(
      range: ReportRange.custom,
      start: start,
      end: end,
    );
  }
}

/// The merchant's selected reporting window. Held outside the notifier so
/// stream updates recompute the report without resetting the selection.
class RangeSelection {
  const RangeSelection({this.range = ReportRange.month, this.start, this.end});

  final ReportRange range;
  final DateTime? start;
  final DateTime? end;
}

final reportsRangeProvider = StateProvider<RangeSelection>(
  (_) => const RangeSelection(),
);

/// Local month abbreviations without pulling intl into the VM file twice.
class DateFormatLike {
  static const _short = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String shortMonth(int monthIndex0) => _short[monthIndex0];
}

final reportsViewModelProvider =
    AsyncNotifierProvider<ReportsViewModel, ReportsState>(ReportsViewModel.new);
