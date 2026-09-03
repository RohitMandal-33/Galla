import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../shared/widgets/transaction_tile.dart';
import '../../entry/view/entry_sheet.dart';

/// A party's page reads like a statement: who it is, what the balance is,
/// and the two or three things you can do about it — nothing else competes.
class PartyDetailScreen extends ConsumerStatefulWidget {
  const PartyDetailScreen({super.key, required this.partyId});

  final String partyId;

  @override
  ConsumerState<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends ConsumerState<PartyDetailScreen> {
  Future<void> _remind(Party party, S s) async {
    HapticFeedback.lightImpact();
    await ref.read(repositoryProvider).markReminded(party.id);
    if (!mounted) return;
    showGallaSnackBar(ScaffoldMessenger.of(context), s.remindSent);
  }

  void _openEntry(
    Party party, {
    required Direction direction,
    required bool credit,
  }) {
    HapticFeedback.lightImpact();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EntrySheet(
        initialDirection: direction,
        isCredit: credit,
        seedParty: party,
        seedCategory: credit
            ? null
            : direction == Direction.moneyIn
            ? 'Customer Payment'
            : null,
      ),
    );
  }

  Future<void> _editParty(Party party, S s) async {
    final saved = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditPartySheet(party: party),
    );
    if (saved == null || !mounted) return;
    showGallaSnackBar(ScaffoldMessenger.of(context), s.saved);
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final parties = ref.watch(partiesProvider).valueOrNull ?? const <Party>[];
    final party = parties.where((p) => p.id == widget.partyId).firstOrNull;
    final allTxns =
        ref.watch(transactionsProvider).valueOrNull ?? const <Txn>[];
    final partyTxns = allTxns
        .where((t) => t.partyId == widget.partyId)
        .toList();
    final invoices =
        ref.watch(invoicesProvider).valueOrNull ?? const <Invoice>[];
    final partyInvoices = invoices
        .where((i) => i.partyId == widget.partyId)
        .toList();

    if (party == null) {
      return Scaffold(
        backgroundColor: GallaColors.canvas,
        appBar: AppBar(title: const Text('Party')),
        body: GallaEmptyState(
          icon: Icons.person_off_outlined,
          headline: 'Party not found',
          body: 'This record may have been removed.',
          actionLabel: 'Back to khata',
          onAction: () => context.go('/ledger'),
        ),
      );
    }

    final currency = settings.currency;
    final balanceMinor = party.balanceMinor;
    final owesMe = balanceMinor > 0;
    final settled = balanceMinor == 0;

    // Real totals derived from this party's entries only.
    var totalCreditMinor = 0;
    var totalPaidMinor = 0;
    for (final t in partyTxns) {
      if (t.isWriteOff || t.isAdjustment) continue;
      if (t.direction == Direction.moneyIn && !owesMe) continue;
      if (t.direction == Direction.moneyOut && owesMe) continue;
      if (t.isCredit) {
        totalCreditMinor += t.amountMinor;
      } else {
        totalPaidMinor += t.amountMinor;
      }
    }

    final initials = party.name.isNotEmpty
        ? party.name
              .trim()
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';
    final accent = owesMe
        ? GallaColors.udhaar
        : (settled ? GallaColors.moneyIn : GallaColors.moneyOut);
    final balanceLabel = owesMe
        ? s.youWillReceive
        : settled
        ? s.settled
        : s.youWillPay;

