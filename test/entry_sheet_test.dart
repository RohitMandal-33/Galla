import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galla/core/database/app_database.dart';
import 'package:galla/core/providers.dart';
import 'package:galla/data/galla_repository.dart';
import 'package:galla/domain/models.dart';
import 'package:galla/features/entry/view/entry_sheet.dart';

void main() {
  late AppDatabase db;
  late GallaRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = GallaRepository(db);
  });

  tearDown(() => db.close());

  Future<void> pumpAndOpen(
    WidgetTester tester,
    Direction direction, {
    bool isCredit = false,
    String? seedCategory,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          settingsProvider.overrideWith(
            (ref) => Stream.value(const AppSettings()),
          ),
          partiesProvider.overrideWith((ref) => Stream.value(const <Party>[])),
          transactionsProvider.overrideWith(
            (ref) => Stream.value(const <Txn>[]),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showAddEntrySheet(
                    context,
                    initialDirection: direction,
                    isCredit: isCredit,
                    seedCategory: seedCategory,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('opening Sale quick action sheet does not crash', (tester) async {
    await pumpAndOpen(tester, Direction.moneyIn, seedCategory: 'Sales');
    expect(find.text('Save'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opening Expense quick action sheet does not crash', (
    tester,
  ) async {
    await pumpAndOpen(tester, Direction.moneyOut);
    expect(find.text('Save'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Credit tile preselects Udhaar toggle', (tester) async {
    await pumpAndOpen(tester, Direction.moneyIn, isCredit: true);
    expect(find.text('Udhaar (Credit)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('QuickAdd Sale tile opens the entry sheet (show-then-pop)', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          repositoryProvider.overrideWithValue(repo),
          settingsProvider.overrideWith(
            (ref) => Stream.value(const AppSettings()),
          ),
          partiesProvider.overrideWith((ref) => Stream.value(const <Party>[])),
          transactionsProvider.overrideWith(
            (ref) => Stream.value(const <Txn>[]),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showQuickAddSheet(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sale'));
    await tester.pumpAndSettle();

    // Quick add closed, entry sheet open with the Sales category seeded.
    expect(find.text('Add transaction'), findsNothing);
    expect(find.text('Save'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('saving a sale entry persists and closes the sheet', (
    tester,
  ) async {
    await pumpAndOpen(tester, Direction.moneyIn, seedCategory: 'Sales');
    await tester.enterText(find.byType(TextField).first, '500');
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final txns = await repo.entriesForDay(DateTime.now());
    expect(txns.single.amountMinor, 50000);
    expect(txns.single.direction, Direction.moneyIn);
    expect(txns.single.category, 'Sales');
  });
}
