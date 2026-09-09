import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_guard.dart';
import '../../../core/theme/galla_theme.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _featuresKey = GlobalKey();

  static const _features = [
    (
      Icons.account_balance_wallet_outlined,
      'Cash Pulse',
      'See cash in hand, today\'s in and out, and whether the drawer is healthy — without opening a spreadsheet.',
    ),
    (
      Icons.menu_book_outlined,
      'Udhaar Ledger',
      'Track who owes you and whom you owe. One tap to record credit, collection, or a reminder.',
    ),
    (
      Icons.inventory_2_outlined,
      'Inventory',
      'Know what is on the shelf and what is running low. Adjust stock as sales happen.',
    ),
    (
      Icons.receipt_long_outlined,
      'Invoicing',
      'Create professional invoices from the same khata. Share as PDF when a customer asks.',
    ),
  ];

  void _scrollToFeatures() {
    final ctx = _featuresKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: GallaAnimations.base,
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  Future<void> _onGetStarted() async {
    await requireAuth(
      context,
      ref,
      reason: 'Create a free account to set up your shop and start recording.',
    );
  }

  Future<void> _onFeatureTap(String title) async {
    await requireAuth(
      context,
      ref,
      reason: 'Log in to use $title in your own khata.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GallaColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverToBoxAdapter(child: _buildHero()),
                  SliverToBoxAdapter(
                    child: Padding(
                      key: _featuresKey,
                      padding: const EdgeInsets.fromLTRB(
                        GallaSpacing.xl,
                        GallaSpacing.lg,
                        GallaSpacing.xl,
                        GallaSpacing.sm,
                      ),
                      child: Text(
                        'What you can do',
                        style: GallaType.cardTitle,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GallaSpacing.xl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: _features.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: GallaSpacing.md),
                      itemBuilder: (context, i) {
                        final f = _features[i];
                        return _FeatureCard(
                          icon: f.$1,
                          title: f.$2,
                          body: f.$3,
                          onTap: () => _onFeatureTap(f.$2),
                        );
                      },
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: GallaSpacing.xxxl),
                  ),
                ],
              ),
            ),
            _StickyCtas(
              onSignIn: () => context.push(
                '/login',
                extra: {'from': '/galla', 'mode': 'login'},
              ),
              onGetStarted: _onGetStarted,
              onExploreGuest: _scrollToFeatures,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GallaSpacing.xl,
        GallaSpacing.base,
        GallaSpacing.xl,
        GallaSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: GallaColors.brandSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(6),
            child: Image.asset(
              'assets/images/galla_logo.png',
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.storefront_rounded,
                size: 20,
                color: GallaColors.brand,
              ),
            ),
          ),
          const SizedBox(width: GallaSpacing.sm),
          Text('Galla', style: GallaType.numberMd),
        ],
      ),
    );
  }

  Widget _buildHero() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        GallaSpacing.xl,
        GallaSpacing.lg,
        GallaSpacing.xl,
        GallaSpacing.base,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(GallaSpacing.xl),
        decoration: BoxDecoration(
          gradient: GallaColors.heroGradient,
          borderRadius: BorderRadius.circular(GallaRadius.xl),
          boxShadow: GallaElevation.hero,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your shop, on one screen',
              style: GallaType.numberXl.copyWith(color: Colors.white),
            ),
            const SizedBox(height: GallaSpacing.sm),
            Text(
              'Cash, udhaar, stock and invoices — a digital khata built for kiranas and small businesses. Browse the product first; sign in when you are ready.',
              style: GallaType.body.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GallaColors.surface,
      borderRadius: BorderRadius.circular(GallaRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(GallaRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(GallaSpacing.base),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(GallaRadius.lg),
            border: Border.all(color: GallaColors.line),
            boxShadow: GallaElevation.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: GallaColors.brandSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: GallaColors.brand, size: 22),
              ),
              const SizedBox(width: GallaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GallaType.tileTitle),
                    const SizedBox(height: 4),
                    Text(body, style: GallaType.caption.copyWith(height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickyCtas extends StatelessWidget {
  const _StickyCtas({
    required this.onSignIn,
    required this.onGetStarted,
    required this.onExploreGuest,
  });

  final VoidCallback onSignIn;
  final VoidCallback onGetStarted;
  final VoidCallback onExploreGuest;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GallaColors.surface,
      elevation: 8,
      shadowColor: GallaColors.brand.withValues(alpha: 0.08),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            GallaSpacing.xl,
            GallaSpacing.md,
            GallaSpacing.xl,
            GallaSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onSignIn,
                      child: const Text('Sign In'),
                    ),
                  ),
                  const SizedBox(width: GallaSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: onGetStarted,
                      child: const Text('Get Started'),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onExploreGuest,
                child: Text(
                  'Explore as Guest',
                  style: GallaType.caption.copyWith(
                    color: GallaColors.brand,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
