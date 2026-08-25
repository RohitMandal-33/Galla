import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';

// ─── State ────────────────────────────────────────────────────────────────────

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
}

enum LedgerViewMode { parties, transactions, calendar }

// ─── ViewModel ────────────────────────────────────────────────────────────────

class LedgerViewModel extends AsyncNotifier<LedgerState> {
  GallaRepository get _repo => ref.read(repositoryProvider);

  @override
  Future<LedgerState> build() async {
    // Listen to reactive streams
    final txns = await ref.watch(transactionsProvider.future);
    final parties = await ref.watch(partiesProvider.future);
    return LedgerState(allTxns: txns, parties: parties);
  }

  Future<void> search(String query) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    if (query.isEmpty) {
      state = AsyncData(
        currentState.copyWith(searchQuery: '', searchResults: []),
      );
      return;
    }

    final results = await _repo.search(
      query,
      branchId: ref.read(selectedBranchIdProvider),
    );
    state = AsyncData(
      currentState.copyWith(searchQuery: query, searchResults: results),
    );
  }

  void setViewMode(LedgerViewMode mode) {
    final s = state.valueOrNull;
    if (s != null) state = AsyncData(s.copyWith(viewMode: mode));
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final ledgerViewModelProvider =
    AsyncNotifierProvider<LedgerViewModel, LedgerState>(LedgerViewModel.new);

final partyDetailProvider = FutureProvider.family<Party?, String>((
  ref,
  partyId,
) async {
  final parties = ref.watch(partiesProvider).valueOrNull ?? [];
  return parties.where((p) => p.id == partyId).firstOrNull;
});
