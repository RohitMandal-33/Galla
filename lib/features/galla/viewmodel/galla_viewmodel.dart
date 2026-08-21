import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class GallaState {
  const GallaState({
    this.summary,
    this.todayTxns = const [],
    this.selectedDay,
    this.loading = true,
  });

  final DailySummary? summary;
  final List<Txn> todayTxns;
  final DateTime? selectedDay;
  final bool loading;

  GallaState copyWith({
    DailySummary? summary,
    List<Txn>? todayTxns,
    DateTime? selectedDay,
    bool? loading,
  }) {
    return GallaState(
      summary: summary ?? this.summary,
      todayTxns: todayTxns ?? this.todayTxns,
      selectedDay: selectedDay ?? this.selectedDay,
      loading: loading ?? this.loading,
    );
  }
}

// ─── ViewModel ────────────────────────────────────────────────────────────────

class GallaViewModel extends AsyncNotifier<GallaState> {
  GallaRepository get _repo => ref.read(repositoryProvider);

  @override
  Future<GallaState> build() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _loadForDay(today);
  }

  Future<GallaState> _loadForDay(DateTime day) async {
    final branchId = ref.read(selectedBranchIdProvider);
    final summary = await _repo.summaryFor(day, branchId: branchId);
    final allTxns = ref.read(transactionsProvider).valueOrNull ?? [];
    final todayTxns = allTxns.where((t) {
      return t.occurredAt.year == day.year &&
          t.occurredAt.month == day.month &&
          t.occurredAt.day == day.day;
    }).toList();

    return GallaState(
      summary: summary,
      todayTxns: todayTxns,
      selectedDay: day,
      loading: false,
    );
  }

  Future<void> selectDay(DateTime day) async {
    state = const AsyncLoading();
    state = AsyncData(await _loadForDay(day));
  }

  void goToYesterday() {
    final current = state.valueOrNull?.selectedDay ?? DateTime.now();
    selectDay(current.subtract(const Duration(days: 1)));
  }

  void goToTomorrow() {
    final current = state.valueOrNull?.selectedDay ?? DateTime.now();
    selectDay(current.add(const Duration(days: 1)));
  }

  void goToToday() {
    final now = DateTime.now();
    selectDay(DateTime(now.year, now.month, now.day));
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final gallaViewModelProvider =
    AsyncNotifierProvider<GallaViewModel, GallaState>(GallaViewModel.new);
