import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galla/core/database/app_database.dart';
import 'package:galla/data/demo_seeder.dart';
import 'package:galla/data/galla_repository.dart';

void main() {
  late AppDatabase db;
  late GallaRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = GallaRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Phase 1: Atomic Operations & Security', () {
    test('generateNextInvoiceNumber increments atomically', () async {
      final inv1 = await repo.generateNextInvoiceNumber();
      final inv2 = await repo.generateNextInvoiceNumber();
      final inv3 = await repo.generateNextInvoiceNumber();

      expect(inv1, equals('INV-0001'));
      expect(inv2, equals('INV-0002'));
      expect(inv3, equals('INV-0003'));
    });

    test('Salted PBKDF2 PIN hashing and verification works', () {
      const pin = '1234';
      final saltedHash = GallaRepository.hashPinSalted(pin);

      expect(saltedHash.contains(':'), isTrue);
      expect(GallaRepository.verifyPinSalted('1234', saltedHash), isTrue);
      expect(GallaRepository.verifyPinSalted('0000', saltedHash), isFalse);

      // Legacy unsalted fallback check
      final legacyHash = GallaRepository.hashPin('9999');
      expect(GallaRepository.verifyPinSalted('9999', legacyHash), isTrue);
      expect(GallaRepository.verifyPinSalted('1111', legacyHash), isFalse);
    });

    test('createInvoice atomically commits all line items, ledger entry, and stock decrement', () async {
      final item = await repo.addInventoryItem(
        name: 'Mustard Oil',
        initialQuantity: 20.0,
        costPriceMinor: 20000,
        salePriceMinor: 25000,
      );

      final inv = await repo.createInvoice(
        partyName: 'Hari Traders',
        items: [
          (description: 'Mustard Oil (x5)', quantity: 5.0, unitPriceMinor: 25000, inventoryItemId: item.id),
        ],
      );

      expect(inv.invoice.invoiceNumber, equals('INV-0001'));
      expect(inv.invoice.totalMinor, equals(125000));
      expect(inv.items.length, equals(1));

      // Check stock decremented
      final updatedInv = await repo.watchInventory().first;
      expect(updatedInv.first.currentQuantity, equals(15.0));

      // Check party balance
      final parties = await repo.partiesWithBalances();
      expect(parties.first.name, equals('Hari Traders'));
      expect(parties.first.balanceMinor, equals(125000));
    });
  });

  group('Phase 14: Demo Seeder', () {
    test('DemoSeeder populates Nepali products, parties, transactions, and invoices', () async {
      await DemoSeeder.seedNepaliKirana(repo);

      final parties = await repo.partiesWithBalances();
      expect(parties.isNotEmpty, isTrue);

      final settings = await repo.loadSettings();
      expect(settings.businessName, equals('Shree Ganesh Kirana'));
      expect(settings.currency, equals('NPR'));

      final todaySummary = await repo.summaryFor(DateTime.now());
      expect(todaySummary.cashOnHandMinor, greaterThan(0));
    });
  });
}
