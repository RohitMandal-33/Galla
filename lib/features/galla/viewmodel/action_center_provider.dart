import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../domain/models.dart';

enum ActionType {
  overduePayment,
  lowStock,
  lowCash,
  weeklyGrowth,
  reconciliationNeeded,
}

class ActionItem {
  const ActionItem({
    required this.id,
    required this.type,
    required this.title,
    required this.badge,
    this.subtitle,
    required this.actionLabel,
    required this.actionRoute,
    this.actionPayload,
    this.icon = Icons.bolt_rounded,
    this.badgeColor = GallaColors.udhaar,
    this.badgeBgColor = GallaColors.udhaarSoft,
    this.iconColor = GallaColors.brand,
    this.iconBgColor = GallaColors.brandSoft,
  });

  final String id;
  final ActionType type;
  final String title;
  final String badge;
  final String? subtitle;
  final String actionLabel;
  final String actionRoute;
  final Object? actionPayload;
  final IconData icon;
  final Color badgeColor;
  final Color badgeBgColor;
  final Color iconColor;
  final Color iconBgColor;
}

final actionCenterProvider = Provider<List<ActionItem>>((ref) {
  final items = <ActionItem>[];
  final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
  final parties = ref.watch(partiesProvider).valueOrNull ?? [];
  final inventory = ref.watch(inventoryProvider).valueOrNull ?? [];
  final txns = ref.watch(transactionsProvider).valueOrNull ?? [];

  // 1. Overdue Udhaar / Credit Check
  final overdueParties = parties.where((p) => p.balanceMinor > 0).toList()
    ..sort((a, b) => b.balanceMinor.compareTo(a.balanceMinor));

  if (overdueParties.isNotEmpty) {
    final top = overdueParties.first;
    final formatted = Money(top.balanceMinor, currency: settings.currency).format();
    items.add(
      ActionItem(
        id: 'udhaar_${top.id}',
        type: ActionType.overduePayment,
        title: '${top.name} owes $formatted',
        badge: 'Payment Due',
        subtitle: top.phone != null && top.phone!.isNotEmpty
            ? 'Follow up via WhatsApp or SMS'
            : 'Review party ledger statement',
        actionLabel: 'Remind',
        actionRoute: '/ledger/parties/${top.id}',
        icon: Icons.notifications_active_outlined,
        badgeColor: GallaColors.udhaar,
        badgeBgColor: GallaColors.udhaarSoft,
        iconColor: GallaColors.udhaar,
        iconBgColor: GallaColors.udhaarSoft,
      ),
    );
  }

  // 2. Low Stock Check
  final lowStock = inventory.where((i) => i.isLowStock).toList()
    ..sort((a, b) => a.currentQuantity.compareTo(b.currentQuantity));

  if (lowStock.isNotEmpty) {
    final item = lowStock.first;
    items.add(
      ActionItem(
        id: 'stock_${item.id}',
        type: ActionType.lowStock,
        title: '${item.name} is running low',
        badge: '${item.currentQuantity.toStringAsFixed(0)} ${item.unit} left',
        subtitle: 'Threshold is ${item.lowStockThreshold.toStringAsFixed(0)} ${item.unit}',
        actionLabel: 'Restock',
        actionRoute: '/inventory',
        icon: Icons.inventory_2_outlined,
        badgeColor: GallaColors.moneyOut,
        badgeBgColor: GallaColors.moneyOutSoft,
        iconColor: GallaColors.moneyOut,
        iconBgColor: GallaColors.moneyOutSoft,
      ),
    );
  }

  // 3. Positive Sales Insight
  if (txns.length >= 5) {
    items.add(
      const ActionItem(
        id: 'sales_insight',
        type: ActionType.weeklyGrowth,
        title: 'Sales activity is active today',
        badge: 'Healthy',
        subtitle: 'Keep recording daily transactions to track profit margins',
        actionLabel: 'Insights',
        actionRoute: '/reports/pnl',
        icon: Icons.trending_up_rounded,
        badgeColor: GallaColors.moneyIn,
        badgeBgColor: GallaColors.moneyInSoft,
        iconColor: GallaColors.moneyIn,
        iconBgColor: GallaColors.moneyInSoft,
      ),
    );
  }

  // 4. Guided Till Reconciliation Check (End of day)
  final hour = DateTime.now().hour;
  if (hour >= 18) {
    items.add(
      const ActionItem(
        id: 'reconciliation_eod',
        type: ActionType.reconciliationNeeded,
        title: 'End of Day Till Count',
        badge: 'Daily Audit',
        subtitle: 'Match physical cash drawer with Galla records',
        actionLabel: 'Audit',
        actionRoute: '/reconciliation',
        icon: Icons.point_of_sale_rounded,
        badgeColor: GallaColors.blue,
        badgeBgColor: GallaColors.blueSoft,
        iconColor: GallaColors.blue,
        iconBgColor: GallaColors.blueSoft,
      ),
    );
  }

  return items;
});
