import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../domain/models.dart';
import '../../../shared/widgets/galla_components.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../entry/view/entry_sheet.dart';

class PartyDetailScreen extends ConsumerStatefulWidget {
  const PartyDetailScreen({super.key, required this.partyId});
  final String partyId;

  @override
  ConsumerState<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends ConsumerState<PartyDetailScreen> {

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final parties = ref.watch(partiesProvider).valueOrNull ?? const <Party>[];
    final party = parties.where((p) => p.id == widget.partyId).firstOrNull;
    final allTxns = ref.watch(transactionsProvider).valueOrNull ?? const <Txn>[];
    final partyTxns = allTxns.where((t) => t.partyId == widget.partyId).toList();
    final invoices = ref.watch(invoicesProvider).valueOrNull ?? const <Invoice>[];
    final partyInvoices = invoices.where((i) => i.partyId == widget.partyId).toList();

    if (party == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Party')),
        body: const Center(child: Text('Party not found')),
      );
    }

    final currency = settings.currency;
    final balanceMinor = party.balanceMinor;
    final owesMe = balanceMinor > 0;

    // Calculate totals
    var totalCreditGivenMinor = 0;
    var totalPaidMinor = 0;
    for (final t in partyTxns) {
      if (t.isCredit && t.direction == Direction.moneyIn) {
        totalCreditGivenMinor += t.amountMinor;
      } else if (!t.isCredit && t.direction == Direction.moneyIn) {
        totalPaidMinor += t.amountMinor;
      }
    }

    final initials = party.name.isNotEmpty
        ? party.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    String m(int v) => Money(v, currency: currency).format();

    return Scaffold(
      backgroundColor: GallaColors.canvas,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── SliverAppBar with hero ─────────────────────────────────────
          SliverAppBar(
            backgroundColor: GallaColors.canvas,
            foregroundColor: GallaColors.ink,
            elevation: 0,
            scrolledUnderElevation: 0,
            floating: false,
            pinned: true,
            expandedHeight: 220,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: () => _editPartyDialog(context, party),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: _PartyHeroHeader(
                initials: initials,
                party: party,
                balanceMinor: balanceMinor,
                owesMe: owesMe,
                currency: currency,
              ),
            ),
          ),

