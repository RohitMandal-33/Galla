import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../domain/models.dart';
import '../../../shared/widgets/galla_components.dart';
import '../viewmodel/inventory_analytics_provider.dart';
import 'add_edit_item_dialog.dart';
import 'stock_adjustment_dialog.dart';

enum InventoryFilter { all, lowStock, fastMoving, slowMoving }

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  InventoryFilter _currentFilter = InventoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final currency = settings.currency;
    final inventoryAsync = ref.watch(inventoryProvider);
    final insights = ref.watch(inventoryAnalyticsProvider);

    return Scaffold(
      backgroundColor: GallaColors.canvas,
      appBar: AppBar(
        title: const Text('Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Product',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const AddEditItemDialog(),
              );
            },
          ),
        ],
      ),
      body: inventoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (allItems) {
          final lowStockItems = allItems.where((i) => i.isLowStock).toList();
          final totalValueMinor = allItems.fold<int>(
            0,
            (sum, i) => sum + i.inventoryValueMinor,
          );

          final filtered = allItems.where((item) {
            final insight = insights[item.id];
            if (_currentFilter == InventoryFilter.lowStock &&
                !item.isLowStock) {
              return false;
            }
            if (_currentFilter == InventoryFilter.fastMoving &&
                insight?.movement != ItemMovement.fastMoving) {
              return false;
            }
            if (_currentFilter == InventoryFilter.slowMoving &&
                insight?.movement != ItemMovement.slowMoving) {
              return false;
            }

            if (_searchQuery.isNotEmpty) {
              final q = _searchQuery.toLowerCase();
              final nameMatch = item.name.toLowerCase().contains(q);
              final skuMatch = (item.sku ?? '').toLowerCase().contains(q);
              if (!nameMatch && !skuMatch) return false;
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Summary Cards
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: GallaColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: GallaColors.line),
                          boxShadow: GallaElevation.card,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Stock Value',
                              style: GallaType.captionSm,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Money(
                                totalValueMinor,
                                currency: currency,
                              ).format(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GallaType.number.copyWith(
                                color: GallaColors.brand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: lowStockItems.isNotEmpty
                              ? GallaColors.moneyOutSoft
                              : GallaColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: lowStockItems.isNotEmpty
                                ? GallaColors.moneyOut
                                : GallaColors.line,
                          ),
                          boxShadow: GallaElevation.card,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Low Stock Items',
                                    style: GallaType.captionSm,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (lowStockItems.isNotEmpty) ...[
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 14,
                                    color: GallaColors.moneyOut,
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${lowStockItems.length} items',
                              style: GallaType.number.copyWith(
                                color: lowStockItems.isNotEmpty
                                    ? GallaColors.moneyOut
                                    : GallaColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Box
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products by name or SKU...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),

              // Filter Chips Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    GallaFilterChip(
                      label: 'All Items (${allItems.length})',
                      selected: _currentFilter == InventoryFilter.all,
                      onTap: () =>
                          setState(() => _currentFilter = InventoryFilter.all),
                    ),
                    const SizedBox(width: 6),
                    GallaFilterChip(
                      label: 'Low Stock (${lowStockItems.length})',
                      selected: _currentFilter == InventoryFilter.lowStock,
                      selectedColor: GallaColors.moneyOut,
                      onTap: () => setState(
                        () => _currentFilter = InventoryFilter.lowStock,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GallaFilterChip(
                      label: 'Fast Moving',
                      selected: _currentFilter == InventoryFilter.fastMoving,
                      selectedColor: GallaColors.moneyIn,
                      onTap: () => setState(
                        () => _currentFilter = InventoryFilter.fastMoving,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GallaFilterChip(
                      label: 'Slow Moving',
                      selected: _currentFilter == InventoryFilter.slowMoving,
                      selectedColor: GallaColors.muted,
                      onTap: () => setState(
                        () => _currentFilter = InventoryFilter.slowMoving,
                      ),
                    ),
                  ],
                ),
              ),

              // Product List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: GallaEmptyState(
                          icon: Icons.inventory_2_outlined,
                          headline: 'No Products Found',
                          body:
                              'Add your store products to track stock, profit margins, and automated reorder alerts.',
                          actionLabel: 'Add Product',
                          onAction: () {
                            showDialog(
                              context: context,
                              builder: (_) => const AddEditItemDialog(),
                            );
                          },
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          4,
                          16,
                          MediaQuery.paddingOf(context).bottom +
                              GallaSpacing.shellBottomClearance,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final item = filtered[i];
                          final insight = insights[item.id];
                          return _ProductCard(
                            item: item,
                            insight: insight,
                            currency: currency,
                            onEdit: () {
                              showDialog(
                                context: context,
                                builder: (_) => AddEditItemDialog(item: item),
                              );
                            },
                            onAdjust: () {
                              showDialog(
                                context: context,
                                builder: (_) =>
                                    StockAdjustmentDialog(item: item),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.insight,
    required this.currency,
    required this.onEdit,
    required this.onAdjust,
  });

  final InventoryItem item;
  final InventoryInsight? insight;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final double? marginPct = insight?.grossMarginPct;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GallaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isLowStock
              ? GallaColors.moneyOut.withValues(alpha: 0.4)
              : GallaColors.line,
        ),
        boxShadow: GallaElevation.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Name + Status Badge + Actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: item.isLowStock
                      ? GallaColors.moneyOutSoft
                      : GallaColors.brandSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: item.isLowStock
                      ? GallaColors.moneyOut
                      : GallaColors.brand,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.name,
                            style: GallaType.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.isLowStock) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: GallaColors.moneyOutSoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Low Stock',
                              style: GallaType.badge.copyWith(
                                color: GallaColors.moneyOut,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.currentQuantity == item.currentQuantity.toInt() ? item.currentQuantity.toInt() : item.currentQuantity} ${item.unit} available',
                      style: GallaType.label.copyWith(
                        color: item.isLowStock
                            ? GallaColors.moneyOut
                            : GallaColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(),
          const SizedBox(height: 6),

          // Row 2: Financials & Smart Forecasts
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sale Price',
                    style: GallaType.captionSm.copyWith(fontSize: 10),
                  ),
                  Text(
                    Money(item.salePriceMinor, currency: currency).format(),
                    style: GallaType.subtitleSm,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Margin',
                    style: GallaType.captionSm.copyWith(fontSize: 10),
                  ),
                  Text(
                    marginPct == null
                        ? '—'
                        : '${marginPct.toStringAsFixed(0)}%',
                    style: GallaType.subtitleSm.copyWith(
                      color: marginPct != null && marginPct >= 15
                          ? GallaColors.moneyIn
                          : GallaColors.ink,
                    ),
                  ),
                ],
              ),
              if (insight?.daysUntilStockout != null &&
                  insight!.daysUntilStockout! < 7)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Runout in',
                      style: GallaType.captionSm.copyWith(fontSize: 10),
                    ),
                    Text(
                      '~${insight!.daysUntilStockout!.toStringAsFixed(1)} days',
                      style: GallaType.subtitleSm.copyWith(
                        color: GallaColors.udhaar,
                      ),
                    ),
                  ],
                ),
              FilledButton.tonal(
                onPressed: onAdjust,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  minimumSize: const Size(60, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text('Count', style: GallaType.labelStrong),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
