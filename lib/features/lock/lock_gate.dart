import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/l10n/strings.dart';
import '../../core/providers.dart';
import '../../core/theme/galla_theme.dart';
import '../../data/galla_repository.dart';

class LockGate extends ConsumerStatefulWidget {
  const LockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> with WidgetsBindingObserver {
  bool _locked = false;
  final _pin = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLock(initial: true));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pin.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      final settings = ref.read(settingsProvider).valueOrNull;
      if (settings?.lockEnabled == true) setState(() => _locked = true);
    }
  }

  Future<void> _maybeLock({bool initial = false}) async {
    final settings = await ref.read(repositoryProvider).loadSettings();
    if (!settings.lockEnabled || settings.pinHash == null) return;
    setState(() => _locked = true);
    if (initial) await _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    try {
      final auth = LocalAuthentication();
      final ok = await auth.authenticate(
        localizedReason: 'Unlock Galla',
        options: const AuthenticationOptions(biometricOnly: false),
      );
      if (ok && mounted) setState(() => _locked = false);
    } catch (_) {}
  }

  Future<void> _submitPin() async {
    final settings = await ref.read(repositoryProvider).loadSettings();
    if (GallaRepository.hashPin(_pin.text) == settings.pinHash) {
      _pin.clear();
      setState(() {
        _locked = false;
        _error = null;
      });
    } else {
      setState(() => _error = 'PIN did not match');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;
    final s = S(ref.watch(stringsLocaleProvider));
    return Scaffold(
      backgroundColor: GallaColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text('Galla', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Your cash book is locked.'),
              const SizedBox(height: 24),
              TextField(
                controller: _pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: s.pin,
                  errorText: _error,
                  filled: true,
                  fillColor: GallaColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onSubmitted: (_) => _submitPin(),
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _submitPin, child: Text(s.unlock)),
              TextButton(onPressed: _tryBiometric, child: const Text('Use Face ID / fingerprint')),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
