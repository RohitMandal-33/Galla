import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/locale.dart';
import '../../core/money/money.dart';
import '../../core/providers.dart';
import '../../core/theme/galla_theme.dart';
import '../../data/demo_seeder.dart';
import '../../data/galla_repository.dart';
import '../../domain/models.dart';
import '../../shared/widgets/galla_components.dart';
import '../../shared/widgets/galla_network_image.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _step = 0;

  // Form State
  final _nameCtrl = TextEditingController(text: 'My Business');
  String _businessType = 'Kirana / Grocery';
  final String _currency = 'NPR';
  String _locale = 'ne';
  final _balanceCtrl = TextEditingController(text: '15000');
  bool _loading = false;

  static const _businessTypes = [
    (
      'Kirana / Retail',
      Icons.storefront_outlined,
      'https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&w=300&q=80',
    ),
    (
      'Wholesale',
      Icons.inventory_2_outlined,
      'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=300&q=80',
    ),
    (
      'Restaurant / Cafe',
      Icons.restaurant_outlined,
      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=300&q=80',
    ),
    (
      'Hardware',
      Icons.build_outlined,
      'https://images.unsplash.com/photo-1581783342308-f792dbdd27c5?auto=format&fit=crop&w=300&q=80',
    ),
    (
      'Clothing / Apparel',
      Icons.checkroom_outlined,
      'https://images.unsplash.com/photo-1441986300917-64674bd600d8?auto=format&fit=crop&w=300&q=80',
    ),
    (
      'Electronics',
      Icons.devices_outlined,
      'https://images.unsplash.com/photo-1550009158-9ebf69173e03?auto=format&fit=crop&w=300&q=80',
    ),
    (
      'Pharmacy',
      Icons.local_pharmacy_outlined,
      'https://images.unsplash.com/photo-1586015555751-63c25aa26388?auto=format&fit=crop&w=300&q=80',
    ),
    (
      'Service / Other',
      Icons.business_center_outlined,
      'https://images.unsplash.com/photo-1497366216548-37526070297c?auto=format&fit=crop&w=300&q=80',
    ),
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding({bool loadDemo = false}) async {
    setState(() => _loading = true);
    final repo = ref.read(repositoryProvider);

    if (loadDemo) {
      await DemoSeeder.seedNepaliKirana(repo);
      // Demo seeding already marks onboardingDone; ensure demo auth as well.
      final s = await repo.loadSettings();
      if (!s.isLoggedIn) {
        await repo.saveSettings(
          s.copyWith(
            isLoggedIn: true,
            authEmail: GallaRepository.demoEmail,
            authIsDemo: true,
          ),
        );
      }
    } else {
      final current = await repo.loadSettings();
      await repo.saveSettings(
        current.copyWith(
          businessName: _nameCtrl.text.trim().isNotEmpty
              ? _nameCtrl.text.trim()
              : 'My Store',
          currency: _currency,
          locale: _locale,
          onboardingDone: true,
          isLoggedIn: true,
          authEmail: current.authEmail ?? 'guest@local',
        ),
      );

      final startingMinor = Money.parseToMinor(_balanceCtrl.text);
      if (startingMinor > 0) {
        await repo.addEntry(
          direction: Direction.moneyIn,
          amountMinor: startingMinor,
          isAdjustment: true,
          note: 'Opening drawer cash',
          category: 'Starting Balance',
        );
      }
    }

    await applyAppLocale(_locale);
    ref.invalidate(settingsProvider);
    ref.invalidate(transactionsProvider);
    ref.invalidate(partiesProvider);
    ref.invalidate(inventoryProvider);

    if (mounted) {
      context.go('/galla');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GallaColors.canvas,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Progress indicator dots
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: List.generate(4, (i) {
                            return AnimatedContainer(
                              duration: GallaAnimations.fast,
                              margin: const EdgeInsets.only(right: 6),
                              width: _step == i ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _step == i
                                    ? GallaColors.brand
                                    : GallaColors.line,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            );
                          }),
                        ),
                        if (_step < 3)
                          TextButton(
                            onPressed: () =>
                                _completeOnboarding(loadDemo: false),
                            child: const Text('Skip'),
                          ),
                      ],
                    ),
                  ),

                  // Step Pages
                  Expanded(
                    child: PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) => setState(() => _step = i),
                      children: [
                        _buildWelcomeStep(),
                        _buildBusinessTypeStep(),
                        _buildStartingBalanceStep(),
                        _buildReadyStep(),
                      ],
                    ),
                  ),

                  // Bottom Button Row
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          if (_step < 3) {
                            _pageCtrl.nextPage(
                              duration: GallaAnimations.base,
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _completeOnboarding(loadDemo: false);
                          }
                        },
                        child: Text(
                          _step == 0
                              ? 'Get Started'
                              : (_step == 3 ? 'Launch My Galla' : 'Continue'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 120,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 20),
            child: GallaNetworkImage(
              imageUrl: 'https://images.unsplash.com/photo-1534723452862-4c874018d66d?auto=format&fit=crop&w=600&q=80',
              borderRadius: 20,
              fit: BoxFit.cover,
              cacheWidth: 600,
              overlayGradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  GallaColors.canvas.withValues(alpha: 0.9),
                ],
              ),
              fallbackIcon: Icons.storefront_rounded,
            ),
          ),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: GallaColors.brandSoft,
              borderRadius: BorderRadius.circular(24),
              boxShadow: GallaElevation.card,
            ),
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              'assets/images/galla_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Your Business Operating System',
            style: GallaType.numberXl,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Simple digital khata, cash pulse, and smart inventory crafted for South Asian retail and small businesses.',
            style: GallaType.body.copyWith(
              fontSize: 14,
              height: 1.5,
              color: GallaColors.muted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Language choice — first thing a merchant decides, changeable
          // later from the business profile.
          Row(
            key: const ValueKey('onboarding-language'),
            children: [
              Expanded(
                child: GallaFilterChip(
                  label: 'English',
                  selected: _locale != 'ne',
                  onTap: () => setState(() => _locale = 'en'),
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GallaFilterChip(
                  label: 'नेपाली',
                  selected: _locale == 'ne',
                  onTap: () => setState(() => _locale = 'ne'),
                  fullWidth: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: GallaColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GallaColors.line),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: GallaColors.brand,
                ),
                SizedBox(width: 8),
                Text(
                  '100% Offline-first & Private on device',
                  style: GallaType.label.copyWith(color: GallaColors.brand),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessTypeStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tell us about your store', style: GallaType.screenTitle),
          const SizedBox(height: 6),
          Text(
            'Enter your shop name and select your category.',
            style: GallaType.body.copyWith(color: GallaColors.muted),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Business / Shop Name',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
          ),
          const SizedBox(height: 16),
          Text('Store Category', style: GallaType.subtitleSm),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _businessTypes.length,
              itemBuilder: (context, i) {
                final item = _businessTypes[i];
                final isSelected = _businessType == item.$1;
                return GestureDetector(
                  onTap: () => setState(() => _businessType = item.$1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GallaColors.brandSoft
                          : GallaColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? GallaColors.brand
                            : GallaColors.line,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        GallaNetworkImage(
                          imageUrl: item.$3,
                          width: 36,
                          height: 36,
                          borderRadius: 8,
                          cacheWidth: 100,
                          cacheHeight: 100,
                          fallbackIcon: item.$2,
                          fallbackColor: isSelected
                              ? GallaColors.brand
                              : GallaColors.muted,
                          fallbackBgColor: isSelected
                              ? GallaColors.brandSoft
                              : GallaColors.surface2,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.$1,
                            style: GallaType.caption.copyWith(
                              color: isSelected
                                  ? GallaColors.brand
                                  : GallaColors.ink,
                              fontWeight: isSelected ? FontWeight.w600 : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartingBalanceStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Starting Cash in Drawer', style: GallaType.screenTitle),
          const SizedBox(height: 6),
          Text(
            'How much cash do you have in your physical cash till today?',
            style: GallaType.body.copyWith(color: GallaColors.muted),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _balanceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: GallaType.total.copyWith(color: GallaColors.brand),
            decoration: InputDecoration(
              prefixText: 'Rs. ',
              prefixStyle: GallaType.screenTitle.copyWith(
                fontWeight: FontWeight.w700,
                color: GallaColors.brand,
              ),
              labelText: 'Opening Cash Balance',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Quick Presets:',
            style: GallaType.chipLabel.copyWith(color: GallaColors.muted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['5000', '15000', '35000', '50000'].map((preset) {
              return ActionChip(
                label: Text('Rs. $preset'),
                onPressed: () => setState(() => _balanceCtrl.text = preset),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildReadyStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: GallaColors.moneyInSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 40,
              color: GallaColors.moneyIn,
            ),
          ),
          const SizedBox(height: 20),
          Text('Ready to take off!', style: GallaType.screenTitle),
          const SizedBox(height: 8),
          Text(
            'Your business configuration is set. You can also load realistic demo data right now to explore all features.',
            style: GallaType.body.copyWith(
              height: 1.4,
              color: GallaColors.muted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => _completeOnboarding(loadDemo: true),
            icon: const Icon(
              Icons.auto_fix_high_rounded,
              color: GallaColors.gold,
            ),
            label: const Text('Load Demo Store (Explore features)'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: GallaColors.gold),
              foregroundColor: GallaColors.gold,
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }
}

class StartingBalanceScreen extends StatelessWidget {
  const StartingBalanceScreen({super.key});

  @override
  Widget build(BuildContext context) => const OnboardingScreen();
}
