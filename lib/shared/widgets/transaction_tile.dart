import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/strings.dart';
import '../../core/money/money.dart';
import '../../core/theme/galla_theme.dart';
import '../../domain/models.dart';
import 'ui.dart';

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
    final title = txn.partyName ??
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
    final formatted = '$sign ${Money(txn.amountMinor, currency: currency).format()}';

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: GallaSpacing.base,
        vertical: GallaSpacing.md,
      ),
      child: Row(
        children: [
          // ── Leading badge ──────────────────────────────────────────────
          DirectionBadge(direction: txn.direction, category: txn.category),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: GallaColors.ink,
                  ),
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
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: amountColor,
              letterSpacing: -0.2,
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
  const _SubtitleRow({required this.txn, required this.timeStr, required this.s});
  final Txn txn;
  final String timeStr;
  final S s;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(timeStr, style: const TextStyle(fontSize: 11, color: GallaColors.muted)),
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
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: GallaColors.udhaar,
              ),
            ),
          ),
        ],
        if (txn.note != null && txn.note!.isNotEmpty) ...[
          const SizedBox(width: 5),
          const Text('·', style: TextStyle(fontSize: 11, color: GallaColors.muted)),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              txn.note!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: GallaColors.muted),
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
      return Text(s.settled, style: const TextStyle(color: GallaColors.muted, fontSize: 12));
    }
    final owesYou = balanceMinor > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          owesYou ? s.theyOweYou : s.youOweThem,
          style: TextStyle(
            color: owesYou ? GallaColors.udhaar : GallaColors.moneyOut,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        Text(
          Money(balanceMinor.abs(), currency: currency).format(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
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
    final isYesterday = DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)));

    final label = isToday
        ? 'Today'
        : isYesterday
            ? 'Yesterday'
            : DateFormat('EEE, d MMM').format(date);

    return Padding(
      padding: const EdgeInsets.only(top: GallaSpacing.base, bottom: GallaSpacing.sm),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: GallaColors.muted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: GallaSpacing.sm),
          Expanded(child: Container(height: 1, color: GallaColors.line)),
        ],
      ),
    );
  }
}
