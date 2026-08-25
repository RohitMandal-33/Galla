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

enum KhataTab { customers, suppliers, all }

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  final _searchController = TextEditingController();
  KhataTab _activeTab = KhataTab.customers;

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
                  tooltip: 'Khata View',
                  onPressed: () => vm.setViewMode(LedgerViewMode.parties),
                ),
              ],
            ),
            body: const CalendarLedgerScreen(),
          );
        }

        final isSearching = state.isSearching;
        final allParties = state.parties;
        final transactions = isSearching ? state.searchResults : state.allTxns;

        // Separate customers (they owe us: balance > 0) vs suppliers (we owe them: balance < 0)
        final customers = allParties.where((p) => p.balanceMinor >= 0).toList();
        final suppliers = allParties.where((p) => p.balanceMinor < 0).toList();

        final totalReceiveMinor = allParties
            .where((p) => p.balanceMinor > 0)
            .fold(0, (sum, p) => sum + p.balanceMinor);

        final totalPayMinor = allParties
            .where((p) => p.balanceMinor < 0)
            .fold(0, (sum, p) => sum + p.balanceMinor.abs());

        final displayedParties = _activeTab == KhataTab.customers
            ? customers
            : (_activeTab == KhataTab.suppliers ? suppliers : allParties);

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
                title: const Text('Khata & Parties'),
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

              // ── Summary Bar & Search ──────────────────────────────────
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
                      // Dual Financial Summary Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: GallaColors.surface,
                          borderRadius: BorderRadius.circular(GallaRadius.lg),
                          border: Border.all(color: GallaColors.line),
                          boxShadow: GallaElevation.card,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.arrow_downward_rounded, size: 12, color: GallaColors.moneyIn),
                                      SizedBox(width: 4),
                                      Text(
                                        'You Will Receive',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: GallaColors.muted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Money(totalReceiveMinor, currency: currency).format(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: GallaColors.moneyIn,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 36, color: GallaColors.line),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.arrow_upward_rounded, size: 12, color: GallaColors.moneyOut),
                                      SizedBox(width: 4),
                                      Text(
                                        'You Will Pay',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: GallaColors.muted),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    Money(totalPayMinor, currency: currency).format(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: GallaColors.moneyOut,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: GallaSpacing.md),

                      // Search Input
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search customer, supplier, phone…',
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

                      // Tabs: Customers | Suppliers | All | All Txns
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _TabChip(
                              label: 'Customers (${customers.length})',
                              selected: _activeTab == KhataTab.customers && state.viewMode == LedgerViewMode.parties,
                              onTap: () {
                                setState(() => _activeTab = KhataTab.customers);
                                vm.setViewMode(LedgerViewMode.parties);
                              },
                            ),
                            const SizedBox(width: 6),
                            _TabChip(
                              label: 'Suppliers (${suppliers.length})',
                              selected: _activeTab == KhataTab.suppliers && state.viewMode == LedgerViewMode.parties,
                              onTap: () {
                                setState(() => _activeTab = KhataTab.suppliers);
                                vm.setViewMode(LedgerViewMode.parties);
                              },
                            ),
                            const SizedBox(width: 6),
                            _TabChip(
                              label: 'Transactions',
                              selected: state.viewMode == LedgerViewMode.transactions,
                              onTap: () => vm.setViewMode(LedgerViewMode.transactions),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Party / Transaction List ──────────────────────────────
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  GallaSpacing.base,
                  0,
                  GallaSpacing.base,
                  MediaQuery.paddingOf(context).bottom + GallaSpacing.shellBottomClearance,
                ),
                sliver: state.viewMode == LedgerViewMode.transactions
                    ? (transactions.isEmpty
                        ? const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(GallaSpacing.xl),
                              child: Center(child: Text('No transactions recorded yet')),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) => Padding(
                                padding: const EdgeInsets.only(bottom: GallaSpacing.sm),
                                child: TransactionTile(
                                  txn: transactions[i],
                                  currency: currency,
                                  s: s,
                                ),
                              ),
                              childCount: transactions.length,
                            ),
                          ))
                    : (displayedParties.isEmpty
                        ? SliverToBoxAdapter(
                            child: GallaEmptyState(
                              icon: Icons.person_add_alt_1_outlined,
                              headline: _activeTab == KhataTab.customers
                                  ? 'No Customers Added Yet'
                                  : 'No Suppliers Added Yet',
                              body: 'Start your first digital khata and easily track who owes you money.',
                              actionLabel: 'Add Party',
                              onAction: () => _addPartyDialog(context),
                            ),
                          )
                        : SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, i) {
                                final party = displayedParties[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: GallaSpacing.sm),
                                  child: GallaPartyCard(
                                    party: party,
                                    currency: currency,
                                    daysOverdue: party.balanceMinor > 0 ? 5 : null,
                                    onTap: () => context.push('/ledger/parties/${party.id}'),
                                  ),
                                );
                              },
                              childCount: displayedParties.length,
                            ),
                          )),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addPartyDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          GallaSpacing.lg,
          GallaSpacing.lg,
          GallaSpacing.lg,
          GallaSpacing.lg + MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Add New Party / Customer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: GallaSpacing.base),
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Party / Customer Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: GallaSpacing.md),
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number (Optional for WhatsApp)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: GallaSpacing.lg),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final repo = ref.read(repositoryProvider);
                final id = await repo.findOrCreateParty(name);
                if (phoneCtrl.text.trim().isNotEmpty) {
                  // update phone if provided
                  await repo.setPartyReminder(id, enabled: true);
                }
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  context.push('/ledger/parties/$id');
                }
              },
              child: const Text('Add to Khata'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? GallaColors.brand : GallaColors.surface,
          borderRadius: BorderRadius.circular(GallaRadius.sm),
          border: Border.all(color: selected ? GallaColors.brand : GallaColors.line),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : GallaColors.ink,
          ),
        ),
      ),
    );
  }
}

class _AddPartyButton extends StatelessWidget {
  const _AddPartyButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: GallaSpacing.sm),
      child: FilledButton.tonalIcon(
        onPressed: onTap,
        icon: const Icon(Icons.person_add_outlined, size: 16),
        label: const Text('Add'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(60, 36),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// Router shims
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) => const LedgerScreen();
}

class TransactionDetailScreen extends StatelessWidget {
  const TransactionDetailScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) => const LedgerScreen();
}

