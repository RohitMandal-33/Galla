import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';

class StaffSwitchDialog extends ConsumerStatefulWidget {
  const StaffSwitchDialog({super.key});

  @override
  ConsumerState<StaffSwitchDialog> createState() => _StaffSwitchDialogState();
}

class _StaffSwitchDialogState extends ConsumerState<StaffSwitchDialog> {
  final _pinController = TextEditingController();
  StaffMember? _selectedStaff;
  bool _asOwner = true;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _applySwitch() async {
    setState(() => _error = null);
    final repo = ref.read(repositoryProvider);
    final current = await repo.loadSettings();

    if (_asOwner) {
      if (current.lockEnabled && current.pinHash != null) {
        final entered = _pinController.text.trim();
        if (!GallaRepository.verifyPinSalted(entered, current.pinHash!)) {
          setState(() => _error = 'Incorrect Owner PIN');
          return;
        }
      }
      await repo.saveSettings(
        current.copyWith(
          activeStaffId: null,
          activeStaffName: null,
          activeStaffRole: StaffRole.owner,
        ),
      );
    } else if (_selectedStaff != null) {
      if (_selectedStaff!.pinHash != null) {
        final entered = _pinController.text.trim();
        final ok = await repo.verifyStaffPin(_selectedStaff!.id, entered);
        if (!ok) {
          setState(() => _error = 'Incorrect Staff PIN');
          return;
        }
      }
      await repo.saveSettings(
        current.copyWith(
          activeStaffId: _selectedStaff!.id,
          activeStaffName: _selectedStaff!.name,
          activeStaffRole: _selectedStaff!.role,
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final staffList = ref.watch(staffMembersProvider).valueOrNull ?? [];

    return AlertDialog(
      title: Text(s.switchStaffMode),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<bool>(
              value: true,
              groupValue: _asOwner,
              title: Text(
                s.ownerRole,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Full access to reports & settings'),
              onChanged: (v) {
                setState(() {
                  _asOwner = true;
                  _selectedStaff = null;
                });
              },
            ),
            const Divider(),
            ...staffList.map((m) {
              return RadioListTile<bool>(
                value: false,
                groupValue: _asOwner
                    ? null
                    : (_selectedStaff?.id == m.id ? false : null),
                title: Text(
                  m.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('Role: ${m.role.name.toUpperCase()}'),
                onChanged: (v) {
                  setState(() {
                    _asOwner = false;
                    _selectedStaff = m;
                  });
                },
              );
            }),
            const SizedBox(height: 12),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'PIN (if configured)',
                filled: true,
                fillColor: GallaColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                errorText: _error,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _applySwitch,
          style: ElevatedButton.styleFrom(
            backgroundColor: GallaColors.brand,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Switch Mode'),
        ),
      ],
    );
  }
}
