import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';

class AddEditItemDialog extends ConsumerStatefulWidget {
  const AddEditItemDialog({super.key, this.item});
  final InventoryItem? item;

  @override
  ConsumerState<AddEditItemDialog> createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends ConsumerState<AddEditItemDialog> {
  final _name = TextEditingController();
  final _sku = TextEditingController();
  final _unit = TextEditingController(text: 'pcs');
  final _quantity = TextEditingController(text: '0');
  final _threshold = TextEditingController(text: '5');
  final _cost = TextEditingController(text: '0');
  final _sale = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      final i = widget.item!;
      _name.text = i.name;
      _sku.text = i.sku ?? '';
      _unit.text = i.unit;
      _quantity.text = i.currentQuantity == i.currentQuantity.toInt()
          ? '${i.currentQuantity.toInt()}'
          : '${i.currentQuantity}';
      _threshold.text = i.lowStockThreshold == i.lowStockThreshold.toInt()
          ? '${i.lowStockThreshold.toInt()}'
          : '${i.lowStockThreshold}';
      _cost.text = '${i.costPriceMinor ~/ 100}';
      _sale.text = '${i.salePriceMinor ~/ 100}';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _unit.dispose();
    _quantity.dispose();
    _threshold.dispose();
    _cost.dispose();
    _sale.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;

    final repo = ref.read(repositoryProvider);
    final branchId = ref.read(selectedBranchIdProvider);
    final qty = double.tryParse(_quantity.text.trim()) ?? 0.0;
    final thres = double.tryParse(_threshold.text.trim()) ?? 5.0;
    final cost = (int.tryParse(_cost.text.trim()) ?? 0) * 100;
    final sale = (int.tryParse(_sale.text.trim()) ?? 0) * 100;

    if (widget.item == null) {
      await repo.addInventoryItem(
        name: name,
        sku: _sku.text.trim().isEmpty ? null : _sku.text.trim(),
        unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
        initialQuantity: qty,
        lowStockThreshold: thres,
        costPriceMinor: cost,
        salePriceMinor: sale,
        branchId: branchId,
      );
    } else {
      final updated = InventoryItem(
        id: widget.item!.id,
        name: name,
        sku: _sku.text.trim().isEmpty ? null : _sku.text.trim(),
        unit: _unit.text.trim().isEmpty ? 'pcs' : _unit.text.trim(),
        currentQuantity: qty,
        lowStockThreshold: thres,
        costPriceMinor: cost,
        salePriceMinor: sale,
        branchId: widget.item!.branchId,
        createdAt: widget.item!.createdAt,
        updatedAt: DateTime.now(),
      );
      await repo.updateInventoryItem(updated);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final isEdit = widget.item != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Item' : s.addItemStock),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              autofocus: !isEdit,
              decoration: InputDecoration(
                labelText: 'Item Name *',
                hintText: 'e.g. Basmati Rice (25kg)',
                filled: true,
                fillColor: GallaColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sku,
                    decoration: InputDecoration(
                      labelText: 'SKU / Code',
                      filled: true,
                      fillColor: GallaColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _unit,
                    decoration: InputDecoration(
                      labelText: 'Unit',
                      hintText: 'pcs, kg, bag',
                      filled: true,
                      fillColor: GallaColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: s.stockQuantity,
                      filled: true,
                      fillColor: GallaColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _threshold,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Alert Level',
                      filled: true,
                      fillColor: GallaColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cost,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '${s.costPrice} (${settings.currency})',
                      filled: true,
                      fillColor: GallaColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _sale,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '${s.salePrice} (${settings.currency})',
                      filled: true,
                      fillColor: GallaColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: GallaColors.brand,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(s.save),
        ),
      ],
    );
  }
}
