import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../domain/models.dart';
import '../../../shared/widgets/galla_components.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../entry/view/entry_sheet.dart';
import '../viewmodel/galla_viewmodel.dart';

class GallaScreen extends ConsumerWidget {
  const GallaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final vmAsync = ref.watch(gallaViewModelProvider);
    final branches = ref.watch(branchesProvider).valueOrNull ?? [];
    final activeBranchId = ref.watch(selectedBranchIdProvider);
    final lowStockItems = ref.watch(lowStockItemsProvider);
    final parties = ref.watch(partiesProvider).valueOrNull ?? [];

    String branchLabel = branches.length > 1 ? 'All Branches' : '';
    if (activeBranchId != null) {
      final matched = branches.where((b) => b.id == activeBranchId);
      if (matched.isNotEmpty) branchLabel = matched.first.name;
    }

    // Greeting based on time of day
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');
    final firstName = settings.businessName.isNotEmpty
        ? settings.businessName.split(' ').first
        : 'there';

    return Scaffold(
      backgroundColor: GallaColors.canvas,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar ─────────────────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: GallaColors.canvas,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: GallaSpacing.base,
            toolbarHeight: 64,
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$greeting, $firstName',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: GallaColors.muted,
                        ),
                      ),
                      GestureDetector(
                        onTap: branches.length > 1 ? () => context.push('/business/branches') : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              settings.businessName.isNotEmpty
                                  ? (branchLabel.isNotEmpty
                                      ? '${settings.businessName} · $branchLabel'
                                      : settings.businessName)
                                  : 'My Business',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: GallaColors.ink,
                                letterSpacing: -0.3,
                              ),
                            ),
                            if (branches.length > 1) ...[
                              const SizedBox(width: 3),
                              const Icon(Icons.expand_more_rounded, size: 16, color: GallaColors.muted),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _NotifButton(),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              GallaSpacing.base,
              GallaSpacing.xs,
              GallaSpacing.base,
              120,
            ),
            sliver: vmAsync.when(
              loading: () => const SliverToBoxAdapter(child: GallaHomeSkeletonLoader()),
              error: (e, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(GallaSpacing.xxl),
                  child: Column(
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 40, color: GallaColors.muted),
                      const SizedBox(height: GallaSpacing.md),
                      const Text(
                        'Couldn\'t load your Galla',
                        style: TextStyle(fontWeight: FontWeight.w700, color: GallaColors.ink),
                      ),
                      const SizedBox(height: GallaSpacing.xs),
                      Text('$e', style: const TextStyle(fontSize: 12, color: GallaColors.muted)),
                    ],
                  ),
                ),
              ),
              data: (vm) {
                // Count parties with outstanding udhaar
                final udhaarParties = parties.where((p) => p.balanceMinor > 0).toList();
                final totalUdhaarMinor = udhaarParties.fold(0, (sum, p) => sum + p.balanceMinor);

                return SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Day Navigation ──────────────────────────────────
                    _DayNavRow(
                      day: vm.selectedDay ?? DateTime.now(),
                      onPrevious: () => ref.read(gallaViewModelProvider.notifier).goToYesterday(),
                      onNext: () => ref.read(gallaViewModelProvider.notifier).goToTomorrow(),
                      onToday: () => ref.read(gallaViewModelProvider.notifier).goToToday(),
                    ),
                    const SizedBox(height: GallaSpacing.md),

                    // ── Balance Hero Card ───────────────────────────────
                    GallaBalanceCard(
                      cashOnHandMinor: vm.summary?.cashOnHandMinor ?? 0,
                      moneyInMinor: vm.summary?.inMinor ?? 0,
                      moneyOutMinor: vm.summary?.outMinor ?? 0,
                      currency: settings.currency,
                      onViewReport: () => context.push('/reports/pnl?range=month'),
                    ),
                    const SizedBox(height: GallaSpacing.md),

                    // ── Udhaar Summary ──────────────────────────────────
                    if (udhaarParties.isNotEmpty) ...[
                      GallaUdhaarCard(
                        totalUdhaarMinor: totalUdhaarMinor,
                        partyCount: udhaarParties.length,
                        currency: settings.currency,
                        onTap: () => context.go('/ledger'),
                      ),
                      const SizedBox(height: GallaSpacing.base),
                    ],

                    // ── Low Stock Alert ─────────────────────────────────
                    if (settings.notifyLowStock && lowStockItems.isNotEmpty) ...[
                      _LowStockBanner(count: lowStockItems.length),
                      const SizedBox(height: GallaSpacing.sm),
                    ],

                    // ── Quick Actions ───────────────────────────────────
                    GallaSectionHeader(
                      title: 'Quick Actions',
                      topPadding: GallaSpacing.xs,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GallaQuickActionButton(
                            label: 'Add Income',
                            icon: Icons.add_rounded,
                            color: GallaColors.moneyIn,
                            bgColor: GallaColors.moneyInSoft,
                            onTap: () => showAddEntrySheet(context, initialDirection: Direction.moneyIn),
                          ),
                        ),
                        const SizedBox(width: GallaSpacing.sm),
                        Expanded(
                          child: GallaQuickActionButton(
                            label: 'Add Expense',
                            icon: Icons.remove_rounded,
                            color: GallaColors.moneyOut,
                            bgColor: GallaColors.moneyOutSoft,
                            onTap: () => showAddEntrySheet(context, initialDirection: Direction.moneyOut),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GallaSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: GallaQuickActionButton(
                            label: 'Add Party',
                            icon: Icons.person_add_outlined,
                            color: GallaColors.blue,
                            bgColor: GallaColors.blueSoft,
                            onTap: () => context.go('/ledger'),
                          ),
                        ),
                        const SizedBox(width: GallaSpacing.sm),
                        Expanded(
                          child: GallaQuickActionButton(
                            label: 'Invoice',
                            icon: Icons.receipt_long_outlined,
                            color: GallaColors.udhaar,
                            bgColor: GallaColors.udhaarSoft,
                            onTap: () => context.push('/invoices/create'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GallaSpacing.lg),

                    // ── Today's Entries ─────────────────────────────────
                    GallaSectionHeader(
                      title: DateUtils.isSameDay(vm.selectedDay ?? DateTime.now(), DateTime.now())
                          ? "Today's Entries"
                          : DateFormat.MMMEd().format(vm.selectedDay ?? DateTime.now()),
                      trailing: vm.todayTxns.isNotEmpty
                          ? TextButton(
                              onPressed: () => context.go('/ledger'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('View All'),
                            )
                          : null,
                      topPadding: 0,
                    ),

                    if (vm.todayTxns.isEmpty)
                      _EmptyEntryCard(s: s)
                    else
                      ...vm.todayTxns.take(8).map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: GallaSpacing.sm),
                              child: TransactionTile(txn: t, currency: settings.currency, s: s),
                            ),
                          ),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notification Button ────────────────────────────────────────────────────────

class _NotifButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: GallaColors.surface,
        borderRadius: BorderRadius.circular(GallaRadius.md),
        border: Border.all(color: GallaColors.line),
      ),
      child: IconButton(
        icon: const Icon(Icons.notifications_outlined, size: 20, color: GallaColors.ink),
        onPressed: () {},
        padding: EdgeInsets.zero,
      ),
    );
  }
}

