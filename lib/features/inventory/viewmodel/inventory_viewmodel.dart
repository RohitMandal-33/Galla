import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';

// ─── ViewModel ────────────────────────────────────────────────────────────────

class InventoryViewModel extends AsyncNotifier<List<InventoryItem>> {
  GallaRepository get _repo => ref.read(repositoryProvider);

  @override
  Future<List<InventoryItem>> build() async {
    return ref.watch(inventoryProvider).valueOrNull ?? [];
  }

  Future<void> addItem({
    required String name,
    String? sku,
    String unit = 'pcs',
    double initialQuantity = 0.0,
    double lowStockThreshold = 5.0,
    int costPriceMinor = 0,
    int salePriceMinor = 0,
  }) async {
    final branchId = ref.read(selectedBranchIdProvider);
    await _repo.addInventoryItem(
      name: name,
      sku: sku,
      unit: unit,
      initialQuantity: initialQuantity,
      lowStockThreshold: lowStockThreshold,
      costPriceMinor: costPriceMinor,
      salePriceMinor: salePriceMinor,
      branchId: branchId,
    );
    ref.invalidateSelf();
  }

  Future<void> updateItem(InventoryItem item) async {
    await _repo.updateInventoryItem(item);
    ref.invalidateSelf();
  }

  Future<void> adjustStock(String id, double newQty, String reason) async {
    await _repo.adjustStock(id, newQty, reason);
    ref.invalidateSelf();
  }

  Future<void> deleteItem(String id) async {
    await _repo.deleteInventoryItem(id);
    ref.invalidateSelf();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final inventoryViewModelProvider =
    AsyncNotifierProvider<InventoryViewModel, List<InventoryItem>>(InventoryViewModel.new);
