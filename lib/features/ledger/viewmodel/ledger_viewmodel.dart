import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';

class LedgerState {
  const LedgerState({
    this.allTxns = const [],
    this.parties = const [],
    this.searchQuery = '',
    this.searchResults = const [],
    this.viewMode = LedgerViewMode.parties,
  });

  final List<Txn> allTxns;
  final List<Party> parties;
  final String searchQuery;
  final List<Txn> searchResults;
  final LedgerViewMode viewMode;

  bool get isSearching => searchQuery.isNotEmpty;

  LedgerState copyWith({
    List<Txn>? allTxns,
    List<Party>? parties,
    String? searchQuery,
    List<Txn>? searchResults,
    LedgerViewMode? viewMode,
  }) {
    return LedgerState(
      allTxns: allTxns ?? this.allTxns,
      parties: parties ?? this.parties,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  /// Most recent activity timestamp per party id, derived from the live
  /// transaction list (no extra DB work).
  Map<String, DateTime> get lastActivityByParty {
    final map = <String, DateTime>{};
    for (final t in allTxns) {
      if (t.partyId == null) continue;
      final existing = map[t.partyId!];
      if (existing == null || t.occurredAt.isAfter(existing)) {
        map[t.partyId!] = t.occurredAt;
      }
    }
    return map;
  }
}

enum LedgerViewMode { parties, transactions, calendar }

class LedgerViewModel extends AsyncNotifier<LedgerState> {
  Timer? _searchDebounce;
  int _searchToken = 0;

  @override
  Future<LedgerState> build() async {
    // Watch reactive streams. Crucially, carry over user selections
    // (view mode / active search) so background data changes never silently
    // reset what the merchant is looking at.
    final txns = await ref.watch(transactionsProvider.future);
    final parties = await ref.watch(partiesProvider.future);
    ref.onDispose(() => _searchDebounce?.cancel());

    final prev = state.valueOrNull;
    final query = prev?.searchQuery ?? '';
    List<Txn> results = prev?.searchResults ?? const [];
    if (query.isNotEmpty) {
      // Re-run against fresh data so search results never go stale.
      results = await ref
          .read(repositoryProvider)
          .search(query, branchId: ref.read(selectedBranchIdProvider));
    }

    return LedgerState(
      allTxns: txns,
      parties: parties,
      searchQuery: query,
      searchResults: results,
      viewMode: prev?.viewMode ?? LedgerViewMode.parties,
    );
  }

  /// Debounced, race-safe search: only the newest query may write results.
  void search(String query) {
    final current = state.valueOrNull;
    if (current == null) return;
    _searchToken++;
    final token = _searchToken;
    _searchDebounce?.cancel();

    if (query.trim().isEmpty) {
      state = AsyncData(
        current.copyWith(searchQuery: '', searchResults: const []),
      );
      return;
    }
    if (query == current.searchQuery && current.searchResults.isNotEmpty) {
      return;
    }

    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      final q = query.trim();
      final repo = ref.read(repositoryProvider);
      final branchId = ref.read(selectedBranchIdProvider);
      try {
        final results = await repo.search(q, branchId: branchId);
        // Ignore stale responses.
        if (token != _searchToken) return;
        final latest = state.valueOrNull;
        if (latest != null) {
          try {
            state = AsyncData(
              latest.copyWith(searchQuery: q, searchResults: results),
            );
          } catch (_) {
            // Provider was disposed mid-flight — nothing to update.
          }
        }
      } catch (_) {
        // Leave previous results visible; the next keystroke retries.
      }
    });
  }

  void setViewMode(LedgerViewMode mode) {
    final s = state.valueOrNull;
    if (s != null) state = AsyncData(s.copyWith(viewMode: mode));
  }
}

final ledgerViewModelProvider =
    AsyncNotifierProvider<LedgerViewModel, LedgerState>(LedgerViewModel.new);
