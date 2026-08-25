import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/strings.dart';
import '../../core/money/money.dart';
import '../../core/theme/galla_theme.dart';
import '../../domain/models.dart';

// ── TransactionTile ─────────────────────────────────────────────────────────────

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.txn,
    required this.currency,
    required this.s,
    this.showCard = true,
  });

  final Txn txn;
  final String currency;
  final S s;
  final bool showCard;

  @override
  Widget build(BuildContext context) {
    final title =
        txn.partyName ??
        txn.category ??
        (txn.isAdjustment
            ? s.correctCash
            : txn.direction == Direction.moneyIn
            ? s.moneyIn
            : s.moneyOut);

    final timeStr = DateFormat.jm().format(txn.occurredAt);
    final isIn = txn.direction == Direction.moneyIn;
    final amountColor = isIn ? GallaColors.moneyIn : GallaColors.moneyOut;
    final sign = isIn ? '+' : '−';
    final formatted =
        '$sign ${Money(txn.amountMinor, currency: currency).format()}';

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GallaSpacing.base,
        vertical: GallaSpacing.md,
      ),
      child: Row(
        children: [
          // ── Leading badge ──────────────────────────────────────────────
          _DirectionBadge(direction: txn.direction, category: txn.category),
          const SizedBox(width: GallaSpacing.md),

          // ── Title + meta ───────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GallaType.bodyStrong.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                _SubtitleRow(txn: txn, timeStr: timeStr, s: s),
              ],
            ),
          ),
          const SizedBox(width: GallaSpacing.sm),

          // ── Amount ─────────────────────────────────────────────────────
          Text(
            formatted,
            style: GallaType.subtitle.copyWith(
              letterSpacing: -0.2,
              color: amountColor,
            ),
          ),
        ],
      ),
    );

    if (!showCard) return content;

    return GestureDetector(
      onTap: () => context.push('/ledger/transaction/${txn.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: GallaColors.surface,
          borderRadius: BorderRadius.circular(GallaRadius.lg),
          border: Border.all(color: GallaColors.line),
        ),
        child: content,
      ),
    );
  }
}

class _SubtitleRow extends StatelessWidget {
  const _SubtitleRow({
    required this.txn,
    required this.timeStr,
    required this.s,
  });
  final Txn txn;
  final String timeStr;
  final S s;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(timeStr, style: GallaType.captionSm),
        if (txn.isCredit) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: GallaColors.udhaarSoft,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Udhaar',
              style: GallaType.badge.copyWith(
                fontSize: 9,
                color: GallaColors.udhaar,
              ),
            ),
          ),
        ],
        if (txn.note != null && txn.note!.isNotEmpty) ...[
          const SizedBox(width: 5),
          Text('·', style: GallaType.captionSm),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              txn.note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GallaType.captionSm,
            ),
          ),
        ],
      ],
    );
  }
}

// ── PartyBalanceLabel ──────────────────────────────────────────────────────────

class PartyBalanceLabel extends StatelessWidget {
  const PartyBalanceLabel({
    super.key,
    required this.balanceMinor,
    required this.currency,
    required this.s,
  });

  final int balanceMinor;
  final String currency;
  final S s;

  @override
  Widget build(BuildContext context) {
    if (balanceMinor == 0) {
      return Text(s.settled, style: GallaType.caption);
    }
    final owesYou = balanceMinor > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          owesYou ? s.theyOweYou : s.youOweThem,
          style: GallaType.labelSm.copyWith(
            color: owesYou ? GallaColors.udhaar : GallaColors.moneyOut,
          ),
        ),
        Text(
          Money(balanceMinor.abs(), currency: currency).format(),
          style: GallaType.numberSm.copyWith(
            fontSize: 14,
            color: owesYou ? GallaColors.udhaar : GallaColors.moneyOut,
          ),
        ),
      ],
    );
  }
}

// ── DateGroupHeader ─────────────────────────────────────────────────────────────
/// Used in ledger/transaction lists to group by date.

class DateGroupHeader extends StatelessWidget {
  const DateGroupHeader({super.key, required this.date});
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = DateUtils.isSameDay(date, now);
    final isYesterday = DateUtils.isSameDay(
      date,
      now.subtract(const Duration(days: 1)),
    );

    final label = isToday
        ? 'Today'
        : isYesterday
        ? 'Yesterday'
        : DateFormat('EEE, d MMM').format(date);

    return Padding(
      padding: const EdgeInsets.only(
        top: GallaSpacing.base,
        bottom: GallaSpacing.sm,
      ),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: GallaType.overline),
          const SizedBox(width: GallaSpacing.sm),
          Expanded(child: Container(height: 1, color: GallaColors.line)),
        ],
      ),
    );
  }
}

// ── Leading category/direction badge (only used by TransactionTile) ────────────

class _DirectionBadge extends StatelessWidget {
  const _DirectionBadge({required this.direction, this.category});
  final Direction direction;
  final String? category;

  static IconData _categoryIcon(String cat) {
    return switch (cat.toLowerCase()) {
      'sales' || 'sale' => Icons.storefront_outlined,
      'services' || 'service' => Icons.miscellaneous_services_outlined,
      'customer payment' => Icons.person_outline_rounded,
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
      _ => Icons.receipt_long_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isIn = direction == Direction.moneyIn;
    final bgColor = isIn ? GallaColors.moneyInSoft : GallaColors.moneyOutSoft;
    final fgColor = isIn ? GallaColors.moneyIn : GallaColors.moneyOut;
    final icon = category != null
        ? _categoryIcon(category!)
        : (isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(GallaRadius.md),
      ),
      child: Icon(icon, color: fgColor, size: 20),
    );
  }
}
