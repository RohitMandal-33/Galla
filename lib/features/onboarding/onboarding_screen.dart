import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../core/theme/galla_theme.dart';
import '../../data/galla_repository.dart';
import '../../domain/models.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _page = PageController();
  int _index = 0;

  Future<void> _finish({required bool skipBalance}) async {
    final repo = ref.read(repositoryProvider);
    final current = await repo.loadSettings();
    await repo.saveSettings(current.copyWith(onboardingDone: true));
    if (!mounted) return;
    if (skipBalance) {
      context.go('/galla');
    } else {
      context.go('/onboarding/balance');
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(stringsLocaleProvider);
    final s = S(locale);
    final pages = [
      (s.welcome1Title, s.welcome1Body, Icons.edit_note_rounded),
      (s.welcome2Title, s.welcome2Body, Icons.account_balance_wallet_outlined),
      (s.welcome3Title, s.welcome3Body, Icons.people_alt_outlined),
    ];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _finish(skipBalance: true),
                  child: Text(s.skip),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemCount: 3,
                  itemBuilder: (context, i) {
                    final p = pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: GallaColors.brandSoft,
                          child: Icon(p.$3, size: 40, color: GallaColors.brand),
                        ),
                        const SizedBox(height: 28),
                        Text(p.$1, style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        Text(p.$2, style: Theme.of(context).textTheme.bodyLarge, textAlign: TextAlign.center),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Container(
                    width: _index == i ? 18 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _index == i ? GallaColors.brand : GallaColors.line,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (_index < 2) {
                      _page.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    } else {
                      _finish(skipBalance: false);
                    }
                  },
                  child: Text(_index < 2 ? s.continueLabel : s.getStarted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StartingBalanceScreen extends ConsumerStatefulWidget {
  const StartingBalanceScreen({super.key});

  @override
  ConsumerState<StartingBalanceScreen> createState() => _StartingBalanceScreenState();
}

class _StartingBalanceScreenState extends ConsumerState<StartingBalanceScreen> {
  final _amount = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save(bool skip) async {
    final repo = ref.read(repositoryProvider);
    if (!skip) {
      final minor = MoneyParse.parse(_amount.text);
      if (minor > 0) {
        await repo.addEntry(
          direction: Direction.moneyIn,
          amountMinor: minor,
          isAdjustment: true,
          note: 'Starting cash',
          category: 'Opening',
        );
      }
    }
    if (mounted) context.go('/galla');
  }

  @override
  Widget build(BuildContext context) {
    final s = S(ref.watch(stringsLocaleProvider));
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.startingBalance, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(s.optionalSetup),
              const SizedBox(height: 24),
              TextField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: s.amount,
                  filled: true,
                  fillColor: GallaColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _save(false),
                  child: Text(s.save),
                ),
              ),
              TextButton(
                onPressed: () => _save(true),
                child: Center(child: Text(s.setLater)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MoneyParse {
  static int parse(String raw) {
    final cleaned = raw.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return 0;
    final v = double.tryParse(cleaned) ?? 0;
    return (v * 100).round();
  }
}
