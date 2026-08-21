import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../domain/models.dart';
import '../../../shared/widgets/galla_components.dart';
import '../viewmodel/entry_viewmodel.dart';

Future<void> showAddEntrySheet(BuildContext context, {Direction initialDirection = Direction.moneyIn}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EntrySheet(initialDirection: initialDirection),
  );
}

// Global backward-compatible shim
Future<void> showEntrySheet(BuildContext context) => showAddEntrySheet(context);

class EntrySheet extends ConsumerStatefulWidget {
  const EntrySheet({super.key, this.initialDirection = Direction.moneyIn, this.seedParty});
  final Direction initialDirection;
  final Party? seedParty;

  @override
  ConsumerState<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<EntrySheet> {
  final _amountController = TextEditingController();
  final _partyController = TextEditingController();
  final _noteController = TextEditingController();
  final _speech = SpeechToText();
  bool _listening = false;
  bool _showMore = false;
  bool _savedSuccess = false;

  static const _incomeCategories = [
    'Sales', 'Services', 'Customer Payment', 'Commission', 'Interest', 'Other Income',
  ];

  static const _expenseCategories = [
    'Purchase / Stock', 'Rent', 'Staff / Salary', 'Electricity / Utility',
    'Transport', 'Personal / Drawings', 'Other Expense',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.seedParty != null) {
      _partyController.text = widget.seedParty!.name;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _partyController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _listen(EntryViewModel vm) async {
    final ok = await _speech.initialize();
    if (!ok) return;
    HapticFeedback.mediumImpact();
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (r) {
        if (r.finalResult) {
          vm.applyNl(r.recognizedWords);
          setState(() => _listening = false);
        }
      },
    );
  }

  Future<void> _pickPhoto(EntryViewModel vm) async {
    final file = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 70);
    if (file == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dest = File(p.join(dir.path, 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg'));
    await File(file.path).copy(dest.path);
    vm.setPhoto(dest.path);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(entryViewModelProvider(widget.initialDirection));
    final vm = ref.read(entryViewModelProvider(widget.initialDirection).notifier);
    final parties = ref.watch(partiesProvider).valueOrNull ?? const <Party>[];
    final inventory = ref.watch(inventoryProvider).valueOrNull ?? const <InventoryItem>[];
    final isIncome = state.direction == Direction.moneyIn;
    final categories = isIncome ? _incomeCategories : _expenseCategories;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    // Sync controller with state
    if (_amountController.text.isNotEmpty) {
      final parsedMinor = Money.parseToMinor(_amountController.text);
      if (parsedMinor != state.amountMinor && state.amountMinor > 0) {
        _amountController.text = (state.amountMinor / 100).toStringAsFixed(
          state.amountMinor % 100 == 0 ? 0 : 2,
        );
      }
    } else if (state.amountMinor > 0) {
      _amountController.text = (state.amountMinor / 100).toStringAsFixed(
        state.amountMinor % 100 == 0 ? 0 : 2,
      );
    }

    if (state.partyName != null && _partyController.text != state.partyName) {
      _partyController.text = state.partyName!;
    }
    if (state.note != null && _noteController.text != state.note) {
      _noteController.text = state.note!;
    }

    final activeColor = isIncome ? GallaColors.moneyIn : GallaColors.moneyOut;

    return Container(
      decoration: const BoxDecoration(
        color: GallaColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(GallaRadius.bottomSheet)),
      ),
      padding: EdgeInsets.fromLTRB(GallaSpacing.lg, 0, GallaSpacing.lg, GallaSpacing.lg + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Handle ──────────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: GallaSpacing.md),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: GallaColors.line,
                  borderRadius: BorderRadius.circular(GallaRadius.pill),
                ),
              ),
            ),

            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: GallaColors.canvas,
                      borderRadius: BorderRadius.circular(GallaRadius.sm),
                      border: Border.all(color: GallaColors.line),
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: GallaColors.ink),
                  ),
                ),
                const SizedBox(width: GallaSpacing.md),
                const Text(
                  'New Entry',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: GallaColors.ink),
                ),
                const Spacer(),
                // Voice input button
                GestureDetector(
                  onTap: _listening ? () => _speech.stop() : () => _listen(vm),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _listening ? GallaColors.moneyOutSoft : GallaColors.brandSoft,
                      borderRadius: BorderRadius.circular(GallaRadius.sm),
                    ),
                    child: Icon(
                      _listening ? Icons.stop_rounded : Icons.mic_none_rounded,
                      color: _listening ? GallaColors.moneyOut : GallaColors.brand,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GallaSpacing.base),

            // ── Income / Expense Toggle ──────────────────────────────────
            Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: GallaColors.canvas,
                borderRadius: BorderRadius.circular(GallaRadius.md),
                border: Border.all(color: GallaColors.line),
              ),
              child: Row(
                children: [
                  _DirectionTab(
                    label: '+ Income',
                    isSelected: isIncome,
                    selectedColor: GallaColors.moneyIn,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      vm.setDirection(Direction.moneyIn);
                      vm.setCategory(null);
                    },
                  ),
                  _DirectionTab(
                    label: '− Expense',
                    isSelected: !isIncome,
                    selectedColor: GallaColors.moneyOut,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      vm.setDirection(Direction.moneyOut);
                      vm.setCategory(null);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: GallaSpacing.xl),

            // ── Amount Input ─────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Rs.',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: activeColor.withValues(alpha: 0.7),
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: GallaSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: activeColor,
                      letterSpacing: -1.5,
                      height: 1.0,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: GallaColors.line,
                        letterSpacing: -1.5,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onChanged: (v) {
                      final minor = Money.parseToMinor(v);
                      vm.setAmount(minor);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: GallaSpacing.md),

            // ── Quick amount chips ──────────────────────────────────────
            Row(
              children: [100, 500, 1000, 5000].map((amt) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        final next = state.amountMinor + (amt * 100);
                        vm.setAmount(next);
                        _amountController.text = (next / 100).toStringAsFixed(0);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: GallaColors.canvas,
                          borderRadius: BorderRadius.circular(GallaRadius.sm),
                          border: Border.all(color: GallaColors.line),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '+$amt',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: GallaColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: GallaSpacing.base),

            // ── Party Field ─────────────────────────────────────────────
            TextField(
              controller: _partyController,
              decoration: InputDecoration(
                labelText: 'Customer / Party',
                hintText: isIncome ? 'e.g. Hari, Sita Store' : 'e.g. Vegetable supplier',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              ),
              onChanged: (v) => vm.setParty(v.trim().isEmpty ? null : v.trim()),
            ),
            if (parties.isNotEmpty) ...[
              const SizedBox(height: GallaSpacing.sm),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: parties.take(6).length,
                  separatorBuilder: (_, _) => const SizedBox(width: 6),
                  itemBuilder: (_, i) {
                    final pp = parties[i];
                    return GestureDetector(
                      onTap: () {
                        _partyController.text = pp.name;
                        vm.setParty(pp.name);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: GallaColors.canvas,
                          borderRadius: BorderRadius.circular(GallaRadius.pill),
                          border: Border.all(color: GallaColors.line),
                        ),
                        child: Text(
                          pp.name,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: GallaSpacing.md),

            // ── Payment Method (Cash / Udhaar) ──────────────────────────
            GallaPaymentMethodSelector(
              isUdhaar: state.isUdhaar,
              onChanged: (v) {
                HapticFeedback.selectionClick();
                vm.setUdhaar(v);
              },
            ),
            const SizedBox(height: GallaSpacing.md),

            // ── Category (horizontal scroll) ────────────────────────────
            Text(
              'Category',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: GallaColors.inkSecondary,
                  ),
            ),
            const SizedBox(height: GallaSpacing.sm),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final cat = categories[i];
                  final isSelected = state.category == cat;
                  final bg = isSelected
                      ? (isIncome ? GallaColors.moneyIn : GallaColors.moneyOut)
                      : GallaColors.canvas;
                  final fg = isSelected ? Colors.white : GallaColors.ink;
                  final border = isSelected ? Colors.transparent : GallaColors.line;
                  return GestureDetector(
                    onTap: () => vm.setCategory(isSelected ? null : cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(GallaRadius.pill),
                        border: Border.all(color: border),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: GallaSpacing.base),

            // ── More details (collapsible) ───────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _showMore = !_showMore),
              child: Row(
                children: [
                  Icon(
                    _showMore ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: GallaColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showMore ? 'Less details' : 'More details',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: GallaColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _showMore
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: GallaSpacing.md),

                        // Note field
                        TextField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Note (Optional)',
                            hintText: 'e.g. Sold groceries and snacks',
                            prefixIcon: Icon(Icons.edit_note_rounded, size: 20),
                          ),
                          onChanged: (v) => vm.setNote(v.trim().isEmpty ? null : v.trim()),
                        ),
                        const SizedBox(height: GallaSpacing.md),

                        // Inventory item link
                        if (inventory.isNotEmpty) ...[
                          DropdownButtonFormField<String?>(
                            initialValue: state.inventoryItemId,
                            decoration: const InputDecoration(
                              labelText: 'Stock Item (Optional)',
                              prefixIcon: Icon(Icons.inventory_2_outlined, size: 20),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('None')),
                              ...inventory.map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text('${item.name} (${item.currentQuantity} ${item.unit})'),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              vm.setInventoryItem(val);
                              if (val != null) {
                                final item = inventory.firstWhere((i) => i.id == val);
                                final price = isIncome ? item.salePriceMinor : item.costPriceMinor;
                                if (state.amountMinor == 0 && price > 0) {
                                  vm.setAmount(price);
                                  _amountController.text = (price / 100).toStringAsFixed(0);
                                }
                                if (_noteController.text.isEmpty) {
                                  _noteController.text = item.name;
                                  vm.setNote(item.name);
                                }
                              }
                            },
                          ),
                          const SizedBox(height: GallaSpacing.md),
                        ],

                        // Attach photo + repeat last
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () => _pickPhoto(vm),
                              icon: Icon(
                                state.photoPath != null ? Icons.check_circle_outline_rounded : Icons.camera_alt_outlined,
                                size: 16,
                              ),
                              label: Text(state.photoPath != null ? 'Photo Attached ✓' : 'Attach Bill Photo'),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                final txns = ref.read(transactionsProvider).valueOrNull ?? [];
                                vm.repeatLast(txns);
                              },
                              child: const Text('Repeat Last'),
                            ),
                          ],
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: GallaSpacing.base),

            // ── Save Button ──────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _savedSuccess
                  ? Center(
                      key: const ValueKey('success'),
                      child: GallaSuccessCheck(color: activeColor),
                    )
                  : FilledButton(
                      key: const ValueKey('save'),
                      style: FilledButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(GallaRadius.lg),
                        ),
                      ),
                      onPressed: state.isValid && !state.saving
                          ? () async {
                              HapticFeedback.mediumImpact();
                              final nav = Navigator.of(context);
                              final ok = await vm.save();
                              if (ok && mounted) {
                                setState(() => _savedSuccess = true);
                                await Future.delayed(const Duration(milliseconds: 500));
                                nav.pop();
                              }
                            }
                          : null,
                      child: state.saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              isIncome ? 'Save Income' : 'Save Expense',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Direction Tab ──────────────────────────────────────────────────────────────

class _DirectionTab extends StatelessWidget {
  const _DirectionTab({
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(GallaRadius.sm),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : GallaColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
