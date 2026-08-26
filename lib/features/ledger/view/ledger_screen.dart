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
import '../../../shared/widgets/galla_components.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../viewmodel/ledger_viewmodel.dart';
import 'calendar_ledger_screen.dart';

enum KhataTab { customers, suppliers }

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});

  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final ledgerAsync = ref.watch(ledgerViewModelProvider);
    final vm = ref.read(ledgerViewModelProvider.notifier);
    final currency = settings.currency;

    return ledgerAsync.when(
      loading: () => const Scaffold(
        backgroundColor: GallaColors.canvas,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: GallaColors.canvas,
        body: Center(
          child: GallaEmptyState(
            icon: Icons.error_outline_rounded,
            headline: s.saveFailed,
            body: '$e',
            actionLabel: s.undo,
            onAction: () => ref.invalidate(ledgerViewModelProvider),
          ),
        ),
      ),
      data: (state) {
        if (state.viewMode == LedgerViewMode.calendar) {
          return Scaffold(
            backgroundColor: GallaColors.canvas,
            appBar: AppBar(
              title: const Text('Calendar'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.list_rounded),
                  tooltip: 'List view',
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

        // Customers owe the merchant (balance > 0); the merchant owes
        // suppliers (balance < 0). Fully settled parties stay under their
        // natural side so nothing disappears after a payment.
        final customers = allParties.where((p) => p.balanceMinor >= 0).toList()
          ..sort((a, b) => b.balanceMinor.compareTo(a.balanceMinor));
        final suppliers = allParties.where((p) => p.balanceMinor < 0).toList()
          ..sort(
            (a, b) => a.balanceMinor.abs().compareTo(b.balanceMinor.abs()),
          );

        final totalReceiveMinor = allParties
            .where((p) => p.balanceMinor > 0)
            .fold(0, (sum, p) => sum + p.balanceMinor);
        final totalPayMinor = allParties
            .where((p) => p.balanceMinor < 0)
            .fold(0, (sum, p) => sum + p.balanceMinor.abs());

        final displayedParties = _tab == KhataTab.customers
            ? customers
            : suppliers;

        return Scaffold(
          backgroundColor: GallaColors.canvas,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                backgroundColor: GallaColors.canvas,
                elevation: 0,
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                title: Text(s.parties, style: GallaType.screenTitle),
                actions: [
                  IconButton(
                    tooltip: 'Calendar view',
                    icon: const Icon(Icons.calendar_month_outlined, size: 20),
                    onPressed: () => vm.setViewMode(LedgerViewMode.calendar),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: GallaSpacing.base),
                    child: FilledButton.tonalIcon(
                      key: const ValueKey('add-party-button'),
                      onPressed: () => _showAddPartySheet(context, s),
                      icon: const Icon(Icons.person_add_outlined, size: 16),
                      label: const Text('Add'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(64, 38),
                        textStyle: GallaType.chipLabel,
                      ),
                    ),
                  ),
                ],
              ),

              // ── Receive / Pay summary — flat typographic block ──────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    GallaSpacing.base,
                    GallaSpacing.xs,
                    GallaSpacing.base,
                    GallaSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GallaStatBlock(
                          label:
                              '${s.youWillReceive} · ${customers.where((p) => p.balanceMinor > 0).length} ${s.people}',
                          value: Money(
                            totalReceiveMinor,
                            currency: currency,
                          ).formatCompact(),
                          valueColor: totalReceiveMinor > 0
                              ? GallaColors.moneyIn
                              : null,
                        ),
                      ),
                      const SizedBox(width: GallaSpacing.lg),
                      Expanded(
                        child: GallaStatBlock(
                          label:
                              '${s.youWillPay} · ${suppliers.length} ${s.suppliers}',
                          value: Money(
                            totalPayMinor,
                            currency: currency,
                          ).formatCompact(),
                          valueColor: totalPayMinor > 0
                              ? GallaColors.moneyOut
                              : null,
                          alignment: CrossAxisAlignment.end,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    GallaSpacing.base,
                    0,
                    GallaSpacing.base,
                    GallaSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: s.search,
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 20,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  tooltip: 'Clear',
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    vm.search('');
                                  },
                                )
                              : null,
                        ),
                        onChanged: vm.search,
                      ),
                      const SizedBox(height: GallaSpacing.sm),
                      if (!isSearching)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              GallaFilterChip(
                                label: 'Customers (${customers.length})',
                                selected: _tab == KhataTab.customers,
                                onTap: () =>
                                    setState(() => _tab = KhataTab.customers),
                              ),
                              const SizedBox(width: 6),
                              GallaFilterChip(
                                label: 'Suppliers (${suppliers.length})',
                                selected: _tab == KhataTab.suppliers,
                                onTap: () =>
                                    setState(() => _tab = KhataTab.suppliers),
                              ),
                              const SizedBox(width: 6),
                              GallaFilterChip(
                                label: 'All transactions',
                                selected:
                                    state.viewMode ==
                                    LedgerViewMode.transactions,
                                onTap: () =>
                                    vm.setViewMode(LedgerViewMode.transactions),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  0,
                  0,
                  0,
                  MediaQuery.paddingOf(context).bottom +
                      GallaSpacing.shellBottomClearance,
                ),
                sliver:
                    state.viewMode == LedgerViewMode.transactions || isSearching
                    ? (transactions.isEmpty
                          ? SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: GallaSpacing.base,
                                ),
                                child: GallaEmptyState(
                                  icon: Icons.receipt_long_outlined,
                                  headline: isSearching
                                      ? 'Nothing matches "${state.searchQuery}"'
                                      : s.noTxnsTitle,
                                  body: isSearching
                                      ? 'Try a name, amount, category or note.'
                                      : s.noTxnsBody,
                                ),
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                i,
                              ) {
                                final txn = transactions[i];
                                return Column(
                                  children: [
                                    TransactionTile(
                                      txn: txn,
                                      currency: currency,
                                      s: s,
                                      dense: true,
                                    ),
                                    if (i != transactions.length - 1)
                                      const Divider(height: 1),
                                  ],
                                );
                              }, childCount: transactions.length),
                            ))
                    : (displayedParties.isEmpty
                          ? SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: GallaSpacing.base,
                                ),
                                child: GallaEmptyState(
                                  icon: Icons.person_add_alt_1_outlined,
                                  headline: _tab == KhataTab.customers
                                      ? 'No customers yet'
                                      : 'No suppliers yet',
                                  body:
                                      'Add a customer to track udhaar — who owes you, and for how long.',
                                  actionLabel: 'Add party',
                                  onAction: () =>
                                      _showAddPartySheet(context, s),
                                ),
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                i,
                              ) {
                                final party = displayedParties[i];
                                final lastActivity =
                                    state.lastActivityByParty[party.id];
                                String? activityLabel;
                                if (lastActivity != null) {
                                  final diff = DateTime.now().difference(
                                    lastActivity,
                                  );
                                  activityLabel = diff.inDays == 0
                                      ? s.today
                                      : diff.inDays == 1
                                      ? 'Yesterday'
                                      : diff.inDays < 30
                                      ? '${diff.inDays}d ago'
                                      : DateFormat(
                                          'd MMM',
                                        ).format(lastActivity);
                                }
                                return Column(
                                  children: [
                                    GallaPartyCard(
                                      party: party,
                                      currency: currency,
                                      lastActivity: activityLabel,
                                      onTap: () => context.push(
                                        '/ledger/parties/${party.id}',
                                      ),
                                    ),
                                    if (i != displayedParties.length - 1)
                                      const Divider(height: 1),
                                  ],
                                );
                              }, childCount: displayedParties.length),
                            )),
              ),
            ],
          ),
        );
      },
    );
  }

  KhataTab _tab = KhataTab.customers;

  void _showAddPartySheet(BuildContext context, S s) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddPartySheet(s: s),
    );
  }
}

