import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class MoreState {
  const MoreState({
    this.settings = const AppSettings(),
    this.branches = const [],
    this.staff = const [],
    this.loading = true,
  });

  final AppSettings settings;
  final List<Branch> branches;
  final List<StaffMember> staff;
  final bool loading;

  MoreState copyWith({
    AppSettings? settings,
    List<Branch>? branches,
    List<StaffMember>? staff,
    bool? loading,
  }) {
    return MoreState(
      settings: settings ?? this.settings,
      branches: branches ?? this.branches,
      staff: staff ?? this.staff,
      loading: loading ?? this.loading,
    );
  }
}

// ─── ViewModel ────────────────────────────────────────────────────────────────

class MoreViewModel extends AsyncNotifier<MoreState> {
  GallaRepository get _repo => ref.read(repositoryProvider);

  @override
  Future<MoreState> build() async {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final branches = ref.watch(branchesProvider).valueOrNull ?? [];
    final staff = ref.watch(staffMembersProvider).valueOrNull ?? [];
    return MoreState(
      settings: settings,
      branches: branches,
      staff: staff,
      loading: false,
    );
  }

  Future<void> updateSettings(AppSettings updated) async {
    await _repo.saveSettings(updated);
    ref.invalidateSelf();
  }

  Future<void> setActiveBranch(String? branchId) async {
    ref.read(selectedBranchIdProvider.notifier).state = branchId;
    final settings =
        ref.read(settingsProvider).valueOrNull ?? const AppSettings();
    await _repo.saveSettings(settings.copyWith(activeBranchId: branchId));
    ref.invalidateSelf();
  }

  Future<bool> switchToStaffMode(
    String staffId,
    String staffName,
    String pin,
  ) async {
    final verified = await _repo.verifyStaffPin(staffId, pin);
    if (!verified) return false;
    final settings =
        ref.read(settingsProvider).valueOrNull ?? const AppSettings();
    await _repo.saveSettings(
      settings.copyWith(
        activeStaffId: staffId,
        activeStaffName: staffName,
        activeStaffRole: StaffRole.staff,
      ),
    );
    ref.invalidateSelf();
    return true;
  }

  Future<void> switchToOwnerMode() async {
    final settings =
        ref.read(settingsProvider).valueOrNull ?? const AppSettings();
    await _repo.saveSettings(
      settings.copyWith(
        activeStaffId: null,
        activeStaffName: null,
        activeStaffRole: StaffRole.owner,
      ),
    );
    ref.invalidateSelf();
  }

  Future<void> wipeAll() async {
    await _repo.wipeAll();
    ref.invalidateSelf();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final moreViewModelProvider = AsyncNotifierProvider<MoreViewModel, MoreState>(
  MoreViewModel.new,
);
