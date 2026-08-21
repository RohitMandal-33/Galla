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
    this.label = 'Cash Available',
  });

  final int cashOnHandMinor;
  final int moneyInMinor;
  final int moneyOutMinor;
  final String currency;
  final VoidCallback? onViewReport;
  final String label;

  @override
  Widget build(BuildContext context) {
    String m(int v) => Money(v, currency: currency).format();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      decoration: BoxDecoration(
        color: GallaColors.brand,
        borderRadius: BorderRadius.circular(GallaRadius.xl),
        // Subtle gradient overlay for depth
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF243E30), Color(0xFF1A3B2E)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: label + view report ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white60,
                  letterSpacing: 0.3,
                ),
              ),
              if (onViewReport != null)
                GestureDetector(
                  onTap: onViewReport,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(GallaRadius.sm),
                    ),
                    child: const Text(
                      'View Report',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Hero balance ─────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(animation),
                child: child,
              ),
            ),
            child: Text(
              m(cashOnHandMinor),
              key: ValueKey(cashOnHandMinor),
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -1.2,
                height: 1.0,
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
                  label: 'Money In',
                  value: m(moneyInMinor),
                  icon: Icons.arrow_downward_rounded,
                  color: const Color(0xFF6EDB96),
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.12)),
              Expanded(
                child: _BalanceFigure(
                  label: 'Money Out',
                  value: m(moneyOutMinor),
                  icon: Icons.arrow_upward_rounded,
                  color: const Color(0xFFFF9595),
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
        crossAxisAlignment: leftAlign ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: leftAlign ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (!leftAlign) ...[
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w500)),
                const SizedBox(width: 4),
                Icon(icon, size: 12, color: Colors.white54),
              ] else ...[
                Icon(icon, size: 12, color: Colors.white54),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w500)),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: -0.3,
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
              child: const Icon(Icons.people_outline_rounded, color: GallaColors.udhaar, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customers owe you',
                    style: TextStyle(
                      fontSize: 11,
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
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: GallaColors.udhaar,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$partyCount ${partyCount == 1 ? "customer" : "customers"}',
                        style: TextStyle(
                          fontSize: 11,
                          color: GallaColors.udhaar.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: GallaColors.udhaar.withValues(alpha: 0.7), size: 20),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: GallaColors.ink,
              letterSpacing: -0.1,
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
  });

  final Party party;
  final String currency;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final initials = party.name.isNotEmpty
        ? party.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    final balanceMinor = party.balanceMinor;
    final owesMe = balanceMinor > 0;
    final iOweThem = balanceMinor < 0;
    final settled = balanceMinor == 0;

    final avatarBg = owesMe ? GallaColors.udhaarSoft : (iOweThem ? GallaColors.moneyOutSoft : GallaColors.brandSoft);
    final avatarFg = owesMe ? GallaColors.udhaar : (iOweThem ? GallaColors.moneyOut : GallaColors.brand);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: GallaSpacing.base, vertical: GallaSpacing.md),
        decoration: BoxDecoration(
          color: GallaColors.surface,
          borderRadius: BorderRadius.circular(GallaRadius.card),
          border: Border.all(color: GallaColors.line),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: avatarFg,
                ),
              ),
            ),
            const SizedBox(width: GallaSpacing.md),

            // Name + phone
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    party.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: GallaColors.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (party.phone != null && party.phone!.isNotEmpty)
                    Text(
                      party.phone!,
                      style: const TextStyle(fontSize: 12, color: GallaColors.muted),
                    ),
                ],
              ),
            ),

            // Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  settled
                      ? 'Settled'
                      : owesMe
                          ? 'They owe'
                          : 'You owe',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    color: settled ? GallaColors.muted : (owesMe ? GallaColors.udhaar : GallaColors.moneyOut),
                  ),
                ),
                if (!settled)
                  Text(
                    Money(balanceMinor.abs(), currency: currency).format(),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: owesMe ? GallaColors.udhaar : GallaColors.moneyOut,
                      letterSpacing: -0.3,
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

enum GallaBadgeType { cash, qr, bank, udhaar, income, expense, pending, settled }

class GallaStatusBadge extends StatelessWidget {
  const GallaStatusBadge({super.key, required this.type});
  final GallaBadgeType type;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, icon) = switch (type) {
      GallaBadgeType.cash => ('Cash', GallaColors.brandSofter, GallaColors.brand, Icons.payments_outlined),
      GallaBadgeType.qr => ('QR', GallaColors.blueSoft, GallaColors.blue, Icons.qr_code_2_rounded),
      GallaBadgeType.bank => ('Bank', GallaColors.blueSoft, GallaColors.blue, Icons.account_balance_outlined),
      GallaBadgeType.udhaar => ('Udhaar', GallaColors.udhaarSoft, GallaColors.udhaar, Icons.pending_outlined),
      GallaBadgeType.income => ('Income', GallaColors.moneyInSoft, GallaColors.moneyIn, Icons.add_rounded),
      GallaBadgeType.expense => ('Expense', GallaColors.moneyOutSoft, GallaColors.moneyOut, Icons.remove_rounded),
      GallaBadgeType.pending => ('Pending', GallaColors.udhaarSoft, GallaColors.udhaar, Icons.schedule_rounded),
      GallaBadgeType.settled => ('Settled', GallaColors.moneyInSoft, GallaColors.moneyIn, Icons.check_rounded),
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
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: GallaSpacing.xxl, vertical: GallaSpacing.xxxl),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: GallaColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GallaSpacing.xs),
            Text(
              body,
              style: const TextStyle(fontSize: 13, color: GallaColors.muted, height: 1.5),
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

class _GallaSkeletonBlockState extends State<GallaSkeletonBlock> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
          ...List.generate(4, (i) => Padding(
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
                  const GallaSkeletonBlock(width: 40, height: 40, radius: GallaRadius.md),
                  const SizedBox(width: GallaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GallaSkeletonBlock(width: 120 + (i % 3) * 20.0, height: 12),
                        const SizedBox(height: 6),
                        const GallaSkeletonBlock(width: 80, height: 10),
                      ],
                    ),
                  ),
                  const GallaSkeletonBlock(width: 60, height: 14),
                ],
              ),
            ),
          )),
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
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
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
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: widget.bgColor,
            borderRadius: BorderRadius.circular(GallaRadius.lg),
            border: Border.all(color: widget.color.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(GallaRadius.sm),
                ),
                child: Icon(widget.icon, color: widget.color, size: 16),
              ),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
    final effectiveColor = color ??
        switch (direction) {
          Direction.moneyIn => GallaColors.moneyIn,
          Direction.moneyOut => GallaColors.moneyOut,
          null => GallaColors.ink,
        };

    final formatted = Money(minor, currency: currency).format();
    final sign = showSign && direction != null ? (direction == Direction.moneyIn ? '+' : '−') : '';

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

