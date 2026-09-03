import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';
import '../../../shared/widgets/galla_components.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  ConsumerState<CreateInvoiceScreen> createState() =>
      _CreateInvoiceScreenState();
}

class _LineItemDraft {
  _LineItemDraft({
    this.description = '',
    this.quantity = 1.0,
    this.unitPriceMinor = 0,
    this.inventoryItemId,
  });

  String description;
  double quantity;
  int unitPriceMinor;
  String? inventoryItemId;

  int get totalMinor => (quantity * unitPriceMinor).round();
}

class _CreateInvoiceScreenState extends ConsumerState<CreateInvoiceScreen> {
  final _partyController = TextEditingController();
  final _notesController = TextEditingController();
  final _taxController = TextEditingController();
  DateTime _issueDate = DateTime.now();
  DateTime? _dueDate;
  double _taxRatePct = 0.0;
  String? _selectedPartyId;
  String? _selectedPartyName;
  bool _saving = false;

  final List<_LineItemDraft> _items = [
    _LineItemDraft(description: '', quantity: 1.0, unitPriceMinor: 0),
  ];

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings != null && settings.taxRatePct > 0) {
      _taxRatePct = settings.taxRatePct;
      _taxController.text = '${settings.taxRatePct}';
    }
  }

  @override
  void dispose() {
    _partyController.dispose();
    _notesController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  int get _subtotalMinor => _items.fold<int>(0, (sum, i) => sum + i.totalMinor);
  int get _taxMinor => ((_subtotalMinor * _taxRatePct) / 100).round();
  int get _totalMinor => _subtotalMinor + _taxMinor;

  Future<void> _saveInvoice() async {
    final partyName = _partyController.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (partyName.isEmpty) {
      showGallaSnackBar(messenger, 'Please enter or select a customer name');
      return;
    }
    if (_dueDate != null && _dueDate!.isBefore(_issueDate)) {
      showGallaSnackBar(messenger, 'Due date cannot be before the issue date');
      return;
    }

    // Drop only rows the user left empty — never silently discard filled-in
    // items, and reject impossible values loudly.
    final validItems = <_LineItemDraft>[];
    var skipped = 0;
    for (final i in _items) {
      final desc = i.description.trim();
      if (desc.isEmpty && i.unitPriceMinor == 0) continue; // untouched row
      if (desc.isEmpty || i.unitPriceMinor <= 0) {
        skipped++;
        continue;
      }
      validItems.add(i);
    }

    if (validItems.isEmpty) {
      showGallaSnackBar(
        messenger,
        'Please add at least one line item with description and price',
      );
      return;
    }
    if (skipped > 0) {
      showGallaSnackBar(
        messenger,
        '$skipped incomplete item${skipped == 1 ? '' : 's'} not added',
      );
    }

    setState(() => _saving = true);
    try {
      final repo = ref.read(repositoryProvider);
      final branchId = ref.read(selectedBranchIdProvider);

      final invWithItems = await repo.createInvoice(
        partyId: _selectedPartyId,
        partyName: partyName,
        issueDate: _issueDate,
        dueDate: _dueDate,
        taxRatePct: _taxRatePct,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        branchId: branchId,
        items: validItems
            .map(
              (i) => (
                description: i.description.trim(),
                quantity: i.quantity,
                unitPriceMinor: i.unitPriceMinor,
                inventoryItemId: i.inventoryItemId,
              ),
            )
            .toList(),
      );

      if (mounted) {
        context.pop();
        context.push('/invoices/${invWithItems.invoice.id}');
      }
    } catch (e) {
      if (mounted) {
        showGallaSnackBar(
          ScaffoldMessenger.of(context),
          'Error: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final currency = settings.currency;
    final parties = ref.watch(partiesProvider).valueOrNull ?? [];
    final inventory = ref.watch(inventoryProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(s.createInvoice)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // Customer / Party Section
          Text(s.parties, style: GallaType.cardTitle),
          const SizedBox(height: 8),
          Autocomplete<Party>(
            optionsBuilder: (textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<Party>.empty();
              }
              return parties.where(
                (p) => p.name.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                ),
              );
            },
            displayStringForOption: (p) => p.name,
            onSelected: (p) {
              _selectedPartyId = p.id;
              _selectedPartyName = p.name;
              _partyController.text = p.name;
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
                  controller.addListener(() {
                    _partyController.text = controller.text;
                    // Editing the text manually must not keep pointing at a
                    // previously selected party — the invoice would otherwise
                    // attach to the wrong customer.
                    if (_selectedPartyName != null &&
                        controller.text.trim() != _selectedPartyName) {
                      _selectedPartyId = null;
                      _selectedPartyName = null;
                    }
                  });
                  return TextField(
                    key: const ValueKey('invoice-party-field'),
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: '${s.parties} / Customer',
                      hintText: 'e.g. Ramesh Traders',
                      filled: true,
                      fillColor: GallaColors.surface,
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  );
                },
          ),
          const SizedBox(height: 16),

          // Dates Row
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _issueDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _issueDate = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Issue Date',
                      filled: true,
                      fillColor: GallaColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      DateFormat.yMMMd().format(_issueDate),
                      style: GallaType.body.copyWith(fontSize: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _dueDate ?? _issueDate.add(const Duration(days: 14)),
                      firstDate: _issueDate,
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: s.dueDate,
                      filled: true,
                      fillColor: GallaColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _dueDate != null
                          ? DateFormat.yMMMd().format(_dueDate!)
                          : 'Optional',
                      style: GallaType.body.copyWith(
                        fontSize: 14,
                        color: _dueDate != null
                            ? GallaColors.ink
                            : GallaColors.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Items Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(s.lineItems, style: GallaType.cardTitle),
              if (inventory.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _pickFromInventory(inventory),
                  icon: const Icon(Icons.inventory_2_outlined, size: 18),
                  label: const Text('Add from Stock'),
                ),
            ],
          ),
          const SizedBox(height: 8),

          ..._items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return _buildItemRow(idx, item, currency);
          }),

          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _items.add(
                  _LineItemDraft(
                    description: '',
                    quantity: 1.0,
                    unitPriceMinor: 0,
                  ),
                );
              });
            },
            icon: const Icon(Icons.add),
            label: Text(s.addItem),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Tax & Notes
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: s.taxRate,
                    hintText: '0',
                    suffixText: '%',
                    filled: true,
                    fillColor: GallaColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  controller: _taxController,
                  onChanged: (v) {
                    final parsed = double.tryParse(v.trim());
                    setState(() {
                      // Tax must be a real percentage — negatives or nonsense
                      // fall back to zero rather than corrupting the total.
                      _taxRatePct = (parsed == null || parsed < 0)
                          ? 0.0
                          : parsed > 100
                          ? 100.0
                          : parsed;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: s.noteHint,
              hintText: 'Payment terms, bank details, or thank you note',
              filled: true,
              fillColor: GallaColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Total Calculation Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GallaColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GallaColors.line),
            ),
            child: Column(
              children: [
                _calcRow(
                  s.subtotal,
                  Money(_subtotalMinor, currency: currency).format(),
                ),
                if (_taxRatePct > 0)
                  _calcRow(
                    '${s.tax} ($_taxRatePct%)',
                    Money(_taxMinor, currency: currency).format(),
                  ),
                const Divider(),
                _calcRow(
                  s.total,
                  Money(_totalMinor, currency: currency).format(),
                  isBold: true,
                  fontSize: 18,
                  color: GallaColors.brand,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _saveInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: GallaColors.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      '${s.save} & Generate Invoice',
                      style: GallaType.cardTitle,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int idx, _LineItemDraft item, String currency) {
    // Keyed by object identity so deleting a row never shifts another row's
    // text fields onto the wrong draft.
    return Container(
      key: ValueKey(item),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GallaColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: GallaColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.description,
                  decoration: InputDecoration(
                    labelText: 'Item / Description #${idx + 1}',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => item.description = v,
                ),
              ),
              if (_items.length > 1)
                IconButton(
                  tooltip: 'Remove item',
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    setState(() => _items.removeAt(idx));
                  },
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  initialValue: item.quantity == item.quantity.toInt()
                      ? '${item.quantity.toInt()}'
                      : '${item.quantity}',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Qty',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) {
                    setState(() {
                      final parsed = double.tryParse(v);
                      // Quantity must be positive; invalid input keeps 1
                      // instead of silently corrupting the total.
                      item.quantity = parsed == null || parsed <= 0
                          ? 1.0
                          : parsed;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  initialValue: item.unitPriceMinor > 0
                      ? '${item.unitPriceMinor ~/ 100}'
                      : '',
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Unit Price ($currency)',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) {
                    setState(() {
                      // Prices are whole major units here; negatives rejected.
                      final val = int.tryParse(v.trim()) ?? 0;
                      item.unitPriceMinor = val < 0 ? 0 : val * 100;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: GallaType.captionSm.copyWith(fontSize: 10),
                  ),
                  Text(
                    Money(item.totalMinor, currency: currency).format(),
                    style: GallaType.subtitleSm,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calcRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 14,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
              color: color ?? GallaColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  void _pickFromInventory(List<InventoryItem> inventory) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: inventory.length,
          itemBuilder: (context, idx) {
            final item = inventory[idx];
            return ListTile(
              title: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Stock: ${item.currentQuantity} ${item.unit}'),
              trailing: Text(
                'Price: ${item.salePriceMinor ~/ 100}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () {
                setState(() {
                  _items.add(
                    _LineItemDraft(
                      description: item.name,
                      quantity: 1.0,
                      unitPriceMinor: item.salePriceMinor,
                      inventoryItemId: item.id,
                    ),
                  );
                });
                Navigator.pop(ctx);
              },
            );
          },
        );
      },
    );
  }
}