// ── Add party sheet ────────────────────────────────────────────────────────────

class _AddPartySheet extends ConsumerStatefulWidget {
  const _AddPartySheet({required this.s});
  final S s;

  @override
  ConsumerState<_AddPartySheet> createState() => _AddPartySheetState();
}

class _AddPartySheetState extends ConsumerState<_AddPartySheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final repo = ref.read(repositoryProvider);
    final id = await repo.findOrCreateParty(name);
    final phone = _phoneCtrl.text.trim();
    if (phone.isNotEmpty) {
      await repo.updateParty(id, phone: phone);
    }
    if (!mounted) return;
    // Resolve the router before popping so we never touch a dead context.
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push('/ledger/parties/$id');
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
            Text('Add party', style: GallaType.numberMd),
            const SizedBox(height: GallaSpacing.base),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _nameCtrl,
              builder: (_, value, _) => TextField(
                controller: _nameCtrl,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  errorText: value.text.trim().isEmpty && value.text.isNotEmpty
                      ? 'Enter a name'
                      : null,
                ),
              ),
            ),
            const SizedBox(height: GallaSpacing.md),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile number (for reminders)',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: GallaSpacing.lg),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _nameCtrl,
              builder: (_, value, _) => FilledButton(
                onPressed: value.text.trim().isEmpty ? null : () => _save(),
                child: const Text('Add to khata'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
