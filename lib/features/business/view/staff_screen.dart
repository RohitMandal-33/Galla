import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';
import 'staff_switch_dialog.dart';

class StaffScreen extends ConsumerStatefulWidget {
  const StaffScreen({super.key});

  @override
  ConsumerState<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends ConsumerState<StaffScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  StaffRole _selectedRole = StaffRole.staff;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _showAddStaffDialog(BuildContext context, S s) {
    _nameController.clear();
    _phoneController.clear();
    _pinController.clear();
    _selectedRole = StaffRole.staff;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(s.addStaff),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Staff Name *',
                    hintText: 'e.g. Ramesh Giri',
                    filled: true,
                    fillColor: GallaColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    filled: true,
                    fillColor: GallaColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<StaffRole>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: s.staffRole,
                    filled: true,
                    fillColor: GallaColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: StaffRole.staff,
                      child: Text(s.staffRoleSimple),
                    ),
                    DropdownMenuItem(
                      value: StaffRole.manager,
                      child: const Text('Manager (Reports Access)'),
                    ),
                    DropdownMenuItem(
                      value: StaffRole.owner,
                      child: Text(s.ownerRole),
                    ),
                  ],
                  onChanged: (r) {
                    if (r != null) setDialogState(() => _selectedRole = r);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Login PIN (4 digits, optional)',
                    filled: true,
                    fillColor: GallaColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = _nameController.text.trim();
                if (name.isEmpty) return;
                await ref
                    .read(repositoryProvider)
                    .createStaffMember(
                      name,
                      phone: _phoneController.text.trim().isEmpty
                          ? null
                          : _phoneController.text.trim(),
                      role: _selectedRole,
                      pin: _pinController.text.trim().isEmpty
                          ? null
                          : _pinController.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GallaColors.brand,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(s.save),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final staffAsync = ref.watch(staffMembersProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.staffMembers),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: s.addStaff,
            onPressed: () => _showAddStaffDialog(context, s),
          ),
        ],
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (staffList) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Current Session Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: GallaColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: GallaColors.line),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: GallaColors.brandSoft,
                      child: Icon(
                        settings.activeStaffRole == StaffRole.owner
                            ? Icons.admin_panel_settings_outlined
                            : Icons.badge_outlined,
                        color: GallaColors.brand,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Active Session Mode', style: GallaType.caption),
                          Text(
                            settings.activeStaffName ?? s.ownerRole,
                            style: GallaType.cardTitle,
                          ),
                          Text(
                            settings.activeStaffRole == StaffRole.owner
                                ? 'Full Owner Permissions'
                                : 'Restricted Staff Mode',
                            style: GallaType.label.copyWith(
                              color: settings.activeStaffRole == StaffRole.owner
                                  ? GallaColors.moneyIn
                                  : GallaColors.moneyOut,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const StaffSwitchDialog(),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Switch'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Registered Staff (${staffList.length})',
                style: GallaType.tileTitle,
              ),
              const SizedBox(height: 8),

              if (staffList.isEmpty)
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
                        const Text(
                          'Add staff members so they can record sales on this till without seeing your full reports.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: GallaColors.muted),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddStaffDialog(context, s),
                          icon: const Icon(Icons.add),
                          label: Text(s.addStaff),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GallaColors.brand,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              ...staffList.map((m) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: GallaColors.line),
                    ),
                    tileColor: GallaColors.surface,
                    leading: CircleAvatar(
                      backgroundColor: GallaColors.brandSoft,
                      child: Text(
                        m.name.isNotEmpty ? m.name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: GallaColors.brand,
                        ),
                      ),
                    ),
                    title: Text(
                      m.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Role: ${m.role.name.toUpperCase()} ${m.phone != null ? "· ${m.phone}" : ""}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () async {
                        await ref
                            .read(repositoryProvider)
                            .deleteStaffMember(m.id);
                        if (settings.activeStaffId == m.id) {
                          final repo = ref.read(repositoryProvider);
                          final current = await repo.loadSettings();
                          await repo.saveSettings(
                            current.copyWith(
                              activeStaffId: null,
                              activeStaffName: null,
                              activeStaffRole: StaffRole.owner,
                            ),
                          );
                        }
                      },
                    ),
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
