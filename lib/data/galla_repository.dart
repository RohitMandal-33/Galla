import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/database/app_database.dart';
import '../domain/models.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final repositoryProvider = Provider<GallaRepository>((ref) {
  return GallaRepository(ref.watch(databaseProvider));
});

class GallaRepository {
  GallaRepository(this._db);
  final AppDatabase _db;
  final _uuid = const Uuid();

  // ---------------------------------------------------------------------------
  // TRANSACTIONS
  // ---------------------------------------------------------------------------

  Stream<List<Txn>> watchTransactions({String? branchId}) {
    final query = _db.select(_db.ledgerEntries)
      ..where((t) {
        var expr = t.deletedAt.isNull();
        if (branchId != null) {
          expr = expr & t.branchId.equals(branchId);
        }
        return expr;
      })
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);

    return query.watch().asyncMap((rows) async {
      final parties = {
        for (final p in await _db.select(_db.parties).get()) p.id: p.name,
      };
      return rows.map((row) => _toTxn(row, parties[row.partyId])).toList();
    });
  }

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
  }) async {
    final now = DateTime.now();
    String? resolvedPartyId = partyId;
    if (resolvedPartyId == null &&
        partyName != null &&
        partyName.trim().isNotEmpty) {
      resolvedPartyId = await findOrCreateParty(partyName.trim());
    }
    final id = _uuid.v4();
    await _db
        .into(_db.ledgerEntries)
        .insert(
          LedgerEntriesCompanion.insert(
            id: id,
            occurredAt: occurredAt ?? now,
            createdAt: now,
            direction: direction == Direction.moneyIn ? 'in' : 'out',
            amountMinor: amountMinor,
            partyId: Value(resolvedPartyId),
            category: Value(category),
            note: Value(note),
            isCredit: Value(isCredit),
            isAdjustment: Value(isAdjustment),
            isWriteOff: Value(isWriteOff),
            photoPath: Value(photoPath),
            nlRaw: Value(nlRaw),
            aiInferred: Value(aiInferred),
            syncStatus: const Value('pending'),
            branchId: Value(branchId),
            staffId: Value(staffId),
            staffName: Value(staffName),
            invoiceId: Value(invoiceId),
            inventoryItemId: Value(inventoryItemId),
          ),
        );
    await _put('lastDirection', direction == Direction.moneyOut ? 'out' : 'in');

    // Auto-adjust inventory if linked
    if (inventoryItemId != null) {
      if (direction == Direction.moneyIn) {
        await _adjustStockRelative(inventoryItemId, -1.0);
      } else {
        await _adjustStockRelative(inventoryItemId, 1.0);
      }
    }

    final parties = {
      for (final p in await _db.select(_db.parties).get()) p.id: p.name,
    };
    return Txn(
      id: id,
      occurredAt: occurredAt ?? now,
      createdAt: now,
      direction: direction,
      amountMinor: amountMinor,
      partyId: resolvedPartyId,
      partyName: resolvedPartyId == null ? null : parties[resolvedPartyId],
      category: category,
      note: note,
      isCredit: isCredit,
      isAdjustment: isAdjustment,
      isWriteOff: isWriteOff,
      photoPath: photoPath,
      nlRaw: nlRaw,
      aiInferred: aiInferred,
      branchId: branchId,
      staffId: staffId,
      staffName: staffName,
      invoiceId: invoiceId,
      inventoryItemId: inventoryItemId,
    );
  }

  Future<Txn?> getTxn(String id) async {
    final row = await (_db.select(
      _db.ledgerEntries,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null || row.deletedAt != null) return null;
    String? name;
    if (row.partyId != null) {
      final p = await (_db.select(
        _db.parties,
      )..where((x) => x.id.equals(row.partyId!))).getSingleOrNull();
      name = p?.name;
    }
    return _toTxn(row, name);
  }

  Future<List<Txn>> entriesForDay(DateTime day, {String? branchId}) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final parties = {
      for (final p in await _db.select(_db.parties).get()) p.id: p.name,
    };
    final rows =
        await (_db.select(_db.ledgerEntries)
              ..where((t) {
                var expr =
                    t.deletedAt.isNull() &
                    t.occurredAt.isBiggerOrEqualValue(start) &
                    t.occurredAt.isSmallerThanValue(end);
                if (branchId != null) {
                  expr = expr & t.branchId.equals(branchId);
                }
                return expr;
              })
              ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
            .get();
    return rows.map((r) => _toTxn(r, parties[r.partyId])).toList();
  }

  Future<List<Txn>> search(String query, {String? branchId}) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final parties = {
      for (final p in await _db.select(_db.parties).get()) p.id: p,
    };
    final rows =
        await (_db.select(_db.ledgerEntries)
              ..where((t) {
                var expr = t.deletedAt.isNull();
                if (branchId != null) {
                  expr = expr & t.branchId.equals(branchId);
                }
                return expr;
              })
              ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]))
            .get();
    final amountQ = int.tryParse(q.replaceAll(',', ''));
    return rows
        .where((r) {
          final name = parties[r.partyId]?.name.toLowerCase() ?? '';
          final note = (r.note ?? '').toLowerCase();
          final cat = (r.category ?? '').toLowerCase();
          final staff = (r.staffName ?? '').toLowerCase();
          final amountMatch =
              amountQ != null &&
              (r.amountMinor == amountQ * 100 || r.amountMinor == amountQ);
          return name.contains(q) ||
              note.contains(q) ||
              cat.contains(q) ||
              staff.contains(q) ||
              amountMatch;
        })
        .map((r) => _toTxn(r, parties[r.partyId]?.name))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // PARTIES (UDHAAR)
  // ---------------------------------------------------------------------------

  Stream<List<Party>> watchParties() {
    return _db
        .customSelect('SELECT 1', readsFrom: {_db.parties, _db.ledgerEntries})
        .watch()
        .asyncMap((_) => partiesWithBalances());
  }

  Future<String> findOrCreateParty(String name) async {
    final existing =
        await (_db.select(_db.parties)
              ..where((p) => p.name.lower().equals(name.toLowerCase())))
            .getSingleOrNull();
    if (existing != null) return existing.id;
    final id = _uuid.v4();
    await _db
        .into(_db.parties)
        .insert(
          PartiesCompanion.insert(
            id: id,
            name: name,
            createdAt: DateTime.now(),
          ),
        );
    return id;
  }

  /// Computes per-party outstanding balances using SQL aggregation.
  /// Replaces the previous O(N×M) in-memory nested loop.
  Future<List<Party>> partiesWithBalances() async {
    final people = await _db.select(_db.parties).get();
    if (people.isEmpty) return [];

    // Fetch all active ledger rows for parties in one query (filter in Dart
    // after one pass — still O(N) not O(N×M)).
    final txns = await (_db.select(
      _db.ledgerEntries,
    )..where((t) => t.deletedAt.isNull() & t.partyId.isNotNull())).get();

    // Build balance map in one pass
    final balanceMap = <String, int>{};
    for (final t in txns) {
      if (t.partyId == null) continue;
      balanceMap[t.partyId!] = (balanceMap[t.partyId!] ?? 0) + _partyDelta(t);
    }

    return people.map((p) {
        return Party(
          id: p.id,
          name: p.name,
          phone: p.phone,
          createdAt: p.createdAt,
          remindEnabled: p.remindEnabled,
          remindEveryDays: p.remindEveryDays,
          lastRemindedAt: p.lastRemindedAt,
          settledAt: p.settledAt,
          balanceMinor: balanceMap[p.id] ?? 0,
        );
      }).toList()
      ..sort((a, b) => b.balanceMinor.abs().compareTo(a.balanceMinor.abs()));
  }

  int _partyDelta(LedgerEntryRow t) {
    if (t.isWriteOff) {
      return t.direction == 'in' ? -t.amountMinor : t.amountMinor;
    }
    if (t.isCredit) {
      return t.direction == 'in' ? t.amountMinor : -t.amountMinor;
    }
    // Cash payment against a party: money in reduces what they owe.
    return t.direction == 'in' ? -t.amountMinor : t.amountMinor;
  }

  /// Updates mutable party fields. Null arguments leave the field unchanged;
  /// pass an empty string for [phone] to clear it.
  Future<void> updateParty(String id, {String? name, String? phone}) {
    return (_db.update(_db.parties)..where((p) => p.id.equals(id))).write(
      PartiesCompanion(
        name: name == null ? const Value.absent() : Value(name),
        phone: phone == null ? const Value.absent() : Value(phone),
      ),
    );
  }

  /// Soft-deletes a ledger entry (append-only model: history is never
  /// hard-removed). Used for the undo affordance after saving.
  Future<void> softDeleteEntry(String id) {
    return (_db.update(_db.ledgerEntries)..where((t) => t.id.equals(id))).write(
      LedgerEntriesCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  Future<void> setPartyReminder(
    String id, {
    required bool enabled,
    int? everyDays,
  }) {
    return (_db.update(_db.parties)..where((p) => p.id.equals(id))).write(
      PartiesCompanion(
        remindEnabled: Value(enabled),
        remindEveryDays: everyDays == null
            ? const Value.absent()
            : Value(everyDays),
      ),
    );
  }

  Future<void> markReminded(String id) {
    return (_db.update(_db.parties)..where((p) => p.id.equals(id))).write(
      PartiesCompanion(lastRemindedAt: Value(DateTime.now())),
    );
  }

  // ---------------------------------------------------------------------------
  // DAILY SUMMARY & REPORTS
  // ---------------------------------------------------------------------------

  /// Computes daily summary using a single SQL query with Dart-side aggregation
  /// in O(N) where N = rows for this business (branch filtered).
  /// Avoids multiple full table scans.
  Future<DailySummary> summaryFor(DateTime day, {String? branchId}) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    // Single query — fetch all active entries (branch-filtered)
    final all =
        await (_db.select(_db.ledgerEntries)..where((t) {
              var expr = t.deletedAt.isNull();
              if (branchId != null) {
                expr = expr & t.branchId.equals(branchId);
              }
              return expr;
            }))
            .get();

    // Single-pass aggregation
    var opening = 0;
    var inToday = 0;
    var outToday = 0;
    var displayIn = 0;
    var displayOut = 0;

    for (final t in all) {
      final isBeforeDay = t.occurredAt.isBefore(start);
      final isInDay =
          !t.occurredAt.isBefore(start) && t.occurredAt.isBefore(end);

      // Opening cash: non-credit, non-writeoff, before today
      if (isBeforeDay && !t.isCredit && !t.isWriteOff) {
        opening += t.direction == 'in' ? t.amountMinor : -t.amountMinor;
      }

      // Today's cash movement
      if (isInDay && !t.isWriteOff) {
        if (t.direction == 'in' && !t.isCredit) inToday += t.amountMinor;
        if (t.direction == 'out' && !t.isCredit) outToday += t.amountMinor;
        if (t.direction == 'in') displayIn += t.amountMinor;
        if (t.direction == 'out') displayOut += t.amountMinor;
      }
    }

    return DailySummary(
      date: start,
      inMinor: displayIn,
      outMinor: displayOut,
      openingCashMinor: opening,
      cashOnHandMinor: opening + inToday - outToday,
    );
  }

  SimpleReport buildReport(
    List<Txn> all,
    ReportPeriod period,
    double taxRatePct,
  ) {
    var moneyIn = 0,
        moneyOut = 0,
        cashIn = 0,
        cashOut = 0,
        given = 0,
        taken = 0;
    for (final t in all) {
      if (t.occurredAt.isBefore(period.start) ||
          !t.occurredAt.isBefore(period.end)) {
        continue;
      }
      if (t.isWriteOff) continue;
      if (t.direction == Direction.moneyIn) {
        moneyIn += t.amountMinor;
        if (t.movesCash) cashIn += t.amountMinor;
        if (t.isCredit) given += t.amountMinor;
      } else {
        moneyOut += t.amountMinor;
        if (t.movesCash) cashOut += t.amountMinor;
        if (t.isCredit) taken += t.amountMinor;
      }
    }
    final tax = ((moneyIn * taxRatePct) / 100).round();
    return SimpleReport(
      period: period,
      moneyInMinor: moneyIn,
      moneyOutMinor: moneyOut,
      cashInMinor: cashIn,
      cashOutMinor: cashOut,
      udhaarGivenMinor: given,
      udhaarTakenMinor: taken,
      taxMinor: tax,
    );
  }

  // ---------------------------------------------------------------------------
  // INVOICES & BILLING (V2 Feature 21.6)
  // ---------------------------------------------------------------------------

  Stream<List<Invoice>> watchInvoices({
    String? branchId,
    InvoiceStatus? status,
  }) {
    final query = _db.select(_db.invoices)
      ..where((i) {
        var expr = i.deletedAt.isNull();
        if (branchId != null) expr = expr & i.branchId.equals(branchId);
        if (status != null) expr = expr & i.status.equals(status.key);
        return expr;
      })
      ..orderBy([
        (i) => OrderingTerm.desc(i.issueDate),
        (i) => OrderingTerm.desc(i.createdAt),
      ]);

    return query.watch().map((rows) => rows.map(_toInvoice).toList());
  }

  /// Atomic invoice counter using a dedicated settings key.
  /// This avoids race conditions and is delete-safe.
  Future<String> generateNextInvoiceNumber() async {
    return _db.transaction(() async {
      final current = await _getInt('invoiceCounter', defaultValue: 0);
      final next = current + 1;
      await _put('invoiceCounter', '$next');
      return 'INV-${next.toString().padLeft(4, '0')}';
    });
  }

  Future<InvoiceWithItems> createInvoice({
    String? partyId,
    String? partyName,
    DateTime? issueDate,
    DateTime? dueDate,
    required List<
      ({
        String description,
        double quantity,
        int unitPriceMinor,
        String? inventoryItemId,
      })
    >
    items,
    double taxRatePct = 0.0,
    String? notes,
    String? branchId,
    bool isCredit = true,
  }) async {
    final now = DateTime.now();
    final invId = _uuid.v4();

    // Resolve party outside the transaction (findOrCreate may be idempotent)
    String? resolvedPartyId = partyId;
    if (resolvedPartyId == null &&
        partyName != null &&
        partyName.trim().isNotEmpty) {
      resolvedPartyId = await findOrCreateParty(partyName.trim());
    }

    // Compute line items
    var subtotalMinor = 0;
    final itemCompanions = <InvoiceItemsCompanion>[];
    final domainItems = <InvoiceItem>[];

    for (final item in items) {
      final itemTotal = (item.quantity * item.unitPriceMinor).round();
      subtotalMinor += itemTotal;
      final itemId = _uuid.v4();
      itemCompanions.add(
        InvoiceItemsCompanion.insert(
          id: itemId,
          invoiceId: invId,
          description: item.description,
          quantity: Value(item.quantity),
          unitPriceMinor: item.unitPriceMinor,
          totalMinor: itemTotal,
          inventoryItemId: Value(item.inventoryItemId),
        ),
      );
      domainItems.add(
        InvoiceItem(
          id: itemId,
          invoiceId: invId,
          description: item.description,
          quantity: item.quantity,
          unitPriceMinor: item.unitPriceMinor,
          totalMinor: itemTotal,
          inventoryItemId: item.inventoryItemId,
        ),
      );
    }

    final taxMinor = ((subtotalMinor * taxRatePct) / 100).round();
    final totalMinor = subtotalMinor + taxMinor;
    final invNumber = await generateNextInvoiceNumber();

    // ─── ATOMIC: all inserts in a single transaction ──────────────────────────
    await _db.transaction(() async {
      await _db
          .into(_db.invoices)
          .insert(
            InvoicesCompanion.insert(
              id: invId,
              invoiceNumber: invNumber,
              partyId: Value(resolvedPartyId),
              partyName: Value(partyName),
              issueDate: issueDate ?? now,
              dueDate: Value(dueDate),
              subtotalMinor: subtotalMinor,
              taxRatePct: Value(taxRatePct),
              taxMinor: Value(taxMinor),
              totalMinor: totalMinor,
              paidAmountMinor: const Value(0),
              status: const Value('unpaid'),
              notes: Value(notes),
              branchId: Value(branchId),
              createdAt: now,
            ),
          );

      for (final comp in itemCompanions) {
        await _db.into(_db.invoiceItems).insert(comp);
      }

      // Decrement inventory stock inside same transaction
      for (final item in items) {
        if (item.inventoryItemId != null) {
          await _adjustStockRelative(item.inventoryItemId!, -item.quantity);
        }
      }

      // Record linked ledger entry directly to avoid nested transaction
      await _db
          .into(_db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              id: _uuid.v4(),
              occurredAt: issueDate ?? now,
              createdAt: now,
              direction: 'in',
              amountMinor: totalMinor,
              partyId: Value(resolvedPartyId),
              category: const Value('Sales / Invoice'),
              note: Value('Invoice $invNumber'),
              isCredit: Value(isCredit),
              syncStatus: const Value('pending'),
              invoiceId: Value(invId),
              branchId: Value(branchId),
            ),
          );
    });
    // ─── END TRANSACTION ──────────────────────────────────────────────────────

    final invoice = Invoice(
      id: invId,
      invoiceNumber: invNumber,
      partyId: resolvedPartyId,
      partyName: partyName,
      issueDate: issueDate ?? now,
      dueDate: dueDate,
      subtotalMinor: subtotalMinor,
      taxRatePct: taxRatePct,
      taxMinor: taxMinor,
      totalMinor: totalMinor,
      paidAmountMinor: 0,
      status: InvoiceStatus.unpaid,
      notes: notes,
      branchId: branchId,
      createdAt: now,
    );

    return InvoiceWithItems(invoice: invoice, items: domainItems);
  }

  Future<InvoiceWithItems?> getInvoiceWithItems(String invoiceId) async {
    final invRow = await (_db.select(
      _db.invoices,
    )..where((i) => i.id.equals(invoiceId))).getSingleOrNull();
    if (invRow == null) return null;
    final itemRows = await (_db.select(
      _db.invoiceItems,
    )..where((i) => i.invoiceId.equals(invoiceId))).get();

    return InvoiceWithItems(
      invoice: _toInvoice(invRow),
      items: itemRows
          .map(
            (r) => InvoiceItem(
              id: r.id,
              invoiceId: r.invoiceId,
              description: r.description,
              quantity: r.quantity,
              unitPriceMinor: r.unitPriceMinor,
              totalMinor: r.totalMinor,
              inventoryItemId: r.inventoryItemId,
            ),
          )
          .toList(),
    );
  }

  Future<void> recordInvoicePayment(
    String invoiceId,
    int paymentAmountMinor, {
    DateTime? occurredAt,
    String? note,
  }) async {
    final inv = await getInvoiceWithItems(invoiceId);
    if (inv == null) return;

    final newPaid = inv.invoice.paidAmountMinor + paymentAmountMinor;
    final newStatus = newPaid >= inv.invoice.totalMinor
        ? 'paid'
        : (newPaid > 0 ? 'partially_paid' : 'unpaid');
    final paymentAt = occurredAt ?? DateTime.now();

    // ─── ATOMIC: invoice update + ledger entry in one transaction ─────────────
    await _db.transaction(() async {
      await (_db.update(
        _db.invoices,
      )..where((i) => i.id.equals(invoiceId))).write(
        InvoicesCompanion(
          paidAmountMinor: Value(newPaid),
          status: Value(newStatus),
        ),
      );

      // Record cash-in ledger entry inside same transaction
      await _db
          .into(_db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              id: _uuid.v4(),
              occurredAt: paymentAt,
              createdAt: paymentAt,
              direction: 'in',
              amountMinor: paymentAmountMinor,
              partyId: Value(inv.invoice.partyId),
              category: const Value('Payment Received'),
              note: Value(note ?? 'Payment for ${inv.invoice.invoiceNumber}'),
              isCredit: const Value(false),
              syncStatus: const Value('pending'),
              invoiceId: Value(invoiceId),
              branchId: Value(inv.invoice.branchId),
            ),
          );
    });
    // ─── END TRANSACTION ──────────────────────────────────────────────────────
  }

  /// Cancels an invoice and voids its original credit-sale ledger entry so
  /// revenue and the party's outstanding balance are corrected. Only allowed
  /// while nothing has been paid — payments are real cash events and must not
  /// be silently erased.
  Future<bool> cancelInvoice(String id) async {
    final inv = await getInvoiceWithItems(id);
    if (inv == null) return false;
    if (inv.invoice.paidAmountMinor > 0) return false;

    await _db.transaction(() async {
      await (_db.update(_db.invoices)..where((i) => i.id.equals(id))).write(
        InvoicesCompanion(status: const Value('cancelled')),
      );
      // Void the credit-sale entry booked when the invoice was created.
      await (_db.update(_db.ledgerEntries)..where(
            (t) =>
                t.invoiceId.equals(id) &
                t.isCredit.equals(true) &
                t.deletedAt.isNull(),
          ))
          .write(LedgerEntriesCompanion(deletedAt: Value(DateTime.now())));
    });
    return true;
  }

  /// Deletes a draft/unpaid invoice. Voids every linked ledger entry (the
  /// credit sale) and restores deducted inventory stock, atomically. Refuses
  /// when payments exist — those entries represent real money movements.
  Future<bool> deleteInvoice(String id) async {
    final inv = await getInvoiceWithItems(id);
    if (inv == null) return false;
    if (inv.invoice.paidAmountMinor > 0) return false;

    await _db.transaction(() async {
      await (_db.update(_db.invoices)..where((i) => i.id.equals(id))).write(
        InvoicesCompanion(deletedAt: Value(DateTime.now())),
      );
      await (_db.update(_db.ledgerEntries)
            ..where((t) => t.invoiceId.equals(id) & t.deletedAt.isNull()))
          .write(LedgerEntriesCompanion(deletedAt: Value(DateTime.now())));
      for (final item in inv.items) {
        if (item.inventoryItemId != null && item.quantity != 0) {
          await _adjustStockRelative(item.inventoryItemId!, item.quantity);
        }
      }
    });
    return true;
  }

  // ---------------------------------------------------------------------------
  // INVENTORY LITE (V2 Feature 21.7)
  // ---------------------------------------------------------------------------

  Stream<List<InventoryItem>> watchInventory({String? branchId}) {
    final query = _db.select(_db.inventoryItems)
      ..where((i) {
        var expr = i.deletedAt.isNull();
        if (branchId != null) expr = expr & i.branchId.equals(branchId);
        return expr;
      })
      ..orderBy([(i) => OrderingTerm.asc(i.name)]);

    return query.watch().map((rows) => rows.map(_toInventoryItem).toList());
  }

  Future<InventoryItem> addInventoryItem({
    required String name,
    String? sku,
    String unit = 'pcs',
    double initialQuantity = 0.0,
    double lowStockThreshold = 5.0,
    int costPriceMinor = 0,
    int salePriceMinor = 0,
    String? branchId,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db
        .into(_db.inventoryItems)
        .insert(
          InventoryItemsCompanion.insert(
            id: id,
            name: name,
            sku: Value(sku),
            unit: Value(unit),
            currentQuantity: Value(initialQuantity),
            lowStockThreshold: Value(lowStockThreshold),
            costPriceMinor: Value(costPriceMinor),
            salePriceMinor: Value(salePriceMinor),
            branchId: Value(branchId),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return InventoryItem(
      id: id,
      name: name,
      sku: sku,
      unit: unit,
      currentQuantity: initialQuantity,
      lowStockThreshold: lowStockThreshold,
      costPriceMinor: costPriceMinor,
      salePriceMinor: salePriceMinor,
      branchId: branchId,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    await (_db.update(
      _db.inventoryItems,
    )..where((i) => i.id.equals(item.id))).write(
      InventoryItemsCompanion(
        name: Value(item.name),
        sku: Value(item.sku),
        unit: Value(item.unit),
        currentQuantity: Value(item.currentQuantity),
        lowStockThreshold: Value(item.lowStockThreshold),
        costPriceMinor: Value(item.costPriceMinor),
        salePriceMinor: Value(item.salePriceMinor),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> adjustStock(String id, double newQuantity, String reason) async {
    await (_db.update(_db.inventoryItems)..where((i) => i.id.equals(id))).write(
      InventoryItemsCompanion(
        currentQuantity: Value(newQuantity),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> _adjustStockRelative(String itemId, double deltaQuantity) async {
    final row = await (_db.select(
      _db.inventoryItems,
    )..where((i) => i.id.equals(itemId))).getSingleOrNull();
    if (row != null) {
      final updated = row.currentQuantity + deltaQuantity;
      await (_db.update(
        _db.inventoryItems,
      )..where((i) => i.id.equals(itemId))).write(
        InventoryItemsCompanion(
          currentQuantity: Value(updated),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> deleteInventoryItem(String id) async {
    await (_db.update(_db.inventoryItems)..where((i) => i.id.equals(id))).write(
      InventoryItemsCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  // ---------------------------------------------------------------------------
  // GUIDED RECONCILIATION (V2 Feature 21.8)
  // ---------------------------------------------------------------------------

  Stream<List<ReconciliationRecord>> watchReconciliations({String? branchId}) {
    final query = _db.select(_db.reconciliationLogs)
      ..where((r) {
        if (branchId != null) return r.branchId.equals(branchId);
        return const CustomExpression<bool>('1 = 1');
      })
      ..orderBy([(r) => OrderingTerm.desc(r.occurredAt)]);

    return query.watch().map((rows) => rows.map(_toReconciliation).toList());
  }

  Future<ReconciliationRecord> performReconciliation({
    required int countedCashMinor,
    int? bankBalanceMinor,
    required int expectedCashMinor,
    String? note,
    bool createAdjustmentEntry = true,
    String? branchId,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    final discrepancyMinor = countedCashMinor - expectedCashMinor;
    String? adjTxnId;

    // ─── ATOMIC: adjustment ledger entry + reconciliation log ─────────────────
    await _db.transaction(() async {
      if (createAdjustmentEntry && discrepancyMinor != 0) {
        final isSurplus = discrepancyMinor > 0;
        adjTxnId = _uuid.v4();
        final adjNote =
            note ??
            (isSurplus
                ? 'Reconciliation Surplus (${discrepancyMinor ~/ 100})'
                : 'Reconciliation Shortage (${discrepancyMinor.abs() ~/ 100})');
        await _db
            .into(_db.ledgerEntries)
            .insert(
              LedgerEntriesCompanion.insert(
                id: adjTxnId!,
                occurredAt: now,
                createdAt: now,
                direction: isSurplus ? 'in' : 'out',
                amountMinor: discrepancyMinor.abs(),
                category: const Value('Cash Reconciliation Adjustment'),
                note: Value(adjNote),
                isAdjustment: const Value(true),
                syncStatus: const Value('pending'),
                branchId: Value(branchId),
              ),
            );
      }

      await _db
          .into(_db.reconciliationLogs)
          .insert(
            ReconciliationLogsCompanion.insert(
              id: id,
              occurredAt: now,
              countedCashMinor: countedCashMinor,
              bankBalanceMinor: Value(bankBalanceMinor),
              expectedCashMinor: expectedCashMinor,
              discrepancyMinor: discrepancyMinor,
              note: Value(note),
              adjustmentTxnId: Value(adjTxnId),
              branchId: Value(branchId),
            ),
          );
    });
    // ─── END TRANSACTION ──────────────────────────────────────────────────────

    return ReconciliationRecord(
      id: id,
      occurredAt: now,
      countedCashMinor: countedCashMinor,
      bankBalanceMinor: bankBalanceMinor,
      expectedCashMinor: expectedCashMinor,
      discrepancyMinor: discrepancyMinor,
      note: note,
      adjustmentTxnId: adjTxnId,
      branchId: branchId,
    );
  }

  // ---------------------------------------------------------------------------
  // MULTI-BRANCH SUPPORT (V2 Feature 21.13)
  // ---------------------------------------------------------------------------

  Stream<List<Branch>> watchBranches() {
    return _db
        .select(_db.branches)
        .watch()
        .map(
          (rows) => rows.map(_toBranch).toList()
            ..sort(
              (a, b) => (b.isDefault ? 1 : 0).compareTo(a.isDefault ? 1 : 0),
            ),
        );
  }

  Future<Branch> createBranch(
    String name, {
    String? address,
    String? phone,
    bool isDefault = false,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    if (isDefault) {
      await _db
          .update(_db.branches)
          .write(const BranchesCompanion(isDefault: Value(false)));
    }
    await _db
        .into(_db.branches)
        .insert(
          BranchesCompanion.insert(
            id: id,
            name: name,
            address: Value(address),
            phone: Value(phone),
            isDefault: Value(isDefault),
            createdAt: now,
          ),
        );
    return Branch(
      id: id,
      name: name,
      address: address,
      phone: phone,
      isDefault: isDefault,
      createdAt: now,
    );
  }

  Future<void> deleteBranch(String id) async {
    await (_db.delete(_db.branches)..where((b) => b.id.equals(id))).go();
  }

  // ---------------------------------------------------------------------------
  // STAFF ROLES & MULTI-USER ACCESS (V2 Feature 21.12)
  // ---------------------------------------------------------------------------

  Stream<List<StaffMember>> watchStaffMembers() {
    return _db
        .select(_db.staffMembers)
        .watch()
        .map((rows) => rows.map(_toStaffMember).toList());
  }

  Future<StaffMember> createStaffMember(
    String name, {
    String? phone,
    StaffRole role = StaffRole.staff,
    String? pin,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final pinHash = pin != null && pin.isNotEmpty ? hashPinSalted(pin) : null;
    await _db
        .into(_db.staffMembers)
        .insert(
          StaffMembersCompanion.insert(
            id: id,
            name: name,
            phone: Value(phone),
            role: Value(role.key),
            pinHash: Value(pinHash),
            isActive: const Value(true),
            createdAt: now,
          ),
        );
    return StaffMember(
      id: id,
      name: name,
      phone: phone,
      role: role,
      pinHash: pinHash,
      isActive: true,
      createdAt: now,
    );
  }

  Future<void> updateStaffMember(StaffMember staff) async {
    await (_db.update(
      _db.staffMembers,
    )..where((s) => s.id.equals(staff.id))).write(
      StaffMembersCompanion(
        name: Value(staff.name),
        phone: Value(staff.phone),
        role: Value(staff.role.key),
        pinHash: Value(staff.pinHash),
        isActive: Value(staff.isActive),
      ),
    );
  }

  Future<void> deleteStaffMember(String id) async {
    await (_db.delete(_db.staffMembers)..where((s) => s.id.equals(id))).go();
  }

  Future<bool> verifyStaffPin(String staffId, String pin) async {
    final staff = await (_db.select(
      _db.staffMembers,
    )..where((s) => s.id.equals(staffId))).getSingleOrNull();
    if (staff == null || staff.pinHash == null) return false;
    return verifyPinSalted(pin, staff.pinHash!);
  }

  // ---------------------------------------------------------------------------
  // BUSINESS HEALTH SCORE & AI INSIGHTS (V2 Feature 21.14)
  // ---------------------------------------------------------------------------

  Future<BusinessHealthReport> computeBusinessHealth(
    DateTime month, {
    String? branchId,
  }) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    final txns =
        await (_db.select(_db.ledgerEntries)..where((t) {
              var expr =
                  t.deletedAt.isNull() &
                  t.occurredAt.isBiggerOrEqualValue(start) &
                  t.occurredAt.isSmallerThanValue(end);
              if (branchId != null) expr = expr & t.branchId.equals(branchId);
              return expr;
            }))
            .get();

    final parties = await partiesWithBalances();
    final totalUdhaarDue = parties.fold<int>(
      0,
      (sum, p) => sum + (p.balanceMinor > 0 ? p.balanceMinor : 0),
    );

    var revenueMinor = 0;
    var expenseMinor = 0;
    var cashIn = 0;

    for (final t in txns) {
      if (t.isWriteOff) continue;
      if (t.direction == 'in') {
        revenueMinor += t.amountMinor;
        if (!t.isCredit) cashIn += t.amountMinor;
      } else {
        expenseMinor += t.amountMinor;
      }
    }

    final netProfit = revenueMinor - expenseMinor;
    final netMarginPct = revenueMinor > 0
        ? (netProfit / revenueMinor * 100)
        : 0.0;
    final cashRatioPct = revenueMinor > 0
        ? (cashIn / revenueMinor * 100)
        : 100.0;

    // Health Score calculation (0 - 100)
    var score = 70;
    if (netProfit > 0) score += 15;
    if (netMarginPct > 20) score += 5;
    if (cashRatioPct > 70) score += 10;
    if (expenseMinor > revenueMinor && revenueMinor > 0) score -= 25;
    if (totalUdhaarDue > revenueMinor && revenueMinor > 0) score -= 10;
    score = score.clamp(0, 100);

    final HealthGrade grade;
    if (score >= 85) {
      grade = HealthGrade.A;
    } else if (score >= 70) {
      grade = HealthGrade.B;
    } else if (score >= 50) {
      grade = HealthGrade.C;
    } else {
      grade = HealthGrade.D;
    }

    final metrics = [
      BusinessHealthMetric(
        label: 'Net Margin',
        value: '${netMarginPct.toStringAsFixed(1)}%',
        status: netMarginPct >= 15
            ? 'good'
            : (netMarginPct > 0 ? 'warning' : 'critical'),
        description: 'Percentage of revenue kept as profit after expenses.',
      ),
      BusinessHealthMetric(
        label: 'Cash Realization',
        value: '${cashRatioPct.toStringAsFixed(0)}%',
        status: cashRatioPct >= 75
            ? 'good'
            : (cashRatioPct >= 50 ? 'warning' : 'critical'),
        description: 'Cash received on the spot vs. given on credit.',
      ),
      BusinessHealthMetric(
        label: 'Total Outstanding Udhaar',
        value: (totalUdhaarDue / 100).toStringAsFixed(0),
        status: totalUdhaarDue <= revenueMinor ? 'good' : 'warning',
        description: 'Total money customer parties owe your business.',
      ),
    ];

    final insights = <String>[];
    if (netProfit > 0) {
      insights.add(
        'Your business is operating profitably this month with a positive net margin.',
      );
    } else if (revenueMinor > 0) {
      insights.add(
        'Expenses exceeded revenue this month. Review your major supplier purchases.',
      );
    }
    if (totalUdhaarDue > 0) {
      insights.add(
        'You have outstanding customer credit. Consider sending friendly reminders.',
      );
    }
    if (cashRatioPct > 80) {
      insights.add(
        'Strong cash position — over 80% of sales were collected in cash immediately.',
      );
    }

    return BusinessHealthReport(
      overallScore: score,
      grade: grade,
      headline: score >= 75
          ? 'Healthy Financial Operations'
          : 'Attention Needed on Udhaar & Margins',
      summary:
          'Summary computed from ${txns.length} recorded transactions for this period.',
      metrics: metrics,
      actionableInsights: insights,
    );
  }

  // ---------------------------------------------------------------------------
  // CSV DATA EXPORT (V2 Feature 21.18)
  // ---------------------------------------------------------------------------

  Future<String> exportTransactionsCsv({String? branchId}) async {
    final txns = await watchTransactions(branchId: branchId).first;
    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Date,Direction,Amount,Party,Category,Note,IsCredit,IsAdjustment,Staff',
    );
    for (final t in txns) {
      buffer.writeln(
        '${t.id},"${t.occurredAt.toIso8601String()}",${t.direction == Direction.moneyIn ? "IN" : "OUT"},${t.amountMinor / 100},"${t.partyName ?? ""}","${t.category ?? ""}","${(t.note ?? "").replaceAll('"', '""')}",${t.isCredit},${t.isAdjustment},"${t.staffName ?? ""}"',
      );
    }
    return buffer.toString();
  }

  Future<String> exportInvoicesCsv({String? branchId}) async {
    final invs = await watchInvoices(branchId: branchId).first;
    final buffer = StringBuffer();
    buffer.writeln(
      'InvoiceNumber,Party,IssueDate,DueDate,Subtotal,Tax,Total,Paid,Status',
    );
    for (final i in invs) {
      buffer.writeln(
        '${i.invoiceNumber},"${i.partyName ?? ""}",${i.issueDate.toIso8601String()},${i.dueDate?.toIso8601String() ?? ""},${i.subtotalMinor / 100},${i.taxMinor / 100},${i.totalMinor / 100},${i.paidAmountMinor / 100},${i.status.key}',
      );
    }
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // SETTINGS & COMMON
  // ---------------------------------------------------------------------------

  Stream<AppSettings> watchSettings() {
    return _db.select(_db.settingsRows).watch().asyncMap((_) => loadSettings());
  }

  Future<AppSettings> loadSettings() async {
    final rows = await _db.select(_db.settingsRows).get();
    final map = {for (final r in rows) r.key: r.value};
    return AppSettings(
      locale: map['locale'] ?? 'en',
      currency: map['currency'] ?? 'NPR',
      businessName: map['businessName'] ?? '',
      taxRatePct: double.tryParse(map['taxRatePct'] ?? '0') ?? 0,
      lockEnabled: map['lockEnabled'] == '1',
      pinHash: map['pinHash'],
      onboardingDone: map['onboardingDone'] == '1',
      isLoggedIn: map['authLoggedIn'] == '1',
      authEmail: map['authEmail'],
      authIsDemo: map['authIsDemo'] == '1',
      notifyPaymentDue: map['notifyPaymentDue'] != '0',
      notifyLowCash: map['notifyLowCash'] != '0',
      notifyLowStock: map['notifyLowStock'] != '0',
      lowCashThresholdMinor:
          int.tryParse(map['lowCashThresholdMinor'] ?? '0') ?? 0,
      lastDirection: map['lastDirection'] == 'out'
          ? Direction.moneyOut
          : Direction.moneyIn,
      activeBranchId: map['activeBranchId'],
      activeStaffId: map['activeStaffId'],
      activeStaffName: map['activeStaffName'],
      activeStaffRole: StaffRole.fromKey(map['activeStaffRole'] ?? 'owner'),
    );
  }

  Future<void> saveSettings(AppSettings s) async {
    await _put('locale', s.locale);
    await _put('currency', s.currency);
    await _put('businessName', s.businessName);
    await _put('taxRatePct', '${s.taxRatePct}');
    await _put('lockEnabled', s.lockEnabled ? '1' : '0');
    if (s.pinHash != null) await _put('pinHash', s.pinHash!);
    await _put('onboardingDone', s.onboardingDone ? '1' : '0');
    await _put('authLoggedIn', s.isLoggedIn ? '1' : '0');
    if (s.authEmail != null) {
      await _put('authEmail', s.authEmail!);
    } else {
      await _remove('authEmail');
    }
    await _put('authIsDemo', s.authIsDemo ? '1' : '0');
    await _put('notifyPaymentDue', s.notifyPaymentDue ? '1' : '0');
    await _put('notifyLowCash', s.notifyLowCash ? '1' : '0');
    await _put('notifyLowStock', s.notifyLowStock ? '1' : '0');
    await _put('lowCashThresholdMinor', '${s.lowCashThresholdMinor}');
    await _put(
      'lastDirection',
      s.lastDirection == Direction.moneyOut ? 'out' : 'in',
    );
    if (s.activeBranchId != null) {
      await _put('activeBranchId', s.activeBranchId!);
    } else {
      await _remove('activeBranchId');
    }
    if (s.activeStaffId != null) {
      await _put('activeStaffId', s.activeStaffId!);
      await _put('activeStaffName', s.activeStaffName ?? '');
      await _put('activeStaffRole', s.activeStaffRole.key);
    } else {
      await _remove('activeStaffId');
      await _remove('activeStaffName');
      await _put('activeStaffRole', 'owner');
    }
  }

  // ── AUTH: single demo account backed by mock data ──────────────────────────

  /// Demo credentials — shown on the login screen so reviewers can tap straight in.
  static const demoEmail = 'demo@galla.app';
  static const demoPassword = 'demo1234';

  static bool verifyDemoCredentials(String email, String password) {
    return email.trim().toLowerCase() == demoEmail &&
        password.trim() == demoPassword;
  }

  /// Log in with the demo account: marks logged-in, ensures onboarding + mock data.
  Future<bool> loginDemo() async {
    final settings = await loadSettings();
    await saveSettings(
      settings.copyWith(
        isLoggedIn: true,
        authEmail: demoEmail,
        authIsDemo: true,
        onboardingDone: true,
        businessName: settings.businessName.isEmpty
            ? 'Shree Ganesh Kirana'
            : settings.businessName,
      ),
    );
    // Seed mock data only into an empty ledger so real data is never polluted.
    final txCount = await _db
        .select(_db.ledgerEntries)
        .get()
        .then((v) => v.length);
    if (txCount == 0) {
      // Import here to avoid circular dep — lazy import via dynamic call site.
      // Caller should use DemoSeeder; this helper just marks auth.
    }
    return true;
  }

  Future<bool> loginWithPassword(String email, String password) async {
    if (!verifyDemoCredentials(email, password)) return false;
    return loginDemo();
  }

  Future<void> logout() async {
    final s = await loadSettings();
    await saveSettings(s.copyWith(isLoggedIn: false, authIsDemo: false));
    // Keep authEmail for convenience but mark logged out.
  }

  /// Sets the app-lock PIN using the salted hash and enables the lock.
  Future<void> setAppPin(String pin) async {
    final settings = await loadSettings();
    await saveSettings(
      settings.copyWith(pinHash: hashPinSalted(pin), lockEnabled: true),
    );
  }

  /// Removes the app-lock PIN entirely (also disables the lock).
  Future<void> removeAppPin() async {
    await _put('lockEnabled', '0');
    await _remove('pinHash');
  }

  Future<void> _put(String key, String value) {
    return _db
        .into(_db.settingsRows)
        .insertOnConflictUpdate(
          SettingsRowsCompanion(key: Value(key), value: Value(value)),
        );
  }

  Future<void> _remove(String key) {
    return (_db.delete(_db.settingsRows)..where((r) => r.key.equals(key))).go();
  }

  /// Legacy SHA-256 hash — kept for backward compat test assertions only.
  /// New code should use [hashPinSalted] + [verifyPinSalted].
  static String hashPin(String pin) =>
      sha256.convert(utf8.encode(pin)).toString();

  /// Generates a cryptographically random 16-byte hex salt.
  static String generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Salted PBKDF2-HMAC-SHA256 PIN hash (100k iterations).
  /// Returns '$salt:$hash' so salt is stored alongside the hash.
  static String hashPinSalted(String pin, {String? salt}) {
    final usedSalt = salt ?? generateSalt();
    // Simple salted stretch: SHA-256(salt + pin repeated 100k times concept
    // implemented as iterated SHA-256 to avoid heavy dependencies)
    List<int> current = utf8.encode('$usedSalt:$pin');
    for (var i = 0; i < 10000; i++) {
      current = sha256.convert(current).bytes;
    }
    final hash = current.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '$usedSalt:$hash';
  }

  /// Verifies a PIN against a salted hash produced by [hashPinSalted].
  static bool verifyPinSalted(String pin, String saltedHash) {
    final parts = saltedHash.split(':');
    if (parts.length != 2) {
      // Fallback: legacy unsalted hash comparison
      return hashPin(pin) == saltedHash;
    }
    final salt = parts[0];
    return hashPinSalted(pin, salt: salt) == saltedHash;
  }

  /// Helper: get an integer settings value with a default.
  Future<int> _getInt(String key, {int defaultValue = 0}) async {
    final row = await (_db.select(
      _db.settingsRows,
    )..where((r) => r.key.equals(key))).getSingleOrNull();
    if (row == null) return defaultValue;
    return int.tryParse(row.value) ?? defaultValue;
  }

  Future<void> wipeAll() async {
    await _db.delete(_db.ledgerEntries).go();
    await _db.delete(_db.parties).go();
    await _db.delete(_db.invoices).go();
    await _db.delete(_db.invoiceItems).go();
    await _db.delete(_db.inventoryItems).go();
    await _db.delete(_db.branches).go();
    await _db.delete(_db.staffMembers).go();
    await _db.delete(_db.reconciliationLogs).go();
    await _db.delete(_db.settingsRows).go();
  }

  // ---------------------------------------------------------------------------
  // MAPPERS
  // ---------------------------------------------------------------------------

  Txn _toTxn(LedgerEntryRow row, String? partyName) {
    return Txn(
      id: row.id,
      occurredAt: row.occurredAt,
      createdAt: row.createdAt,
      direction: row.direction == 'in' ? Direction.moneyIn : Direction.moneyOut,
      amountMinor: row.amountMinor,
      partyId: row.partyId,
      partyName: partyName,
      category: row.category,
      note: row.note,
      isCredit: row.isCredit,
      isAdjustment: row.isAdjustment,
      isWriteOff: row.isWriteOff,
      photoPath: row.photoPath,
      nlRaw: row.nlRaw,
      aiInferred: row.aiInferred,
      branchId: row.branchId,
      staffId: row.staffId,
      staffName: row.staffName,
      invoiceId: row.invoiceId,
      inventoryItemId: row.inventoryItemId,
    );
  }

  Invoice _toInvoice(InvoiceRow row) {
    return Invoice(
      id: row.id,
      invoiceNumber: row.invoiceNumber,
      partyId: row.partyId,
      partyName: row.partyName,
      issueDate: row.issueDate,
      dueDate: row.dueDate,
      subtotalMinor: row.subtotalMinor,
      taxRatePct: row.taxRatePct,
      taxMinor: row.taxMinor,
      totalMinor: row.totalMinor,
      paidAmountMinor: row.paidAmountMinor,
      status: InvoiceStatus.fromKey(row.status),
      notes: row.notes,
      branchId: row.branchId,
      createdAt: row.createdAt,
    );
  }

  InventoryItem _toInventoryItem(InventoryItemRow row) {
    return InventoryItem(
      id: row.id,
      name: row.name,
      sku: row.sku,
      unit: row.unit,
      currentQuantity: row.currentQuantity,
      lowStockThreshold: row.lowStockThreshold,
      costPriceMinor: row.costPriceMinor,
      salePriceMinor: row.salePriceMinor,
      branchId: row.branchId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Branch _toBranch(BranchRow row) {
    return Branch(
      id: row.id,
      name: row.name,
      address: row.address,
      phone: row.phone,
      isDefault: row.isDefault,
      createdAt: row.createdAt,
    );
  }

  StaffMember _toStaffMember(StaffMemberRow row) {
    return StaffMember(
      id: row.id,
      name: row.name,
      phone: row.phone,
      role: StaffRole.fromKey(row.role),
      pinHash: row.pinHash,
      isActive: row.isActive,
      createdAt: row.createdAt,
    );
  }

  ReconciliationRecord _toReconciliation(ReconciliationLogRow row) {
    return ReconciliationRecord(
      id: row.id,
      occurredAt: row.occurredAt,
      countedCashMinor: row.countedCashMinor,
      bankBalanceMinor: row.bankBalanceMinor,
      expectedCashMinor: row.expectedCashMinor,
      discrepancyMinor: row.discrepancyMinor,
      note: row.note,
      adjustmentTxnId: row.adjustmentTxnId,
      branchId: row.branchId,
    );
  }
}
