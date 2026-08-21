import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/parser/nl_parser.dart';
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
    this.paymentMethod = 'Cash',
    this.photoPath,
    this.inventoryItemId,
    this.nlRaw,
    this.saving = false,
    this.saved = false,
  });

  final Direction direction;
  final int amountMinor;
  final String? partyName;
  final String? category;
  final String? note;
  final bool isUdhaar;
  final String paymentMethod;
  final String? photoPath;
  final String? inventoryItemId;
  final String? nlRaw;
  final bool saving;
  final bool saved;

  EntryState copyWith({
    Direction? direction,
    int? amountMinor,
    String? partyName,
    String? category,
    String? note,
    bool? isUdhaar,
    String? paymentMethod,
    String? photoPath,
    String? inventoryItemId,
    String? nlRaw,
    bool? saving,
    bool? saved,
  }) {
    return EntryState(
      direction: direction ?? this.direction,
      amountMinor: amountMinor ?? this.amountMinor,
      partyName: partyName ?? this.partyName,
      category: category ?? this.category,
      note: note ?? this.note,
      isUdhaar: isUdhaar ?? this.isUdhaar,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      photoPath: photoPath ?? this.photoPath,
      inventoryItemId: inventoryItemId ?? this.inventoryItemId,
      nlRaw: nlRaw ?? this.nlRaw,
      saving: saving ?? this.saving,
      saved: saved ?? this.saved,
    );
  }

  bool get isValid => amountMinor > 0;
}

// ─── ViewModel ────────────────────────────────────────────────────────────────

class EntryViewModel extends StateNotifier<EntryState> {
  EntryViewModel(this._repo, this._ref, {Direction? initialDirection})
      : super(EntryState(direction: initialDirection ?? Direction.moneyIn));

  final GallaRepository _repo;
  final Ref _ref;
  final _parser = NlParser();

  void setDirection(Direction direction) =>
      state = state.copyWith(direction: direction);

  void setAmount(int minor) => state = state.copyWith(amountMinor: minor);

  void addToAmount(int delta) =>
      state = state.copyWith(amountMinor: state.amountMinor + delta);

  void setParty(String? name) => state = state.copyWith(partyName: name);

  void setCategory(String? cat) => state = state.copyWith(category: cat);

  void setNote(String? note) => state = state.copyWith(note: note);

  void setUdhaar(bool val) => state = state.copyWith(isUdhaar: val);

  void setPaymentMethod(String method) =>
      state = state.copyWith(paymentMethod: method);

  void setPhoto(String path) => state = state.copyWith(photoPath: path);

  void setInventoryItem(String? id) =>
      state = state.copyWith(inventoryItemId: id);

  void applyNl(String raw) {
    final parsed = _parser.parse(raw);
    state = state.copyWith(
      direction: parsed.direction ?? state.direction,
      amountMinor: parsed.amountMinor ?? state.amountMinor,
      partyName: parsed.partyName ?? state.partyName,
      category: parsed.category ?? state.category,
      note: parsed.note ?? state.note,
      isUdhaar: parsed.isCredit,
      nlRaw: raw,
    );
  }

  void repeatLast(List<Txn> txns) {
    if (txns.isEmpty) return;
    final last = txns.first;
    state = state.copyWith(
      direction: last.direction,
      amountMinor: last.amountMinor,
      partyName: last.partyName,
      category: last.category,
      note: last.note,
      isUdhaar: last.isCredit,
      inventoryItemId: last.inventoryItemId,
    );
  }

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
        nlRaw: state.nlRaw,
        aiInferred: state.nlRaw != null,
        branchId: branchId,
        staffId: settings?.activeStaffId,
        staffName: settings?.activeStaffName,
        inventoryItemId: state.inventoryItemId,
      );
      state = state.copyWith(saving: false, saved: true);
      return true;
    } catch (_) {
      state = state.copyWith(saving: false);
      return false;
    }
  }

  void reset({Direction? direction}) {
    state = EntryState(direction: direction ?? state.direction);
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final entryViewModelProvider = StateNotifierProvider.autoDispose
    .family<EntryViewModel, EntryState, Direction>((ref, initialDirection) {
  return EntryViewModel(
    ref.read(repositoryProvider),
    ref,
    initialDirection: initialDirection,
  );
});
