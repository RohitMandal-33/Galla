import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';
import 'add_edit_item_dialog.dart';
import 'stock_adjustment_dialog.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  String _searchQuery = '';
  bool _filterLowStockOnly = false;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final currency = settings.currency;
    final inventoryAsync = ref.watch(inventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.inventory),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: s.addItemStock,
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
          final totalValueMinor = allItems.fold<int>(0, (sum, i) => sum + i.inventoryValueMinor);

          final filtered = allItems.where((item) {
            if (_filterLowStockOnly && !item.isLowStock) return false;
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: GallaColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: GallaColors.line),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.totalInventoryValue, style: const TextStyle(fontSize: 11, color: GallaColors.muted)),
                            const SizedBox(height: 2),
                            Text(
                              Money(totalValueMinor, currency: currency).format(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: GallaColors.brand,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() => _filterLowStockOnly = !_filterLowStockOnly);
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _filterLowStockOnly
                                ? GallaColors.moneyOutSoft
                                : GallaColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: lowStockItems.isNotEmpty ? GallaColors.moneyOut : GallaColors.line,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(s.lowStockAlert, style: const TextStyle(fontSize: 11, color: GallaColors.muted)),
                                  if (lowStockItems.isNotEmpty) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.warning_amber_rounded, size: 14, color: GallaColors.moneyOut),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${lowStockItems.length} items',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: lowStockItems.isNotEmpty ? GallaColors.moneyOut : GallaColors.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search items by name or SKU...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: GallaColors.surface,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),

              // Item List
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.inventory_2_outlined, size: 48, color: GallaColors.muted),
                              const SizedBox(height: 12),
                              Text(
                                s.emptyInventory,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: GallaColors.muted),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => const AddEditItemDialog(),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: Text(s.addItemStock),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GallaColors.brand,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, idx) {
                          final item = filtered[idx];
                          final isLow = item.isLowStock;

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: GallaColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isLow ? GallaColors.moneyOut.withValues(alpha: 0.5) : GallaColors.line,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isLow ? GallaColors.moneyOutSoft : GallaColors.brandSoft,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    color: isLow ? GallaColors.moneyOut : GallaColors.brand,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                color: GallaColors.ink,
                                              ),
                                            ),
                                          ),
                                          if (isLow)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: GallaColors.moneyOutSoft,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                s.lowStockAlert,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w700,
                                                  color: GallaColors.moneyOut,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            'Stock: ${item.currentQuantity == item.currentQuantity.toInt() ? item.currentQuantity.toInt() : item.currentQuantity} ${item.unit}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: isLow ? GallaColors.moneyOut : GallaColors.ink,
                                            ),
                                          ),
                                          if (item.salePriceMinor > 0) ...[
                                            const Text(' · ', style: TextStyle(color: GallaColors.muted)),
                                            Text(
                                              'Sale: ${Money(item.salePriceMinor, currency: currency).format()}',
                                              style: const TextStyle(fontSize: 12, color: GallaColors.muted),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, color: GallaColors.muted),
                                  onSelected: (action) async {
                                    if (action == 'adjust') {
                                      showDialog(
                                        context: context,
                                        builder: (_) => StockAdjustmentDialog(item: item),
                                      );
                                    } else if (action == 'edit') {
                                      showDialog(
                                        context: context,
                                        builder: (_) => AddEditItemDialog(item: item),
                                      );
                                    } else if (action == 'delete') {
                                      await ref.read(repositoryProvider).deleteInventoryItem(item.id);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    PopupMenuItem(
                                      value: 'adjust',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.tune, size: 18),
                                          const SizedBox(width: 8),
                                          Text(s.adjustStock),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Edit Item'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Delete', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddEditItemDialog(),
          );
        },
        backgroundColor: GallaColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(s.addItemStock),
      ),
    );
  }
}
