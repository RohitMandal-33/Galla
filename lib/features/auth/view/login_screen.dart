import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/supabase/supabase_provider.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../data/demo_seeder.dart';
import '../../../data/galla_repository.dart';
import '../../../data/supabase_sync_service.dart';
import '../../../shared/widgets/galla_network_image.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController(text: GallaRepository.demoEmail);
  final _passCtrl = TextEditingController(text: GallaRepository.demoPassword);
  bool _obscure = true;
  bool _loading = false;
  bool _isSignUp = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final repo = ref.read(repositoryProvider);
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    // Check if using the local offline demo account
    if (email == GallaRepository.demoEmail && pass == GallaRepository.demoPassword) {
      final ok = await repo.loginWithPassword(email, pass);
      if (!ok) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Invalid demo credentials.';
        });
        return;
      }

      final existing = await repo.watchTransactions().first;
      if (existing.isEmpty) {
        await DemoSeeder.seedNepaliKirana(repo);
      }

      ref.invalidate(settingsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(partiesProvider);
      ref.invalidate(inventoryProvider);
      ref.invalidate(invoicesProvider);

      if (!mounted) return;
      setState(() => _loading = false);
      context.go('/galla');
      return;
    }

    // Authenticate with Supabase Backend
    try {
      final supabase = ref.read(supabaseClientProvider);
      if (_isSignUp) {
        final res = await supabase.auth.signUp(email: email, password: pass);
        if (res.user == null) {
          throw 'Sign up was not completed. Please verify email and password.';
        }
      } else {
        await supabase.auth.signInWithPassword(email: email, password: pass);
      }

      final user = supabase.auth.currentUser;
      if (user != null) {
        final current = await repo.loadSettings();
        await repo.saveSettings(current.copyWith(
          isLoggedIn: true,
          authEmail: user.email ?? email,
          authIsDemo: false,
          onboardingDone: true,
        ));

        // Start background sync
        ref.read(syncServiceProvider).init();
      }

      ref.invalidate(settingsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(partiesProvider);
      ref.invalidate(inventoryProvider);
      ref.invalidate(invoicesProvider);

      if (!mounted) return;
      setState(() => _loading = false);
      context.go('/galla');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('AuthException: ', '');
      });
    }
  }

  Future<void> _useDemo() async {
    _emailCtrl.text = GallaRepository.demoEmail;
    _passCtrl.text = GallaRepository.demoPassword;
    await _login();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GallaColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(GallaSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand header
                  Column(
                    children: [
                      Container(
                        height: 100,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: GallaNetworkImage(
                          imageUrl: 'https://images.unsplash.com/photo-1578916171728-46686eac8d58?auto=format&fit=crop&w=600&q=80',
                          borderRadius: GallaRadius.lg,
                          fit: BoxFit.cover,
                          cacheWidth: 600,
                          overlayGradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              GallaColors.canvas.withValues(alpha: 0.85),
                            ],
                          ),
                          fallbackIcon: Icons.storefront_rounded,
                        ),
                      ),
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: GallaColors.brandSoft,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/images/galla_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.storefront_rounded,
                            size: 32,
                            color: GallaColors.brand,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Welcome to Galla',
                        style: GallaType.numberXl,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your daily khata — cash, udhaar & stock',
                        style: GallaType.body.copyWith(
                          color: GallaColors.muted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  Container(
                    padding: const EdgeInsets.all(GallaSpacing.base),
                    decoration: BoxDecoration(
                      color: GallaColors.surface,
                      borderRadius: BorderRadius.circular(GallaRadius.lg),
                      border: Border.all(color: GallaColors.line),
                      boxShadow: GallaElevation.card,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Sign in', style: GallaType.cardTitle),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'demo@galla.app',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _login(),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: GallaColors.moneyOutSoft,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: GallaColors.moneyOut,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: GallaType.caption.copyWith(
                                      color: GallaColors.moneyOut,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loading ? null : _login,
                          child: _loading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_isSignUp ? 'Create Cloud Account' : 'Sign in'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () {
                                  setState(() {
                                    _isSignUp = !_isSignUp;
                                    _error = null;
                                  });
                                },
                          child: Text(
                            _isSignUp
                                ? 'Already have an account? Sign in'
                                : "Don't have an account? Sign up with email",
                            style: GallaType.caption.copyWith(
                              color: GallaColors.brand,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _loading ? null : _useDemo,
                          icon: const Icon(Icons.bolt_rounded, size: 18),
                          label: const Text('Use demo account — one tap'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: GallaColors.gold),
                            foregroundColor: GallaColors.goldDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Demo credentials card — explicit per spec
                  Container(
                    padding: const EdgeInsets.all(GallaSpacing.base),
                    decoration: BoxDecoration(
                      color: GallaColors.goldSoft,
                      borderRadius: BorderRadius.circular(GallaRadius.md),
                      border: Border.all(
                        color: GallaColors.gold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_fix_high_rounded,
                              size: 16,
                              color: GallaColors.goldDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Demo account (mock data)',
                              style: GallaType.labelStrong.copyWith(
                                color: GallaColors.goldDark,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: _useDemo,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: GallaColors.brand,
                                  borderRadius: BorderRadius.circular(
                                    GallaRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  'Tap to fill',
                                  style: GallaType.badge.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _CredRow(
                          label: 'Email',
                          value: GallaRepository.demoEmail,
                        ),
                        _CredRow(
                          label: 'Password',
                          value: GallaRepository.demoPassword,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Loads Shree Ganesh Kirana mock data: 6 inventory items, 5 parties, 10+ transactions, 1 invoice — graphs become populated instantly.',
                          style: GallaType.captionSm,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: GallaColors.muted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Offline-first · PIN + biometrics after sign-in',
                        style: GallaType.captionSm,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CredRow extends StatelessWidget {
  const _CredRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 72, child: Text(label, style: GallaType.captionSm)),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GallaColors.line),
              ),
              child: Text(
                value,
                style: GallaType.bodyStrong.copyWith(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
