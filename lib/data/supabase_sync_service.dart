import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/supabase/supabase_provider.dart';
import '../domain/models.dart';
import 'galla_repository.dart';

final syncServiceProvider = Provider<SupabaseSyncService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final repo = ref.watch(repositoryProvider);
  return SupabaseSyncService(supabase, repo);
});

class SupabaseSyncService {
  SupabaseSyncService(this._supabase, this._repo);

  final SupabaseClient _supabase;
  final GallaRepository _repo;

  RealtimeChannel? _realtimeChannel;
  bool _isSyncing = false;

  bool get isAuthenticated => _supabase.auth.currentUser != null;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  void init() {
    if (!isAuthenticated) return;
    _subscribeToRealtime();
    syncAll();
  }

  void dispose() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  /// Pushes the local store name and profile immediately (Save / onboarding).
  Future<void> pushBusinessProfile() async {
    if (!isAuthenticated) return;
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _pushBusiness(userId);
    } catch (e) {
      debugPrint('Supabase business push error (non-fatal): $e');
    }
  }

  Future<void> syncAll() async {
    if (!isAuthenticated || _isSyncing) return;
    _isSyncing = true;
    final userId = currentUserId;
    if (userId == null) {
      _isSyncing = false;
      return;
    }

    try {
      await _mergeBusiness(userId);
      await _pushBusiness(userId);
      await _pushAll(userId);
      await _pullAll(userId);
    } catch (e) {
      debugPrint('Supabase sync error (non-fatal, continuing offline): $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _mergeBusiness(String userId) async {
    final settings = await _repo.loadSettings();
    final localStamp = await _repo.businessUpdatedAt();
    Map<String, dynamic>? remote;
    try {
      remote = await _supabase
          .from('businesses')
          .select()
          .eq('id', userId)
          .maybeSingle();
    } catch (e) {
      debugPrint('Supabase businesses pull skipped: $e');
    }

    final remoteUpdated = _parseDate(remote?['updated_at']);
    final remoteName = (remote?['name'] as String?)?.trim() ?? '';
    final localName = settings.businessName.trim();

    final remoteIsNewer =
        remote != null &&
        remoteUpdated != null &&
        (localStamp == null || remoteUpdated.isAfter(localStamp));
    final shouldApplyRemote =
        remote != null &&
        remoteName.isNotEmpty &&
        (localName.isEmpty || remoteIsNewer);

    if (shouldApplyRemote) {
      await _repo.applyCloudBusinessProfile(
        name: remoteName,
        currency: (remote['currency'] as String?) ?? settings.currency,
        taxRatePct: (remote['tax_rate_pct'] as num?)?.toDouble() ??
            settings.taxRatePct,
        locale: remote['locale'] as String?,
        lowCashThresholdMinor:
            (remote['low_cash_threshold_minor'] as num?)?.toInt(),
        notifyPaymentDue: remote['notify_payment_due'] as bool?,
        notifyLowCash: remote['notify_low_cash'] as bool?,
        notifyLowStock: remote['notify_low_stock'] as bool?,
        updatedAt: remoteUpdated ?? DateTime.now().toUtc(),
      );
    }
  }

  Future<void> _pushBusiness(String userId) async {
    final settings = await _repo.loadSettings();
    final name = settings.businessName.trim();
    if (name.isEmpty) return;

    final now = DateTime.now().toUtc();
    try {
      final existing = await _supabase
          .from('businesses')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (existing != null &&
          existing['name'] == name &&
          existing['currency'] == settings.currency &&
          (existing['tax_rate_pct'] as num?)?.toDouble() == settings.taxRatePct &&
          existing['locale'] == settings.locale &&
          (existing['low_cash_threshold_minor'] as num?)?.toInt() ==
              settings.lowCashThresholdMinor) {
        return;
      }
    } catch (_) {}

    await _supabase.from('businesses').upsert({
      'id': userId,
      'email': settings.authEmail ?? _supabase.auth.currentUser?.email ?? '',
      'name': name,
      'currency': settings.currency,
      'tax_rate_pct': settings.taxRatePct,
      'locale': settings.locale,
      'low_cash_threshold_minor': settings.lowCashThresholdMinor,
      'notify_payment_due': settings.notifyPaymentDue,
      'notify_low_cash': settings.notifyLowCash,
      'notify_low_stock': settings.notifyLowStock,
      'updated_at': now.toIso8601String(),
    });
    await _repo.markBusinessUpdatedAt(now);
  }

  Future<void> _pushAll(String userId) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final branches = await _repo.watchBranches().first;
    for (final b in branches) {
      await _supabase.from('branches').upsert({
        'id': b.id,
        'business_id': userId,
        'name': b.name,
        'address': b.address,
        'phone': b.phone,
        'is_default': b.isDefault,
        'created_at': b.createdAt.toIso8601String(),
        'updated_at': now,
      });
    }

    final staff = await _repo.watchStaffMembers().first;
    for (final s in staff) {
      await _supabase.from('staff_members').upsert({
        'id': s.id,
        'business_id': userId,
        'name': s.name,
        'phone': s.phone,
        'role': s.role.key,
        'is_active': s.isActive,
        'created_at': s.createdAt.toIso8601String(),
        'updated_at': now,
      });
    }

    final parties = await _repo.watchParties().first;
    for (final p in parties) {
      await _supabase.from('parties').upsert({
        'id': p.id,
        'business_id': userId,
        'name': p.name,
        'phone': p.phone,
        'balance_minor': p.balanceMinor,
        'remind_enabled': p.remindEnabled,
        'remind_every_days': p.remindEveryDays,
        'last_reminded_at': p.lastRemindedAt?.toIso8601String(),
        'settled_at': p.settledAt?.toIso8601String(),
        'created_at': p.createdAt.toIso8601String(),
        'updated_at': now,
      });
    }

    final inventory = await _repo.inventoryForSync();
    for (final row in inventory) {
      final item = row.item;
      await _supabase.from('inventory_items').upsert({
        'id': item.id,
        'business_id': userId,
        'branch_id': item.branchId,
        'name': item.name,
        'sku': item.sku,
        'unit': item.unit,
        'current_quantity': item.currentQuantity,
        'low_stock_threshold': item.lowStockThreshold,
        'cost_price_minor': item.costPriceMinor,
        'sale_price_minor': item.salePriceMinor,
        'created_at': item.createdAt.toIso8601String(),
        'updated_at': item.updatedAt.toIso8601String(),
        'deleted_at': row.deletedAt?.toIso8601String(),
      });
    }

    final invoices = await _repo.invoicesForSync();
    for (final row in invoices) {
      final inv = row.invoice;
      await _supabase.from('invoices').upsert({
        'id': inv.id,
        'business_id': userId,
        'party_id': inv.partyId,
        'party_name': inv.partyName,
        'invoice_number': inv.invoiceNumber,
        'issue_date': _dateOnly(inv.issueDate),
        'due_date': inv.dueDate == null ? null : _dateOnly(inv.dueDate!),
        'subtotal_minor': inv.subtotalMinor,
        'tax_rate_pct': inv.taxRatePct,
        'tax_minor': inv.taxMinor,
        'total_minor': inv.totalMinor,
        'paid_amount_minor': inv.paidAmountMinor,
        'status': _invoiceStatusToCloud(inv.status),
        'notes': inv.notes,
        'branch_id': inv.branchId,
        'created_at': inv.createdAt.toIso8601String(),
        'updated_at': now,
        'deleted_at': row.deletedAt?.toIso8601String(),
      });
    }

    final items = await _repo.allInvoiceItems();
    for (final item in items) {
      await _supabase.from('invoice_items').upsert({
        'id': item.id,
        'invoice_id': item.invoiceId,
        'inventory_item_id': item.inventoryItemId,
        'description': item.description,
        'quantity': item.quantity,
        'unit_price_minor': item.unitPriceMinor,
        'total_minor': item.totalMinor,
      });
    }

    final txns = await _repo.transactionsForSync();
    for (final row in txns) {
      final t = row.txn;
      await _supabase.from('transactions').upsert({
        'id': t.id,
        'business_id': userId,
        'party_id': t.partyId,
        'inventory_item_id': t.inventoryItemId,
        'invoice_id': t.invoiceId,
        'branch_id': t.branchId,
        'staff_id': t.staffId,
        'staff_name': t.staffName,
        'direction': t.direction == Direction.moneyIn ? 'money_in' : 'money_out',
        'amount_minor': t.amountMinor,
        'category': t.category,
        'note': t.note,
        'is_credit': t.isCredit,
        'is_adjustment': t.isAdjustment,
        'is_write_off': t.isWriteOff,
        'photo_url': t.photoPath,
        'nl_raw': t.nlRaw,
        'ai_inferred': t.aiInferred,
        'occurred_at': t.occurredAt.toIso8601String(),
        'created_at': t.createdAt.toIso8601String(),
        'updated_at': now,
        'deleted_at': row.deletedAt?.toIso8601String(),
      });
    }

    final recs = await _repo.watchReconciliations().first;
    for (final r in recs) {
      await _supabase.from('reconciliations').upsert({
        'id': r.id,
        'business_id': userId,
        'occurred_at': r.occurredAt.toIso8601String(),
        'counted_cash_minor': r.countedCashMinor,
        'bank_balance_minor': r.bankBalanceMinor,
        'expected_cash_minor': r.expectedCashMinor,
        'discrepancy_minor': r.discrepancyMinor,
        'note': r.note,
        'adjustment_txn_id': r.adjustmentTxnId,
        'branch_id': r.branchId,
        'updated_at': now,
      });
    }
  }

  Future<void> _pullAll(String userId) async {
    final remoteBranches = await _supabase
        .from('branches')
        .select()
        .eq('business_id', userId);
    for (final row in remoteBranches as List<dynamic>) {
      await _repo.upsertBranchFromRemote(
        Branch(
          id: row['id'] as String,
          name: row['name'] as String,
          address: row['address'] as String?,
          phone: row['phone'] as String?,
          isDefault: row['is_default'] as bool? ?? false,
          createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
        ),
      );
    }

    final remoteStaff = await _supabase
        .from('staff_members')
        .select()
        .eq('business_id', userId);
    for (final row in remoteStaff as List<dynamic>) {
      await _repo.upsertStaffFromRemote(
        StaffMember(
          id: row['id'] as String,
          name: row['name'] as String,
          phone: row['phone'] as String?,
          role: StaffRole.fromKey(row['role'] as String? ?? 'staff'),
          isActive: row['is_active'] as bool? ?? true,
          createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
        ),
      );
    }

    final remoteParties = await _supabase
        .from('parties')
        .select()
        .eq('business_id', userId);
    for (final row in remoteParties as List<dynamic>) {
      await _repo.upsertPartyFromRemote(
        Party(
          id: row['id'] as String,
          name: row['name'] as String,
          phone: row['phone'] as String?,
          balanceMinor: (row['balance_minor'] as num?)?.toInt() ?? 0,
          remindEnabled: row['remind_enabled'] as bool? ?? false,
          remindEveryDays: (row['remind_every_days'] as num?)?.toInt() ?? 14,
          lastRemindedAt: _parseDate(row['last_reminded_at']),
          settledAt: _parseDate(row['settled_at']),
          createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
        ),
      );
    }

    final remoteInventory = await _supabase
        .from('inventory_items')
        .select()
        .eq('business_id', userId);
    for (final row in remoteInventory as List<dynamic>) {
      await _repo.upsertInventoryFromRemote(
        InventoryItem(
          id: row['id'] as String,
          name: row['name'] as String,
          sku: row['sku'] as String?,
          unit: row['unit'] as String? ?? 'pcs',
          currentQuantity:
              (row['current_quantity'] as num?)?.toDouble() ?? 0,
          lowStockThreshold:
              (row['low_stock_threshold'] as num?)?.toDouble() ?? 5,
          costPriceMinor: (row['cost_price_minor'] as num?)?.toInt() ?? 0,
          salePriceMinor: (row['sale_price_minor'] as num?)?.toInt() ?? 0,
          branchId: row['branch_id'] as String?,
          createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
          updatedAt: _parseDate(row['updated_at']) ?? DateTime.now(),
        ),
        deletedAt: _parseDate(row['deleted_at']),
      );
    }

    final remoteInvoices = await _supabase
        .from('invoices')
        .select()
        .eq('business_id', userId);
    for (final row in remoteInvoices as List<dynamic>) {
      await _repo.upsertInvoiceFromRemote(
        Invoice(
          id: row['id'] as String,
          invoiceNumber: row['invoice_number'] as String,
          partyId: row['party_id'] as String?,
          partyName: row['party_name'] as String?,
          issueDate: _parseDate(row['issue_date']) ?? DateTime.now(),
          dueDate: _parseDate(row['due_date']),
          subtotalMinor: (row['subtotal_minor'] as num?)?.toInt() ?? 0,
          taxRatePct: (row['tax_rate_pct'] as num?)?.toDouble() ?? 0,
          taxMinor: (row['tax_minor'] as num?)?.toInt() ?? 0,
          totalMinor: (row['total_minor'] as num?)?.toInt() ?? 0,
          paidAmountMinor: (row['paid_amount_minor'] as num?)?.toInt() ?? 0,
          status: InvoiceStatus.fromKey(row['status'] as String? ?? 'unpaid'),
          notes: row['notes'] as String?,
          branchId: row['branch_id'] as String?,
          createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
        ),
        deletedAt: _parseDate(row['deleted_at']),
      );
    }

    final invoiceIds = [
      for (final row in remoteInvoices as List<dynamic>) row['id'] as String,
    ];
    final remoteItems = invoiceIds.isEmpty
        ? const <dynamic>[]
        : await _supabase
            .from('invoice_items')
            .select()
            .inFilter('invoice_id', invoiceIds);
    final byInvoice = <String, List<InvoiceItem>>{};
    for (final row in remoteItems) {
      final item = InvoiceItem(
        id: row['id'] as String,
        invoiceId: row['invoice_id'] as String,
        description: row['description'] as String,
        quantity: (row['quantity'] as num?)?.toDouble() ?? 1,
        unitPriceMinor: (row['unit_price_minor'] as num?)?.toInt() ?? 0,
        totalMinor: (row['total_minor'] as num?)?.toInt() ?? 0,
        inventoryItemId: row['inventory_item_id'] as String?,
      );
      byInvoice.putIfAbsent(item.invoiceId, () => []).add(item);
    }
    for (final row in remoteInvoices as List<dynamic>) {
      final id = row['id'] as String;
      await _repo.replaceInvoiceItemsFromRemote(id, byInvoice[id] ?? const []);
    }

    final remoteTxns = await _supabase
        .from('transactions')
        .select()
        .eq('business_id', userId);
    for (final row in remoteTxns as List<dynamic>) {
      final dir = row['direction'] as String? ?? 'money_in';
      await _repo.upsertTxnFromRemote(
        Txn(
          id: row['id'] as String,
          occurredAt: _parseDate(row['occurred_at']) ?? DateTime.now(),
          createdAt: _parseDate(row['created_at']) ?? DateTime.now(),
          direction: dir == 'money_out' ? Direction.moneyOut : Direction.moneyIn,
          amountMinor: (row['amount_minor'] as num?)?.toInt() ?? 0,
          partyId: row['party_id'] as String?,
          category: row['category'] as String?,
          note: row['note'] as String?,
          isCredit: row['is_credit'] as bool? ?? false,
          isAdjustment: row['is_adjustment'] as bool? ?? false,
          isWriteOff: row['is_write_off'] as bool? ?? false,
          photoPath: row['photo_url'] as String?,
          nlRaw: row['nl_raw'] as String?,
          aiInferred: row['ai_inferred'] as bool? ?? false,
          branchId: row['branch_id'] as String?,
          staffId: row['staff_id'] as String?,
          staffName: row['staff_name'] as String?,
          invoiceId: row['invoice_id'] as String?,
          inventoryItemId: row['inventory_item_id'] as String?,
        ),
        deletedAt: _parseDate(row['deleted_at']),
      );
    }

    final remoteRecs = await _supabase
        .from('reconciliations')
        .select()
        .eq('business_id', userId);
    for (final row in remoteRecs as List<dynamic>) {
      await _repo.upsertReconciliationFromRemote(
        ReconciliationRecord(
          id: row['id'] as String,
          occurredAt: _parseDate(row['occurred_at']) ?? DateTime.now(),
          countedCashMinor: (row['counted_cash_minor'] as num?)?.toInt() ?? 0,
          bankBalanceMinor: (row['bank_balance_minor'] as num?)?.toInt(),
          expectedCashMinor: (row['expected_cash_minor'] as num?)?.toInt() ?? 0,
          discrepancyMinor: (row['discrepancy_minor'] as num?)?.toInt() ?? 0,
          note: row['note'] as String?,
          adjustmentTxnId: row['adjustment_txn_id'] as String?,
          branchId: row['branch_id'] as String?,
        ),
      );
    }
  }

  void _subscribeToRealtime() {
    final userId = currentUserId;
    if (userId == null) return;

    _realtimeChannel = _supabase
        .channel('public:sync')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'business_id',
            value: userId,
          ),
          callback: (_) => syncAll(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'businesses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (_) => syncAll(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'parties',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'business_id',
            value: userId,
          ),
          callback: (_) => syncAll(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'inventory_items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'business_id',
            value: userId,
          ),
          callback: (_) => syncAll(),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'invoices',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'business_id',
            value: userId,
          ),
          callback: (_) => syncAll(),
        )
        .subscribe();
  }

  static String _invoiceStatusToCloud(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.partiallyPaid:
        return 'partially_paid';
      case InvoiceStatus.paid:
        return 'paid';
      case InvoiceStatus.cancelled:
        return 'cancelled';
      case InvoiceStatus.unpaid:
        return 'unpaid';
    }
  }

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
