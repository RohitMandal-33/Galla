import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';

/// List filters. [overdue] is computed from real due dates, not inferred
/// from payment status.
enum InvoiceFilter { all, unpaid, partiallyPaid, overdue, paid, cancelled }

class InvoicesState {
  const InvoicesState({
    this.invoices = const [],
    this.filter = InvoiceFilter.all,
  });

  final List<Invoice> invoices;
  final InvoiceFilter filter;

  List<Invoice> get filtered {
    switch (filter) {
      case InvoiceFilter.all:
        return invoices;
      case InvoiceFilter.overdue:
        final today = DateTime.now();
        return invoices.where((i) {
          if (i.status == InvoiceStatus.paid ||
              i.status == InvoiceStatus.cancelled) {
            return false;
          }
          return i.dueDate != null &&
              i.dueDate!.isBefore(DateTime(today.year, today.month, today.day));
        }).toList();
      case InvoiceFilter.cancelled:
        return invoices
            .where((i) => i.status == InvoiceStatus.cancelled)
            .toList();
      default:
        return invoices.where((i) => i.status.key == filter.name).toList();
    }
  }
}

class InvoicesViewModel extends AsyncNotifier<InvoicesState> {
  GallaRepository get _repo => ref.read(repositoryProvider);

  @override
  Future<InvoicesState> build() async {
    // Carry the selected filter across stream emissions so background data
    // updates never reset what the merchant is looking at.
    final prev = state.valueOrNull;
    final invoices = await ref.watch(invoicesProvider.future);
    return InvoicesState(
      invoices: invoices,
      filter: prev?.filter ?? InvoiceFilter.all,
    );
  }

  void setFilter(InvoiceFilter filter) {
    final s = state.valueOrNull;
    if (s != null) state = AsyncData(s.copyWith(filter));
  }

  Future<bool> deleteInvoice(String id) => _repo.deleteInvoice(id);

  Future<bool> cancelInvoice(String id) async {
    final ok = await _repo.cancelInvoice(id);
    if (ok) ref.invalidateSelf();
    return ok;
  }

  Future<void> recordPayment(String invoiceId, int amountMinor) =>
      _repo.recordInvoicePayment(invoiceId, amountMinor);
}

extension _Copy on InvoicesState {
  InvoicesState copyWith(InvoiceFilter filter) =>
      InvoicesState(invoices: invoices, filter: filter);
}

final invoicesViewModelProvider =
    AsyncNotifierProvider<InvoicesViewModel, InvoicesState>(
      InvoicesViewModel.new,
    );
