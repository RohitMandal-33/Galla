import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../domain/models.dart';

enum ItemMovement { fastMoving, normal, slowMoving, deadStock }

class InventoryInsight {
  const InventoryInsight({
    required this.item,
    required this.avgDailySales,
    required this.daysUntilStockout,
    required this.recommendedReorder,
    required this.movement,
    this.grossMarginPct,
  });

  final InventoryItem item;
  final double avgDailySales;
  final double? daysUntilStockout;
  final double recommendedReorder;
  final ItemMovement movement;

  /// Null when cost or sale price is unknown — never guess a margin.
  final double? grossMarginPct;
}

final inventoryAnalyticsProvider = Provider<Map<String, InventoryInsight>>((
  ref,
) {
  final items = ref.watch(inventoryProvider).valueOrNull ?? [];
  final txns = ref.watch(transactionsProvider).valueOrNull ?? [];
  final result = <String, InventoryInsight>{};

  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));

  for (final item in items) {
    // Look at sales over past 30 days
    final itemSales = txns.where((t) {
      return t.inventoryItemId == item.id &&
          t.direction == Direction.moneyIn &&
          t.occurredAt.isAfter(thirtyDaysAgo);
    }).toList();

    final totalSold = itemSales.length
        .toDouble(); // Default 1 unit per txn if not specified
    final avgDaily = totalSold > 0 ? (totalSold / 30.0) : 0.0;

    double? stockoutDays;
    if (avgDaily > 0 && item.currentQuantity > 0) {
      stockoutDays = item.currentQuantity / avgDaily;
    } else if (item.currentQuantity <= 0) {
      stockoutDays = 0.0;
    }

    // Recommended reorder = 14 days of supply, floored at twice the low-stock
    // threshold and capped at 100. Bounds are ordered defensively — Dart's
    // num.clamp throws when lower > upper (thresholds are free-text input),
    // which used to take down the whole Inventory tab.
    final targetQty = avgDaily * 14.0;
    final floorQty = item.lowStockThreshold * 2.0;
    final safeFloor = floorQty.clamp(0.0, 100.0);
    final recommendedReorder = targetQty < safeFloor
        ? safeFloor
        : (targetQty > 100.0 ? 100.0 : targetQty);

    // Movement classification
    final ItemMovement movement;
    if (avgDaily >= 1.5) {
      movement = ItemMovement.fastMoving;
    } else if (totalSold == 0 &&
        item.createdAt.isBefore(now.subtract(const Duration(days: 14)))) {
      movement = ItemMovement.deadStock;
    } else if (avgDaily < 0.3 && totalSold > 0) {
      movement = ItemMovement.slowMoving;
    } else {
      movement = ItemMovement.normal;
    }

    // Margin % — unknown (not zero!) when prices are not recorded.
    final double? margin;
    if (item.salePriceMinor > 0 && item.costPriceMinor > 0) {
      margin =
          ((item.salePriceMinor - item.costPriceMinor) / item.salePriceMinor) *
          100.0;
    } else {
      margin = null;
    }

    result[item.id] = InventoryInsight(
      item: item,
      avgDailySales: avgDaily,
      daysUntilStockout: stockoutDays,
      recommendedReorder: recommendedReorder,
      movement: movement,
      grossMarginPct: margin,
    );
  }

  return result;
});
