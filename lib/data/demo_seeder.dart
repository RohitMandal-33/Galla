import 'package:flutter/foundation.dart';
import '../domain/models.dart';
import 'galla_repository.dart';

class DemoSeeder {
  static Future<void> seedNepaliKirana(GallaRepository repo) async {
    debugPrint('🌱 Seeding Shree Ganesh Kirana Pasal demo data...');

    // 1. Settings
    final currentSettings = await repo.loadSettings();
    await repo.saveSettings(
      currentSettings.copyWith(
        businessName: 'Shree Ganesh Kirana',
        currency: 'NPR',
        locale: 'ne',
        onboardingDone: true,
        notifyPaymentDue: true,
        notifyLowStock: true,
      ),
    );

    // 2. Inventory Items
    final oil = await repo.addInventoryItem(
      name: 'Dhara Mustard Oil 1L',
      sku: 'OIL-1L',
      unit: 'bottle',
      initialQuantity: 18.0,
      lowStockThreshold: 8.0,
      costPriceMinor: 22000, // NPR 220
      salePriceMinor: 26000, // NPR 260
    );

    final rice = await repo.addInventoryItem(
      name: 'Basmati Rice 25kg',
      sku: 'RICE-25KG',
      unit: 'bag',
      initialQuantity: 6.0,
      lowStockThreshold: 5.0,
      costPriceMinor: 210000, // NPR 2100
      salePriceMinor: 245000, // NPR 2450
    );

    final waiwai = await repo.addInventoryItem(
      name: 'Wai Wai Noodles (Box)',
      sku: 'NOODLE-BOX',
      unit: 'box',
      initialQuantity: 12.0,
      lowStockThreshold: 4.0,
      costPriceMinor: 55000, // NPR 550
      salePriceMinor: 65000, // NPR 650
    );

    final tea = await repo.addInventoryItem(
      name: 'Tokla CTC Tea 500g',
      sku: 'TEA-500G',
      unit: 'pkt',
      initialQuantity: 14.0,
      lowStockThreshold: 6.0,
      costPriceMinor: 24000, // NPR 240
      salePriceMinor: 28000, // NPR 280
    );

    final sugar = await repo.addInventoryItem(
      name: 'Local White Sugar 1kg',
      sku: 'SUGAR-1KG',
      unit: 'kg',
      initialQuantity: 45.0,
      lowStockThreshold: 15.0,
      costPriceMinor: 9500, // NPR 95
      salePriceMinor: 11000, // NPR 110
    );

    final soap = await repo.addInventoryItem(
      name: 'Lifebuoy Soap 125g',
      sku: 'SOAP-125G',
      unit: 'pcs',
      initialQuantity: 28.0,
      lowStockThreshold: 10.0,
      costPriceMinor: 4200, // NPR 42
      salePriceMinor: 5000, // NPR 50
    );

    // 3. Parties
    final hariId = await repo.findOrCreateParty('Hari Traders (Supplier)');
    final sitaId = await repo.findOrCreateParty('Sita Stores');
    final bikashId = await repo.findOrCreateParty('Bikash Sharma');
    await repo.findOrCreateParty('Gita Rai');
    await repo.findOrCreateParty('Ramesh Grocery');

    // Enable reminders for top debtor
    await repo.setPartyReminder(hariId, enabled: true, everyDays: 7);
    await repo.setPartyReminder(sitaId, enabled: true, everyDays: 14);

    final now = DateTime.now();

    // 4. Starting Balance & Historical Transactions (Past 7 days)
    // Opening starting cash
    await repo.addEntry(
      direction: Direction.moneyIn,
      amountMinor: 3500000, // NPR 35,000 opening cash
      occurredAt: now.subtract(const Duration(days: 7)),
      category: 'Starting Cash',
      note: 'Galla opening balance',
      isAdjustment: true,
    );

    // Day -5
    await repo.addEntry(
      direction: Direction.moneyIn,
      amountMinor: 1450000, // NPR 14,500
      occurredAt: now.subtract(const Duration(days: 5)),
      category: 'Sales / Cash',
      note: 'Morning Kirana retail sales',
      inventoryItemId: waiwai.id,
    );
    await repo.addEntry(
      direction: Direction.moneyOut,
      amountMinor: 850000, // NPR 8,500
      occurredAt: now.subtract(const Duration(days: 5)),
      partyId: hariId,
      partyName: 'Hari Traders (Supplier)',
      category: 'Stock Purchase',
      note: 'Wholesale sugar & tea supply restock',
    );

    // Day -3 (Udhaar given to Sita)
    await repo.addEntry(
      direction: Direction.moneyIn,
      amountMinor: 680000, // NPR 6,800
      occurredAt: now.subtract(const Duration(days: 3)),
      partyId: sitaId,
      partyName: 'Sita Stores',
      category: 'Credit Sale',
      note: '3 bags rice on 15-day udhaar',
      isCredit: true,
      inventoryItemId: rice.id,
    );

    // Day -2
    await repo.addEntry(
      direction: Direction.moneyIn,
      amountMinor: 1850000, // NPR 18,500
      occurredAt: now.subtract(const Duration(days: 2)),
      category: 'Daily Sales',
      note: 'Retail cash & Fonepay collections',
      inventoryItemId: oil.id,
    );
    await repo.addEntry(
      direction: Direction.moneyOut,
      amountMinor: 350000, // NPR 3,500
      occurredAt: now.subtract(const Duration(days: 2)),
      category: 'Electricity / Utilities',
      note: 'NEA Shop Electricity Bill',
    );

    // Yesterday
    await repo.addEntry(
      direction: Direction.moneyIn,
      amountMinor: 2240000, // NPR 22,400
      occurredAt: now.subtract(const Duration(days: 1)),
      category: 'Daily Sales',
      note: 'Weekend rush sales',
      inventoryItemId: tea.id,
    );
    await repo.addEntry(
      direction: Direction.moneyIn,
      amountMinor: 250000, // NPR 2,500
      occurredAt: now.subtract(const Duration(days: 1)),
      partyId: bikashId,
      partyName: 'Bikash Sharma',
      category: 'Credit Sale',
      note: 'Monthly groceries on khata',
      isCredit: true,
      inventoryItemId: sugar.id,
    );

    // Today's Transactions
    await repo.addEntry(
      direction: Direction.moneyIn,
      amountMinor: 845000, // NPR 8,450
      occurredAt: now.subtract(const Duration(hours: 4)),
      category: 'Morning Sales',
      note: 'Cash drawer collections',
      inventoryItemId: soap.id,
    );
    await repo.addEntry(
      direction: Direction.moneyIn,
      amountMinor: 300000, // NPR 3,000
      occurredAt: now.subtract(const Duration(hours: 2)),
      partyId: sitaId,
      partyName: 'Sita Stores',
      category: 'Payment Received',
      note: 'Partial cash payment for previous udhaar',
      isCredit: false,
    );
    await repo.addEntry(
      direction: Direction.moneyOut,
      amountMinor: 120000, // NPR 1,200
      occurredAt: now.subtract(const Duration(hours: 1)),
      category: 'Transport / Rickshaw',
      note: 'Delivery cart hire charges',
    );

    // 5. Invoicing Demo
    await repo.createInvoice(
      partyId: sitaId,
      partyName: 'Sita Stores',
      issueDate: now.subtract(const Duration(days: 1)),
      dueDate: now.add(const Duration(days: 14)),
      taxRatePct: 0.0,
      notes: 'Payment via Fonepay / QR or Cash upon delivery',
      items: [
        (
          description: 'Dhara Mustard Oil 1L (x10)',
          quantity: 10.0,
          unitPriceMinor: 26000,
          inventoryItemId: oil.id,
        ),
        (
          description: 'Basmati Rice 25kg (x2)',
          quantity: 2.0,
          unitPriceMinor: 245000,
          inventoryItemId: rice.id,
        ),
      ],
    );

    debugPrint('✅ Demo seed complete for Shree Ganesh Kirana Pasal.');
  }
}