// ── Day Navigation Row ──────────────────────────────────────────────────────────

class _DayNavRow extends StatelessWidget {
  const _DayNavRow({
    required this.day,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });
  final DateTime day;
  final VoidCallback onPrevious, onNext, onToday;

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(day, DateTime.now());
    return Row(
      children: [
        GestureDetector(
          onTap: onPrevious,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: GallaColors.surface,
              borderRadius: BorderRadius.circular(GallaRadius.sm),
              border: Border.all(color: GallaColors.line),
            ),
            child: const Icon(Icons.chevron_left_rounded, size: 18, color: GallaColors.muted),
          ),
        ),
        const SizedBox(width: GallaSpacing.sm),
        Expanded(
          child: Center(
            child: Text(
              isToday
                  ? 'Today, ${DateFormat('MMM d').format(day)}'
                  : DateFormat('EEE, MMM d, yyyy').format(day),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: GallaColors.muted,
              ),
            ),
          ),
        ),
        const SizedBox(width: GallaSpacing.sm),
        GestureDetector(
          onTap: onNext,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: GallaColors.surface,
              borderRadius: BorderRadius.circular(GallaRadius.sm),
              border: Border.all(color: GallaColors.line),
            ),
            child: const Icon(Icons.chevron_right_rounded, size: 18, color: GallaColors.muted),
          ),
        ),
        if (!isToday) ...[
          const SizedBox(width: GallaSpacing.sm),
          GestureDetector(
            onTap: onToday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: GallaColors.brandSoft,
                borderRadius: BorderRadius.circular(GallaRadius.sm),
              ),
              child: const Text(
                'Today',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: GallaColors.brand,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Low Stock Banner ──────────────────────────────────────────────────────────

class _LowStockBanner extends StatelessWidget {
  const _LowStockBanner({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/inventory'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: GallaSpacing.base, vertical: GallaSpacing.sm),
        decoration: BoxDecoration(
          color: GallaColors.udhaarSofter,
          borderRadius: BorderRadius.circular(GallaRadius.md),
          border: Border.all(color: GallaColors.udhaar.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: GallaColors.udhaar, size: 16),
            const SizedBox(width: GallaSpacing.sm),
            Expanded(
              child: Text(
                '$count item${count > 1 ? "s" : ""} running low on stock — tap to review',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: GallaColors.udhaar,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: GallaColors.udhaar, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Empty Entry Card ──────────────────────────────────────────────────────────

class _EmptyEntryCard extends StatelessWidget {
  const _EmptyEntryCard({required this.s});
  final S s;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: GallaSpacing.xxl, horizontal: GallaSpacing.xl),
      decoration: BoxDecoration(
        color: GallaColors.surface,
        borderRadius: BorderRadius.circular(GallaRadius.lg),
        border: Border.all(color: GallaColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: GallaColors.brandSofter,
              borderRadius: BorderRadius.circular(GallaRadius.lg),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 24,
              color: GallaColors.brand,
            ),
          ),
          const SizedBox(height: GallaSpacing.md),
          const Text(
            'Your first entry starts today\'s Galla.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: GallaColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GallaSpacing.xs),
          Text(
            s.nothingToday,
            style: const TextStyle(fontSize: 12, color: GallaColors.muted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GallaSpacing.base),
          OutlinedButton.icon(
            onPressed: () => showAddEntrySheet(context, initialDirection: Direction.moneyIn),
            icon: const Icon(Icons.add, size: 16),
            label: Text(s.addEntry),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(160, 40),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Money helper ──────────────────────────────────────────────────────────────
// ignore: unused_element
String _m(int v, String currency) => Money(v, currency: currency).format();

// DayScreen shim for router compatibility
class DayScreen extends StatelessWidget {
  const DayScreen({super.key, required this.date});
  final String date;

  @override
  Widget build(BuildContext context) => const GallaScreen();
}