          // ── Summary boxes ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                GallaSpacing.base,
                GallaSpacing.base,
                GallaSpacing.base,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryBox(
                      label: 'Credit Given',
                      value: m(totalCreditGivenMinor),
                      color: GallaColors.udhaar,
                      bgColor: GallaColors.udhaarSofter,
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                  const SizedBox(width: GallaSpacing.sm),
                  Expanded(
                    child: _SummaryBox(
                      label: 'Paid Back',
                      value: m(totalPaidMinor),
                      color: GallaColors.moneyIn,
                      bgColor: GallaColors.moneyInSoft,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                  const SizedBox(width: GallaSpacing.sm),
                  Expanded(
                    child: _SummaryBox(
                      label: 'Outstanding',
                      value: m(balanceMinor.abs()),
                      color: owesMe ? GallaColors.udhaar : GallaColors.moneyIn,
                      bgColor: owesMe ? GallaColors.udhaarSofter : GallaColors.moneyInSoft,
                      icon: owesMe ? Icons.pending_outlined : Icons.check_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Transactions header ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                GallaSpacing.base,
                GallaSpacing.xl,
                GallaSpacing.base,
                GallaSpacing.sm,
              ),
              child: GallaSectionHeader(
                title: 'Transaction History',
                topPadding: 0,
                trailing: partyTxns.isNotEmpty
                    ? Text(
                        '${partyTxns.length} entries',
                        style: const TextStyle(fontSize: 12, color: GallaColors.muted, fontWeight: FontWeight.w500),
                      )
                    : null,
              ),
            ),
          ),

          // ── Transactions list ──────────────────────────────────────────
          if (partyTxns.isEmpty)
            SliverToBoxAdapter(
              child: GallaEmptyState(
                icon: Icons.receipt_long_outlined,
                headline: 'No transactions yet',
                body: 'Record income or expense with ${party.name} to see their history here.',
                iconColor: GallaColors.udhaar,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                GallaSpacing.base,
                0,
                GallaSpacing.base,
                160,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final t = partyTxns[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: GallaSpacing.sm),
                      child: TransactionTile(txn: t, currency: currency, s: s),
                    );
                  },
                  childCount: partyTxns.length,
                ),
              ),
            ),

          // ── Invoices section ───────────────────────────────────────────
          if (partyInvoices.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  GallaSpacing.base,
                  GallaSpacing.xl,
                  GallaSpacing.base,
                  GallaSpacing.sm,
                ),
                child: GallaSectionHeader(title: 'Invoices', topPadding: 0),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(GallaSpacing.base, 0, GallaSpacing.base, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final inv = partyInvoices[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: GallaSpacing.sm),
                      child: _InvoiceTile(inv: inv, currency: currency),
                    );
                  },
                  childCount: partyInvoices.length,
                ),
              ),
            ),
          ],
        ],
      ),

      // ── Bottom Actions ──────────────────────────────────────────────────
      bottomNavigationBar: _PartyActionBar(party: party),
    );
  }

  void _editPartyDialog(BuildContext context, Party party) {
    final phoneCtrl = TextEditingController(text: party.phone ?? '');
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Edit ${party.name}'),
        content: TextField(
          controller: phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Phone Number'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

// ── Party Hero Header ─────────────────────────────────────────────────────────

class _PartyHeroHeader extends StatelessWidget {
  const _PartyHeroHeader({
    required this.initials,
    required this.party,
    required this.balanceMinor,
    required this.owesMe,
    required this.currency,
  });

  final String initials;
  final Party party;
  final int balanceMinor;
  final bool owesMe;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final hasBalance = balanceMinor != 0;

    return Container(
      color: GallaColors.canvas,
      padding: EdgeInsets.only(
        top: topPad + 60,
        left: GallaSpacing.base,
        right: GallaSpacing.base,
        bottom: GallaSpacing.base,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: owesMe ? GallaColors.udhaarSoft : GallaColors.brandSoft,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: owesMe ? GallaColors.udhaar : GallaColors.brand,
              ),
            ),
          ),
          const SizedBox(height: GallaSpacing.sm),

          // Name
          Text(
            party.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: GallaColors.ink,
              letterSpacing: -0.3,
            ),
          ),
          if (party.phone != null && party.phone!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(party.phone!, style: const TextStyle(fontSize: 13, color: GallaColors.muted)),
          ],

          if (hasBalance) ...[
            const SizedBox(height: GallaSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: owesMe ? GallaColors.udhaarSofter : GallaColors.moneyInSoft,
                borderRadius: BorderRadius.circular(GallaRadius.pill),
                border: Border.all(
                  color: (owesMe ? GallaColors.udhaar : GallaColors.moneyIn).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    owesMe ? 'You will receive ' : 'You owe ',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: owesMe ? GallaColors.udhaar : GallaColors.moneyIn,
                    ),
                  ),
                  Text(
                    Money(balanceMinor.abs(), currency: currency).format(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: owesMe ? GallaColors.udhaar : GallaColors.moneyIn,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: GallaSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: GallaColors.moneyInSoft,
                borderRadius: BorderRadius.circular(GallaRadius.pill),
              ),
              child: const Text(
                '✓ Fully Settled',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: GallaColors.moneyIn,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Summary Box ───────────────────────────────────────────────────────────────

class _SummaryBox extends StatelessWidget {
  const _SummaryBox({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: GallaSpacing.md, vertical: GallaSpacing.md),
      decoration: BoxDecoration(
        color: GallaColors.surface,
        borderRadius: BorderRadius.circular(GallaRadius.card),
        border: Border.all(color: GallaColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(GallaRadius.sm)),
            child: Icon(icon, size: 15, color: color),
          ),
          const SizedBox(height: GallaSpacing.sm),
          Text(label, style: const TextStyle(fontSize: 10, color: GallaColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Invoice Tile ──────────────────────────────────────────────────────────────

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.inv, required this.currency});
  final Invoice inv;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isPaid = inv.status == InvoiceStatus.paid;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GallaSpacing.base,
        vertical: GallaSpacing.md,
      ),
      decoration: BoxDecoration(
        color: GallaColors.surface,
        borderRadius: BorderRadius.circular(GallaRadius.card),
        border: Border.all(color: GallaColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(inv.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(
                  DateFormat.yMMMd().format(inv.issueDate),
                  style: const TextStyle(fontSize: 11, color: GallaColors.muted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Money(inv.totalMinor, currency: currency).format(),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 3),
              GallaStatusBadge(type: isPaid ? GallaBadgeType.settled : GallaBadgeType.pending),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Party Action Bar ─────────────────────────────────────────────────────────

class _PartyActionBar extends StatelessWidget {
  const _PartyActionBar({required this.party});
  final Party party;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GallaSpacing.base,
        vertical: GallaSpacing.md,
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
            // Primary actions row
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: GallaColors.udhaar,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GallaRadius.button)),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => EntrySheet(
                          initialDirection: Direction.moneyIn,
                          seedParty: party,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Credit', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: GallaSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: GallaColors.brand,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GallaRadius.button)),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => EntrySheet(
                          initialDirection: Direction.moneyIn,
                          seedParty: party,
                        ),
                      );
                    },
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('Receive Payment', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GallaSpacing.sm),
            // Secondary action
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: GallaColors.udhaar,
                  side: const BorderSide(color: GallaColors.udhaar, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GallaRadius.button)),
                ),
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined, size: 16),
                label: const Text('Send Reminder', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
