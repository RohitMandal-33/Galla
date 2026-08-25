import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class InvoicesState {
  const InvoicesState({
    this.invoices = const [],
    this.filter,
    this.loading = true,
  });

  final List<Invoice> invoices;
  final InvoiceStatus? filter;
  final bool loading;

  List<Invoice> get filtered => filter == null
      ? invoices
      : invoices.where((i) => i.status == filter).toList();

  InvoicesState copyWith({
    List<Invoice>? invoices,
    InvoiceStatus? Function()? filter,
    bool? loading,
  }) {
    return InvoicesState(
      invoices: invoices ?? this.invoices,
      filter: filter != null ? filter() : this.filter,
      loading: loading ?? this.loading,
    );
  }
}

// ─── ViewModel ────────────────────────────────────────────────────────────────

class InvoicesViewModel extends AsyncNotifier<InvoicesState> {
  GallaRepository get _repo => ref.read(repositoryProvider);

  @override
  Future<InvoicesState> build() async {
    final invoices = ref.watch(invoicesProvider).valueOrNull ?? [];
    return InvoicesState(invoices: invoices, loading: false);
  }

  void setFilter(InvoiceStatus? status) {
    final s = state.valueOrNull;
    if (s == null) return;
    state = AsyncData(
      InvoicesState(invoices: s.invoices, filter: status, loading: false),
    );
  }

  Future<void> deleteInvoice(String id) async {
    await _repo.deleteInvoice(id);
    ref.invalidateSelf();
  }

  Future<void> recordPayment(String invoiceId, int amountMinor) async {
    await _repo.recordInvoicePayment(invoiceId, amountMinor);
    ref.invalidateSelf();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final invoicesViewModelProvider =
    AsyncNotifierProvider<InvoicesViewModel, InvoicesState>(
      InvoicesViewModel.new,
    );
