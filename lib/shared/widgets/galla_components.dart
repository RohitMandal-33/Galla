import 'package:flutter/material.dart';

import '../../core/money/money.dart';
import '../../core/theme/galla_theme.dart';
import '../../domain/models.dart';
import 'galla_network_image.dart';

// ── SnackBar utilities ─────────────────────────────────────────────────────────

/// Shows a consistently-styled SnackBar that:
/// - Auto-dismisses after 5 seconds.
/// - Can be swiped away horizontally.
/// - Replaces any currently visible SnackBar (no stacking).
///
/// [action] is an optional action button. Use [ScaffoldMessenger.of(context)]
/// to obtain [messenger] before any async gap.
void showGallaSnackBar(
  ScaffoldMessengerState messenger,
  String message, {
  SnackBarAction? action,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        dismissDirection: DismissDirection.horizontal,
        action: action,
      ),
    );
}

/// [NavigatorObserver] that clears any visible SnackBar whenever the route
/// changes. Attach this to [GoRouter.observers] so notifications never bleed
/// into the next screen.
class GallaSnackBarClearObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _clear(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _clear(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _clear(newRoute);

  void _clear(Route<dynamic>? route) {
    final ctx = route?.navigator?.context;
    if (ctx != null && ctx.mounted) {
      ScaffoldMessenger.maybeOf(ctx)?.clearSnackBars();
    }
  }
}

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
        boxShadow: GallaElevation.hero,
        gradient: GallaColors.heroGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: label + view report ─────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GallaType.label.copyWith(
                    letterSpacing: 0.3,
                    color: Colors.white70,
                  ),
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
/// Party list row: name over last-activity/phone on the left, balance state
/// over amount on the right. Flat by design — lists provide dividers.

class GallaPartyCard extends StatelessWidget {
  const GallaPartyCard({
    super.key,
    required this.party,
    required this.currency,
    required this.onTap,
    this.lastActivity,
  });

  final Party party;
  final String currency;
  final VoidCallback onTap;

  /// Pre-formatted "last activity" line (e.g. "3d ago" or a date).
  final String? lastActivity;

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
    final balanceColor = owesMe
        ? GallaColors.udhaar
        : (iOweThem ? GallaColors.moneyOut : GallaColors.muted);

    final metaLine = lastActivity ?? party.phone;
    final hasMeta = metaLine != null && metaLine.isNotEmpty;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: GallaSpacing.base,
          vertical: GallaSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: avatarBg,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: GallaType.labelStrong.copyWith(
                  fontSize: 14,
                  color: avatarFg,
                ),
              ),
            ),
            const SizedBox(width: GallaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    party.name,
                    style: GallaType.bodyStrong.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasMeta) ...[
                    const SizedBox(height: 2),
                    Text(
                      metaLine,
                      style: GallaType.caption.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: GallaSpacing.sm),
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
                    fontSize: 11,
                    color: balanceColor,
                  ),
                ),
                if (!settled) ...[
                  const SizedBox(height: 2),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: Text(
                      Money(
                        balanceMinor.abs(),
                        currency: currency,
                      ).formatCompact(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: GallaType.number.copyWith(color: balanceColor),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
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
    this.imageUrl,
  });

  final IconData icon;
  final String headline;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;
  final String? imageUrl;

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
            if (imageUrl != null)
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(bottom: GallaSpacing.base),
                child: GallaNetworkImage(
                  imageUrl: imageUrl!,
                  width: 80,
                  height: 80,
                  borderRadius: 20,
                  cacheWidth: 160,
                  cacheHeight: 160,
                  fallbackIcon: icon,
                  fallbackColor: fg,
                  fallbackBgColor: fg.withValues(alpha: 0.08),
                ),
              )
            else
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

// ── GallaStatBlock ─────────────────────────────────────────────────────────────
/// Quiet typographic metric: label over amount. No container — grouping is
/// done with whitespace and alignment. Use for supporting metrics under a hero
/// figure or in report summaries.
class GallaStatBlock extends StatelessWidget {
  const GallaStatBlock({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
    this.alignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      crossAxisAlignment: alignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GallaType.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: GallaSpacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: alignment == CrossAxisAlignment.end
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Text(
            value,
            style: GallaType.numberLg.copyWith(
              letterSpacing: -0.5,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
    if (onTap != null) {
      content = Semantics(
        button: true,
        label: '$label $value',
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      );
    }
    return content;
  }
}

// ── GallaAttentionRow ──────────────────────────────────────────────────────────
/// Flat, single-line actionable item ("3 payments due", "2 products low").
/// Deliberately NOT a card: attention items sit on the canvas with dividers,
/// so only truly actionable content draws the eye.
class GallaAttentionRow extends StatelessWidget {
  const GallaAttentionRow({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onAction,
    this.subtitle,
    this.icon = Icons.bolt_rounded,
    this.iconColor = GallaColors.brand,
    this.iconBgColor = GallaColors.brandSoft,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onTap;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? onAction,
      borderRadius: BorderRadius.circular(GallaRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GallaSpacing.md),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(GallaRadius.sm),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: GallaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GallaType.bodyStrong.copyWith(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle!,
                      style: GallaType.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: GallaSpacing.sm),
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(48, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel),
            ),
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
