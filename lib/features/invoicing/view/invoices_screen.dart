import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../domain/models.dart';
import '../viewmodel/invoices_viewmodel.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final invAsync = ref.watch(invoicesViewModelProvider);
    final vm = ref.read(invoicesViewModelProvider.notifier);
    final currency = settings.currency;

    return Scaffold(
      backgroundColor: GallaColors.canvas,
      appBar: AppBar(
        backgroundColor: GallaColors.canvas,
        title: Text(s.invoices),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: GallaColors.brand,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 18),
            ),
            tooltip: 'Create Invoice',
            onPressed: () => context.push('/invoices/create'),
          ),
        ],
      ),
      body: invAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (state) {
          final invoices = state.filtered;

          return Column(
            children: [
              // ── Filter Chips: All | Paid | Unpaid | Overdue ───────────────
              Container(
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All',
                      isSelected: state.filter == null,
                      onTap: () => vm.setFilter(null),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Paid',
                      isSelected: state.filter == InvoiceStatus.paid,
                      onTap: () => vm.setFilter(InvoiceStatus.paid),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Unpaid',
                      isSelected: state.filter == InvoiceStatus.unpaid,
                      onTap: () => vm.setFilter(InvoiceStatus.unpaid),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Overdue / Partial',
                      isSelected: state.filter == InvoiceStatus.partiallyPaid,
                      onTap: () => vm.setFilter(InvoiceStatus.partiallyPaid),
                    ),
                  ],
                ),
              ),

              // ── Invoice List ──────────────────────────────────────────────
              Expanded(
                child: invoices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 48, color: GallaColors.faint),
                            const SizedBox(height: 12),
                            const Text('No invoices found', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => context.push('/invoices/create'),
                              icon: const Icon(Icons.add),
                              label: const Text('Create First Invoice'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                        itemCount: invoices.length,
                        itemBuilder: (context, index) {
                          final inv = invoices[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _InvoiceCard(
                              invoice: inv,
                              currency: currency,
                              onTap: () => context.push('/invoices/${inv.id}'),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? GallaColors.brand : GallaColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? GallaColors.brand : GallaColors.line),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : GallaColors.ink,
          ),
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.currency,
    required this.onTap,
  });

  final Invoice invoice;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = invoice.status;
    final isPaid = status == InvoiceStatus.paid;
    final isPartial = status == InvoiceStatus.partiallyPaid;

    final statusColor = isPaid
        ? GallaColors.moneyIn
        : (isPartial ? GallaColors.amber : GallaColors.moneyOut);

    return Container(
      decoration: BoxDecoration(
        color: GallaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GallaColors.line),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: onTap,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              invoice.invoiceNumber,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            Text(
              Money(invoice.totalMinor, currency: currency).format(),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.partyName ?? 'Walk-in Customer',
                    style: const TextStyle(fontSize: 13, color: GallaColors.muted),
                  ),
                  Text(
                    DateFormat.yMMMd().format(invoice.issueDate),
                    style: const TextStyle(fontSize: 11, color: GallaColors.muted),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
