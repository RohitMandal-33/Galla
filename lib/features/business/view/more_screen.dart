import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' show SharePlus, ShareParams, XFile;

import '../../../core/l10n/strings.dart';
import '../../../core/providers.dart';
import '../../../data/galla_repository.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../domain/models.dart';
import '../../../shared/widgets/galla_components.dart';
import '../../../shared/widgets/galla_network_image.dart';
import 'staff_switch_dialog.dart';

/// Secondary navigation — everything low-frequency lives here so the four
/// primary destinations stay uncluttered.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final branches = ref.watch(branchesProvider).valueOrNull ?? [];
    final staff = ref.watch(staffMembersProvider).valueOrNull ?? [];

    final initials = settings.businessName.isNotEmpty
        ? settings.businessName
              .trim()
              .split(' ')
              .map((w) => w.isNotEmpty ? w[0] : '')
              .take(2)
              .join()
              .toUpperCase()
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
          // ── Profile — opens the full business profile screen ────────────
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: GallaColors.brand,
              borderRadius: BorderRadius.circular(GallaRadius.lg),
              boxShadow: GallaElevation.card,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: GallaNetworkImage(
                    imageUrl: 'https://images.unsplash.com/photo-1604719312566-8912e9227c6a?auto=format&fit=crop&w=600&q=80',
                    borderRadius: 0,
                    fit: BoxFit.cover,
                    cacheWidth: 600,
                    overlayGradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        GallaColors.brand.withValues(alpha: 0.94),
                        GallaColors.brandMid.withValues(alpha: 0.88),
                      ],
                    ),
                    fallbackIcon: Icons.storefront_rounded,
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.all(GallaSpacing.base),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      initials,
                      style: GallaType.number.copyWith(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    settings.businessName.isNotEmpty
                        ? settings.businessName
                        : s.businessName,
                    style: GallaType.number.copyWith(color: Colors.white),
                  ),
                  subtitle: Text(
                    settings.activeStaffRole == StaffRole.owner
                        ? 'Owner'
                        : 'Staff · ${settings.activeStaffName}',
                    style: GallaType.body.copyWith(color: Colors.white70),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.white70,
                  ),
                  onTap: () => context.push('/profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: GallaSpacing.base),

          _MenuGroup(
            title: 'Business',
            items: [
              _MenuItem(
                icon: Icons.insights_rounded,
                iconColor: GallaColors.brand,
                title: 'Analytics',
                trailingText: 'Graphs',
                onTap: () => context.push('/analytics'),
              ),
              _MenuItem(
                icon: Icons.storefront_outlined,
                iconColor: GallaColors.brand,
                title: s.branches,
                trailingText:
                    '${branches.length} ${branches.length == 1 ? 'branch' : 'branches'}',
                onTap: () => context.push('/business/branches'),
              ),
              _MenuItem(
                icon: Icons.group_outlined,
                iconColor: GallaColors.blue,
                title: s.staffMembers,
                trailingText: '${staff.length}',
                onTap: () => context.push('/business/staff'),
              ),
              _MenuItem(
                icon: Icons.receipt_long_outlined,
                iconColor: GallaColors.goldDark,
                title: s.invoices,
                onTap: () => context.push('/invoices'),
              ),
              _MenuItem(
                icon: Icons.tune_outlined,
                iconColor: GallaColors.moneyOut,
                title: s.reconciliation,
                onTap: () => context.push('/reconciliation'),
              ),
            ],
          ),
          const SizedBox(height: GallaSpacing.base),

          _MenuGroup(
            title: 'Data & security',
            items: [
              // Real backup/export: share the ledger as CSV files.
              _MenuItem(
                icon: Icons.ios_share_rounded,
                iconColor: GallaColors.moneyIn,
                title: 'Export data (CSV)',
                onTap: () => _exportCsv(context, ref, s),
              ),
              _MenuItem(
                icon: Icons.lock_outline_rounded,
                iconColor: GallaColors.ink,
                title: s.switchStaffMode,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const StaffSwitchDialog(),
                ),
              ),
              _MenuItem(
                icon: Icons.help_outline_rounded,
                iconColor: GallaColors.muted,
                title: 'Help & support',
                onTap: () => _showHelpDialog(context),
              ),
              _MenuItem(
                icon: Icons.share_outlined,
                iconColor: GallaColors.brand,
                title: 'Share Galla',
                onTap: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        'Galla — a simple digital khata for small shops. Record sales, expenses and udhaar in seconds.',
                    subject: 'Galla khata app',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GallaSpacing.base),
          _MenuGroup(
            title: 'Account',
            items: [
              if (settings.isLoggedIn)
                _MenuItem(
                  icon: Icons.logout_rounded,
                  iconColor: GallaColors.moneyOut,
                  title: 'Sign out (${settings.authEmail ?? ''})',
                  onTap: () => _signOut(context, ref),
                ),
              if (!settings.isLoggedIn)
                _MenuItem(
                  icon: Icons.login_rounded,
                  iconColor: GallaColors.brand,
                  title: 'Sign in',
                  onTap: () => context.go('/login'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref, S s) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(repositoryProvider);
      final branchId = ref.read(selectedBranchIdProvider);
      final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
      final dir = await getTemporaryDirectory();

      final txnsCsv = await repo.exportTransactionsCsv(branchId: branchId);
      final invsCsv = await repo.exportInvoicesCsv(branchId: branchId);

      final txnFile = File('${dir.path}/galla-transactions-$stamp.csv');
      final invFile = File('${dir.path}/galla-invoices-$stamp.csv');
      await txnFile.writeAsString(txnsCsv);
      await invFile.writeAsString(invsCsv);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(txnFile.path, mimeType: 'text/csv'),
            XFile(invFile.path, mimeType: 'text/csv'),
          ],
          subject: 'Galla data export',
        ),
      );
    } catch (_) {
      showGallaSnackBar(messenger, s.saveFailed);
    }
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to access your khata.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(repositoryProvider).logout();
    ref.invalidate(settingsProvider);
    if (context.mounted) context.go('/login');
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How Galla works'),
        content: const Text(
          '• Galla (home): your cash position for today.\n'
          '• Khata: who owes you and whom you owe.\n'
          '• Stock: what is on the shelf and what is running low.\n'
          '• Reports: honest totals you can share as PDF or CSV.\n'
          '• Analytics: graphs for last 7/14/30 days.\n\n'
          'Everything is saved on this phone as soon as you record it.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
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
            style: GallaType.subtitleSm.copyWith(color: GallaColors.muted),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: GallaColors.surface,
            borderRadius: BorderRadius.circular(GallaRadius.lg),
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
      title: Text(title, style: GallaType.bodyStrong.copyWith(fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null) ...[
            Text(
              trailingText!,
              style: GallaType.label.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 6),
          ],
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: GallaColors.muted,
          ),
        ],
      ),
    );
  }
}
