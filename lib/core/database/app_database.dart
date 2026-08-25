import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('PartyRow')
class Parties extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get remindEnabled =>
      boolean().withDefault(const Constant(false))();
  IntColumn get remindEveryDays => integer().withDefault(const Constant(14))();
  DateTimeColumn get lastRemindedAt => dateTime().nullable()();
  DateTimeColumn get settledAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LedgerEntryRow')
class LedgerEntries extends Table {
  TextColumn get id => text()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get direction => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get partyId => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get isCredit => boolean().withDefault(const Constant(false))();
  BoolColumn get isAdjustment => boolean().withDefault(const Constant(false))();
  BoolColumn get isWriteOff => boolean().withDefault(const Constant(false))();
  TextColumn get photoPath => text().nullable()();
  TextColumn get nlRaw => text().nullable()();
  BoolColumn get aiInferred => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  // Version 2 additions
  TextColumn get branchId => text().nullable()();
  TextColumn get staffId => text().nullable()();
  TextColumn get staffName => text().nullable()();
  TextColumn get invoiceId => text().nullable()();
  TextColumn get inventoryItemId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InvoiceRow')
class Invoices extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceNumber => text()();
  TextColumn get partyId => text().nullable()();
  TextColumn get partyName => text().nullable()();
  DateTimeColumn get issueDate => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  IntColumn get subtotalMinor => integer()();
  RealColumn get taxRatePct => real().withDefault(const Constant(0.0))();
  IntColumn get taxMinor => integer().withDefault(const Constant(0))();
  IntColumn get totalMinor => integer()();
  IntColumn get paidAmountMinor => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('unpaid'))();
  TextColumn get notes => text().nullable()();
  TextColumn get branchId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InvoiceItemRow')
class InvoiceItems extends Table {
  TextColumn get id => text()();
  TextColumn get invoiceId => text()();
  TextColumn get description => text()();
  RealColumn get quantity => real().withDefault(const Constant(1.0))();
  IntColumn get unitPriceMinor => integer()();
  IntColumn get totalMinor => integer()();
  TextColumn get inventoryItemId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('InventoryItemRow')
class InventoryItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get sku => text().nullable()();
  TextColumn get unit => text().withDefault(const Constant('pcs'))();
  RealColumn get currentQuantity => real().withDefault(const Constant(0.0))();
  RealColumn get lowStockThreshold => real().withDefault(const Constant(5.0))();
  IntColumn get costPriceMinor => integer().withDefault(const Constant(0))();
  IntColumn get salePriceMinor => integer().withDefault(const Constant(0))();
  TextColumn get branchId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BranchRow')
class Branches extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('StaffMemberRow')
class StaffMembers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get role => text().withDefault(const Constant('staff'))();
  TextColumn get pinHash => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ReconciliationLogRow')
class ReconciliationLogs extends Table {
  TextColumn get id => text()();
  DateTimeColumn get occurredAt => dateTime()();
  IntColumn get countedCashMinor => integer()();
  IntColumn get bankBalanceMinor => integer().nullable()();
  IntColumn get expectedCashMinor => integer()();
  IntColumn get discrepancyMinor => integer()();
  TextColumn get note => text().nullable()();
  TextColumn get adjustmentTxnId => text().nullable()();
  TextColumn get branchId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SettingsRowData')
class SettingsRows extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    Parties,
    LedgerEntries,
    Invoices,
    InvoiceItems,
    InventoryItems,
    Branches,
    StaffMembers,
    ReconciliationLogs,
    SettingsRows,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'galla_db'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(invoices);
        await m.createTable(invoiceItems);
        await m.createTable(inventoryItems);
        await m.createTable(branches);
        await m.createTable(staffMembers);
        await m.createTable(reconciliationLogs);
        await m.addColumn(ledgerEntries, ledgerEntries.branchId);
        await m.addColumn(ledgerEntries, ledgerEntries.staffId);
        await m.addColumn(ledgerEntries, ledgerEntries.staffName);
        await m.addColumn(ledgerEntries, ledgerEntries.invoiceId);
        await m.addColumn(ledgerEntries, ledgerEntries.inventoryItemId);
      }
    },
  );
}
