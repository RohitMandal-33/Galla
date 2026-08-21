import 'package:flutter/material.dart';

import '../../core/money/money.dart';
import '../../core/theme/galla_theme.dart';
import '../../domain/models.dart';

// ── MoneyText ──────────────────────────────────────────────────────────────────

enum MoneyTextSize { hero, display, large, normal, small }

class MoneyText extends StatelessWidget {
  const MoneyText(
    this.minor, {
    super.key,
    required this.currency,
    this.large = false,
    this.direction,
    this.size = MoneyTextSize.normal,
  });

  final int minor;
  final String currency;
  final bool large;
  final Direction? direction;
  final MoneyTextSize size;

  @override
  Widget build(BuildContext context) {
    final color = switch (direction) {
      Direction.moneyIn => GallaColors.moneyIn,
      Direction.moneyOut => GallaColors.moneyOut,
      null => GallaColors.ink,
    };

    final effectiveSize = large ? MoneyTextSize.display : size;

    final style = switch (effectiveSize) {
      MoneyTextSize.hero => Theme.of(context).textTheme.displayLarge,
      MoneyTextSize.display => Theme.of(context).textTheme.displaySmall,
      MoneyTextSize.large => Theme.of(context).textTheme.titleLarge,
      MoneyTextSize.normal => Theme.of(context).textTheme.titleMedium,
      MoneyTextSize.small => Theme.of(context).textTheme.bodyMedium,
    };

    return Text(
      Money(minor, currency: currency).format(),
      style: style?.copyWith(color: color, fontVariations: const [FontVariation('wght', 700)]),
    );
  }
}

// ── DirectionBadge ──────────────────────────────────────────────────────────────

class DirectionBadge extends StatelessWidget {
  const DirectionBadge({super.key, required this.direction, this.category});
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
      'electricity / utility' || 'electricity' || 'utility' => Icons.bolt_outlined,
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
    final icon = category != null ? _categoryIcon(category!) : (isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded);

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(GallaRadius.md),
      ),
      child: Icon(icon, color: fgColor, size: 19),
    );
  }
}

// ── EmptyState ──────────────────────────────────────────────────────────────────

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.icon,
    this.headline,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData? icon;
  final String? headline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(GallaSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: GallaColors.brandSofter,
              borderRadius: BorderRadius.circular(GallaRadius.xl),
            ),
            child: Icon(
              icon ?? Icons.receipt_long_outlined,
              size: 30,
              color: GallaColors.brand.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: GallaSpacing.base),
          if (headline != null) ...[
            Text(
              headline!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: GallaColors.ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: GallaSpacing.xs),
          ],
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GallaSpacing.lg),
          FilledButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
