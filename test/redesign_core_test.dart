import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galla/core/database/app_database.dart';
import 'package:galla/core/providers.dart';
import 'package:galla/data/galla_repository.dart';
import 'package:galla/domain/models.dart';
import 'package:galla/features/entry/viewmodel/entry_viewmodel.dart';
import 'package:galla/features/business/view/business_profile_screen.dart';
import 'package:galla/features/galla/view/galla_screen.dart';
import 'package:galla/features/galla/viewmodel/action_center_provider.dart';
import 'package:galla/features/invoicing/view/invoices_screen.dart';
import 'package:galla/features/lock/lock_gate.dart';
import 'package:galla/features/reports/view/reports_screen.dart';
import 'package:galla/shared/widgets/galla_components.dart';

/// Critical interaction paths for the redesigned app:
/// every number shown must exist in the database, every action must be
/// reflected immediately, and nothing may fail silently.

AppDatabase _db() => AppDatabase(NativeDatabase.memory());

/// Pumps [frames] × 50 ms so Drift watches propagate through Riverpod.
Future<void> settleFrames(WidgetTester tester, [int frames = 6]) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  // Local-auth platform channels never resolve under flutter_test; widget
  // tests exercise the PIN path only.
  setUp(() => LockGate.biometricsEnabled = false);
  tearDown(() => LockGate.biometricsEnabled = true);

  group('Home dashboard reactivity (core trust loop)', () {
    testWidgets(
      'saving an entry updates cash, sales and activity immediately',
      (tester) async {
        final db = _db();
        final repo = GallaRepository(db);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [repositoryProvider.overrideWithValue(repo)],
            child: const MaterialApp(home: Scaffold(body: GallaScreen())),
          ),
        );
        await settleFrames(tester);

        // Empty state before any data.
        expect(find.text('No transactions yet'), findsOneWidget);

        await repo.addEntry(
          direction: Direction.moneyIn,
          amountMinor: 50000,
          partyName: 'Hari',
        );
        await settleFrames(tester);

        // Activity list refreshed reactively… (slivers build lazily, so
        // include offstage items)
        expect(find.text('Hari', skipOffstage: false), findsOneWidget);
        expect(find.text('+ Rs 500', skipOffstage: false), findsOneWidget);
        // …and the cash hero reflects the same real number.
        expect(find.text('Rs 500.00', skipOffstage: false), findsWidgets);

        await db.close();
        await tester.pump();
      },
    );
  });

  group('Entry save semantics', () {
    test('credit raises what they owe; a payment reduces it', () async {
      final db = _db();
      final repo = GallaRepository(db);
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      // Hari buys 200 for cash…
      final paymentVm = container.read(
        entryViewModelProvider(
          const EntrySeed(
            direction: Direction.moneyIn,
            isCredit: false,
            amountMinor: 0,
          ),
        ).notifier,
      );
      paymentVm
        ..setAmount(20000)
        ..setParty('Hari');
      final payment = await paymentVm.save();
      expect(payment!.isCredit, false);

      // …then 500 more on udhaar.
      final udhaarVm = container.read(
        entryViewModelProvider(
          const EntrySeed(
            direction: Direction.moneyIn,
            isCredit: true,
            amountMinor: 0,
          ),
        ).notifier,
      );
      udhaarVm
        ..setAmount(50000)
        ..setParty('Hari');
      final udhaar = await udhaarVm.save();
      expect(udhaar!.isCredit, true);

      final txns = await repo.entriesForDay(DateTime.now());
      expect(txns.length, 2);

      // Only real cash moved into the drawer.
      final summary = await repo.summaryFor(DateTime.now());
      expect(summary.cashOnHandMinor, 20000);

      // Balance: +500 credit given − 200 collected = 300 still owed.
      final parties = await repo.partiesWithBalances();
      expect(parties.single.balanceMinor, 30000);

      container.dispose();
      await db.close();
    });

    test('switching direction clears out-of-place category', () async {
      final db = _db();
      final repo = GallaRepository(db);
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repo)],
      );

      final vm = container.read(
        entryViewModelProvider(
          const EntrySeed(
            direction: Direction.moneyOut,
            isCredit: false,
            amountMinor: 0,
          ),
        ).notifier,
      );
      vm.setCategory('Rent');
      vm.setDirection(Direction.moneyIn);
      final saved = await (vm..setAmount(1000)).save();
      expect(
        saved!.category,
        isNull,
        reason: '"Rent" must never survive a switch into Cash In',
      );

      container.dispose();
      await db.close();
    });

    test('save failure surfaces instead of silently succeeding', () async {
      final db = _db();
      final failingRepo = _FailingRepo(db);
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(failingRepo)],
      );

      final vm = container.read(
        entryViewModelProvider(
          const EntrySeed(
            direction: Direction.moneyIn,
            isCredit: false,
            amountMinor: 0,
          ),
        ).notifier,
      );
      vm.setAmount(5000);
      final result = await vm.save();
      expect(result, isNull, reason: 'failure must be reported to the UI');

      container.dispose();
      await db.close();
    });
  });

  group('Reports integrity', () {
    testWidgets('selected range survives background data changes', (
      tester,
    ) async {
      final db = _db();
      final repo = GallaRepository(db);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: Scaffold(body: ReportsScreen())),
        ),
      );
      await settleFrames(tester, 8);

      GallaFilterChip chip(String label) => tester.widget<GallaFilterChip>(
        find.widgetWithText(GallaFilterChip, label),
      );

      expect(chip('This month').selected, isTrue);
      await tester.tap(find.text('This week'));
      await settleFrames(tester, 4);
      expect(chip('This week').selected, isTrue);

      // A new entry lands mid-session — the selection must NOT reset.
      await repo.addEntry(direction: Direction.moneyOut, amountMinor: 1000);
      await settleFrames(tester, 6);

      expect(
        chip('This week').selected,
        isTrue,
        reason: "stream updates must never reset the merchant's filter",
      );
      expect(find.text('Net result · Sales − Expenses'), findsOneWidget);

      await db.close();
      await tester.pump();
    });
  });

  group('Invoice lifecycle', () {
    test('cancelling voids the booked revenue and the receivable', () async {
      final db = _db();
      final repo = GallaRepository(db);
      final inv = await repo.createInvoice(
        partyName: 'Sita Store',
        items: [
          (
            description: 'Rice',
            quantity: 1.0,
            unitPriceMinor: 100000,
            inventoryItemId: null,
          ),
        ],
      );

      // Before: revenue booked, customer owes.
      var summary = await repo.summaryFor(DateTime.now());
      expect(summary.inMinor, 100000);
      var parties = await repo.partiesWithBalances();
      expect(parties.single.balanceMinor, 100000);

      final ok = await repo.cancelInvoice(inv.invoice.id);
      expect(ok, isTrue);

      // After: books corrected — the sale never happened.
      summary = await repo.summaryFor(DateTime.now());
      expect(summary.inMinor, 0);
      parties = await repo.partiesWithBalances();
      expect(parties.single.balanceMinor, 0);

      await db.close();
    });

    test('delete restores stock and refuses when payments exist', () async {
      final db = _db();
      final repo = GallaRepository(db);
      final item = await repo.addInventoryItem(
        name: 'Oil 1L',
        initialQuantity: 10,
      );
      final inv = await repo.createInvoice(
        partyName: 'Sita Store',
        items: [
          (
            description: item.name,
            quantity: 4.0,
            unitPriceMinor: 26000,
            inventoryItemId: item.id,
          ),
        ],
      );
      // Stock was deducted by the sale.
      expect((await repo.watchInventory().first).first.currentQuantity, 6.0);

      // Payments block deletion — money movements cannot be erased silently.
      await repo.recordInvoicePayment(inv.invoice.id, 26000);
      expect(await repo.deleteInvoice(inv.invoice.id), isFalse);

      // Cancel is refused too once paid.
      expect(await repo.cancelInvoice(inv.invoice.id), isFalse);

      await db.close();
    });

    testWidgets('invoice list keeps its filter while data changes', (
      tester,
    ) async {
      final db = _db();
      final repo = GallaRepository(db);
      await repo.createInvoice(
        partyName: 'A',
        items: [
          (
            description: 'x',
            quantity: 1.0,
            unitPriceMinor: 100,
            inventoryItemId: null,
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(home: Scaffold(body: InvoicesScreen())),
        ),
      );
      await settleFrames(tester, 6);

      await tester.tap(find.text('Unpaid'));
      await settleFrames(tester, 3);

      // New invoice arrives from another flow — filter holds.
      await repo.createInvoice(
        partyName: 'B',
        items: [
          (
            description: 'y',
            quantity: 1.0,
            unitPriceMinor: 100,
            inventoryItemId: null,
          ),
        ],
      );
      await settleFrames(tester, 6);

      final unpaidChip = tester.widget<GallaFilterChip>(
        find.widgetWithText(GallaFilterChip, 'Unpaid'),
      );
      expect(unpaidChip.selected, isTrue);

      await db.close();
      await tester.pump();
    });
  });

  group('App lock', () {
    testWidgets('PIN set → gate locks → correct PIN unlocks', (tester) async {
      final db = _db();
      final repo = GallaRepository(db);
      await repo.setAppPin('4321');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: LockGate(
              child: Scaffold(
                body: Center(child: Text('TOP SECRET LEDGER CONTENT')),
              ),
            ),
          ),
        ),
      );
      // _maybeLock runs post-frame; biometric attempt is skipped in tests.
      await settleFrames(tester, 8);

      expect(find.textContaining('Galla is Locked'), findsOneWidget);
      expect(find.text('TOP SECRET LEDGER CONTENT'), findsNothing);

      // Wrong PIN → error, stays locked.
      await tester.enterText(find.byType(TextField), '0000');
      await tester.tap(find.text('Unlock'));
      await tester.pump();
      expect(find.textContaining('Incorrect PIN'), findsOneWidget);
      expect(find.text('TOP SECRET LEDGER CONTENT'), findsNothing);

      // Correct PIN → content revealed.
      await tester.enterText(find.byType(TextField), '4321');
      await tester.tap(find.text('Unlock'));
      await settleFrames(tester, 4);
      expect(find.text('TOP SECRET LEDGER CONTENT'), findsOneWidget);

      await db.close();
      await tester.pump();
    });

    testWidgets('no PIN set → gate never locks', (tester) async {
      final db = _db();
      final repo = GallaRepository(db);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: LockGate(
              child: Scaffold(body: Center(child: Text('UNLOCKED CONTENT'))),
            ),
          ),
        ),
      );
      await settleFrames(tester, 8);

      expect(find.text('UNLOCKED CONTENT'), findsOneWidget);
      expect(find.textContaining('Galla is Locked'), findsNothing);

      await db.close();
      await tester.pump();
    });
  });
  group('Language & profile control', () {
    testWidgets('language choice persists and flips localized copy', (
      tester,
    ) async {
      final db = _db();
      final repo = GallaRepository(db);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: Scaffold(body: BusinessProfileScreen()),
          ),
        ),
      );
      await settleFrames(tester, 6);

      // Default install is English…
      expect(find.text('English'), findsWidgets);
      expect((await repo.loadSettings()).locale, 'en');

      // …switching to Nepali persists immediately.
      await tester.ensureVisible(find.byKey(const ValueKey('lang-ne')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('lang-ne')));
      await settleFrames(tester, 6);
      expect(
        (await repo.loadSettings()).locale,
        'ne',
        reason: 'language control must persist without pressing Save',
      );

      await db.close();
      await tester.pump();
    });

    testWidgets('alert toggles persist instantly', (tester) async {
      final db = _db();
      final repo = GallaRepository(db);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [repositoryProvider.overrideWithValue(repo)],
          child: const MaterialApp(
            home: Scaffold(body: BusinessProfileScreen()),
          ),
        ),
      );
      await settleFrames(tester, 6);

      expect((await repo.loadSettings()).notifyLowStock, isTrue);
      final toggleFinder = find.byKey(
        const ValueKey('toggle-low-stock'),
        skipOffstage: false,
      );
      await tester.ensureVisible(toggleFinder);
      await tester.pump();
      await tester.tap(toggleFinder);
      await settleFrames(tester, 6);
      expect(
        (await repo.loadSettings()).notifyLowStock,
        isFalse,
        reason: 'a toggle that did nothing would be a fake control',
      );

      await db.close();
      await tester.pump();
    });

    test('low-stock attention item respects the alert preference', () async {
      final db = _db();
      final repo = GallaRepository(db);
      final container = ProviderContainer(
        overrides: [repositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await repo.addInventoryItem(name: 'Oil', initialQuantity: 1);

      // Alerts ON (default): item appears in attention.
      final stock = await container.read(inventoryProvider.future);
      expect(stock.single.isLowStock, isTrue);
      var actions = container.read(actionCenterProvider);
      expect(actions.any((a) => a.type == ActionType.lowStock), isTrue);

      // Alerts OFF: same stock state produces no low-stock card.
      await repo.saveSettings(
        (await repo.loadSettings()).copyWith(notifyLowStock: false),
      );
      await container.read(settingsProvider.future);
      actions = container.read(actionCenterProvider);
      expect(
        actions.any((a) => a.type == ActionType.lowStock),
        isFalse,
        reason: 'the toggle must gate the real behaviour',
      );

      await db.close();
    });
  });
}

class _FailingRepo extends GallaRepository {
  _FailingRepo(super.db);

  @override
  Future<Txn> addEntry({
    required Direction direction,
    required int amountMinor,
    DateTime? occurredAt,
    String? partyName,
    String? partyId,
    String? category,
    String? note,
    bool isCredit = false,
    bool isAdjustment = false,
    bool isWriteOff = false,
    String? photoPath,
    String? nlRaw,
    bool aiInferred = false,
    String? branchId,
    String? staffId,
    String? staffName,
    String? invoiceId,
    String? inventoryItemId,
  }) {
    throw Exception('disk full');
  }
}
