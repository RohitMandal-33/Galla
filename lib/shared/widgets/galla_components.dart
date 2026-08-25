import 'package:flutter/material.dart';

import '../../core/money/money.dart';
import '../../core/theme/galla_theme.dart';
import '../../domain/models.dart';

// ── GallaBalanceCard ───────────────────────────────────────────────────────────
/// Dark brand-green hero card showing daily financial summary.

class GallaBalanceCard extends StatelessWidget {
  const GallaBalanceCard({
    super.key,
    required this.cashOnHandMinor,
    required this.moneyInMinor,
    required this.moneyOutMinor,
    required this.currency,
    this.onViewReport,
    this.label = 'Today\'s Cash',
    this.trendPercent,
  });

  final int cashOnHandMinor;
  final int moneyInMinor;
  final int moneyOutMinor;
  final String currency;
  final VoidCallback? onViewReport;
  final String label;
  final double? trendPercent;

  @override
  Widget build(BuildContext context) {
    String m(int v) => Money(v, currency: currency).format();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: GallaColors.brand,
        borderRadius: BorderRadius.circular(GallaRadius.xl),
        boxShadow: GallaElevation.hero,
        gradient: GallaColors.heroGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: label + trend + view report ─────────────────────────
          Row(
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Text(
                      label,
                      style: GallaType.label.copyWith(
                        letterSpacing: 0.3,
                        color: Colors.white70,
                      ),
                    ),
                    if (trendPercent != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (trendPercent! >= 0
                                      ? GallaColors.moneyInOnDark
                                      : GallaColors.moneyOutOnDark)
                                  .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(GallaRadius.xs),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              trendPercent! >= 0
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
                              size: 10,
                              color: trendPercent! >= 0
                                  ? GallaColors.moneyInOnDark
                                  : GallaColors.moneyOutOnDark,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${trendPercent!.abs().toStringAsFixed(1)}% vs yest.',
                              style: GallaType.badge.copyWith(
                                color: trendPercent! >= 0
                                    ? GallaColors.moneyInOnDark
                                    : GallaColors.moneyOutOnDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              if (onViewReport != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onViewReport,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(GallaRadius.sm),
                    ),
                    child: Text(
                      'Report',
                      style: GallaType.labelSm.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),

          // ── Hero balance ─────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: GallaAnimations.base,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: FittedBox(
              key: ValueKey(cashOnHandMinor),
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                m(cashOnHandMinor),
                style: GallaType.hero.copyWith(
                  height: 1.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // ── Divider ──────────────────────────────────────────────────────
          Container(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 16),

          // ── Money in / out row ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _BalanceFigure(
                  label: 'Cash In',
                  value: m(moneyInMinor),
                  icon: Icons.arrow_downward_rounded,
                  color: GallaColors.moneyInOnDark,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.12),
              ),
              Expanded(
                child: _BalanceFigure(
                  label: 'Cash Out',
                  value: m(moneyOutMinor),
                  icon: Icons.arrow_upward_rounded,
                  color: GallaColors.moneyOutOnDark,
                  leftAlign: false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── GallaMetricCard ────────────────────────────────────────────────────────────
/// Financial metric tile for Revenue, Profit, Outstanding with trend % and color.

class GallaMetricCard extends StatelessWidget {
  const GallaMetricCard({
    super.key,
    required this.title,
    required this.value,
    this.trendPercent,
    this.isPositiveTrend = true,
    this.accentColor = GallaColors.brand,
    this.icon,
    this.onTap,
  });

  final String title;
  final String value;
  final double? trendPercent;
  final bool isPositiveTrend;
  final Color accentColor;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: GallaColors.surface,
          borderRadius: BorderRadius.circular(GallaRadius.lg),
          border: Border.all(color: GallaColors.line),
          boxShadow: GallaElevation.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GallaType.labelSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    icon,
                    size: 14,
                    color: accentColor.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GallaType.number.copyWith(letterSpacing: -0.4),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (trendPercent != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    isPositiveTrend
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 11,
                    color: isPositiveTrend
                        ? GallaColors.moneyIn
                        : GallaColors.moneyOut,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${trendPercent!.toStringAsFixed(0)}%',
                    style: GallaType.badge.copyWith(
                      color: isPositiveTrend
                          ? GallaColors.moneyIn
                          : GallaColors.moneyOut,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── GallaActionCard ────────────────────────────────────────────────────────────
/// Action Center recommendation tile with direct CTA.

class GallaActionCard extends StatelessWidget {
  const GallaActionCard({
    super.key,
    required this.title,
    required this.badge,
    this.subtitle,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.bolt_rounded,
    this.badgeColor = GallaColors.udhaar,
    this.badgeBgColor = GallaColors.udhaarSoft,
    this.iconColor = GallaColors.brand,
    this.iconBgColor = GallaColors.brandSoft,
  });

  final String title;
  final String badge;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;
  final Color badgeColor;
  final Color badgeBgColor;
  final Color iconColor;
  final Color iconBgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GallaColors.surface,
        borderRadius: BorderRadius.circular(GallaRadius.lg),
        border: Border.all(color: GallaColors.line),
        boxShadow: GallaElevation.card,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(GallaRadius.md),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: GallaType.subtitleSm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(GallaRadius.xs),
                      ),
                      child: Text(
                        badge,
                        style: GallaType.badge.copyWith(color: badgeColor),
                      ),
                    ),
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: GallaType.captionSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: GallaColors.brand,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                minimumSize: const Size(52, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(GallaRadius.sm),
                ),
                textStyle: GallaType.labelStrong,
              ),
              child: Text(
                actionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── GallaPaymentBadge ──────────────────────────────────────────────────────────
/// Visual badge identifying payment channels (Cash / Fonepay / eSewa / Khalti / Bank).

class GallaPaymentBadge extends StatelessWidget {
  const GallaPaymentBadge({super.key, required this.method});
  final String method;

  @override
  Widget build(BuildContext context) {
    final lower = method.toLowerCase();
    final Color bg;
    final Color fg;
    final String label;

    if (lower.contains('esewa')) {
      bg = GallaColors.esewaSoft;
      fg = GallaColors.esewa;
      label = 'eSewa';
    } else if (lower.contains('khalti')) {
      bg = GallaColors.khaltiSoft;
      fg = GallaColors.khalti;
      label = 'Khalti';
    } else if (lower.contains('fonepay') || lower.contains('qr')) {
      bg = GallaColors.fonepaySoft;
      fg = GallaColors.fonepay;
      label = 'QR/Fonepay';
    } else if (lower.contains('bank')) {
      bg = GallaColors.blueSoft;
      fg = GallaColors.blue;
      label = 'Bank';
    } else {
      bg = GallaColors.brandSoft;
      fg = GallaColors.brand;
      label = 'Cash';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(GallaRadius.xs),
      ),
      child: Text(label, style: GallaType.badge.copyWith(color: fg)),
    );
  }
}

// ── GallaStatusDot ────────────────────────────────────────────────────────────

class GallaStatusDot extends StatelessWidget {
  const GallaStatusDot({
    super.key,
    this.color = GallaColors.moneyIn,
    this.size = 7,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _BalanceFigure extends StatelessWidget {
  const _BalanceFigure({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.leftAlign = true,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool leftAlign;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: leftAlign ? 0 : GallaSpacing.base,
        right: leftAlign ? GallaSpacing.base : 0,
      ),
      child: Column(
        crossAxisAlignment: leftAlign
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: leftAlign
                ? MainAxisAlignment.start
                : MainAxisAlignment.end,
            children: [
              if (!leftAlign) ...[
                Text(
                  label,
                  style: GallaType.labelSm.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(icon, size: 12, color: Colors.white54),
              ] else ...[
                Icon(icon, size: 12, color: Colors.white54),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GallaType.labelSm.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white54,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GallaType.cardTitle.copyWith(
              letterSpacing: -0.3,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── GallaUdhaarCard ────────────────────────────────────────────────────────────
/// Amber summary card showing outstanding customer Udhaar.

class GallaUdhaarCard extends StatelessWidget {
  const GallaUdhaarCard({
    super.key,
    required this.totalUdhaarMinor,
    required this.partyCount,
    required this.currency,
    required this.onTap,
  });

  final int totalUdhaarMinor;
  final int partyCount;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = Money(totalUdhaarMinor, currency: currency).format();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: GallaColors.udhaarSofter,
          borderRadius: BorderRadius.circular(GallaRadius.lg),
          border: Border.all(color: GallaColors.udhaar.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: GallaColors.udhaarSoft,
                borderRadius: BorderRadius.circular(GallaRadius.md),
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                color: GallaColors.udhaar,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customers owe you',
                    style: GallaType.labelSm.copyWith(
                      fontWeight: FontWeight.w500,
                      color: GallaColors.udhaar.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        m,
                        style: GallaType.number.copyWith(
                          fontSize: 17,
                          color: GallaColors.udhaar,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$partyCount ${partyCount == 1 ? "customer" : "customers"}',
                        style: GallaType.labelSm.copyWith(
                          fontWeight: FontWeight.w500,
                          color: GallaColors.udhaar.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: GallaColors.udhaar.withValues(alpha: 0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── GallaSectionHeader ─────────────────────────────────────────────────────────

class GallaSectionHeader extends StatelessWidget {
  const GallaSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.topPadding = GallaSpacing.base,
    this.bottomPadding = GallaSpacing.sm,
  });

  final String title;
  final Widget? trailing;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GallaType.tileTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ── GallaPartyCard ─────────────────────────────────────────────────────────────
/// Party list tile with initials avatar and balance display.

class GallaPartyCard extends StatelessWidget {
  const GallaPartyCard({
    super.key,
    required this.party,
    required this.currency,
    required this.onTap,
    this.daysOverdue,
    this.lastActivity,
    this.onRemind,
  });

  final Party party;
  final String currency;
  final VoidCallback onTap;
  final int? daysOverdue;
  final String? lastActivity;
  final VoidCallback? onRemind;

  @override
  Widget build(BuildContext context) {
    final initials = party.name.isNotEmpty
        ? party.name
              .trim()
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : '?';

    final balanceMinor = party.balanceMinor;
    final owesMe = balanceMinor > 0;
    final iOweThem = balanceMinor < 0;
    final settled = balanceMinor == 0;

    final avatarBg = owesMe
        ? GallaColors.udhaarSoft
        : (iOweThem ? GallaColors.moneyOutSoft : GallaColors.brandSoft);
    final avatarFg = owesMe
        ? GallaColors.udhaar
        : (iOweThem ? GallaColors.moneyOut : GallaColors.brand);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: GallaSpacing.base,
          vertical: GallaSpacing.md,
        ),
        decoration: BoxDecoration(
          color: GallaColors.surface,
          borderRadius: BorderRadius.circular(GallaRadius.card),
          border: Border.all(color: GallaColors.line),
          boxShadow: GallaElevation.card,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: avatarBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GallaType.numberSm.copyWith(color: avatarFg),
              ),
            ),
            const SizedBox(width: GallaSpacing.md),

            // Name + phone + overdue pill
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          party.name,
                          style: GallaType.tileTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (daysOverdue != null && daysOverdue! > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: GallaColors.moneyOutSoft,
                            borderRadius: BorderRadius.circular(GallaRadius.xs),
                          ),
                          child: Text(
                            '${daysOverdue}d overdue',
                            style: GallaType.badge.copyWith(
                              fontSize: 9,
                              color: GallaColors.moneyOut,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (lastActivity != null)
                    Text(lastActivity!, style: GallaType.caption)
                  else if (party.phone != null && party.phone!.isNotEmpty)
                    Text(party.phone!, style: GallaType.caption),
                ],
              ),
            ),

            // Balance + Quick Action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  settled
                      ? 'Settled'
                      : owesMe
                      ? 'They owe'
                      : 'You owe',
                  style: GallaType.labelSm.copyWith(
                    fontSize: 10,
                    letterSpacing: 0.2,
                    color: settled
                        ? GallaColors.muted
                        : (owesMe ? GallaColors.udhaar : GallaColors.moneyOut),
                  ),
                ),
                if (!settled)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      Money(balanceMinor.abs(), currency: currency).format(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: GallaType.numberSm.copyWith(
                        color: owesMe
                            ? GallaColors.udhaar
                            : GallaColors.moneyOut,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── GallaStatusBadge ───────────────────────────────────────────────────────────
/// Small chip showing payment method or udhaar status.

enum GallaBadgeType {
  cash,
  qr,
  bank,
  udhaar,
  income,
  expense,
  pending,
  settled,
}

class GallaStatusBadge extends StatelessWidget {
  const GallaStatusBadge({super.key, required this.type});
  final GallaBadgeType type;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, icon) = switch (type) {
      GallaBadgeType.cash => (
        'Cash',
        GallaColors.brandSofter,
        GallaColors.brand,
        Icons.payments_outlined,
      ),
      GallaBadgeType.qr => (
        'QR',
        GallaColors.fonepaySoft,
        GallaColors.fonepay,
        Icons.qr_code_2_rounded,
      ),
      GallaBadgeType.bank => (
        'Bank',
        GallaColors.blueSoft,
        GallaColors.blue,
        Icons.account_balance_outlined,
      ),
      GallaBadgeType.udhaar => (
        'Udhaar',
        GallaColors.udhaarSoft,
        GallaColors.udhaar,
        Icons.pending_outlined,
      ),
      GallaBadgeType.income => (
        'Income',
        GallaColors.moneyInSoft,
        GallaColors.moneyIn,
        Icons.add_rounded,
      ),
      GallaBadgeType.expense => (
        'Expense',
        GallaColors.moneyOutSoft,
        GallaColors.moneyOut,
        Icons.remove_rounded,
      ),
      GallaBadgeType.pending => (
        'Pending',
        GallaColors.udhaarSoft,
        GallaColors.udhaar,
        Icons.schedule_rounded,
      ),
      GallaBadgeType.settled => (
        'Settled',
        GallaColors.moneyInSoft,
        GallaColors.moneyIn,
        Icons.check_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(GallaRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(label, style: GallaType.badge.copyWith(color: fg)),
        ],
      ),
    );
  }
}

// ── GallaFilterChip ─────────────────────────────────────────────────────────────
/// Single-select pill chip for filters and tab rows. The one true chip — use
/// this everywhere instead of feature-local copies.

class GallaFilterChip extends StatelessWidget {
  const GallaFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor = GallaColors.brand,
    this.fullWidth = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Accent used when selected. Defaults to brand; pass a semantic color
  /// (e.g. moneyOut for "Low Stock") when the filter carries meaning.
  final Color selectedColor;

  /// Stretch to fill available width (for Expanded / evenly-split rows).
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: GallaAnimations.fast,
        width: fullWidth ? double.infinity : null,
        alignment: fullWidth ? Alignment.center : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? selectedColor : GallaColors.surface,
          borderRadius: BorderRadius.circular(GallaRadius.pill),
          border: Border.all(
            color: selected ? selectedColor : GallaColors.line,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GallaType.chipLabel.copyWith(
            color: selected ? Colors.white : GallaColors.ink,
          ),
        ),
      ),
    );
  }
}

// ── GallaEmptyState ─────────────────────────────────────────────────────────────
/// Premium empty state widget with icon, headline, body copy, and optional action.

class GallaEmptyState extends StatelessWidget {
  const GallaEmptyState({
    super.key,
    required this.icon,
    required this.headline,
    required this.body,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  final IconData icon;
  final String headline;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final fg = iconColor ?? GallaColors.brand;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: GallaSpacing.xxl,
          vertical: GallaSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(GallaRadius.xl),
              ),
              child: Icon(icon, size: 34, color: fg.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: GallaSpacing.base),
            Text(
              headline,
              style: GallaType.cardTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GallaSpacing.xs),
            Text(
              body,
              style: GallaType.body.copyWith(
                height: 1.5,
                color: GallaColors.muted,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: GallaSpacing.xl),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── GallaSkeletonLoader ─────────────────────────────────────────────────────────
/// Shimmer skeleton placeholders for loading states.

class GallaSkeletonBlock extends StatefulWidget {
  const GallaSkeletonBlock({
    super.key,
    required this.width,
    required this.height,
    this.radius = GallaRadius.sm,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<GallaSkeletonBlock> createState() => _GallaSkeletonBlockState();
}

class _GallaSkeletonBlockState extends State<GallaSkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: GallaColors.line.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

class GallaHomeSkeletonLoader extends StatelessWidget {
  const GallaHomeSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: GallaSpacing.base),
      child: Column(
        children: [
          // Balance card skeleton
          Container(
            height: 170,
            decoration: BoxDecoration(
              color: GallaColors.brand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(GallaRadius.xl),
            ),
          ),
          const SizedBox(height: GallaSpacing.base),
          // Udhaar skeleton
          Container(
            height: 66,
            decoration: BoxDecoration(
              color: GallaColors.line,
              borderRadius: BorderRadius.circular(GallaRadius.lg),
            ),
          ),
          const SizedBox(height: GallaSpacing.xl),
          // Transaction skeletons
          ...List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: GallaSpacing.sm),
              child: Container(
                height: 66,
                decoration: BoxDecoration(
                  color: GallaColors.surface,
                  borderRadius: BorderRadius.circular(GallaRadius.lg),
                  border: Border.all(color: GallaColors.line),
                ),
                padding: const EdgeInsets.all(GallaSpacing.md),
                child: Row(
                  children: [
                    const GallaSkeletonBlock(
                      width: 40,
                      height: 40,
                      radius: GallaRadius.md,
                    ),
                    const SizedBox(width: GallaSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GallaSkeletonBlock(
                            width: 120 + (i % 3) * 20.0,
                            height: 12,
                          ),
                          const SizedBox(height: 6),
                          const GallaSkeletonBlock(width: 80, height: 10),
                        ],
                      ),
                    ),
                    const GallaSkeletonBlock(width: 60, height: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── GallaQuickActionButton ──────────────────────────────────────────────────────
/// Action button for the quick actions grid on the home screen.

class GallaQuickActionButton extends StatefulWidget {
  const GallaQuickActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  State<GallaQuickActionButton> createState() => _GallaQuickActionButtonState();
}

class _GallaQuickActionButtonState extends State<GallaQuickActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.96,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(GallaRadius.lg),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.22),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(GallaRadius.md),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: GallaType.chipLabel.copyWith(
                  fontWeight: FontWeight.w800,
                  color: widget.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── GallaMoneyDisplay ──────────────────────────────────────────────────────────
/// Standalone hero financial number display — currency symbol + amount.

class GallaMoneyDisplay extends StatelessWidget {
  const GallaMoneyDisplay({
    super.key,
    required this.minor,
    required this.currency,
    this.direction,
    this.fontSize = 40,
    this.color,
    this.showSign = false,
  });

  final int minor;
  final String currency;
  final Direction? direction;
  final double fontSize;
  final Color? color;
  final bool showSign;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ??
        switch (direction) {
          Direction.moneyIn => GallaColors.moneyIn,
          Direction.moneyOut => GallaColors.moneyOut,
          null => GallaColors.ink,
        };

    final formatted = Money(minor, currency: currency).format();
    final sign = showSign && direction != null
        ? (direction == Direction.moneyIn ? '+' : '−')
        : '';

    return Text(
      '$sign$formatted',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: effectiveColor,
        letterSpacing: -1.2,
        height: 1.0,
      ),
    );
  }
}
