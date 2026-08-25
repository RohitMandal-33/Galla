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
import '../viewmodel/action_center_provider.dart';
import '../viewmodel/galla_viewmodel.dart';

class GallaScreen extends ConsumerWidget {
  const GallaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final vmAsync = ref.watch(gallaViewModelProvider);
    final branches = ref.watch(branchesProvider).valueOrNull ?? [];
    final activeBranchId = ref.watch(selectedBranchIdProvider);
    final parties = ref.watch(partiesProvider).valueOrNull ?? [];
    final actions = ref.watch(actionCenterProvider);
    final txns = ref.watch(transactionsProvider).valueOrNull ?? [];

    String branchLabel = branches.length > 1 ? 'All Branches' : '';
    if (activeBranchId != null) {
      final matched = branches.where((b) => b.id == activeBranchId);
      if (matched.isNotEmpty) branchLabel = matched.first.name;
    }

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');
    final firstName = settings.businessName.isNotEmpty
        ? settings.businessName.split(' ').first
        : 'Merchant';

    final initials = settings.businessName.isNotEmpty
        ? settings.businessName
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'GK';

    // 30-day metrics calculation for the 3 financial cards
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    var revMinor = 0;
    var expMinor = 0;
    for (final t in txns) {
      if (t.occurredAt.isAfter(thirtyDaysAgo) && !t.isWriteOff) {
        if (t.direction == Direction.moneyIn) revMinor += t.amountMinor;
        if (t.direction == Direction.moneyOut) expMinor += t.amountMinor;
      }
    }
    final profitMinor = revMinor - expMinor;

    final udhaarParties = parties.where((p) => p.balanceMinor > 0).toList();
    final totalUdhaarMinor = udhaarParties.fold(
      0,
      (sum, p) => sum + p.balanceMinor,
    );

