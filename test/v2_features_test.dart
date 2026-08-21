import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galla/core/database/app_database.dart';
import 'package:galla/data/galla_repository.dart';
import 'package:galla/domain/models.dart';

void main() {
  late AppDatabase db;
  late GallaRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = GallaRepository(db);
  });

  tearDown(() => db.close());

  group('Version 2: Invoicing & Billing', () {
    test('createInvoice generates sequential number, calculates tax, and updates inventory & party balance', () async {
      // 1. Add inventory item
      final item = await repo.addInventoryItem(
        name: 'Basmati Rice 25kg',
        initialQuantity: 10.0,
        lowStockThreshold: 3.0,
        costPriceMinor: 200000,
        salePriceMinor: 250000,
      );

      // 2. Create invoice with 2 bags of rice
      final invWithItems = await repo.createInvoice(
        partyName: 'Sita Store',
        items: [
          (
            description: item.name,
            quantity: 2.0,
            unitPriceMinor: 250000,
            inventoryItemId: item.id,
          ),
        ],
        taxRatePct: 10.0,
      );

      final invoice = invWithItems.invoice;
      expect(invoice.invoiceNumber, 'INV-0001');
      expect(invoice.subtotalMinor, 500000); // 2 * 2500.00
      expect(invoice.taxMinor, 50000); // 10%
      expect(invoice.totalMinor, 550000);
      expect(invoice.status, InvoiceStatus.unpaid);

      // 3. Verify inventory auto-decremented from 10 to 8
      final updatedInv = await repo.watchInventory().first;
      expect(updatedInv.first.currentQuantity, 8.0);

      // 4. Verify party balance
      final parties = await repo.partiesWithBalances();
      expect(parties.single.name, 'Sita Store');
      expect(parties.single.balanceMinor, 550000);

      // 5. Record partial payment of 3000.00 (300000 minor)
      await repo.recordInvoicePayment(invoice.id, 300000);
      final refreshedInv = await repo.getInvoiceWithItems(invoice.id);
      expect(refreshedInv!.invoice.status, InvoiceStatus.partiallyPaid);
      expect(refreshedInv.invoice.paidAmountMinor, 300000);
      expect(refreshedInv.invoice.dueAmountMinor, 250000);

      // 6. Record remaining payment of 2500.00
      await repo.recordInvoicePayment(invoice.id, 250000);
      final finalInv = await repo.getInvoiceWithItems(invoice.id);
      expect(finalInv!.invoice.status, InvoiceStatus.paid);
      expect(finalInv.invoice.isFullyPaid, true);
    });
  });

  group('Version 2: Inventory Lite', () {
    test('Inventory stock adjustment & low stock alerts', () async {
      final item = await repo.addInventoryItem(
        name: 'Mustard Oil 1L',
        initialQuantity: 4.0,
        lowStockThreshold: 5.0,
        costPriceMinor: 15000,
        salePriceMinor: 18000,
      );

      expect(item.isLowStock, true); // 4.0 <= 5.0

      // Adjust stock to 10
      await repo.adjustStock(item.id, 10.0, 'Restock delivery');
      final items = await repo.watchInventory().first;
      expect(items.first.currentQuantity, 10.0);
      expect(items.first.isLowStock, false);
    });
  });

  group('Version 2: Guided Cash Reconciliation', () {
    test('Reconciliation detects discrepancy and creates explicit adjustment entry', () async {
      // Add initial sale of 1000.00
      await repo.addEntry(
        direction: Direction.moneyIn,
        amountMinor: 100000,
        category: 'Sales',
      );

      final summary = await repo.summaryFor(DateTime.now());
      expect(summary.cashOnHandMinor, 100000);

      // Physical cash count is 950.00 (shortage of 50.00 / 5000 minor)
      final rec = await repo.performReconciliation(
        countedCashMinor: 95000,
        expectedCashMinor: summary.cashOnHandMinor,
        createAdjustmentEntry: true,
        note: 'End of day till audit',
      );

      expect(rec.hasDiscrepancy, true);
      expect(rec.discrepancyMinor, -5000);
      expect(rec.adjustmentTxnId, isNotNull);

      // Verify adjusted cash on hand is now exactly 950.00
      final updatedSummary = await repo.summaryFor(DateTime.now());
      expect(updatedSummary.cashOnHandMinor, 95000);
    });
  });

  group('Version 2: Multi-Branch & Staff', () {
    test('Branch creation and filtering', () async {
      final b1 = await repo.createBranch('Main Store', isDefault: true);
      final b2 = await repo.createBranch('Branch 2 (Warehouse)');

      final branches = await repo.watchBranches().first;
      expect(branches.length, 2);

      // Record transaction for branch 2
      await repo.addEntry(
        direction: Direction.moneyIn,
        amountMinor: 50000,
        branchId: b2.id,
      );

      // Record transaction for branch 1
      await repo.addEntry(
        direction: Direction.moneyIn,
        amountMinor: 30000,
        branchId: b1.id,
      );

      final b2Txns = await repo.watchTransactions(branchId: b2.id).first;
      expect(b2Txns.length, 1);
      expect(b2Txns.first.amountMinor, 50000);

      final allTxns = await repo.watchTransactions().first;
      expect(allTxns.length, 2);
    });

    test('Staff member creation and PIN authentication', () async {
      final staff = await repo.createStaffMember(
        'Ramesh Staff',
        role: StaffRole.staff,
        pin: '1234',
      );

      expect(staff.role, StaffRole.staff);
      expect(await repo.verifyStaffPin(staff.id, '1234'), true);
      expect(await repo.verifyStaffPin(staff.id, '9999'), false);
    });
  });

  group('Version 2: Health Score & CSV Export', () {
    test('Business Health Score computation', () async {
      await repo.addEntry(
        direction: Direction.moneyIn,
        amountMinor: 100000, // Revenue 1000
      );
      await repo.addEntry(
        direction: Direction.moneyOut,
        amountMinor: 40000, // Expense 400
      );

      final health = await repo.computeBusinessHealth(DateTime.now());
      expect(health.overallScore >= 70, true);
      expect(health.metrics.isNotEmpty, true);
      expect(health.actionableInsights.isNotEmpty, true);
    });

    test('CSV export generates proper headers and rows', () async {
      await repo.addEntry(
        direction: Direction.moneyIn,
        amountMinor: 50000,
        partyName: 'Hari',
        note: 'Rice sale',
      );

      final csv = await repo.exportTransactionsCsv();
      expect(csv.contains('ID,Date,Direction,Amount,Party,Category,Note'), true);
      expect(csv.contains('500.0'), true);
      expect(csv.contains('Hari'), true);
    });
  });
}
