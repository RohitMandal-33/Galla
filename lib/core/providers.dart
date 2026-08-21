import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/galla_repository.dart';
import '../domain/models.dart';

final settingsProvider = StreamProvider<AppSettings>((ref) {
  return ref.watch(repositoryProvider).watchSettings();
});

final selectedBranchIdProvider = StateProvider<String?>((ref) {
  return ref.watch(settingsProvider).valueOrNull?.activeBranchId;
});

final transactionsProvider = StreamProvider<List<Txn>>((ref) {
  final branchId = ref.watch(selectedBranchIdProvider);
  return ref.watch(repositoryProvider).watchTransactions(branchId: branchId);
});

final partiesProvider = StreamProvider<List<Party>>((ref) {
  return ref.watch(repositoryProvider).watchParties();
});

final selectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final stringsLocaleProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).valueOrNull?.locale ?? 'en';
});

// Version 2 Providers
final invoicesProvider = StreamProvider<List<Invoice>>((ref) {
  final branchId = ref.watch(selectedBranchIdProvider);
  return ref.watch(repositoryProvider).watchInvoices(branchId: branchId);
});

final inventoryProvider = StreamProvider<List<InventoryItem>>((ref) {
  final branchId = ref.watch(selectedBranchIdProvider);
  return ref.watch(repositoryProvider).watchInventory(branchId: branchId);
});

final lowStockItemsProvider = Provider<List<InventoryItem>>((ref) {
  final items = ref.watch(inventoryProvider).valueOrNull ?? [];
  return items.where((i) => i.isLowStock).toList();
});

final branchesProvider = StreamProvider<List<Branch>>((ref) {
  return ref.watch(repositoryProvider).watchBranches();
});

final staffMembersProvider = StreamProvider<List<StaffMember>>((ref) {
  return ref.watch(repositoryProvider).watchStaffMembers();
});

final reconciliationsProvider = StreamProvider<List<ReconciliationRecord>>((ref) {
  final branchId = ref.watch(selectedBranchIdProvider);
  return ref.watch(repositoryProvider).watchReconciliations(branchId: branchId);
});

final healthReportProvider = FutureProvider<BusinessHealthReport>((ref) {
  final now = DateTime.now();
  final branchId = ref.watch(selectedBranchIdProvider);
  return ref.watch(repositoryProvider).computeBusinessHealth(now, branchId: branchId);
});
