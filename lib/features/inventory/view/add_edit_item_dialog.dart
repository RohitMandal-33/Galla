import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';
import '../../../shared/widgets/galla_components.dart';

class AddEditItemDialog extends ConsumerStatefulWidget {
  const AddEditItemDialog({super.key, this.item});
  final InventoryItem? item;

  @override
  ConsumerState<AddEditItemDialog> createState() => _AddEditItemDialogState();
}

class _AddEditItemDialogState extends ConsumerState<AddEditItemDialog> {
  static const _defaultUnits = [
    'pcs',
    'kg',
    'gm',
    'ltr',
    'ml',
    'packet',
    'box',
    'bottle',
    'dozen',
    'bag',
    'can',
    'meter',
  ];

  final _name = TextEditingController();
  final _customUnit = TextEditingController();
  final _quantity = TextEditingController(text: '0');
  final _threshold = TextEditingController(text: '5');
  final _cost = TextEditingController(text: '0');
  final _sale = TextEditingController(text: '0');

  String _selectedUnit = 'pcs';
  bool _isCustomUnit = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      final i = widget.item!;
      _name.text = i.name;
      if (_defaultUnits.contains(i.unit)) {
        _selectedUnit = i.unit;
        _isCustomUnit = false;
      } else {
        _selectedUnit = 'custom';
        _isCustomUnit = true;
        _customUnit.text = i.unit;
      }
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
    _customUnit.dispose();
    _quantity.dispose();
    _threshold.dispose();
    _cost.dispose();
    _sale.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final name = _name.text.trim();
    if (name.isEmpty) {
      showGallaSnackBar(messenger, 'Give the item a name first');
      return;
    }

    final unit = _isCustomUnit
        ? (_customUnit.text.trim().isEmpty ? 'pcs' : _customUnit.text.trim())
        : _selectedUnit;

    double parsePositive(String raw, double fallback) {
      final v = double.tryParse(raw.trim());
      if (v == null || v < 0) return fallback;
      return v;
    }

    final repo = ref.read(repositoryProvider);
    final branchId = ref.read(selectedBranchIdProvider);
    // Negative stock/prices are never valid input — fall back instead of
    // silently writing impossible numbers into the books.
    final qty = parsePositive(_quantity.text.trim(), 0.0);
    final thres = parsePositive(_threshold.text.trim(), 5.0);
    final cost = (int.tryParse(_cost.text.trim()) ?? 0) < 0
        ? 0
        : (int.tryParse(_cost.text.trim()) ?? 0) * 100;
    final sale = (int.tryParse(_sale.text.trim()) ?? 0) < 0
        ? 0
        : (int.tryParse(_sale.text.trim()) ?? 0) * 100;

    try {
      if (widget.item == null) {
        await repo.addInventoryItem(
          name: name,
          sku: null,
          unit: unit,
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
          sku: widget.item!.sku,
          unit: unit,
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
      if (mounted) navigator.pop();
    } catch (_) {
      showGallaSnackBar(messenger, S('en').saveFailed);
    }
  }

  Future<void> _delete() async {
    final item = widget.item!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item?'),
        content: Text('"${item.name}" will be removed from your stock list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: GallaColors.moneyOut,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(repositoryProvider).deleteInventoryItem(item.id);
    if (!mounted) return;
    Navigator.of(context).pop();
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
            DropdownButtonFormField<String>(
              initialValue: _selectedUnit,
              decoration: InputDecoration(
                labelText: 'Unit *',
                filled: true,
                fillColor: GallaColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: [
                ..._defaultUnits.map(
                  (u) => DropdownMenuItem(value: u, child: Text(u)),
                ),
                const DropdownMenuItem(
                  value: 'custom',
                  child: Text('Custom (enter manually)...'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedUnit = val;
                    _isCustomUnit = val == 'custom';
                  });
                }
              },
            ),
            if (_isCustomUnit) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _customUnit,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Custom Unit Name *',
                  hintText: 'e.g. bundle, roll, sack, tin',
                  filled: true,
                  fillColor: GallaColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
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
        if (isEdit)
          TextButton(
            style: TextButton.styleFrom(foregroundColor: GallaColors.moneyOut),
            onPressed: _delete,
            child: const Text('Delete'),
          ),
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
