import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';

// ─── State ────────────────────────────────────────────────────────────────────

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

  EntryState copyWith({
    Direction? direction,
    int? amountMinor,
    String? partyName,
    String? category,
    String? note,
    bool? isUdhaar,
    String? photoPath,
    bool? saving,
  }) {
    return EntryState(
      direction: direction ?? this.direction,
      amountMinor: amountMinor ?? this.amountMinor,
      partyName: partyName ?? this.partyName,
      category: category ?? this.category,
      note: note ?? this.note,
      isUdhaar: isUdhaar ?? this.isUdhaar,
      photoPath: photoPath ?? this.photoPath,
      saving: saving ?? this.saving,
    );
  }

  bool get isValid => amountMinor > 0;
}

// ─── ViewModel ────────────────────────────────────────────────────────────────

/// Immutable seed applied when the entry view model is created. Seeding here
/// (instead of mutating after creation) keeps Riverpod happy — providers must
/// not be modified while the widget tree is building.
class EntrySeed {
  const EntrySeed({
    this.direction = Direction.moneyIn,
    this.isCredit = false,
    this.partyName,
    this.category,
    this.amountMinor = 0,
  });

  final Direction direction;
  final bool isCredit;
  final String? partyName;
  final String? category;
  final int amountMinor;

  @override
  bool operator ==(Object other) =>
      other is EntrySeed &&
      other.direction == direction &&
      other.isCredit == isCredit &&
      other.partyName == partyName &&
      other.category == category &&
      other.amountMinor == amountMinor;

  @override
  int get hashCode =>
      Object.hash(direction, isCredit, partyName, category, amountMinor);
}

class EntryViewModel extends StateNotifier<EntryState> {
  EntryViewModel(this._repo, this._ref, {EntrySeed seed = const EntrySeed()})
    : super(
        EntryState(
          direction: seed.direction,
          isUdhaar: seed.isCredit,
          partyName: seed.partyName,
          category: seed.category,
          amountMinor: seed.amountMinor,
        ),
      );

  final GallaRepository _repo;
  final Ref _ref;

  void setDirection(Direction direction) =>
      state = state.copyWith(direction: direction);

  void setAmount(int minor) => state = state.copyWith(amountMinor: minor);

  void setParty(String? name) => state = state.copyWith(partyName: name);

  void setCategory(String? cat) => state = state.copyWith(category: cat);

  void setNote(String? note) => state = state.copyWith(note: note);

  void setUdhaar(bool val) => state = state.copyWith(isUdhaar: val);

  void setPhoto(String path) => state = state.copyWith(photoPath: path);

  Future<bool> save() async {
    if (!state.isValid) return false;
    state = state.copyWith(saving: true);

    final settings = _ref.read(settingsProvider).valueOrNull;
    final branchId = _ref.read(selectedBranchIdProvider);

    try {
      await _repo.addEntry(
        direction: state.direction,
        amountMinor: state.amountMinor,
        partyName: state.partyName,
        category: state.category,
        note: state.note,
        isCredit: state.isUdhaar,
        photoPath: state.photoPath,
        branchId: branchId,
        staffId: settings?.activeStaffId,
        staffName: settings?.activeStaffName,
      );
      state = state.copyWith(saving: false);
      return true;
    } catch (_) {
      state = state.copyWith(saving: false);
      return false;
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final entryViewModelProvider = StateNotifierProvider.autoDispose
    .family<EntryViewModel, EntryState, EntrySeed>((ref, seed) {
      return EntryViewModel(ref.read(repositoryProvider), ref, seed: seed);
    });
