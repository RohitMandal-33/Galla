import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/locale.dart';
import '../../../core/l10n/strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../data/demo_seeder.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';
import '../../../shared/widgets/galla_components.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _taxCtrl;
  late TextEditingController _thresholdCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider).valueOrNull ?? const AppSettings();
    _nameCtrl = TextEditingController(text: s.businessName);
    _taxCtrl = TextEditingController(
      text: s.taxRatePct > 0 ? '${s.taxRatePct}' : '',
    );
    _thresholdCtrl = TextEditingController(
      text: s.lowCashThresholdMinor > 0
          ? '${s.lowCashThresholdMinor ~/ 100}'
          : '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taxCtrl.dispose();
    _thresholdCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final repo = ref.read(repositoryProvider);
    final current = await repo.loadSettings();
    final taxRaw = double.tryParse(_taxCtrl.text.trim()) ?? 0.0;
    final threshold = (int.tryParse(_thresholdCtrl.text.trim()) ?? 0) * 100;

    await repo.saveSettings(
      current.copyWith(
        businessName: _nameCtrl.text.trim(),
        taxRatePct: taxRaw < 0 ? 0 : taxRaw,
        lowCashThresholdMinor: threshold < 0 ? 0 : threshold,
      ),
    );

    setState(() => _loading = false);
    showGallaSnackBar(messenger, 'Business profile updated');
    router.pop();
  }

  // ── App lock ────────────────────────────────────────────────────────────────

  Future<String?> _promptPin(String title) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: '4–6 digit PIN',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final pin = ctrl.text.trim();
              if (pin.length < 4) return;
              Navigator.pop(ctx, pin);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return (result == null || result.length < 4) ? null : result;
  }

  Future<void> _setPin(bool isChange) async {
    final repo = ref.read(repositoryProvider);
    var newPin = await _promptPin(isChange ? 'Enter a new PIN' : 'Set app PIN');

    // Changing an existing PIN requires the current one first.
    if (isChange && newPin != null) {
      final current = await _promptPin('Enter your current PIN');
      if (current == null) return;
      final settings = await repo.loadSettings();
      final ok =
          settings.pinHash != null &&
          GallaRepository.verifyPinSalted(current, settings.pinHash!);
      if (!ok) {
        if (!mounted) return;
        showGallaSnackBar(
          ScaffoldMessenger.of(context),
          'Current PIN is incorrect',
        );
        return;
      }
      // Re-ask for the new PIN after successful verification.
      newPin = await _promptPin('Re-enter your new PIN');
    }
    if (newPin == null) return;

    await repo.setAppPin(newPin);
    if (!mounted) return;
    showGallaSnackBar(
      ScaffoldMessenger.of(context),
      isChange
          ? 'PIN changed — lock is on'
          : 'PIN set — Galla will now lock when you leave the app',
    );
  }

  Future<void> _removePin() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove PIN?'),
        content: const Text(
          'Anyone who opens this device will be able to read your cash book.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep PIN'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: GallaColors.moneyOut,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(repositoryProvider).removeAppPin();
  }

  // ── Language ────────────────────────────────────────────────────────────────

  Future<void> _changeLanguage(String locale) async {
    if (locale == settingsLocale) return;
    final repo = ref.read(repositoryProvider);
    final current = await repo.loadSettings();
    await repo.saveSettings(current.copyWith(locale: locale));
    // Dates and any intl formatters follow immediately.
    await applyAppLocale(locale);
  }

  String get settingsLocale =>
      ref.read(settingsProvider).valueOrNull?.locale ?? 'en';

  // ── Demo data ───────────────────────────────────────────────────────────────

  Future<void> _loadDemo() async {
    final txns = ref.read(transactionsProvider).valueOrNull ?? const <Txn>[];
    if (txns.isNotEmpty) {
      // Never mix demo rows into real books.
      if (!mounted) return;
      showGallaSnackBar(
        ScaffoldMessenger.of(context),
        'Demo data can only be loaded into an empty ledger so your real '
        'records are never mixed with sample data',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load demo data?'),
        content: const Text(
          'Adds realistic Nepali retail sample data so you can explore Galla '
          'before recording your own entries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Load demo'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _loading = true);
      await DemoSeeder.seedNepaliKirana(ref.read(repositoryProvider));
      ref.invalidate(settingsProvider);
      ref.invalidate(transactionsProvider);
      ref.invalidate(partiesProvider);
      ref.invalidate(inventoryProvider);
      ref.invalidate(invoicesProvider);
      ref.invalidate(branchesProvider);
      ref.invalidate(staffMembersProvider);
      ref.invalidate(reconciliationsProvider);
      ref.invalidate(healthReportProvider);
      setState(() => _loading = false);
      if (mounted) context.go('/galla');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final hasPin = settings.pinHash != null;
    final initials = settings.businessName.isNotEmpty
        ? settings.businessName
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase()
        : 'G';

    return Scaffold(
      backgroundColor: GallaColors.canvas,
      appBar: AppBar(
        title: const Text('Business profile'),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _save,
              child: const Text(
                'Save',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(GallaSpacing.base),
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: GallaColors.brand,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: initials.isNotEmpty
                    ? Text(
                        initials,
                        style: GallaType.numberLg.copyWith(color: Colors.white),
                      )
                    : Icon(
                        Icons.storefront_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
            ),
            const SizedBox(height: GallaSpacing.lg),

            // ── Language ─────────────────────────────────────────────────
            GallaSectionHeader(title: s.language, topPadding: 0),
            Container(
              padding: const EdgeInsets.all(GallaSpacing.base),
              decoration: BoxDecoration(
                color: GallaColors.surface,
                borderRadius: BorderRadius.circular(GallaRadius.lg),
                border: Border.all(color: GallaColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GallaFilterChip(
                      key: const ValueKey('lang-en'),
                      label: s.english,
                      selected: settings.locale != 'ne',
                      onTap: () => _changeLanguage('en'),
                      fullWidth: true,
                    ),
                  ),
                  const SizedBox(width: GallaSpacing.sm),
                  Expanded(
                    child: GallaFilterChip(
                      key: const ValueKey('lang-ne'),
                      label: s.nepali,
                      selected: settings.locale == 'ne',
                      onTap: () => _changeLanguage('ne'),
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GallaSpacing.lg),

            GallaSectionHeader(title: 'Business', topPadding: 0),
            Container(
              padding: const EdgeInsets.all(GallaSpacing.base),
              decoration: BoxDecoration(
                color: GallaColors.surface,
                borderRadius: BorderRadius.circular(GallaRadius.lg),
                border: Border.all(color: GallaColors.line),
              ),
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Business name',
                      hintText: 'e.g. Shree Ganesh Kirana',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Please enter a name'
                        : null,
                  ),
                  const SizedBox(height: GallaSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: settings.currency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      prefixIcon: Icon(Icons.currency_exchange_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'NPR',
                        child: Text('NPR — Nepali Rupee (Rs)'),
                      ),
                      DropdownMenuItem(
                        value: 'INR',
                        child: Text('INR — Indian Rupee (₹)'),
                      ),
                      DropdownMenuItem(
                        value: 'USD',
                        child: Text('USD — US Dollar (\$)'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        ref
                            .read(repositoryProvider)
                            .saveSettings(settings.copyWith(currency: v));
                      }
                    },
                  ),
                  const SizedBox(height: GallaSpacing.md),
                  TextFormField(
                    controller: _taxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Default tax / VAT % (optional)',
                      hintText: 'e.g. 13 for Nepal VAT',
                      prefixIcon: Icon(Icons.percent_rounded),
                    ),
                  ),
                  const SizedBox(height: GallaSpacing.md),
                  TextFormField(
                    key: const ValueKey('threshold-field'),
                    controller: _thresholdCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: s.lowCashThresholdLabel,
                      prefixIcon: const Icon(
                        Icons.account_balance_wallet_outlined,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GallaSpacing.lg),

            // ── Alerts ────────────────────────────────────────────────────
            GallaSectionHeader(title: s.alerts, topPadding: 0),
            Container(
              decoration: BoxDecoration(
                color: GallaColors.surface,
                borderRadius: BorderRadius.circular(GallaRadius.lg),
                border: Border.all(color: GallaColors.line),
              ),
              // Switch tiles paint ink on the nearest Material.
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    _AlertToggle(
                      key: const ValueKey('toggle-payment-reminders'),
                      icon: Icons.notifications_active_outlined,
                      title: s.paymentReminders,
                      subtitle: s.paymentRemindersSub,
                      value: settings.notifyPaymentDue,
                      flag: AlertFlag.paymentDue,
                    ),
                    const Divider(height: 1, indent: GallaSpacing.xl),
                    _AlertToggle(
                      key: const ValueKey('toggle-low-cash'),
                      icon: Icons.account_balance_wallet_outlined,
                      title: s.lowCashAlert,
                      subtitle: s.lowCashAlertSub,
                      value: settings.notifyLowCash,
                      flag: AlertFlag.lowCash,
                    ),
                    const Divider(height: 1, indent: GallaSpacing.xl),
                    _AlertToggle(
                      key: const ValueKey('toggle-low-stock'),
                      icon: Icons.inventory_2_outlined,
                      title: s.lowStockAlert,
                      subtitle: s.lowStockAlertSub,
                      value: settings.notifyLowStock,
                      flag: AlertFlag.lowStock,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: GallaSpacing.lg),

            // ── Security ──────────────────────────────────────────────────
            GallaSectionHeader(title: 'Security', topPadding: 0),
            Container(
              padding: const EdgeInsets.all(GallaSpacing.base),
              decoration: BoxDecoration(
                color: GallaColors.surface,
                borderRadius: BorderRadius.circular(GallaRadius.lg),
                border: Border.all(color: GallaColors.line),
              ),
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    // A single tile instead of Row+Switch: rows give
                    // non-flex children unbounded width, which ListTiles
                    // reject.
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('App lock', style: GallaType.subtitle),
                      subtitle: Text(
                        hasPin
                            ? 'PIN is set · Face ID / fingerprint offered'
                            : 'No PIN set yet',
                        style: GallaType.caption,
                      ),
                      value: settings.lockEnabled && hasPin,
                      activeThumbColor: GallaColors.brand,
                      onChanged: hasPin
                          ? (v) async {
                              final repo = ref.read(repositoryProvider);
                              final current = await repo.loadSettings();
                              await repo.saveSettings(
                                current.copyWith(lockEnabled: v),
                              );
                            }
                          : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const ValueKey('set-pin-button'),
                            onPressed: () => _setPin(hasPin),
                            child: Text(hasPin ? 'Change PIN' : 'Set PIN'),
                          ),
                        ),
                        if (hasPin) ...[
                          const SizedBox(width: GallaSpacing.sm),
                          OutlinedButton(
                            onPressed: _removePin,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GallaColors.moneyOut,
                            ),
                            child: const Text('Remove'),
                          ),
                        ],
                      ],
                    ),
                    const Divider(height: GallaSpacing.xl),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_android_rounded,
                          color: GallaColors.muted,
                          size: 18,
                        ),
                        const SizedBox(width: GallaSpacing.sm),
                        Expanded(
                          child: Text(
                            'Your records are stored only on this device. Nothing is uploaded anywhere.',
                            style: GallaType.caption,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: GallaSpacing.lg),

            GallaSectionHeader(
              title: 'Try Galla with sample data',
              topPadding: 0,
            ),
            Container(
              padding: const EdgeInsets.all(GallaSpacing.base),
              decoration: BoxDecoration(
                color: GallaColors.surface,
                borderRadius: BorderRadius.circular(GallaRadius.lg),
                border: Border.all(color: GallaColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _loadDemo,
                    icon: const Icon(
                      Icons.auto_fix_high_rounded,
                      color: GallaColors.goldDark,
                    ),
                    label: const Text('Load sample kirana store'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: GallaColors.gold),
                      foregroundColor: GallaColors.goldDark,
                    ),
                  ),
                  const SizedBox(height: GallaSpacing.sm),
                  Text(
                    'Only available while your ledger is empty.',
                    style: GallaType.captionSm,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: GallaSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

enum AlertFlag { paymentDue, lowCash, lowStock }

/// An alerts switch that persists instantly — a control that silently did
/// nothing would be worse than no control at all.
class _AlertToggle extends ConsumerWidget {
  const _AlertToggle({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.flag,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final AlertFlag flag;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: GallaSpacing.base,
        vertical: GallaSpacing.xs,
      ),
      secondary: Icon(icon, size: 22, color: GallaColors.brand),
      title: Text(title, style: GallaType.bodyStrong.copyWith(fontSize: 14)),
      subtitle: Text(subtitle, style: GallaType.caption),
      value: value,
      activeThumbColor: GallaColors.brand,
      onChanged: (v) async {
        final repo = ref.read(repositoryProvider);
        // Load fresh so we never overwrite concurrent changes with the
        // possibly-stale widget snapshot.
        final current = await repo.loadSettings();
        await repo.saveSettings(switch (flag) {
          AlertFlag.paymentDue => current.copyWith(notifyPaymentDue: v),
          AlertFlag.lowCash => current.copyWith(notifyLowCash: v),
          AlertFlag.lowStock => current.copyWith(notifyLowStock: v),
        });
      },
    );
  }
}
