import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/money/money.dart';
import '../../../core/parser/nl_parser.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';
import '../viewmodel/entry_viewmodel.dart';

/// Post-save confirmation with an Undo affordance. Undo soft-deletes the
/// just-created entry (append-only ledger: history is never hard-erased).
/// Capture [undo] from a live context before popping the sheet.
void showEntryUndo(
  ScaffoldMessengerState messenger,
  S s,
  String label,
  Txn txn,
  String currency,
  Future<void> Function() undo,
) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          '$label · ${Money(txn.amountMinor, currency: currency).formatCompact()}',
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: s.undo.toUpperCase(),
          onPressed: () async {
            await undo();
            messenger.showSnackBar(SnackBar(content: Text(s.entryRemoved)));
          },
        ),
      ),
    );
}

// ── Master Launcher ────────────────────────────────────────────────────────────

Future<void> showQuickAddSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const QuickAddSheet(),
  );
}

Future<void> showAddEntrySheet(
  BuildContext context, {
  Direction initialDirection = Direction.moneyIn,
  bool isCredit = false,
  Party? seedParty,
  String? seedPartyName,
  String? seedCategory,
  int? seedAmountMinor,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EntrySheet(
      initialDirection: initialDirection,
      isCredit: isCredit,
      seedParty: seedParty,
      seedPartyName: seedPartyName,
      seedCategory: seedCategory,
      seedAmountMinor: seedAmountMinor,
    ),
  );
}

Future<void> showVoiceEntryModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const VoiceEntrySheet(),
  );
}

// ── Quick Add Hub ─────────────────────────────────────────────────────────────

class QuickAddSheet extends ConsumerWidget {
  const QuickAddSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(transactionsProvider).valueOrNull ?? [];
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();

    return Container(
      decoration: const BoxDecoration(
        color: GallaColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GallaRadius.bottomSheet),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        GallaSpacing.lg,
        GallaSpacing.sm,
        GallaSpacing.lg,
        GallaSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: GallaColors.line,
                borderRadius: BorderRadius.circular(GallaRadius.pill),
              ),
            ),
          ),
          const SizedBox(height: GallaSpacing.base),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add transaction', style: GallaType.numberMd),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: GallaColors.muted,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: GallaSpacing.sm),

          // 8-Option Grid
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _ActionTile(
                icon: Icons.add_circle_outline_rounded,
                label: 'Sale',
                color: GallaColors.moneyIn,
                bg: GallaColors.moneyInSoft,
                onTap: () {
                  // Launch from the navigator's context: this sheet's own
                  // context dies at pop() and can't open the next route.
                  final nav = Navigator.of(context);
                  nav.pop();
                  showAddEntrySheet(
                    nav.context,
                    initialDirection: Direction.moneyIn,
                    seedCategory: 'Sales',
                  );
                },
              ),
              _ActionTile(
                icon: Icons.remove_circle_outline_rounded,
                label: 'Expense',
                color: GallaColors.moneyOut,
                bg: GallaColors.moneyOutSoft,
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  showAddEntrySheet(
                    nav.context,
                    initialDirection: Direction.moneyOut,
                  );
                },
              ),
              _ActionTile(
                icon: Icons.call_received_rounded,
                label: 'Received',
                color: GallaColors.moneyIn,
                bg: GallaColors.moneyInSoft,
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  showAddEntrySheet(
                    nav.context,
                    initialDirection: Direction.moneyIn,
                    seedCategory: 'Customer Payment',
                  );
                },
              ),
              _ActionTile(
                icon: Icons.call_made_rounded,
                label: 'Paid',
                color: GallaColors.moneyOut,
                bg: GallaColors.moneyOutSoft,
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  showAddEntrySheet(
                    nav.context,
                    initialDirection: Direction.moneyOut,
                  );
                },
              ),
              _ActionTile(
                icon: Icons.pending_actions_rounded,
                label: 'Credit',
                color: GallaColors.udhaar,
                bg: GallaColors.udhaarSoft,
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  showAddEntrySheet(
                    nav.context,
                    initialDirection: Direction.moneyIn,
                    isCredit: true,
                  );
                },
              ),
              _ActionTile(
                icon: Icons.receipt_long_rounded,
                label: 'Invoice',
                color: GallaColors.blue,
                bg: GallaColors.blueSoft,
                onTap: () {
                  // Resolve the router before popping so we never touch a
                  // deactivated context after the sheet closes.
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.push('/invoices/create');
                },
              ),
              _ActionTile(
                icon: Icons.inventory_2_outlined,
                label: 'Stock',
                color: GallaColors.gold,
                bg: GallaColors.goldSoft,
                onTap: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.go('/inventory');
                },
              ),
              _ActionTile(
                icon: Icons.mic_rounded,
                label: 'Speak',
                color: GallaColors.brand,
                bg: GallaColors.brandSoft,
                onTap: () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  showVoiceEntryModal(nav.context);
                },
              ),
            ],
          ),
          const SizedBox(height: GallaSpacing.base),

          // Recent / Repeat Actions
          if (txns.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: GallaSpacing.xs),
            Text(
              'Recent Actions',
              style: GallaType.chipLabel.copyWith(color: GallaColors.muted),
            ),
            const SizedBox(height: GallaSpacing.xs),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: txns.take(3).map((t) {
                final isInc = t.direction == Direction.moneyIn;
                final amt = Money(
                  t.amountMinor,
                  currency: settings.currency,
                ).format();
                final title = t.partyName ?? t.category ?? 'Sale';
                return ActionChip(
                  avatar: Icon(
                    isInc
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 12,
                    color: isInc ? GallaColors.moneyIn : GallaColors.moneyOut,
                  ),
                  label: Text(
                    'Repeat $title ($amt)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    final nav = Navigator.of(context);
                    nav.pop();
                    showAddEntrySheet(
                      nav.context,
                      initialDirection: t.direction,
                      isCredit: t.isCredit,
                      seedPartyName: t.partyName,
                      seedCategory: t.category,
                      seedAmountMinor: t.amountMinor,
                    );
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(GallaRadius.lg),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(label, style: GallaType.labelStrong),
        ],
      ),
    );
  }
}

