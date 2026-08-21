import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams;

import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../domain/models.dart';
import 'staff_switch_dialog.dart';
import '../viewmodel/more_viewmodel.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final branches = ref.watch(branchesProvider).valueOrNull ?? [];
    final staff = ref.watch(staffMembersProvider).valueOrNull ?? [];

    final initials = settings.businessName.isNotEmpty
        ? settings.businessName.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'G';

    return Scaffold(
      backgroundColor: GallaColors.canvas,
      appBar: AppBar(
        backgroundColor: GallaColors.canvas,
        title: const Text('More'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          // ── Profile Card ──────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: GallaColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GallaColors.line),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: GallaColors.brandSoft,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: GallaColors.brand,
                  ),
                ),
              ),
              title: Text(
                settings.businessName.isNotEmpty ? settings.businessName : 'My Business',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              subtitle: Text(
                settings.activeStaffRole == StaffRole.owner
                    ? 'Owner'
                    : 'Staff: ${settings.activeStaffName}',
                style: const TextStyle(fontSize: 13, color: GallaColors.muted),
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: GallaColors.muted),
              onTap: () => _editBusinessDialog(context, ref, settings),
            ),
          ),
          const SizedBox(height: 16),

          // ── Primary Operations Group ──────────────────────────────────────
          _MenuGroup(
            title: 'Business Management',
            items: [
              _MenuItem(
                icon: Icons.storefront_outlined,
                iconColor: GallaColors.brand,
                title: 'Multi-Branch',
                trailingText: '${branches.length} ${branches.length == 1 ? "Branch" : "Branches"}',
                onTap: () => context.push('/business/branches'),
              ),
              _MenuItem(
                icon: Icons.group_outlined,
                iconColor: GallaColors.blue,
                title: 'Staff & Users',
                trailingText: '${staff.length} Active',
                onTap: () => context.push('/business/staff'),
              ),
              _MenuItem(
                icon: Icons.receipt_long_outlined,
                iconColor: GallaColors.amber,
                title: 'Invoicing & Billing',
                onTap: () => context.push('/invoices'),
              ),
              _MenuItem(
                icon: Icons.inventory_2_outlined,
                iconColor: GallaColors.moneyIn,
                title: 'Stock & Inventory',
                onTap: () => context.push('/inventory'),
              ),
              _MenuItem(
                icon: Icons.tune_outlined,
                iconColor: GallaColors.moneyOut,
                title: 'Cash Reconciliation',
                onTap: () => context.push('/reconciliation'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Intelligence & Data ───────────────────────────────────────────
          _MenuGroup(
            title: 'AI & Data Insights',
            items: [
              _MenuItem(
                icon: Icons.auto_awesome_outlined,
                iconColor: GallaColors.brand,
                title: 'AI Assistant',
                trailingText: 'Insights',
                onTap: () => context.push('/ai-assistant'),
              ),
              _MenuItem(
                icon: Icons.cloud_done_outlined,
                iconColor: GallaColors.moneyIn,
                title: 'Backup & Sync',
                trailingText: 'Offline First',
                onTap: () => _showSyncDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Settings & Security ───────────────────────────────────────────
          _MenuGroup(
            title: 'Settings & Security',
            items: [
              _MenuItem(
                icon: Icons.lock_outline_rounded,
                iconColor: GallaColors.ink,
                title: 'Switch Staff / Owner Mode',
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const StaffSwitchDialog(),
                ),
              ),
              _MenuItem(
                icon: Icons.settings_outlined,
                iconColor: GallaColors.ink,
                title: 'General Settings',
                onTap: () => _showSettingsDialog(context, ref, settings),
              ),
              _MenuItem(
                icon: Icons.help_outline_rounded,
                iconColor: GallaColors.muted,
                title: 'Help & Support',
                onTap: () => _showHelpDialog(context),
              ),
              _MenuItem(
                icon: Icons.share_outlined,
                iconColor: GallaColors.brand,
                title: 'Share Galla App',
                onTap: () => SharePlus.instance.share(
                  ShareParams(
                    text: 'Galla — Smart digital ledger and khata for small shops. Download today!',
                    subject: 'Galla Khata App',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editBusinessDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    final nameCtrl = TextEditingController(text: settings.businessName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Business Profile'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Business / Shop Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isNotEmpty) {
                await ref.read(moreViewModelProvider.notifier).updateSettings(
                      settings.copyWith(businessName: newName),
                    );
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref, AppSettings settings) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Preferences'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Currency: ${settings.currency}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Estimated Tax: ${settings.taxRatePct}%', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Language: ${settings.locale == "ne" ? "Nepali" : "English"}', style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
        ],
      ),
    );
  }

  void _showSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Data & Sync Status'),
        content: const Text(
          'All your business ledger records are safely stored on this device with SQLite (Offline First). Data is immediately accessible without internet.',
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Understood')),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Galla Help & Guide'),
        content: const Text(
          '• Cash Book (Galla): Record daily sales, expenses, and cash in hand.\n• Udhaar Ledger: Track customer credit and repayments.\n• Invoices: Generate professional bills.\n• Reconciliation: Audit physical cash drawer.',
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.title, required this.items});
  final String title;
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: GallaColors.muted,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: GallaColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: GallaColors.line),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                items[i],
                if (i < items.length - 1) const Divider(height: 1, indent: 56),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailingText,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? trailingText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText!,
              style: const TextStyle(fontSize: 12, color: GallaColors.muted, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: GallaColors.muted),
        ],
      ),
    );
  }
}
