import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../domain/models.dart';

enum ActionType { paymentDue, lowStock, lowCash, reconciliationNeeded }

/// A single actionable, data-derived attention item. Every item shown here
/// must correspond to real application state — no filler insights.
class ActionItem {
  const ActionItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    required this.actionLabel,
    required this.actionRoute,
    this.icon = Icons.bolt_rounded,
    this.iconColor = GallaColors.brand,
    this.iconBgColor = GallaColors.brandSoft,
  });

  final String id;
  final ActionType type;
  final String title;
  final String? subtitle;
  final String actionLabel;
  final String actionRoute;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
}

final actionCenterProvider = Provider<List<ActionItem>>((ref) {
  final items = <ActionItem>[];
  final settings =
      ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
  final parties = ref.watch(partiesProvider).valueOrNull ?? [];
  final inventory = ref.watch(inventoryProvider).valueOrNull ?? [];
  final txns = ref.watch(transactionsProvider).valueOrNull ?? [];

  // 1. Largest outstanding customer balance.
  final debtors = parties.where((p) => p.balanceMinor > 0).toList()
    ..sort((a, b) => b.balanceMinor.compareTo(a.balanceMinor));
  if (debtors.isNotEmpty) {
    final top = debtors.first;
    items.add(
      ActionItem(
        id: 'udhaar_${top.id}',
        type: ActionType.paymentDue,
        title: debtors.length == 1
            ? '${top.name} owes ${Money(top.balanceMinor, currency: settings.currency).formatCompact()}'
            : '${debtors.length} payments due · ${top.name} owes the most',
        subtitle: 'Follow up and record the payment when it arrives',
        actionLabel: 'Remind',
        actionRoute: '/ledger/parties/${top.id}',
        icon: Icons.notifications_active_outlined,
        iconColor: GallaColors.udhaar,
        iconBgColor: GallaColors.udhaarSoft,
      ),
    );
  }

  // 2. Low stock — only when the merchant asked for stock alerts.
  if (settings.notifyLowStock) {
    final lowStock = inventory.where((i) => i.isLowStock).toList()
      ..sort((a, b) => a.currentQuantity.compareTo(b.currentQuantity));
    if (lowStock.isNotEmpty) {
      final item = lowStock.first;
      items.add(
        ActionItem(
          id: 'stock_${item.id}',
          type: ActionType.lowStock,
          title: lowStock.length > 1
              ? '${lowStock.length} products low in stock'
              : '${item.name} is running low',
          subtitle: lowStock.length > 1
              ? '${item.name} and others need restocking'
              : '${item.currentQuantity.toStringAsFixed(0)} ${item.unit} left',
          actionLabel: 'Restock',
          actionRoute: '/inventory',
          icon: Icons.inventory_2_outlined,
          iconColor: GallaColors.moneyOut,
          iconBgColor: GallaColors.moneyOutSoft,
        ),
      );
    }
  }

  // 3. End-of-day till count — shown late in the day, only once real cash
  // entries exist today.
  if (DateTime.now().hour >= 17 && _hasCashActivityToday(txns)) {
    items.add(
      const ActionItem(
        id: 'reconciliation_eod',
        type: ActionType.reconciliationNeeded,
        title: 'Count the till before closing',
        subtitle: 'Match physical cash with what Galla recorded today',
        actionLabel: 'Count',
        actionRoute: '/reconciliation',
        icon: Icons.point_of_sale_rounded,
        iconColor: GallaColors.blue,
        iconBgColor: GallaColors.blueSoft,
      ),
    );
  }

  return items;
});

bool _hasCashActivityToday(List<Txn> txns) {
  final now = DateTime.now();
  return txns.any(
    (t) =>
        !t.isWriteOff &&
        t.occurredAt.year == now.year &&
        t.occurredAt.month == now.month &&
        t.occurredAt.day == now.day,
  );
}
