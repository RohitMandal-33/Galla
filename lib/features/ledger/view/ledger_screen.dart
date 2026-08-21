import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';
import '../../../shared/widgets/galla_components.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../viewmodel/ledger_viewmodel.dart';
import 'calendar_ledger_screen.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final ledgerAsync = ref.watch(ledgerViewModelProvider);
    final vm = ref.read(ledgerViewModelProvider.notifier);
    final currency = settings.currency;

    return ledgerAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      data: (state) {
        if (state.viewMode == LedgerViewMode.calendar) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Calendar Ledger'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.people_outline_rounded),
                  tooltip: 'Party View',
                  onPressed: () => vm.setViewMode(LedgerViewMode.parties),
                ),
              ],
            ),
            body: const CalendarLedgerScreen(),
          );
        }

        final isSearching = state.isSearching;
        final parties = state.parties;
        final transactions = isSearching ? state.searchResults : state.allTxns;

        // Udhaar summary
        final udhaarParties = parties.where((p) => p.balanceMinor > 0).toList();
        final totalUdhaarMinor = udhaarParties.fold(0, (sum, p) => sum + p.balanceMinor);

        return Scaffold(
          backgroundColor: GallaColors.canvas,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ──────────────────────────────────────────────
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: GallaColors.canvas,
                elevation: 0,
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                title: Text(s.ledgerTab),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.calendar_month_outlined, size: 20),
                    tooltip: 'Calendar View',
                    onPressed: () => vm.setViewMode(LedgerViewMode.calendar),
                  ),
                  _AddPartyButton(
                    onTap: () => _addPartyDialog(context),
                  ),
                  const SizedBox(width: GallaSpacing.xs),
                ],
              ),

              // ── Search Bar ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    GallaSpacing.base,
                    GallaSpacing.xs,
                    GallaSpacing.base,
                    GallaSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search parties, notes, amounts…',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    vm.search('');
                                  },
                                )
                              : null,
                        ),
                        onChanged: (v) => vm.search(v.trim()),
                      ),
                      const SizedBox(height: GallaSpacing.sm),

                      // ── Mode Toggle ──────────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _ModeSegment(
                              label: 'Parties',
                              count: parties.length,
                              isSelected: state.viewMode == LedgerViewMode.parties,
                              onTap: () => vm.setViewMode(LedgerViewMode.parties),
                            ),
                          ),
                          const SizedBox(width: GallaSpacing.sm),
                          Expanded(
                            child: _ModeSegment(
                              label: 'All Transactions',
                              isSelected: state.viewMode == LedgerViewMode.transactions,
                              onTap: () => vm.setViewMode(LedgerViewMode.transactions),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Udhaar Summary (Party view only) ──────────────────────
              if (state.viewMode == LedgerViewMode.parties &&
                  !isSearching &&
                  udhaarParties.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      GallaSpacing.base,
                      0,
                      GallaSpacing.base,
                      GallaSpacing.md,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GallaSpacing.base,
                        vertical: GallaSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: GallaColors.udhaarSofter,
                        borderRadius: BorderRadius.circular(GallaRadius.lg),
                        border: Border.all(color: GallaColors.udhaar.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people_outline_rounded, color: GallaColors.udhaar, size: 18),
                          const SizedBox(width: GallaSpacing.sm),
                          Expanded(
                            child: Text(
                              'Total outstanding from ${udhaarParties.length} ${udhaarParties.length == 1 ? "customer" : "customers"}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: GallaColors.udhaar,
                              ),
                            ),
                          ),
                          Text(
                            Money(totalUdhaarMinor, currency: currency).format(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: GallaColors.udhaar,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // ── Content ───────────────────────────────────────────────
              if (state.viewMode == LedgerViewMode.parties && !isSearching) ...[
                if (parties.isEmpty)
                  SliverToBoxAdapter(
                    child: GallaEmptyState(
                      icon: Icons.people_outline_rounded,
                      headline: 'No parties yet',
                      body: 'Parties appear automatically when you record Udhaar entries, or add one manually.',
                      actionLabel: 'Add First Party',
                      onAction: () => _addPartyDialog(context),
                      iconColor: GallaColors.blue,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      GallaSpacing.base,
                      0,
                      GallaSpacing.base,
                      120,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final party = parties[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: GallaSpacing.sm),
                            child: GallaPartyCard(
                              party: party,
                              currency: currency,
                              onTap: () => context.push('/ledger/parties/${party.id}'),
                            ),
                          );
                        },
                        childCount: parties.length,
                      ),
                    ),
                  ),
              ] else ...[
                if (transactions.isEmpty)
                  SliverToBoxAdapter(
                    child: GallaEmptyState(
                      icon: Icons.receipt_long_outlined,
                      headline: isSearching ? 'No results found' : 'No transactions yet',
                      body: isSearching
                          ? 'Try a different search term.'
                          : 'Your transactions will appear here as you record entries.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      GallaSpacing.base,
                      0,
                      GallaSpacing.base,
                      120,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final t = transactions[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: GallaSpacing.sm),
                            child: TransactionTile(txn: t, currency: currency, s: s),
                          );
                        },
                        childCount: transactions.length,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _addPartyDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add New Party'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Customer / Party Name *'),
            ),
            const SizedBox(height: GallaSpacing.md),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                await ref.read(repositoryProvider).findOrCreateParty(name);
                if (context.mounted) Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Create Party'),
          ),
        ],
      ),
    );
  }
}

// ── Add Party Button ──────────────────────────────────────────────────────────

class _AddPartyButton extends StatelessWidget {
  const _AddPartyButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: GallaSpacing.xs),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: GallaColors.brandSoft,
          borderRadius: BorderRadius.circular(GallaRadius.sm),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_add_alt_1_outlined, size: 16, color: GallaColors.brand),
            SizedBox(width: 5),
            Text(
              'Add Party',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: GallaColors.brand),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mode Segment ──────────────────────────────────────────────────────────────

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? GallaColors.brand : GallaColors.surface,
          borderRadius: BorderRadius.circular(GallaRadius.md),
          border: Border.all(color: isSelected ? GallaColors.brand : GallaColors.line),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : GallaColors.ink,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white.withValues(alpha: 0.2) : GallaColors.brandSoft,
                  borderRadius: BorderRadius.circular(GallaRadius.pill),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : GallaColors.brand,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Shim SearchScreen for router compatibility
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) => const LedgerScreen();
}

// Shim TransactionDetailScreen for router compatibility
class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => const LedgerScreen();
}
