import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';

/// The day currently shown on the home screen. Held outside the AsyncNotifier
/// so changing days re-runs [GallaViewModel.build] reactively without a
/// loading flash and without losing the previously rendered data.
final gallaSelectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

class GallaState {
  const GallaState({
    required this.selectedDay,
    this.summary,
    this.txns = const [],
  });

  final DateTime selectedDay;
  final DailySummary? summary;
  final List<Txn> txns;

  bool get isToday => DateUtilsProxy.isSameDay(selectedDay, DateTime.now());
}

class GallaViewModel extends AsyncNotifier<GallaState> {
  @override
  Future<GallaState> build() async {
    // Watch both inputs: switching days or saving an entry re-runs this
    // build, so the dashboard can never go stale after a save.
    final day = ref.watch(gallaSelectedDayProvider);
    final txns = await ref.watch(transactionsProvider.future);
    final branchId = ref.watch(selectedBranchIdProvider);

    final repo = ref.read(repositoryProvider);
    final summary = await repo.summaryFor(day, branchId: branchId);

    final dayTxns = txns.where((t) => _sameDay(t.occurredAt, day)).toList();

    return GallaState(selectedDay: day, summary: summary, txns: dayTxns);
  }

  void goToYesterday() => _shiftDays(-1);
  void goToTomorrow() => _shiftDays(1);

  void goToToday() {
    final now = DateTime.now();
    ref.read(gallaSelectedDayProvider.notifier).state = DateTime(
      now.year,
      now.month,
      now.day,
    );
  }

  void _shiftDays(int delta) {
    final current = ref.read(gallaSelectedDayProvider);
    final next = current.add(Duration(days: delta));
    // Never navigate into the future beyond today — a cash book has no
    // tomorrow entries.
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    if (next.isAfter(todayStart)) return;
    ref.read(gallaSelectedDayProvider.notifier).state = next;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

final gallaViewModelProvider =
    AsyncNotifierProvider<GallaViewModel, GallaState>(GallaViewModel.new);

/// Tiny local helper so the state class stays dependency-light in tests.
class DateUtilsProxy {
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