// ── Voice Entry Modal ─────────────────────────────────────────────────────────

class VoiceEntrySheet extends ConsumerStatefulWidget {
  const VoiceEntrySheet({super.key});

  @override
  ConsumerState<VoiceEntrySheet> createState() => _VoiceEntrySheetState();
}

class _VoiceEntrySheetState extends ConsumerState<VoiceEntrySheet>
    with SingleTickerProviderStateMixin {
  final _speech = SpeechToText();
  final _parser = NlParser();
  bool _isListening = false;
  bool _failed = false;
  String _transcript = '';
  ParsedEntry? _parsed;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    // A calm, single breathing pulse only while actually listening — no
    // infinite idle animation.
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startListening());
  }

  @override
  void dispose() {
    _speech.stop();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (!mounted) return;
    setState(() {
      _failed = false;
      _transcript = '';
      _parsed = null;
    });
    bool available;
    try {
      available = await _speech.initialize();
    } catch (_) {
      available = false;
    }
    if (!mounted) return;
    if (!available) {
      // Speech is unavailable (no permission / unsupported device) — say so
      // instead of leaving the user stuck on "Tap to speak".
      setState(() => _failed = true);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _isListening = true);
    if (mounted && _isListening) _animCtrl.repeat(reverse: true);

    await _speech.listen(
      localeId:
          'ne_NP', // Defaults to Nepali if supported, falls back automatically.
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _transcript = result.recognizedWords;
          if (_transcript.trim().isNotEmpty) {
            _parsed = _parser.parse(_transcript);
          }
        });
        if (result.finalResult && mounted) {
          setState(() => _isListening = false);
          _animCtrl.stop();
        }
      },
    );
  }

  void _stopListening() {
    _speech.stop();
    if (mounted) {
      setState(() => _isListening = false);
      _animCtrl.stop();
    }
  }

  Future<void> _confirmAndSave() async {
    final parsed = _parsed;
    if (parsed == null || parsed.amountMinor == null) return;
    final repo = ref.read(repositoryProvider);
    final settings =
        ref.read(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);

    final txn = await repo.addEntry(
      direction: parsed.direction ?? Direction.moneyIn,
      amountMinor: parsed.amountMinor!,
      partyName: parsed.partyName,
      category: parsed.category,
      note: _transcript,
      isCredit: parsed.isCredit,
      nlRaw: _transcript,
      aiInferred: true,
      branchId: settings.activeBranchId,
    );

    if (!mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    showEntryUndo(
      messenger,
      s,
      '${s.entryAdded} · ${s.voiceEntry}',
      txn,
      settings.currency,
      () => repo.softDeleteEntry(txn.id),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();

    return Container(
      decoration: const BoxDecoration(
        color: GallaColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(GallaRadius.bottomSheet),
        ),
      ),
      padding: const EdgeInsets.all(GallaSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: GallaColors.line,
              borderRadius: BorderRadius.circular(GallaRadius.pill),
            ),
          ),
          const SizedBox(height: GallaSpacing.lg),

          // Mic circle — animates only while listening.
          AnimatedBuilder(
            animation: _animCtrl,
            builder: (context, child) {
              final scale = _isListening ? 1.0 + (_animCtrl.value * 0.12) : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: _isListening
                        ? GallaColors.brand
                        : GallaColors.brandSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                    size: 36,
                    color: _isListening ? Colors.white : GallaColors.brand,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: GallaSpacing.base),

          Text(
            _failed
                ? "Couldn't start speech recognition"
                : _isListening
                ? 'Listening…'
                : _parsed == null
                ? 'Speak'
                : 'Check the details',
            style: GallaType.cardTitle,
          ),
          const SizedBox(height: GallaSpacing.xs),
          Text(
            _failed
                ? 'Check the microphone permission in Settings, or add the entry by typing instead.'
                : _transcript.isEmpty
                ? 'Try saying: "Hari lai 500 ko saman udhar diye"'
                : '"$_transcript"',
            style: GallaType.body.copyWith(
              color: _transcript.isEmpty || _failed
                  ? GallaColors.muted
                  : GallaColors.ink,
              fontStyle: _transcript.isEmpty && !_failed
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GallaSpacing.lg),

          // Parsed confirmation — the merchant confirms what the parser heard.
          if (_parsed != null && _parsed!.amountMinor != null) ...[
            VoicePreviewCard(
              parsed: _parsed!,
              currency: settings.currency,
              transcript: _transcript,
            ),
            const SizedBox(height: GallaSpacing.base),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _startListening,
                    child: const Text('Try Again'),
                  ),
                ),
                const SizedBox(width: GallaSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _confirmAndSave,
                    child: const Text('Confirm & Save'),
                  ),
                ),
              ],
            ),
          ] else ...[
            OutlinedButton.icon(
              onPressed: _startListening,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Speak Again'),
            ),
            if (!_isListening && !_failed) ...[
              const SizedBox(height: GallaSpacing.sm),
              TextButton(
                onPressed: _stopListening,
                child: const Text('Cancel'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// The parser's inference shown back to the merchant before committing.
/// Extracted from the sheet so it can be widget-tested without a live
/// speech engine. AI infers; the merchant confirms; the ledger stays exact.
class VoicePreviewCard extends StatelessWidget {
  const VoicePreviewCard({
    super.key,
    required this.parsed,
    required this.currency,
    required this.transcript,
  });

  final ParsedEntry parsed;
  final String currency;
  final String transcript;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(GallaSpacing.base),
      decoration: BoxDecoration(
        color: GallaColors.surface2,
        borderRadius: BorderRadius.circular(GallaRadius.lg),
        border: Border.all(color: GallaColors.gold.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.hearing_rounded, size: 16, color: GallaColors.gold),
              const SizedBox(width: 6),
              Text(
                'Galla understood',
                style: GallaType.chipLabel.copyWith(
                  color: GallaColors.goldDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Type',
                style: GallaType.body.copyWith(color: GallaColors.muted),
              ),
              Text(
                parsed.isCredit
                    ? 'Udhaar'
                    : (parsed.direction == Direction.moneyIn
                          ? 'Money In'
                          : 'Money Out'),
                style: GallaType.subtitleSm,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Amount',
                style: GallaType.body.copyWith(color: GallaColors.muted),
              ),
              Text(
                Money(parsed.amountMinor ?? 0, currency: currency).format(),
                style: GallaType.numberSm,
              ),
            ],
          ),
          if (parsed.partyName != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Party',
                  style: GallaType.body.copyWith(color: GallaColors.muted),
                ),
                Flexible(
                  child: Text(
                    parsed.partyName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GallaType.subtitleSm,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Standard Entry Form ───────────────────────────────────────────────────────

class EntrySheet extends ConsumerStatefulWidget {
  const EntrySheet({
    super.key,
    this.initialDirection = Direction.moneyIn,
    this.isCredit = false,
    this.seedParty,
    this.seedPartyName,
    this.seedCategory,
    this.seedAmountMinor,
  });

  final Direction initialDirection;
  final bool isCredit;
  final Party? seedParty;
  final String? seedPartyName;
  final String? seedCategory;
  final int? seedAmountMinor;

  @override
  ConsumerState<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends ConsumerState<EntrySheet> {
  final _amountController = TextEditingController();
  final _partyController = TextEditingController();
  final _noteController = TextEditingController();
  final _formScroll = ScrollController();
  final _chipKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    if (widget.seedParty != null) {
      _partyController.text = widget.seedParty!.name;
    } else if (widget.seedPartyName != null) {
      _partyController.text = widget.seedPartyName!;
    }
    final seedMinor = widget.seedAmountMinor ?? 0;
    if (seedMinor > 0) {
      final whole = seedMinor ~/ 100;
      final cents = seedMinor % 100;
      _amountController.text = cents == 0
          ? '$whole'
          : (seedMinor / 100).toString();
    }
    // Make a seeded category visible as soon as the sheet lays out.
    if (widget.seedCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _revealChip(widget.seedCategory!);
      });
    }
  }

  void _revealChip(String category) {
    final keyContext = _chipKeys[category]?.currentContext;
    if (keyContext != null && keyContext.mounted) {
      Scrollable.ensureVisible(
        keyContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
  }

  EntrySeed get _seed => EntrySeed(
    direction: widget.initialDirection,
    isCredit: widget.isCredit,
    partyName: widget.seedParty?.name ?? widget.seedPartyName,
    category: widget.seedCategory,
    amountMinor: widget.seedAmountMinor ?? 0,
  );

  @override
  void dispose() {
    _amountController.dispose();
    _partyController.dispose();
    _noteController.dispose();
    _formScroll.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(EntryViewModel vm) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (file == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dest = File(
      p.join(dir.path, 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg'),
    );
    await File(file.path).copy(dest.path);
    vm.setPhoto(dest.path);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(entryViewModelProvider(_seed));
    final vm = ref.read(entryViewModelProvider(_seed).notifier);
    final parties = ref.watch(partiesProvider).valueOrNull ?? const <Party>[];
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final isIncome = state.direction == Direction.moneyIn;
    final categories = isIncome ? incomeCategories : expenseCategories;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final activeColor = isIncome ? GallaColors.moneyIn : GallaColors.moneyOut;
    final currencySymbol = Money(0, currency: settings.currency).symbol;

    // ── IME / window-inset strategy ────────────────────────────────────────
    // The activity runs with windowSoftInputMode=adjustResize, so the IME inset
    // arrives here via MediaQuery. The SHEET ROOT owns that inset (Flutter's
    // equivalent of imePadding at the correct level): everything, including
    // the pinned Save action, rides above the keyboard. The form scrolls in a
    // height-capped region so nothing is ever clipped or pushed off-screen,
    // and no space is wasted when the keyboard is hidden.
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: GallaColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(GallaRadius.bottomSheet),
          ),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        padding: const EdgeInsets.fromLTRB(
          GallaSpacing.lg,
          0,
          GallaSpacing.lg,
          GallaSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: GallaSpacing.md),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: GallaColors.line,
                  borderRadius: BorderRadius.circular(GallaRadius.pill),
                ),
              ),
            ),

            // Direction Selector
            Row(
              children: [
                Expanded(
                  child: _DirectionTab(
                    label: 'Cash In (+)',
                    selected: isIncome,
                    color: GallaColors.moneyIn,
                    onTap: () => vm.setDirection(Direction.moneyIn),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _DirectionTab(
                    label: 'Cash Out (-)',
                    selected: !isIncome,
                    color: GallaColors.moneyOut,
                    onTap: () => vm.setDirection(Direction.moneyOut),
                  ),
                ),
              ],
            ),
            const SizedBox(height: GallaSpacing.base),

            // Scrollable form region — grows only when space allows, scrolls
            // under small viewports/keyboards. TextFields reveal their caret
            // via Scrollable.ensureVisible into this controller automatically
            // (e.g. focusing Note scrolls it into view).
            Flexible(
              child: SingleChildScrollView(
                controller: _formScroll,
                padding: const EdgeInsets.only(bottom: GallaSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Amount Field
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      autofocus: true,
                      cursorColor: activeColor,
                      style: GallaType.totalLg.copyWith(color: activeColor),
                      decoration: InputDecoration(
                        prefixText: '$currencySymbol ',
                        prefixStyle: GallaType.numberXl.copyWith(
                          fontWeight: FontWeight.w700,
                          color: activeColor.withValues(alpha: 0.7),
                        ),
                        hintText: '0',
                        hintStyle: TextStyle(color: GallaColors.line),
                        border: InputBorder.none,
                        filled: false,
                      ),
                      onChanged: (v) => vm.setAmount(Money.parseToMinor(v)),
                    ),
                    const Divider(),
                    const SizedBox(height: GallaSpacing.sm),

                    // Party Input
                    TextField(
                      controller: _partyController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Party / Customer / Supplier (Optional)',
                        prefixIcon: const Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                        ),
                        suffixIcon: parties.isNotEmpty
                            ? PopupMenuButton<String>(
                                icon: const Icon(Icons.arrow_drop_down_rounded),
                                onSelected: (name) {
                                  _partyController.text = name;
                                  vm.setParty(name);
                                },
                                itemBuilder: (_) => parties
                                    .take(5)
                                    .map(
                                      (p) => PopupMenuItem(
                                        value: p.name,
                                        child: Text(p.name),
                                      ),
                                    )
                                    .toList(),
                              )
                            : null,
                      ),
                      onChanged: vm.setParty,
                    ),
                    const SizedBox(height: GallaSpacing.sm),

                    // Category Chips — horizontally scrollable (LazyRow
                    // equivalent); selected chip always scrolled into view and
                    // trailing spacing keeps the last chip clear of the edge.
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...categories.map((cat) {
                            final selected = state.category == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                key: _chipKeys.putIfAbsent(
                                  cat,
                                  () => GlobalKey(debugLabel: cat),
                                ),
                                label: Text(cat),
                                selected: selected,
                                selectedColor: activeColor.withValues(
                                  alpha: 0.15,
                                ),
                                labelStyle: GallaType.caption.copyWith(
                                  color: selected
                                      ? activeColor
                                      : GallaColors.ink,
                                ),
                                onSelected: (val) {
                                  vm.setCategory(val ? cat : null);
                                  if (val) _revealChip(cat);
                                },
                              ),
                            );
                          }),
                          const SizedBox(width: GallaSpacing.base),
                        ],
                      ),
                    ),
                    const SizedBox(height: GallaSpacing.sm),

                    // Udhaar (Credit) Toggle — no cash movement until settled
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: state.isUdhaar
                            ? GallaColors.udhaarSoft
                            : GallaColors.surface2,
                        borderRadius: BorderRadius.circular(GallaRadius.md),
                        border: Border.all(
                          color: state.isUdhaar
                              ? GallaColors.udhaar
                              : GallaColors.line,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                          dense: true,
                          value: state.isUdhaar,
                          activeThumbColor: GallaColors.udhaar,
                          onChanged: (v) => vm.setUdhaar(v),
                          secondary: Icon(
                            Icons.hourglass_top_rounded,
                            size: 20,
                            color: state.isUdhaar
                                ? GallaColors.udhaar
                                : GallaColors.muted,
                          ),
                          title: Text(
                            'Udhaar (Credit)',
                            style: GallaType.subtitle,
                          ),
                          subtitle: Text(
                            'No cash moved yet',
                            style: GallaType.captionSm.copyWith(
                              color: state.isUdhaar
                                  ? GallaColors.udhaar
                                  : GallaColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: GallaSpacing.sm),

                    // Note + Photo Row
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _noteController,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Note (Optional)',
                              prefixIcon: Icon(Icons.notes_rounded, size: 20),
                            ),
                            onChanged: vm.setNote,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          icon: Icon(
                            state.photoPath != null
                                ? Icons.check_circle_rounded
                                : Icons.camera_alt_outlined,
                            color: state.photoPath != null
                                ? GallaColors.moneyIn
                                : GallaColors.ink,
                          ),
                          onPressed: () => _pickPhoto(vm),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: GallaSpacing.sm),

            // Pinned primary action — lives OUTSIDE the scroll region so it
            // stays visible and tappable above the keyboard at all times.
            FilledButton(
              onPressed: state.isValid && !state.saving
                  ? () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      final txn = await vm.save();
                      if (txn != null) {
                        showEntryUndo(
                          messenger,
                          s,
                          '${s.entryAdded} · ${txn.category ?? (txn.direction == Direction.moneyIn ? s.typeSale : s.typeExpense)}',
                          txn,
                          settings.currency,
                          () => ref
                              .read(repositoryProvider)
                              .softDeleteEntry(txn.id),
                        );
                        navigator.pop();
                      } else if (!ref
                          .read(entryViewModelProvider(_seed))
                          .saving) {
                        // Save failed — never fail silently.
                        messenger.showSnackBar(
                          SnackBar(content: Text(s.saveFailed)),
                        );
                      }
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: activeColor,
                minimumSize: const Size.fromHeight(52),
              ),
              child: state.saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : Text(s.save, style: GallaType.cardTitle),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirectionTab extends StatelessWidget {
  const _DirectionTab({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : GallaColors.surface2,
          borderRadius: BorderRadius.circular(GallaRadius.md),
          border: Border.all(color: selected ? color : GallaColors.line),
        ),
        child: Center(
          child: Text(
            label,
            style: GallaType.subtitleSm.copyWith(
              color: selected ? color : GallaColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}
