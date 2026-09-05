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

  /// Returns true if a user is actively authenticated with Supabase.
  bool get isAuthenticated => _supabase.auth.currentUser != null;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Starts real-time listening and performs an initial sync if authenticated.
  void init() {
    if (!isAuthenticated) return;
    _subscribeToRealtime();
    syncAll();
  }

  /// Stop real-time subscriptions when logging out.
  void dispose() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  /// Synchronize all pending local data with Supabase and fetch remote updates.
  Future<void> syncAll() async {
    if (!isAuthenticated || _isSyncing) return;
    _isSyncing = true;
    final userId = currentUserId;
    if (userId == null) {
      _isSyncing = false;
      return;
    }

    try {
      // 1. Push local parties
      final localParties = await _repo.watchParties().first;
      for (final p in localParties) {
        await _supabase.from('parties').upsert({
          'id': p.id,
          'business_id': userId,
          'name': p.name,
          'phone': p.phone,
          'balance_minor': p.balanceMinor,
          'remind_enabled': p.remindEnabled,
          'remind_every_days': p.remindEveryDays,
          'created_at': p.createdAt.toIso8601String(),
        });
      }

      // 2. Push local inventory items
      final localInventory = await _repo.watchInventory().first;
      for (final item in localInventory) {
        await _supabase.from('inventory_items').upsert({
          'id': item.id,
          'business_id': userId,
          'name': item.name,
          'sku': item.sku,
          'unit': item.unit,
          'current_quantity': item.currentQuantity,
          'low_stock_threshold': item.lowStockThreshold,
          'cost_price_minor': item.costPriceMinor,
          'sale_price_minor': item.salePriceMinor,
          'created_at': item.createdAt.toIso8601String(),
          'updated_at': item.updatedAt.toIso8601String(),
        });
      }

      // 3. Push local transactions
      final localTxns = await _repo.watchTransactions().first;
      for (final t in localTxns) {
        await _supabase.from('transactions').upsert({
          'id': t.id,
          'business_id': userId,
          'party_id': t.partyId,
          'inventory_item_id': t.inventoryItemId,
          'direction': t.direction == Direction.moneyIn ? 'money_in' : 'money_out',
          'amount_minor': t.amountMinor,
          'category': t.category,
          'note': t.note,
          'is_credit': t.isCredit,
          'is_adjustment': t.isAdjustment,
          'is_write_off': t.isWriteOff,
          'occurred_at': t.occurredAt.toIso8601String(),
          'created_at': t.createdAt.toIso8601String(),
        });
      }

      // 4. Pull remote parties
      final remoteParties = await _supabase
          .from('parties')
          .select()
          .eq('business_id', userId);

      for (final row in remoteParties as List<dynamic>) {
        final party = Party(
          id: row['id'] as String,
          name: row['name'] as String,
          phone: row['phone'] as String?,
          balanceMinor: (row['balance_minor'] as num?)?.toInt() ?? 0,
          remindEnabled: row['remind_enabled'] as bool? ?? false,
          remindEveryDays: (row['remind_every_days'] as num?)?.toInt() ?? 14,
          createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ?? DateTime.now(),
        );
        await _repo.upsertPartyFromRemote(party);
      }
    } catch (e) {
      debugPrint('Supabase sync error (non-fatal, continuing offline): $e');
    } finally {
      _isSyncing = false;
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
          callback: (payload) {
            // Trigger background pull when changes occur
            syncAll();
          },
        )
        .subscribe();
  }
}
