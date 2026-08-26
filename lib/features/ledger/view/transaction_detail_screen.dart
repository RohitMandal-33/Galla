import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../data/galla_repository.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../domain/models.dart';
import '../../../shared/widgets/galla_components.dart';

/// What happened, to whom, for how much — plus provenance (voice-inferred,
/// adjustment, invoice-linked). Every fact on this page comes from the stored
/// row; nothing is derived or decorated.
class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({super.key, required this.txnId});

  final String txnId;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  Txn? _txn;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final txn = await ref.read(repositoryProvider).getTxn(widget.txnId);
    if (!mounted) return;
    setState(() {
      _txn = txn;
      _loading = false;
    });
  }

  Future<void> _confirmRemove(S s) async {
    final txn = _txn;
    if (txn == null || txn.invoiceId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove this entry?'),
        content: const Text(
          'The amount will be removed from your books. This can be undone '
          'only by adding the entry again.',
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
            child: Text(s.removeEntry),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Capture before the await so we never touch a dead context.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await ref.read(repositoryProvider).softDeleteEntry(txn.id);
    messenger.showSnackBar(SnackBar(content: Text(s.entryRemoved)));
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final currency = settings.currency;
    final parties = ref.watch(partiesProvider).valueOrNull ?? const <Party>[];

    if (_loading) {
      return Scaffold(
        backgroundColor: GallaColors.canvas,
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final txn = _txn;
    if (txn == null) {
      return Scaffold(
        backgroundColor: GallaColors.canvas,
        appBar: AppBar(),
        body: GallaEmptyState(
          icon: Icons.search_off_rounded,
          headline: 'Entry not found',
          body: 'It may have been removed.',
          actionLabel: 'Back',
          onAction: () => context.pop(),
        ),
      );
    }

    final isIn = txn.direction == Direction.moneyIn;
    final accent = isIn ? GallaColors.moneyIn : GallaColors.moneyOut;
    final partyName =
        parties.where((p) => p.id == txn.partyId).firstOrNull?.name ??
        txn.partyName;
    final createdLabel = DateFormat(
      'EEE, d MMM yyyy · jm',
    ).format(txn.createdAt);

    String typeLine;
    if (txn.isAdjustment) {
      typeLine = s.correctCash;
    } else if (txn.isWriteOff) {
      typeLine = s.writeOff;
    } else if (txn.isCredit) {
      typeLine = '${s.udhaar} · ${isIn ? s.creditGiven : s.creditTaken}';
    } else {
      typeLine = isIn ? s.typeSale : s.typeExpense;
    }

    return Scaffold(
      backgroundColor: GallaColors.canvas,
      appBar: AppBar(
        title: Text(typeLine),
        actions: [
          if (txn.invoiceId != null)
            IconButton(
              tooltip: s.invoices,
              icon: const Icon(Icons.receipt_long_outlined, size: 20),
              onPressed: () => context.push('/invoices/${txn.invoiceId}'),
            )
          else
            IconButton(
              tooltip: s.removeEntry,
              icon: const Icon(Icons.delete_outline_rounded, size: 20),
              onPressed: () => _confirmRemove(s),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(GallaSpacing.base),
        children: [
          const SizedBox(height: GallaSpacing.md),
          Center(
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isIn ? Icons.south_west_rounded : Icons.north_east_rounded,
                    color: accent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: GallaSpacing.md),
                Text(
                  '${isIn ? '+' : '−'} ${Money(txn.amountMinor, currency: currency).format()}',
                  style: GallaType.total.copyWith(color: accent),
                ),
                const SizedBox(height: GallaSpacing.xs),
                Text(
                  typeLine,
                  style: GallaType.body.copyWith(color: GallaColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: GallaSpacing.xl),

          // ── Facts ──────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: GallaColors.surface,
              borderRadius: BorderRadius.circular(GallaRadius.lg),
              border: Border.all(color: GallaColors.line),
            ),
            padding: const EdgeInsets.symmetric(horizontal: GallaSpacing.base),
            child: Column(
              children: [
                if (partyName != null && partyName.isNotEmpty)
                  _FactRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Party',
                    value: partyName,
                    onTap: txn.partyId != null
                        ? () => context.push('/ledger/parties/${txn.partyId}')
                        : null,
                  ),
                if (txn.category != null)
                  _FactRow(
                    icon: Icons.sell_outlined,
                    label: 'Category',
                    value: txn.category!,
                  ),
                if (txn.note != null && txn.note!.isNotEmpty)
                  _FactRow(
                    icon: Icons.notes_rounded,
                    label: s.noteHint.replaceFirst(' (optional)', ''),
                    value: txn.aiInferred && txn.nlRaw != null
                        ? '"${txn.nlRaw}"'
                        : txn.note!,
                  ),
                _FactRow(
                  icon: Icons.schedule_rounded,
                  label: s.recordedJustNow.isEmpty ? 'Recorded' : 'Recorded',
                  value: createdLabel,
                ),
              ],
            ),
          ),

          if (txn.photoPath != null && File(txn.photoPath!).existsSync()) ...[
            const SizedBox(height: GallaSpacing.base),
            ClipRRect(
              borderRadius: BorderRadius.circular(GallaRadius.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: Image.file(
                  File(txn.photoPath!),
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          const SizedBox(height: GallaSpacing.xxl),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: GallaSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: GallaColors.muted),
          const SizedBox(width: GallaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GallaType.labelSm),
                const SizedBox(height: 2),
                Text(value, style: GallaType.bodyStrong.copyWith(fontSize: 14)),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: GallaColors.faint,
            ),
        ],
      ),
    );
    return onTap == null
        ? row
        : GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: row,
          );
  }
}
