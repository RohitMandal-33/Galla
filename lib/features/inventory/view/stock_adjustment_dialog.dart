import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';

class StockAdjustmentDialog extends ConsumerStatefulWidget {
  const StockAdjustmentDialog({super.key, required this.item});
  final InventoryItem item;

  @override
  ConsumerState<StockAdjustmentDialog> createState() =>
      _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends ConsumerState<StockAdjustmentDialog> {
  late final TextEditingController _qtyController;
  final _reasonController = TextEditingController(
    text: 'Physical Stock Count Audit',
  );

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.item.currentQuantity == widget.item.currentQuantity.toInt()
          ? '${widget.item.currentQuantity.toInt()}'
          : '${widget.item.currentQuantity}',
    );
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final currentQty = widget.item.currentQuantity;
    final enteredQty =
        double.tryParse(_qtyController.text.trim()) ?? currentQty;
    final delta = enteredQty - currentQty;

    return AlertDialog(
      title: Text('${s.adjustStock}: ${widget.item.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Recorded: $currentQty ${widget.item.unit}',
              style: GallaType.body.copyWith(
                fontSize: 14,
                color: GallaColors.muted,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'New Counted Quantity (${widget.item.unit})',
                filled: true,
                fillColor: GallaColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            if (delta != 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: delta > 0
                      ? GallaColors.moneyInSoft
                      : GallaColors.moneyOutSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  delta > 0
                      ? '+${delta.toStringAsFixed(1)} Surplus'
                      : '${delta.toStringAsFixed(1)} Shortage',
                  style: GallaType.chipLabel.copyWith(
                    color: delta > 0
                        ? GallaColors.moneyIn
                        : GallaColors.moneyOut,
                  ),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for Adjustment',
                filled: true,
                fillColor: GallaColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
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
          onPressed: () async {
            final qty = double.tryParse(_qtyController.text.trim());
            if (qty == null) return;
            await ref
                .read(repositoryProvider)
                .adjustStock(
                  widget.item.id,
                  qty,
                  _reasonController.text.trim(),
                );
            if (context.mounted) Navigator.pop(context);
          },
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
