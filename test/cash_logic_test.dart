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

  test('cash on hand ignores udhaar and carries forward', () async {
    await repo.addEntry(
      direction: Direction.moneyIn,
      amountMinor: 100000,
      isAdjustment: true,
      note: 'Opening',
    );
    await repo.addEntry(
      direction: Direction.moneyIn,
      amountMinor: 50000,
      partyName: 'Hari',
      isCredit: true,
    );
    await repo.addEntry(
      direction: Direction.moneyOut,
      amountMinor: 20000,
      note: 'Oil',
    );
    final summary = await repo.summaryFor(DateTime.now());
    expect(summary.cashOnHandMinor, 80000);
    expect(summary.inMinor, 150000);
    expect(summary.outMinor, 20000);
    final parties = await repo.partiesWithBalances();
    expect(parties.single.name, 'Hari');
    expect(parties.single.balanceMinor, 50000);
  });

  test('payment received reduces what they owe', () async {
    await repo.addEntry(
      direction: Direction.moneyIn,
      amountMinor: 50000,
      partyName: 'Hari',
      isCredit: true,
    );
    await repo.addEntry(
      direction: Direction.moneyIn,
      amountMinor: 20000,
      partyName: 'Hari',
    );
    final parties = await repo.partiesWithBalances();
    expect(parties.single.balanceMinor, 30000);
  });
}
