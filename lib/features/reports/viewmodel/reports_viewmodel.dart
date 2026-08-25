import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';

// ─── State ────────────────────────────────────────────────────────────────────

enum ReportRange { week, month, year }

class ReportsState {
  const ReportsState({
    this.range = ReportRange.month,
    this.report,
    this.healthReport,
    this.loading = true,
  });

  final ReportRange range;
  final SimpleReport? report;
  final BusinessHealthReport? healthReport;
  final bool loading;

  ReportsState copyWith({
    ReportRange? range,
    SimpleReport? report,
    BusinessHealthReport? healthReport,
    bool? loading,
  }) {
    return ReportsState(
      range: range ?? this.range,
      report: report ?? this.report,
      healthReport: healthReport ?? this.healthReport,
      loading: loading ?? this.loading,
    );
  }
}

// ─── ViewModel ────────────────────────────────────────────────────────────────

class ReportsViewModel extends AsyncNotifier<ReportsState> {
  GallaRepository get _repo => ref.read(repositoryProvider);

  @override
  Future<ReportsState> build() async {
    final txns = ref.watch(transactionsProvider).valueOrNull ?? [];
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final branchId = ref.watch(selectedBranchIdProvider);

    return _compute(txns, settings, branchId, ReportRange.month);
  }

  Future<ReportsState> _compute(
    List<Txn> txns,
    AppSettings settings,
    String? branchId,
    ReportRange range,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final period = _periodFor(range, today, settings);

    final report = _repo.buildReport(txns, period, settings.taxRatePct);
    final health = await _repo.computeBusinessHealth(now, branchId: branchId);

    return ReportsState(
      range: range,
      report: report,
      healthReport: health,
      loading: false,
    );
  }

  ReportPeriod _periodFor(
    ReportRange range,
    DateTime today,
    AppSettings settings,
  ) {
    return switch (range) {
      ReportRange.week => ReportPeriod(
        start: today.subtract(Duration(days: today.weekday - 1)),
        end: today.add(const Duration(days: 1)),
        label: 'This Week',
      ),
      ReportRange.year => ReportPeriod(
        start: DateTime(today.year),
        end: DateTime(today.year + 1),
        label: 'This Year',
      ),
      ReportRange.month => ReportPeriod(
        start: DateTime(today.year, today.month, 1),
        end: today.month == 12
            ? DateTime(today.year + 1, 1, 1)
            : DateTime(today.year, today.month + 1, 1),
        label: 'This Month',
      ),
    };
  }

  void setRange(ReportRange range) {
    final txns = ref.read(transactionsProvider).valueOrNull ?? [];
    final settings =
        ref.read(settingsProvider).valueOrNull ?? const AppSettings();
    final branchId = ref.read(selectedBranchIdProvider);
    state = const AsyncLoading();
    _compute(txns, settings, branchId, range).then((s) => state = AsyncData(s));
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final reportsViewModelProvider =
    AsyncNotifierProvider<ReportsViewModel, ReportsState>(ReportsViewModel.new);
