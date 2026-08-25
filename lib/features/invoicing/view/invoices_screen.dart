import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../shared/widgets/galla_components.dart';
import '../../../domain/models.dart';
import '../viewmodel/invoices_viewmodel.dart';

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
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
                    GallaFilterChip(
                      label: 'All',
                      selected: state.filter == null,
                      onTap: () => vm.setFilter(null),
                    ),
                    const SizedBox(width: 8),
                    GallaFilterChip(
                      label: 'Paid',
                      selected: state.filter == InvoiceStatus.paid,
                      onTap: () => vm.setFilter(InvoiceStatus.paid),
                    ),
                    const SizedBox(width: 8),
                    GallaFilterChip(
                      label: 'Unpaid',
                      selected: state.filter == InvoiceStatus.unpaid,
                      onTap: () => vm.setFilter(InvoiceStatus.unpaid),
                    ),
                    const SizedBox(width: 8),
                    GallaFilterChip(
                      label: 'Overdue / Partial',
                      selected: state.filter == InvoiceStatus.partiallyPaid,
                      onTap: () => vm.setFilter(InvoiceStatus.partiallyPaid),
                    ),
                  ],
                ),
              ),

              // ── Invoice List ──────────────────────────────────────────────
              Expanded(
                child: invoices.isEmpty
                    ? GallaEmptyState(
                        icon: Icons.receipt_long_outlined,
                        headline: 'No invoices found',
                        body:
                            'Create your first invoice to start billing customers.',
                        actionLabel: 'Create First Invoice',
                        onAction: () => context.push('/invoices/create'),
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
            Text(invoice.invoiceNumber, style: GallaType.numberSm),
            Text(
              Money(invoice.totalMinor, currency: currency).format(),
              style: GallaType.numberSm,
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
                    style: GallaType.body.copyWith(color: GallaColors.muted),
                  ),
                  Text(
                    DateFormat.yMMMd().format(invoice.issueDate),
                    style: GallaType.captionSm,
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
                  style: GallaType.labelStrong.copyWith(
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
