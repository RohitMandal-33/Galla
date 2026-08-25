import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';
import 'invoice_pdf_generator.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  const InvoiceDetailScreen({super.key, required this.invoiceId});
  final String invoiceId;

  @override
  ConsumerState<InvoiceDetailScreen> createState() =>
      _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  InvoiceWithItems? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = ref.read(repositoryProvider);
    final res = await repo.getInvoiceWithItems(widget.invoiceId);
    if (mounted) {
      setState(() {
        _data = res;
        _loading = false;
      });
    }
  }

  Future<void> _recordPaymentDialog(
    BuildContext context,
    Invoice inv,
    String currency,
    S s,
  ) async {
    final amountCtrl = TextEditingController(
      text: (inv.dueAmountMinor / 100).toStringAsFixed(0),
    );
    final noteCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.recordInvoicePayment,
                style: GallaType.numberMd.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Total Due: ${Money(inv.dueAmountMinor, currency: currency).format()}',
                style: const TextStyle(color: GallaColors.muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: '${s.amount} ($currency)',
                  filled: true,
                  fillColor: GallaColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  labelText: s.noteHint,
                  hintText: 'Cash / Bank Transfer / Digital Pay',
                  filled: true,
                  fillColor: GallaColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final val = int.tryParse(amountCtrl.text.trim()) ?? 0;
                    if (val <= 0) return;
                    final repo = ref.read(repositoryProvider);
                    await repo.recordInvoicePayment(
                      inv.id,
                      val * 100,
                      note: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx);
                    await _load();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GallaColors.moneyIn,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    s.save,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final currency = settings.currency;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_data == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Invoice not found')),
      );
    }

    final inv = _data!.invoice;
    final items = _data!.items;
    final isPaid = inv.status == InvoiceStatus.paid;

    return Scaffold(
      appBar: AppBar(
        title: Text(inv.invoiceNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: s.sharePdf,
            onPressed: () => InvoicePdfGenerator.shareInvoice(
              invoiceWithItems: _data!,
              businessName: settings.businessName,
              currency: currency,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Invoice?'),
                  content: const Text(
                    'Are you sure you want to delete this invoice?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(repositoryProvider).deleteInvoice(inv.id);
                if (mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GallaColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GallaColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      inv.invoiceNumber,
                      style: GallaType.numberLg.copyWith(
                        color: GallaColors.brand,
                      ),
                    ),
                    _statusBadge(inv.status, s),
                  ],
                ),
                const SizedBox(height: 12),
                Text(inv.partyName ?? 'Customer', style: GallaType.cardTitle),
                const SizedBox(height: 4),
                Text(
                  'Issued: ${DateFormat.yMMMd().format(inv.issueDate)}',
                  style: GallaType.caption,
                ),
                if (inv.dueDate != null)
                  Text(
                    'Due: ${DateFormat.yMMMd().format(inv.dueDate!)}',
                    style: GallaType.label.copyWith(
                      color: GallaColors.moneyOut,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Line Items
          Text(s.lineItems, style: GallaType.cardTitle),
          const SizedBox(height: 8),

          Container(
            decoration: BoxDecoration(
              color: GallaColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GallaColors.line),
            ),
            child: Column(
              children: [
                ...items.asMap().entries.map((e) {
                  final idx = e.key;
                  final item = e.value;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.description,
                                    style: GallaType.bodyStrong.copyWith(
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${item.quantity == item.quantity.toInt() ? item.quantity.toInt() : item.quantity} × ${Money(item.unitPriceMinor, currency: currency).format()}',
                                    style: GallaType.caption,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              Money(
                                item.totalMinor,
                                currency: currency,
                              ).format(),
                              style: GallaType.subtitle,
                            ),
                          ],
                        ),
                      ),
                      if (idx < items.length - 1) const Divider(height: 1),
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Financial Breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GallaColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GallaColors.line),
            ),
            child: Column(
              children: [
                _row(
                  s.subtotal,
                  Money(inv.subtotalMinor, currency: currency).format(),
                ),
                if (inv.taxRatePct > 0)
                  _row(
                    '${s.tax} (${inv.taxRatePct}%)',
                    Money(inv.taxMinor, currency: currency).format(),
                  ),
                const Divider(),
                _row(
                  s.total,
                  Money(inv.totalMinor, currency: currency).format(),
                  isBold: true,
                ),
                _row(
                  s.paid,
                  Money(inv.paidAmountMinor, currency: currency).format(),
                  color: GallaColors.moneyIn,
                ),
                if (!isPaid)
                  _row(
                    s.due,
                    Money(inv.dueAmountMinor, currency: currency).format(),
                    isBold: true,
                    color: GallaColors.moneyOut,
                  ),
              ],
            ),
          ),

          if (inv.notes != null && inv.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: GallaColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GallaColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: GallaType.chipLabel.copyWith(
                      color: GallaColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    inv.notes!,
                    style: GallaType.body.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: GallaColors.surface,
          border: Border(top: BorderSide(color: GallaColors.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => InvoicePdfGenerator.shareInvoice(
                  invoiceWithItems: _data!,
                  businessName: settings.businessName,
                  currency: currency,
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(s.sharePdf),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            if (!isPaid) ...[
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _recordPaymentDialog(context, inv, currency, s),
                  icon: const Icon(Icons.payments_outlined),
                  label: Text(s.recordPayment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GallaColors.moneyIn,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GallaType.body.copyWith(fontSize: 14)),
          Text(
            value,
            style: GallaType.body.copyWith(
              fontSize: 14,
              color: color ?? GallaColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(InvoiceStatus status, S s) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case InvoiceStatus.paid:
        bg = GallaColors.moneyInSoft;
        fg = GallaColors.moneyIn;
        label = s.paid;
        break;
      case InvoiceStatus.partiallyPaid:
        bg = GallaColors.brandSoft;
        fg = GallaColors.brand;
        label = s.partiallyPaid;
        break;
      case InvoiceStatus.cancelled:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade700;
        label = 'Cancelled';
        break;
      default:
        bg = GallaColors.moneyOutSoft;
        fg = GallaColors.moneyOut;
        label = s.unpaid;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: GallaType.chipLabel.copyWith(color: fg)),
    );
  }
}