    return Scaffold(
      backgroundColor: GallaColors.canvas,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App Bar / Header ──────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: GallaColors.canvas,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            titleSpacing: GallaSpacing.base,
            toolbarHeight: 88,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: GallaColors.brand,
                      shape: BoxShape.circle,
                      boxShadow: GallaElevation.card,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: GallaType.number.copyWith(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: GallaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$greeting, $firstName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GallaType.label,
                      ),
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                settings.businessName.isNotEmpty
                                    ? (branchLabel.isNotEmpty
                                          ? '${settings.businessName} · $branchLabel'
                                          : settings.businessName)
                                    : 'Shree Ganesh Kirana',
                                style: GallaType.number.copyWith(
                                  fontSize: 17,
                                  letterSpacing: -0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 11,
                              color: GallaColors.muted,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, d MMMM').format(DateTime.now()),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GallaType.captionSm,
                      ),
                    ],
                  ),
                ),
                // AI Assistant Icon
                IconButton.filledTonal(
                  icon: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 20,
                    color: GallaColors.brand,
                  ),
                  tooltip: 'Galla Assistant',
                  onPressed: () => context.push('/ai-assistant'),
                ),
              ],
            ),
          ),

          // ── Main Content ──────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              GallaSpacing.base,
              GallaSpacing.xs,
              GallaSpacing.base,
              MediaQuery.paddingOf(context).bottom +
                  GallaSpacing.shellBottomClearance,
            ),
            sliver: vmAsync.when(
              loading: () =>
                  const SliverToBoxAdapter(child: GallaHomeSkeletonLoader()),
              error: (e, _) =>
                  SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
              data: (vm) {
                return SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Day Navigation Bar ──────────────────────────────
                    _DayNavRow(
                      day: vm.selectedDay ?? DateTime.now(),
                      onPrevious: () => ref
                          .read(gallaViewModelProvider.notifier)
                          .goToYesterday(),
                      onNext: () => ref
                          .read(gallaViewModelProvider.notifier)
                          .goToTomorrow(),
                      onToday: () =>
                          ref.read(gallaViewModelProvider.notifier).goToToday(),
                    ),
                    const SizedBox(height: GallaSpacing.md),

                    // ── 1. Hero Card: Today's Cash ──────────────────────
                    GallaBalanceCard(
                      cashOnHandMinor: vm.summary?.cashOnHandMinor ?? 0,
                      moneyInMinor: vm.summary?.inMinor ?? 0,
                      moneyOutMinor: vm.summary?.outMinor ?? 0,
                      currency: settings.currency,
                      trendPercent: 12.4,
                      onViewReport: () =>
                          context.push('/reports/pnl?range=month'),
                    ),
                    const SizedBox(height: GallaSpacing.md),

                    // ── 2. Three Financial Metric Cards ─────────────────
                    Row(
                      children: [
                        Expanded(
                          child: GallaMetricCard(
                            title: 'Revenue',
                            value: Money(
                              revMinor,
                              currency: settings.currency,
                            ).format(),
                            trendPercent: 14.0,
                            isPositiveTrend: true,
                            accentColor: GallaColors.moneyIn,
                            icon: Icons.trending_up_rounded,
                            onTap: () =>
                                context.push('/reports/pnl?range=month'),
                          ),
                        ),
                        const SizedBox(width: GallaSpacing.sm),
                        Expanded(
                          child: GallaMetricCard(
                            title: 'Net Profit',
                            value: Money(
                              profitMinor,
                              currency: settings.currency,
                            ).format(),
                            trendPercent: 21.0,
                            isPositiveTrend: profitMinor >= 0,
                            accentColor: profitMinor >= 0
                                ? GallaColors.brand
                                : GallaColors.moneyOut,
                            icon: Icons.account_balance_wallet_outlined,
                            onTap: () =>
                                context.push('/reports/pnl?range=month'),
                          ),
                        ),
                        const SizedBox(width: GallaSpacing.sm),
                        Expanded(
                          child: GallaMetricCard(
                            title: 'Udhaar Due',
                            value: Money(
                              totalUdhaarMinor,
                              currency: settings.currency,
                            ).format(),
                            trendPercent: 5.0,
                            isPositiveTrend: false,
                            accentColor: GallaColors.udhaar,
                            icon: Icons.people_outline_rounded,
                            onTap: () => context.go('/ledger'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GallaSpacing.lg),

                    // ── 3. Action Center / Recommendations ──────────────
                    if (actions.isNotEmpty) ...[
                      const GallaSectionHeader(
                        title: 'Action Center',
                        topPadding: 0,
                        bottomPadding: GallaSpacing.sm,
                      ),
                      ...actions.take(3).map((act) {
                        return Padding(
                          padding: const EdgeInsets.only(
                            bottom: GallaSpacing.sm,
                          ),
                          child: GallaActionCard(
                            title: act.title,
                            badge: act.badge,
                            subtitle: act.subtitle,
                            actionLabel: act.actionLabel,
                            icon: act.icon,
                            badgeColor: act.badgeColor,
                            badgeBgColor: act.badgeBgColor,
                            iconColor: act.iconColor,
                            iconBgColor: act.iconBgColor,
                            onAction: () {
                              if (act.actionRoute.startsWith('/ledger')) {
                                context.push(act.actionRoute);
                              } else {
                                context.push(act.actionRoute);
                              }
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: GallaSpacing.md),
                    ],

                    // ── 4. Quick Actions Row ────────────────────────────
                    const GallaSectionHeader(
                      title: 'Quick Actions',
                      topPadding: 0,
                      bottomPadding: GallaSpacing.sm,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: GallaQuickActionButton(
                            label: 'Sale',
                            icon: Icons.add_rounded,
                            color: GallaColors.moneyIn,
                            bgColor: GallaColors.moneyInSoft,
                            onTap: () => showAddEntrySheet(
                              context,
                              initialDirection: Direction.moneyIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: GallaSpacing.sm),
                        Expanded(
                          child: GallaQuickActionButton(
                            label: 'Expense',
                            icon: Icons.remove_rounded,
                            color: GallaColors.moneyOut,
                            bgColor: GallaColors.moneyOutSoft,
                            onTap: () => showAddEntrySheet(
                              context,
                              initialDirection: Direction.moneyOut,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GallaSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: GallaQuickActionButton(
                            label: 'Invoice',
                            icon: Icons.receipt_long_outlined,
                            color: GallaColors.blue,
                            bgColor: GallaColors.blueSoft,
                            onTap: () => context.push('/invoices/create'),
                          ),
                        ),
                        const SizedBox(width: GallaSpacing.sm),
                        Expanded(
                          child: GallaQuickActionButton(
                            label: 'Voice',
                            icon: Icons.mic_rounded,
                            color: GallaColors.brand,
                            bgColor: GallaColors.brandSoft,
                            onTap: () => showVoiceEntryModal(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: GallaSpacing.lg),

                    // ── 5. Today's Entries ──────────────────────────────
                    GallaSectionHeader(
                      title:
                          DateUtils.isSameDay(
                            vm.selectedDay ?? DateTime.now(),
                            DateTime.now(),
                          )
                          ? "Today's Entries"
                          : DateFormat.MMMEd().format(
                              vm.selectedDay ?? DateTime.now(),
                            ),
                      trailing: vm.todayTxns.isNotEmpty
                          ? TextButton(
                              onPressed: () => context.go('/ledger'),
                              child: const Text('View All'),
                            )
                          : null,
                      topPadding: 0,
                    ),

                    if (vm.todayTxns.isEmpty)
                      GallaEmptyState(
                        icon: Icons.receipt_long_outlined,
                        headline: 'Your first entry starts today\'s Galla.',
                        body: s.nothingToday,
                        actionLabel: s.addEntry,
                        onAction: () => showAddEntrySheet(
                          context,
                          initialDirection: Direction.moneyIn,
                        ),
                      )
                    else
                      ...vm.todayTxns
                          .take(8)
                          .map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: GallaSpacing.sm,
                              ),
                              child: TransactionTile(
                                txn: t,
                                currency: settings.currency,
                                s: s,
                              ),
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
            child: const Icon(
              Icons.chevron_left_rounded,
              size: 18,
              color: GallaColors.muted,
            ),
          ),
        ),
        const SizedBox(width: GallaSpacing.sm),
        Expanded(
          child: Center(
            child: Text(
              isToday
                  ? 'Today, ${DateFormat('MMM d').format(day)}'
                  : DateFormat('EEE, MMM d, yyyy').format(day),
              style: GallaType.bodyStrong.copyWith(color: GallaColors.muted),
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
            child: const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: GallaColors.muted,
            ),
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
              child: Text(
                'Today',
                style: GallaType.chipLabel.copyWith(color: GallaColors.brand),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Router shim
class DayScreen extends StatelessWidget {
  const DayScreen({super.key, required this.date});
  final String date;

  @override
  Widget build(BuildContext context) => const GallaScreen();
}
