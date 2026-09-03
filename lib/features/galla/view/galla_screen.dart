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

/// Home ("Galla") — today's cash position at a glance.
///
/// Vertical hierarchy: context header → cash hero → one primary action →
/// supporting metrics (flat) → attention items (only if actionable) →
/// today's activity.
class GallaScreen extends ConsumerWidget {
  const GallaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final vmAsync = ref.watch(gallaViewModelProvider);
    final parties = ref.watch(partiesProvider).valueOrNull ?? [];
    final actions = ref.watch(actionCenterProvider);

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
            titleSpacing: GallaSpacing.base,
            toolbarHeight: 76,
            title: _Header(settings: settings, s: s),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              GallaSpacing.base,
              0,
              GallaSpacing.base,
              MediaQuery.paddingOf(context).bottom +
                  GallaSpacing.shellBottomClearance,
            ),
            sliver: vmAsync.when(
              loading: () =>
                  const SliverToBoxAdapter(child: GallaHomeSkeletonLoader()),
              error: (e, _) => SliverToBoxAdapter(
                child: GallaEmptyState(
                  icon: Icons.error_outline_rounded,
                  headline: s.saveFailed,
                  body: e.toString(),
                  actionLabel: s.unlock,
                  onAction: () => ref.invalidate(gallaViewModelProvider),
                ),
              ),
              data: (vm) {
                final summary = vm.summary;
                // Real totals only — every figure below comes from recorded
                // transactions or party balances.
                final debtors =
                    parties.where((p) => p.balanceMinor > 0).toList()..sort(
                      (a, b) => b.balanceMinor.compareTo(a.balanceMinor),
                    );
                final toCollect = debtors.fold<int>(
                  0,
                  (sum, p) => sum + p.balanceMinor,
                );

                return SliverList(
                  delegate: SliverChildListDelegate([
                    _DayNavRow(
                      day: vm.selectedDay,
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

                    // ── Cash position ────────────────────────────────────
                    GallaBalanceCard(
                      label: s.cashAvailable,
                      cashOnHandMinor: summary?.cashOnHandMinor ?? 0,
                      moneyInMinor: summary?.inMinor ?? 0,
                      moneyOutMinor: summary?.outMinor ?? 0,
                      currency: settings.currency,
                      onViewReport: () => context.go('/reports'),
                    ),
                    const SizedBox(height: GallaSpacing.md),

                    // ── One primary action ────────────────────────────────
                    FilledButton.icon(
                      key: const ValueKey('home-add-transaction'),
                      onPressed: () => showQuickAddSheet(context),
                      icon: const Icon(Icons.add_rounded, size: 22),
                      label: Text(s.addTransaction),
                    ),
                    const SizedBox(height: GallaSpacing.xl),

                    // ── Supporting metrics (flat, real) ───────────────────
                    _MetricsRow(
                      salesMinor: summary?.inMinor ?? 0,
                      expensesMinor: summary?.outMinor ?? 0,
                      toCollectMinor: toCollect,
                      currency: settings.currency,
                      s: s,
                    ),
                    const SizedBox(height: GallaSpacing.md),

                    // ── Analytics shortcut (graphs) — only when there is data so the empty-state
                    // remains on-stage for the trust-loop widget test and for a clean first-run.
                    if (vm.txns.isNotEmpty || toCollect > 0) ...[
                      GestureDetector(
                        onTap: () => context.push('/analytics'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: GallaColors.surface,
                            borderRadius: BorderRadius.circular(GallaRadius.md),
                            border: Border.all(color: GallaColors.line),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: GallaColors.brandSoft,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.insights_rounded,
                                  size: 18,
                                  color: GallaColors.brand,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Analytics · Graphs',
                                      style: GallaType.subtitleSm,
                                    ),
                                    Text(
                                      'Sales trend, categories & cash pulse',
                                      style: GallaType.captionSm,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: GallaColors.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: GallaSpacing.md),
                    ],

                    // ── Attention items (only when actionable) ────────────
                    if (actions.isNotEmpty) ...[
                      const GallaSectionHeader(
                        title: 'Needs attention',
                        topPadding: GallaSpacing.sm,
                        bottomPadding: 0,
                      ),
                      ..._attentionRows(context, actions),
                      const SizedBox(height: GallaSpacing.lg),
                    ],

                    // ── Today's activity ──────────────────────────────────
                    GallaSectionHeader(
                      title: vm.isToday
                          ? s.todaysActivity
                          : DateFormat.MMMEd().format(vm.selectedDay),
                      topPadding: GallaSpacing.base,
                      bottomPadding: GallaSpacing.xs,
                      trailing: vm.txns.isNotEmpty
                          ? TextButton(
                              onPressed: () => context.go('/ledger'),
                              child: Text('View all'),
                            )
                          : null,
                    ),

                    if (vm.txns.isEmpty)
                      GallaEmptyState(
                        icon: Icons.receipt_long_outlined,
                        headline: s.noTxnsTitle,
                        body: s.noTxnsBody,
                        actionLabel: s.addEntry,
                        onAction: () => showAddEntrySheet(
                          context,
                          initialDirection: Direction.moneyIn,
                        ),
                      )
                    else
                      ..._txnList(
                        context,
                        vm.txns.take(10).toList(),
                        s,
                        settings.currency,
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

  List<Widget> _attentionRows(BuildContext context, List<ActionItem> actions) {
    final rows = <Widget>[];
    for (final act in actions.take(3)) {
      rows.add(
        GallaAttentionRow(
          key: ValueKey(act.id),
          title: act.title,
          subtitle: act.subtitle,
          actionLabel: act.actionLabel,
          icon: act.icon,
          iconColor: act.iconColor,
          iconBgColor: act.iconBgColor,
          onAction: () => context.push(act.actionRoute),
        ),
      );
      rows.add(const Divider(height: 1));
    }
    return rows;
  }

  List<Widget> _txnList(
    BuildContext context,
    List<Txn> txns,
    S s,
    String currency,
  ) {
    final widgets = <Widget>[];
    for (var i = 0; i < txns.length; i++) {
      widgets.add(TransactionTile(txn: txns[i], currency: currency, s: s));
      if (i != txns.length - 1) {
        widgets.add(const Divider(height: 1, indent: GallaSpacing.huge));
      }
    }
    return widgets;
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.settings, required this.s});
  final AppSettings settings;
  final S s;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : (hour < 17 ? 'Good afternoon' : 'Good evening');
    final hasName = settings.businessName.trim().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(greeting, style: GallaType.label),
              const SizedBox(height: 2),
              Text(
                DateFormat('EEEE, d MMMM').format(DateTime.now()),
                style: GallaType.number.copyWith(
                  fontSize: 17,
                  letterSpacing: -0.4,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => context.push('/profile'),
          child: Semantics(
            button: true,
            label: 'Business profile',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    hasName ? settings.businessName : 'Galla',
                    style: GallaType.bodyStrong.copyWith(
                      color: GallaColors.muted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: GallaSpacing.xs),
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: GallaColors.brand,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: hasName
                      ? Text(
                          settings.businessName
                              .trim()
                              .split(' ')
                              .map((w) => w.isNotEmpty ? w[0] : '')
                              .take(2)
                              .join()
                              .toUpperCase(),
                          style: GallaType.labelStrong.copyWith(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.storefront_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Flat metric strip ──────────────────────────────────────────────────────────

class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.salesMinor,
    required this.expensesMinor,
    required this.toCollectMinor,
    required this.currency,
    required this.s,
  });

  final int salesMinor;
  final int expensesMinor;
  final int toCollectMinor;
  final String currency;
  final S s;

  @override
  Widget build(BuildContext context) {
    const divider = SizedBox(
      width: 1,
      height: 34,
      child: ColoredBox(color: GallaColors.line),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: GallaSpacing.base),
      decoration: BoxDecoration(
        color: GallaColors.surfaceElevated,
        borderRadius: BorderRadius.circular(GallaRadius.md),
        border: Border.all(color: GallaColors.lineSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: GallaStatBlock(
              label: s.sales,
              value: Money(salesMinor, currency: currency).formatCompact(),
              valueColor: GallaColors.moneyIn,
              onTap: () => context.go('/reports'),
              alignment: CrossAxisAlignment.center,
            ),
          ),
          divider,
          Expanded(
            child: GallaStatBlock(
              label: s.expenses,
              value: Money(expensesMinor, currency: currency).formatCompact(),
              valueColor: GallaColors.ink,
              onTap: () => context.go('/reports'),
              alignment: CrossAxisAlignment.center,
            ),
          ),
          divider,
          Expanded(
            child: GallaStatBlock(
              label: s.toCollect,
              value: Money(toCollectMinor, currency: currency).formatCompact(),
              valueColor: toCollectMinor > 0 ? GallaColors.udhaar : null,
              onTap: () => context.go('/ledger'),
              alignment: CrossAxisAlignment.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Day navigation ─────────────────────────────────────────────────────────────

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
        _NavChevron(icon: Icons.chevron_left_rounded, onTap: onPrevious),
        Expanded(
          child: Center(
            child: Semantics(
              header: true,
              child: Text(
                isToday
                    ? 'Today · ${DateFormat('MMM d').format(day)}'
                    : DateFormat('EEE, MMM d').format(day),
                style: GallaType.bodyStrong.copyWith(color: GallaColors.muted),
              ),
            ),
          ),
        ),
        _NavChevron(
          icon: Icons.chevron_right_rounded,
          onTap: isToday ? null : onNext,
        ),
        if (!isToday) ...[
          const SizedBox(width: GallaSpacing.sm),
          GestureDetector(
            onTap: onToday,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: GallaColors.brandSoft,
                borderRadius: BorderRadius.circular(GallaRadius.sm),
              ),
              child: Text(
                'Today'.toUpperCase(),
                style: GallaType.chipLabel.copyWith(
                  fontSize: 11,
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

class _NavChevron extends StatelessWidget {
  const _NavChevron({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: GallaColors.surface,
          borderRadius: BorderRadius.circular(GallaRadius.sm),
          border: Border.all(color: GallaColors.line),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: onTap == null ? GallaColors.faint : GallaColors.muted,
        ),
      ),
    );
  }
}