    return Scaffold(
      backgroundColor: GallaColors.canvas,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: GallaColors.canvas,
            foregroundColor: GallaColors.ink,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              party.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GallaType.screenTitle.copyWith(fontSize: 18),
            ),
            actions: [
              IconButton(
                tooltip: 'Edit details',
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _editParty(party, s),
              ),
            ],
          ),

          // ── Balance hero ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                GallaSpacing.base,
                GallaSpacing.sm,
                GallaSpacing.base,
                0,
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: GallaType.cardTitle.copyWith(color: accent),
                    ),
                  ),
                  const SizedBox(width: GallaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(balanceLabel, style: GallaType.label),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            Money(
                              balanceMinor.abs(),
                              currency: currency,
                            ).format(),
                            style: GallaType.totalLg.copyWith(
                              letterSpacing: -1.2,
                              color: settled ? GallaColors.ink : accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Supporting totals (flat) ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: GallaSpacing.base,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GallaStatBlock(
                      label: s.creditGiven,
                      value: Money(
                        totalCreditMinor,
                        currency: currency,
                      ).formatCompact(),
                      valueColor: GallaColors.udhaar,
                    ),
                  ),
                  Expanded(
                    child: GallaStatBlock(
                      label: s.recordPayment,
                      value: Money(
                        totalPaidMinor,
                        currency: currency,
                      ).formatCompact(),
                      valueColor: GallaColors.moneyIn,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── History ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: GallaSectionHeader(
              title: 'History',
              topPadding: GallaSpacing.xl,
              bottomPadding: 0,
              trailing: partyTxns.isNotEmpty
                  ? Text('${partyTxns.length} entries', style: GallaType.label)
                  : null,
            ),
          ),
          if (partyTxns.isEmpty)
            SliverToBoxAdapter(
              child: GallaEmptyState(
                icon: Icons.receipt_long_outlined,
                headline: 'Nothing yet',
                body:
                    'Sales, payments and udhaar with ${party.name} will appear here.',
                iconColor: GallaColors.udhaar,
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final t = partyTxns[index];
                return Column(
                  children: [
                    TransactionTile(
                      txn: t,
                      currency: currency,
                      s: s,
                      dense: true,
                    ),
                    if (index != partyTxns.length - 1) const Divider(height: 1),
                  ],
                );
              }, childCount: partyTxns.length),
            ),

          // ── Invoices ───────────────────────────────────────────────────
          if (partyInvoices.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: GallaSectionHeader(
                title: s.invoices,
                topPadding: GallaSpacing.xl,
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final inv = partyInvoices[index];
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: GallaSpacing.base,
                      ),
                      onTap: () => context.push('/invoices/${inv.id}'),
                      title: Text(
                        inv.invoiceNumber,
                        style: GallaType.bodyStrong,
                      ),
                      subtitle: Text(
                        DateFormat.yMMMd().format(inv.issueDate),
                        style: GallaType.caption.copyWith(fontSize: 12),
                      ),
                      trailing: Text(
                        Money(
                          inv.totalMinor,
                          currency: currency,
                        ).formatCompact(),
                        style: GallaType.numberSm,
                      ),
                    ),
                    if (index != partyInvoices.length - 1)
                      const Divider(height: 1),
                  ],
                );
              }, childCount: partyInvoices.length),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 140)),
        ],
      ),

      // ── Bottom actions ────────────────────────────────────────────────
      bottomNavigationBar: _PartyActionBar(
        key: ValueKey('actions_${party.id}_$settled'),
        owesMe: owesMe,
        settled: settled,
        s: s,
        onPrimary: () => _openEntry(
          party,
          direction: owesMe ? Direction.moneyIn : Direction.moneyOut,
          credit: false,
        ),
        onSecondary: () => _openEntry(
          party,
          direction: owesMe ? Direction.moneyIn : Direction.moneyOut,
          credit: true,
        ),
        onRemind: () => _remind(party, s),
      ),
    );
  }
}

// ── Bottom action bar ─────────────────────────────────────────────────────────

class _PartyActionBar extends StatelessWidget {
  const _PartyActionBar({
    super.key,
    required this.owesMe,
    required this.settled,
    required this.s,
    required this.onPrimary,
    required this.onSecondary,
    required this.onRemind,
  });

  final bool owesMe;
  final bool settled;
  final S s;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final VoidCallback onRemind;

  @override
  Widget build(BuildContext context) {
    // For customers: primary = receive payment; secondary = give udhaar.
    // For suppliers: primary = pay them; secondary = take udhaar.
    final primaryLabel = owesMe ? s.receivePayment : s.payNow;
    final secondaryLabel = owesMe ? s.giveUdhaar : s.takeUdhaar;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        GallaSpacing.base,
        GallaSpacing.md,
        GallaSpacing.base,
        GallaSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: GallaColors.surface,
        border: Border(top: BorderSide(color: GallaColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    key: ValueKey('party-primary-${owesMe ? "in" : "out"}'),
                    style: FilledButton.styleFrom(
                      backgroundColor: owesMe
                          ? GallaColors.brand
                          : GallaColors.brand,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: onPrimary,
                    icon: Icon(
                      owesMe
                          ? Icons.payments_rounded
                          : Icons.send_to_mobile_rounded,
                      size: 18,
                    ),
                    label: Text(primaryLabel),
                  ),
                ),
                const SizedBox(width: GallaSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    key: const ValueKey('party-udhaar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GallaColors.udhaar,
                      side: const BorderSide(
                        color: GallaColors.udhaar,
                        width: 1.4,
                      ),
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: onSecondary,
                    child: Text(secondaryLabel, textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
            if (!settled) ...[
              const SizedBox(height: GallaSpacing.xs),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: TextButton.icon(
                  onPressed: onRemind,
                  icon: const Icon(Icons.notifications_outlined, size: 16),
                  label: Text('Send reminder', style: GallaType.bodyStrong),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Edit party sheet ──────────────────────────────────────────────────────────
/// Actually persists changes (the previous dialog silently discarded them).

class _EditPartySheet extends ConsumerStatefulWidget {
  const _EditPartySheet({required this.party});
  final Party party;

  @override
  ConsumerState<_EditPartySheet> createState() => _EditPartySheetState();
}

class _EditPartySheetState extends ConsumerState<_EditPartySheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.party.name);
    _phoneCtrl = TextEditingController(text: widget.party.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(repositoryProvider)
          .updateParty(
            widget.party.id,
            name: name,
            phone: _phoneCtrl.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop({'name': name, 'phone': _phoneCtrl.text.trim()});
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showGallaSnackBar(
        ScaffoldMessenger.of(context),
        S('en').saveFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit ${widget.party.name}', style: GallaType.numberMd),
            const SizedBox(height: GallaSpacing.base),
            TextField(
              controller: _nameCtrl,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: GallaSpacing.md),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile number (for reminders)',
              ),
            ),
            const SizedBox(height: GallaSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : () => _save(),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
