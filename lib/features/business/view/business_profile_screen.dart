import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../data/demo_seeder.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';
import '../../../shared/widgets/galla_components.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
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
    _taxCtrl = TextEditingController(text: s.taxRatePct > 0 ? '${s.taxRatePct}' : '');
    _thresholdCtrl = TextEditingController(
      text: s.lowCashThresholdMinor > 0 ? '${s.lowCashThresholdMinor ~/ 100}' : '',
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

    final repo = ref.read(repositoryProvider);
    final current = await repo.loadSettings();
    final taxPct = double.tryParse(_taxCtrl.text.trim()) ?? 0.0;
    final threshold = (int.tryParse(_thresholdCtrl.text.trim()) ?? 0) * 100;

    await repo.saveSettings(
      current.copyWith(
        businessName: _nameCtrl.text.trim(),
        taxRatePct: taxPct,
        lowCashThresholdMinor: threshold,
      ),
    );

    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business profile updated successfully')),
      );
      context.pop();
    }
  }

  Future<void> _loadDemo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Load Demo Data?'),
        content: const Text(
          'This will populate your Galla with realistic Nepali retail data for "Shree Ganesh Kirana".',
        ),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => ctx.pop(true), child: const Text('Load Demo')),
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
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demo data loaded successfully!')),
        );
        context.go('/galla');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final initials = settings.businessName.isNotEmpty
        ? settings.businessName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'GK';

    return Scaffold(
      backgroundColor: GallaColors.canvas,
      appBar: AppBar(
        title: const Text('Business Profile'),
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(GallaSpacing.base),
          children: [
            // Avatar Header
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: GallaColors.brand,
                      shape: BoxShape.circle,
                      boxShadow: GallaElevation.hero,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: GallaColors.gold,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.store_rounded, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GallaSpacing.lg),

            // Business Info Card
            GallaSectionHeader(title: 'Business Information', topPadding: 0),
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
                      labelText: 'Business Name',
                      hintText: 'e.g. Shree Ganesh Kirana',
                      prefixIcon: Icon(Icons.storefront_outlined),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a name' : null,
                  ),
                  const SizedBox(height: GallaSpacing.md),
                  DropdownButtonFormField<String>(
                    value: settings.currency,
                    decoration: const InputDecoration(
                      labelText: 'Primary Currency',
                      prefixIcon: Icon(Icons.currency_exchange_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'NPR', child: Text('NPR — Nepali Rupee (Rs)')),
                      DropdownMenuItem(value: 'INR', child: Text('INR — Indian Rupee (₹)')),
                      DropdownMenuItem(value: 'USD', child: Text('USD — US Dollar (\$)')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(repositoryProvider).saveSettings(settings.copyWith(currency: v));
                      }
                    },
                  ),
                  const SizedBox(height: GallaSpacing.md),
                  TextFormField(
                    controller: _taxCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Default Tax / VAT % (Optional)',
                      hintText: 'e.g. 13 for Nepal VAT',
                      prefixIcon: Icon(Icons.percent_rounded),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GallaSpacing.lg),

            // Security Card
            GallaSectionHeader(title: 'Security & App Lock', topPadding: 0),
            Container(
              padding: const EdgeInsets.all(GallaSpacing.base),
              decoration: BoxDecoration(
                color: GallaColors.surface,
                borderRadius: BorderRadius.circular(GallaRadius.lg),
                border: Border.all(color: GallaColors.line),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('PIN & Biometric Lock', style: TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('Require Face ID / Fingerprint or PIN to open Galla'),
                    value: settings.lockEnabled,
                    activeColor: GallaColors.brand,
                    onChanged: (v) async {
                      final repo = ref.read(repositoryProvider);
                      await repo.saveSettings(settings.copyWith(lockEnabled: v));
                    },
                  ),
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: GallaColors.brand, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Your business data is stored encrypted on this device.',
                          style: TextStyle(fontSize: 12, color: GallaColors.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: GallaSpacing.lg),

            // Demo Data Card
            GallaSectionHeader(title: 'Demo & Testing', topPadding: 0),
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
                    icon: const Icon(Icons.auto_fix_high_rounded, color: GallaColors.gold),
                    label: const Text('Load Demo Data (Kirana Store)'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: GallaColors.gold),
                      foregroundColor: GallaColors.gold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Seeds realistic Nepali products, customers, transactions, and invoices.',
                    style: TextStyle(fontSize: 11, color: GallaColors.muted),
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
