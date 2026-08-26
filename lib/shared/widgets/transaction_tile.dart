import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/strings.dart';
import '../../core/money/money.dart';
import '../../core/theme/galla_theme.dart';
import '../../domain/models.dart';

/// A single ledger row, optimised for scanning:
///
///   Hari Traders                     +Rs 1,200
///   Sale · Udhaar                        10:42
///
/// Flat by design — no card chrome. Lists provide dividers between rows.
/// State is conveyed by an explicit +/− sign in addition to colour, so the
/// row works for colour-blind users.
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.txn,
    required this.currency,
    required this.s,
    this.dense = false,
  });

  final Txn txn;
  final String currency;
  final S s;

  /// Tighter vertical padding for long lists (ledger history).
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final title = txn.partyName ?? txn.category ?? _fallbackTitle();

    final isIn = txn.direction == Direction.moneyIn;
    final amountColor = isIn ? GallaColors.moneyIn : GallaColors.moneyOut;
    final amountText =
        '${isIn ? '+' : '−'} ${Money(txn.amountMinor, currency: currency).formatCompact()}';
    final timeStr = DateFormat.jm().format(txn.occurredAt);

    return Semantics(
      button: true,
      label: '$title, $amountText ${isIn ? s.moneyIn : s.moneyOut}, $timeStr',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          context.push('/ledger/transaction/${txn.id}');
        },
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: GallaSpacing.base,
            vertical: dense ? GallaSpacing.sm + 2 : GallaSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _DirectionBadge(direction: txn.direction, category: txn.category),
              const SizedBox(width: GallaSpacing.md),
              // ── Title + type line ────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GallaType.bodyStrong.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            txn.category ?? _typeLabel(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GallaType.caption.copyWith(fontSize: 12),
                          ),
                        ),
                        if (txn.isCredit) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: GallaColors.udhaarSoft,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              s.udhaar,
                              style: GallaType.badge.copyWith(
                                fontSize: 9,
                                color: GallaColors.udhaar,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: GallaSpacing.sm),
              // ── Amount over time ────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountText,
                    style: GallaType.numberSm.copyWith(color: amountColor),
                  ),
                  const SizedBox(height: 2),
                  Text(timeStr, style: GallaType.captionSm),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fallbackTitle() {
    if (txn.isAdjustment) return s.correctCash;
    if (txn.isWriteOff) return s.writeOff;
    return txn.direction == Direction.moneyIn ? s.moneyIn : s.moneyOut;
  }

  String _typeLabel() {
    if (txn.isAdjustment) return s.correctCash;
    if (txn.isWriteOff) return s.writeOff;
    if (txn.isCredit) {
      return txn.direction == Direction.moneyIn ? s.creditGiven : s.creditTaken;
    }
    return txn.direction == Direction.moneyIn ? s.typeSale : s.typeExpense;
  }
}

// ── Leading category/direction badge (only used by TransactionTile) ────────────

class _DirectionBadge extends StatelessWidget {
  const _DirectionBadge({required this.direction, this.category});
  final Direction direction;
  final String? category;

  static IconData _categoryIcon(String cat) {
    return switch (cat.toLowerCase()) {
      'sales' || 'sale' || 'sales / invoice' => Icons.storefront_outlined,
      'services' || 'service' => Icons.miscellaneous_services_outlined,
      'customer payment' || 'payment received' => Icons.payments_outlined,
      'commission' => Icons.percent_rounded,
      'interest' => Icons.account_balance_outlined,
      'purchase / stock' || 'purchase' || 'stock' => Icons.inventory_2_outlined,
      'rent' => Icons.home_outlined,
      'staff / salary' || 'salary' => Icons.badge_outlined,
      'electricity / utility' ||
      'electricity' ||
      'utility' => Icons.bolt_outlined,
      'transport' => Icons.local_shipping_outlined,
      'personal / drawings' || 'personal' => Icons.person_outlined,
      'cash reconciliation adjustment' => Icons.tune_rounded,
      _ => Icons.receipt_long_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isIn = direction == Direction.moneyIn;
    final bgColor = isIn ? GallaColors.moneyInSoft : GallaColors.moneyOutSoft;
    final fgColor = isIn ? GallaColors.moneyIn : GallaColors.moneyOut;
    final icon = category != null && category!.trim().isNotEmpty
        ? _categoryIcon(category!)
        : (isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(GallaRadius.sm),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: fgColor, size: 18),
    );
  }
}
