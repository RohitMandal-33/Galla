import 'dart:async';
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

class _LockGateState extends ConsumerState<LockGate>
    with WidgetsBindingObserver {
  bool _locked = false;
  final _pin = TextEditingController();
  String? _error;
  int _failedAttempts = 0;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _maybeLock(initial: true),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    _pin.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
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
      if (ok && mounted) {
        setState(() {
          _locked = false;
          _failedAttempts = 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _submitPin() async {
    if (_cooldownSeconds > 0) return;

    final settings = await ref.read(repositoryProvider).loadSettings();
    if (settings.pinHash == null) {
      setState(() => _locked = false);
      return;
    }

    final isValid = GallaRepository.verifyPinSalted(
      _pin.text,
      settings.pinHash!,
    );
    if (isValid) {
      _pin.clear();
      setState(() {
        _locked = false;
        _error = null;
        _failedAttempts = 0;
      });
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _startCooldown(30);
        setState(() {
          _error = 'Too many failed attempts. Locked for 30 seconds.';
        });
      } else {
        setState(() {
          _error = 'Incorrect PIN (${5 - _failedAttempts} attempts left)';
        });
      }
    }
  }

  void _startCooldown(int seconds) {
    _cooldownSeconds = seconds;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _cooldownSeconds = 0;
          _error = null;
        });
      } else {
        setState(() {
          _cooldownSeconds--;
          _error = 'Too many failed attempts. Locked for $_cooldownSeconds s.';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_locked) return widget.child;
    final s = S(ref.watch(stringsLocaleProvider));

    return Scaffold(
      backgroundColor: GallaColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: GallaColors.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    size: 36,
                    color: GallaColors.brand,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Galla is Locked',
                style: GallaType.numberXl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Enter your 4-digit security PIN to access your business ledger.',
                style: GallaType.body.copyWith(color: GallaColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                autofocus: true,
                enabled: _cooldownSeconds == 0,
                textAlign: TextAlign.center,
                style: GallaType.numberXl.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  labelText: s.pin,
                  errorText: _error,
                  filled: true,
                  fillColor: GallaColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onSubmitted: (_) => _submitPin(),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _cooldownSeconds > 0 ? null : _submitPin,
                child: Text(
                  _cooldownSeconds > 0
                      ? 'Locked ($_cooldownSeconds s)'
                      : s.unlock,
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _tryBiometric,
                icon: const Icon(Icons.fingerprint_rounded, size: 18),
                label: const Text('Use Face ID / Fingerprint'),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 14,
                    color: GallaColors.muted,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Stored locally on this device',
                    style: GallaType.captionSm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