// ── GallaPaymentMethodSelector ─────────────────────────────────────────────────
/// Segmented payment method selector: Cash | QR | Bank | Udhaar

class GallaPaymentMethodSelector extends StatelessWidget {
  const GallaPaymentMethodSelector({
    super.key,
    required this.isUdhaar,
    required this.onChanged,
  });

  final bool isUdhaar;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: GallaColors.canvas,
        borderRadius: BorderRadius.circular(GallaRadius.md),
        border: Border.all(color: GallaColors.line),
      ),
      child: Row(
        children: [
          _MethodTab(
            label: 'Cash',
            icon: Icons.payments_outlined,
            selected: !isUdhaar,
            color: GallaColors.brand,
            onTap: () => onChanged(false),
          ),
          _MethodTab(
            label: 'Udhaar',
            icon: Icons.pending_outlined,
            selected: isUdhaar,
            color: GallaColors.udhaar,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _MethodTab extends StatelessWidget {
  const _MethodTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(GallaRadius.sm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: selected ? color : GallaColors.muted),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? color : GallaColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── GallaConfirmationOverlay ────────────────────────────────────────────────────
/// Success checkmark animation shown after saving.

class GallaSuccessCheck extends StatefulWidget {
  const GallaSuccessCheck({super.key, this.color = GallaColors.moneyIn});
  final Color color;

  @override
  State<GallaSuccessCheck> createState() => _GallaSuccessCheckState();
}

class _GallaSuccessCheckState extends State<GallaSuccessCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
      ),
    );
  }
}
