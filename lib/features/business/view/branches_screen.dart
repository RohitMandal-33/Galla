import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';

class BranchesScreen extends ConsumerStatefulWidget {
  const BranchesScreen({super.key});

  @override
  ConsumerState<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends ConsumerState<BranchesScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showAddBranchDialog(BuildContext context, S s) {
    _nameController.clear();
    _addressController.clear();
    _phoneController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.addBranch),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '${s.branchName} *',
                hintText: 'e.g. Branch 2 / Thamel Store',
                filled: true,
                fillColor: GallaColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Location / Address',
                filled: true,
                fillColor: GallaColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Contact Phone',
                filled: true,
                fillColor: GallaColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isEmpty) return;
              await ref.read(repositoryProvider).createBranch(
                    name,
                    address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
                    phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GallaColors.brand,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(s.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final branchesAsync = ref.watch(branchesProvider);
    final activeBranchId = ref.watch(selectedBranchIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.branches),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: s.addBranch,
            onPressed: () => _showAddBranchDialog(context, s),
          ),
        ],
      ),
      body: branchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (branches) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GallaColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GallaColors.line),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.store_mall_directory_outlined, color: GallaColors.brand, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Track cash books and inventory separately for multiple store locations, or view all combined.',
                        style: TextStyle(fontSize: 13, color: GallaColors.muted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // "All Branches" Option
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: activeBranchId == null ? GallaColors.brand : GallaColors.line,
                    width: activeBranchId == null ? 2 : 1,
                  ),
                ),
                tileColor: GallaColors.surface,
                leading: const Icon(Icons.apps_rounded, color: GallaColors.brand),
                title: Text(s.allBranches, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('Combined view across all locations'),
                trailing: activeBranchId == null
                    ? const Icon(Icons.check_circle, color: GallaColors.brand)
                    : null,
                onTap: () {
                  ref.read(selectedBranchIdProvider.notifier).state = null;
                  ref.read(repositoryProvider).loadSettings().then((set) {
                    ref.read(repositoryProvider).saveSettings(set.copyWith(activeBranchId: null));
                  });
                },
              ),
              const SizedBox(height: 12),

              Text('Your Branches (${branches.length})',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 8),

              if (branches.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: GallaColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: GallaColors.line),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Text('No additional branches added yet.', style: TextStyle(color: GallaColors.muted)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddBranchDialog(context, s),
                          icon: const Icon(Icons.add),
                          label: Text(s.addBranch),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GallaColors.brand,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              ...branches.map((b) {
                final isSelected = activeBranchId == b.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? GallaColors.brand : GallaColors.line,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    tileColor: GallaColors.surface,
                    leading: const Icon(Icons.storefront_outlined, color: GallaColors.brand),
                    title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: b.address != null ? Text(b.address!) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          const Icon(Icons.check_circle, color: GallaColors.brand),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () async {
                            await ref.read(repositoryProvider).deleteBranch(b.id);
                            if (activeBranchId == b.id) {
                              ref.read(selectedBranchIdProvider.notifier).state = null;
                            }
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      ref.read(selectedBranchIdProvider.notifier).state = b.id;
                      ref.read(repositoryProvider).loadSettings().then((set) {
                        ref.read(repositoryProvider).saveSettings(set.copyWith(activeBranchId: b.id));
                      });
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
