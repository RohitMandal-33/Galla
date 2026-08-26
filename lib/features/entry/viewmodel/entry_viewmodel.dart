import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';

/// Categories available per direction. Shared by the entry form and the
/// view model so switching direction can never leave an invalid category
/// selected.
const incomeCategories = [
  'Sales',
  'Services',
  'Customer Payment',
  'Commission',
  'Other Income',
];

const expenseCategories = [
  'Purchase / Stock',
  'Rent',
  'Staff / Salary',
  'Electricity / Utility',
  'Transport',
  'Other Expense',
];

class EntryState {
  const EntryState({
    this.direction = Direction.moneyIn,
    this.amountMinor = 0,
    this.partyName,
    this.category,
    this.note,
    this.isUdhaar = false,
    this.photoPath,
    this.saving = false,
  });

  final Direction direction;
  final int amountMinor;
  final String? partyName;
  final String? category;
  final String? note;
  final bool isUdhaar;
  final String? photoPath;
  final bool saving;

  bool get isValid => amountMinor > 0 && !saving;

  EntryState copyWith({
    Direction? direction,
    int? amountMinor,
    String? partyName,
    bool clearParty = false,
    String? category,
    bool clearCategory = false,
    String? note,
    bool clearNote = false,
    bool? isUdhaar,
    String? photoPath,
    bool? saving,
  }) {
    return EntryState(
      direction: direction ?? this.direction,
      amountMinor: amountMinor ?? this.amountMinor,
      partyName: clearParty ? null : (partyName ?? this.partyName),
      category: clearCategory ? null : (category ?? this.category),
      note: clearNote ? null : (note ?? this.note),
      isUdhaar: isUdhaar ?? this.isUdhaar,
      photoPath: photoPath ?? this.photoPath,
      saving: saving ?? this.saving,
    );
  }
}

/// Immutable seed describing how the entry form opens. Used as the family
/// key of [entryViewModelProvider] so every variant of the sheet gets its
/// own isolated form state.
class EntrySeed {
  const EntrySeed({
    required this.direction,
    required this.isCredit,
    required this.amountMinor,
    this.partyName,
    this.category,
  });

  final Direction direction;
  final bool isCredit;
  final int amountMinor;
  final String? partyName;
  final String? category;

  @override
  bool operator ==(Object other) =>
      identical(other, this) ||
      (other is EntrySeed &&
          other.direction == direction &&
          other.isCredit == isCredit &&
          other.partyName == partyName &&
          other.category == category &&
          other.amountMinor == amountMinor);

  @override
  int get hashCode =>
      Object.hash(direction, isCredit, partyName, category, amountMinor);
}

class EntryViewModel extends StateNotifier<EntryState> {
  EntryViewModel(this._ref, EntrySeed seed)
    : super(
        EntryState(
          direction: seed.direction,
          isUdhaar: seed.isCredit,
          partyName: seed.partyName,
          category: seed.category,
          amountMinor: seed.amountMinor,
        ),
      );

  final Ref _ref;

  void setAmount(int minor) => state = state.copyWith(amountMinor: minor);

  void setParty(String name) => state = state.copyWith(partyName: name.trim());

  void setNote(String note) => state = state.copyWith(note: note);

  void setPhoto(String path) => state = state.copyWith(photoPath: path);

  /// Switching direction must never carry a category that belongs to the
  /// other direction (e.g. "Rent" surviving a switch into Cash In).
  void setDirection(Direction direction) {
    if (state.direction == direction) return;
    final stillValid = direction == Direction.moneyIn
        ? incomeCategories.contains(state.category)
        : expenseCategories.contains(state.category);
    state = state.copyWith(
      direction: direction,
      category: stillValid ? state.category : null,
      clearCategory: !stillValid,
    );
  }

  void setUdhaar(bool value) => state = state.copyWith(isUdhaar: value);

  void setCategory(String? category) => state = state.copyWith(
    category: category,
    clearCategory: category == null,
  );

  /// Persists the entry. Returns the saved transaction so callers can offer
  /// undo, or null when saving failed (callers must surface the failure).
  Future<Txn?> save() async {
    if (!state.isValid || state.saving) return null;
    state = state.copyWith(saving: true);
    try {
      final repo = _ref.read(repositoryProvider);
      final settings =
          _ref.read(settingsProvider).valueOrNull ?? const AppSettings();
      final branchId =
          _ref.read(selectedBranchIdProvider) ?? settings.activeBranchId;
      final staffId = settings.activeStaffRole == StaffRole.owner
          ? null
          : settings.activeStaffId;
      final staffName = settings.activeStaffRole == StaffRole.owner
          ? null
          : settings.activeStaffName;

      final txn = await repo.addEntry(
        direction: state.direction,
        amountMinor: state.amountMinor,
        partyName: (state.partyName?.isEmpty ?? true) ? null : state.partyName,
        category: state.category,
        note: (state.note?.isEmpty ?? true) ? null : state.note,
        isCredit: state.isUdhaar,
        photoPath: state.photoPath,
        branchId: branchId,
        staffId: staffId,
        staffName: staffName,
      );
      return txn;
    } catch (_) {
      return null;
    } finally {
      if (mounted) state = state.copyWith(saving: false);
    }
  }
}

final entryViewModelProvider = StateNotifierProvider.autoDispose
    .family<EntryViewModel, EntryState, EntrySeed>(
      (ref, seed) => EntryViewModel(ref, seed),
    );
