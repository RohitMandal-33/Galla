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
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PaymentSheet(invoice: inv, currency: currency, s: s),
    );
    if (saved == true) await _load();
  }

  Future<void> _cancelInvoice(Invoice inv, S s) async {
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.cancelInvoiceAction),
        content: const Text(
          'The invoice will be marked cancelled and its amount removed from '
          'your udhaar. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: GallaColors.moneyOut,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.cancelInvoiceAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref.read(repositoryProvider).cancelInvoice(inv.id);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Only invoices without payments can be cancelled'),
        ),
      );
      return;
    }
    await _load();
    messenger.showSnackBar(SnackBar(content: Text(s.invoiceCancelled)));
    router.pop();
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
          if (inv.status != InvoiceStatus.paid &&
              inv.status != InvoiceStatus.cancelled)
            IconButton(
              icon: const Icon(Icons.block_rounded, size: 20),
              tooltip: s.cancelInvoiceAction,
              onPressed: () => _cancelInvoice(inv, s),
            )
          else
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final router = GoRouter.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Invoice?'),
                    content: Text(
                      inv.status == InvoiceStatus.cancelled
                          ? 'The cancelled invoice and its entry will be removed.'
                          : 'Only unpaid invoices can be deleted. Its stock deduction will be restored.',
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
                if (confirm != true || !mounted) return;
                final ok = await ref
                    .read(repositoryProvider)
                    .deleteInvoice(inv.id);
                if (!ok) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Invoices with payments cannot be deleted — cancel the invoice instead',
                      ),
                    ),
                  );
                  return;
                }
                router.pop();
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

// ── Payment sheet ──────────────────────────────────────────────────────────────
/// Payment entry with a hard cap at the amount due — the ledger must never
/// record more cash than is owed.

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({
    required this.invoice,
    required this.currency,
    required this.s,
  });

  final Invoice invoice;
  final String currency;
  final S s;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  late final TextEditingController _amountCtrl;
  final _noteCtrl = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Prefill the exact due amount (whole rupees; paisa shown in the label).
    _amountCtrl = TextEditingController(
      text: (widget.invoice.dueAmountMinor / 100).toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving) return;
    final val = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    final dueMajor = widget.invoice.dueAmountMinor / 100;
    setState(() {
      if (val <= 0) {
        _error = 'Enter an amount greater than zero';
        return;
      }
      if (val > dueMajor + 0.009) {
        _error =
            'More than the amount due (${Money(widget.invoice.dueAmountMinor, currency: widget.currency).format()})';
        return;
      }
      _error = null;
    });
    if (_error != null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(repositoryProvider)
          .recordInvoicePayment(
            widget.invoice.id,
            val * 100,
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.s.saveFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final inv = widget.invoice;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: GallaColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(GallaRadius.bottomSheet),
          ),
        ),
        padding: const EdgeInsets.all(GallaSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.s.recordInvoicePayment, style: GallaType.numberMd),
            const SizedBox(height: GallaSpacing.xs),
            Text(
              'Due: ${Money(inv.dueAmountMinor, currency: widget.currency).format()}',
              style: GallaType.body.copyWith(color: GallaColors.muted),
            ),
            const SizedBox(height: GallaSpacing.base),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                labelText: '${widget.s.amount} (${widget.currency})',
                errorText: _error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: GallaSpacing.md),
            TextField(
              controller: _noteCtrl,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: widget.s.noteHint,
                hintText: 'Cash / Bank Transfer / Digital Pay',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: GallaSpacing.base),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: GallaColors.moneyIn,
                ),
                onPressed: _saving ? null : () => _submit(),
                icon: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : const Icon(Icons.payments_outlined, size: 18),
                label: Text(widget.s.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
