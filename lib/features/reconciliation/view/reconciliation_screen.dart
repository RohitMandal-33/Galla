import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../data/galla_repository.dart';
import '../../../domain/models.dart';
import '../../../shared/widgets/galla_components.dart';

class ReconciliationScreen extends ConsumerStatefulWidget {
  const ReconciliationScreen({super.key});

  @override
  ConsumerState<ReconciliationScreen> createState() => _ReconciliationScreenState();
}

class _ReconciliationScreenState extends ConsumerState<ReconciliationScreen> {
  final _cashController = TextEditingController();
  final _bankController = TextEditingController();
  final _noteController = TextEditingController();
  DailySummary? _todaySummary;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  @override
  void dispose() {
    _cashController.dispose();
    _bankController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    final repo = ref.read(repositoryProvider);
    final branchId = ref.read(selectedBranchIdProvider);
    final summary = await repo.summaryFor(DateTime.now(), branchId: branchId);
    if (mounted) {
      setState(() {
        _todaySummary = summary;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final currency = settings.currency;
    final historyAsync = ref.watch(reconciliationsProvider);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(s.reconciliation)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final expectedCashMinor = _todaySummary?.cashOnHandMinor ?? 0;
    final countedVal = int.tryParse(_cashController.text.trim());
    final countedCashMinor = countedVal != null ? countedVal * 100 : null;
    final discrepancyMinor = countedCashMinor != null ? countedCashMinor - expectedCashMinor : null;

    return Scaffold(
      backgroundColor: GallaColors.canvas,
      appBar: AppBar(
        backgroundColor: GallaColors.canvas,
        title: Text(s.reconciliation),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          GallaSpacing.base,
          GallaSpacing.xs,
          GallaSpacing.base,
          120,
        ),
        children: [
          // ── Intro / Purpose Card ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(GallaSpacing.cardPadding),
            decoration: BoxDecoration(
              color: GallaColors.brandSoft,
              borderRadius: BorderRadius.circular(GallaRadius.xl),
              border: Border.all(color: GallaColors.brand.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: GallaColors.brand.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(GallaRadius.md),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined, color: GallaColors.brand, size: 22),
                ),
                const SizedBox(width: GallaSpacing.md),
                Expanded(
                  child: Text(
                    s.reconcileIntro,
                    style: const TextStyle(fontSize: 13, color: GallaColors.brand, height: 1.35, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: GallaSpacing.md),

          // ── System Expected Cash ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(GallaSpacing.cardPadding),
            decoration: BoxDecoration(
              color: GallaColors.surface,
              borderRadius: BorderRadius.circular(GallaRadius.xl),
              border: Border.all(color: GallaColors.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.systemExpected, style: const TextStyle(fontSize: 12, color: GallaColors.muted)),
                    const SizedBox(height: 3),
                    Text(
                      Money(expectedCashMinor, currency: currency).format(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: GallaColors.brand,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _loadSummary();
                  },
                  tooltip: 'Recalculate',
                ),
              ],
            ),
          ),
          const SizedBox(height: GallaSpacing.lg),

          // ── Physical Count Inputs ──────────────────────────────────────
          GallaSectionHeader(
            title: 'Physical Count Verification',
            topPadding: 0,
            bottomPadding: GallaSpacing.sm,
          ),

          TextField(
            controller: _cashController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: '${s.countedCash} * ($currency)',
              hintText: 'Enter total cash counted in till',
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: GallaSpacing.md),

          TextField(
            controller: _bankController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '${s.bankBalance} (Optional) ($currency)',
              hintText: 'Current bank account balance',
              prefixIcon: const Icon(Icons.account_balance_outlined),
            ),
          ),
          const SizedBox(height: GallaSpacing.md),

          // ── Live Discrepancy Breakdown ──────────────────────────────────
          if (discrepancyMinor != null && countedCashMinor != null) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(GallaSpacing.cardPadding),
              decoration: BoxDecoration(
                color: discrepancyMinor == 0
                    ? GallaColors.moneyInSoft
                    : GallaColors.moneyOutSoft,
                borderRadius: BorderRadius.circular(GallaRadius.xl),
                border: Border.all(
                  color: discrepancyMinor == 0 ? GallaColors.moneyIn.withValues(alpha: 0.4) : GallaColors.moneyOut.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        s.discrepancy,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: GallaColors.ink),
                      ),
                      Text(
                        discrepancyMinor == 0
                            ? s.noDiscrepancy
                            : (discrepancyMinor > 0
                                ? '+${Money(discrepancyMinor, currency: currency).format()} (Surplus)'
                                : '-${Money(discrepancyMinor.abs(), currency: currency).format()} (Shortage)'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: discrepancyMinor == 0 ? GallaColors.moneyIn : GallaColors.moneyOut,
                        ),
                      ),
                    ],
                  ),
                  if (discrepancyMinor != 0) ...[
                    const SizedBox(height: GallaSpacing.sm),
                    const Divider(),
                    const SizedBox(height: GallaSpacing.sm),
                    const Text(
                      'Common Causes Checklist:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: GallaColors.inkSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      discrepancyMinor < 0
                          ? '• Unrecorded cash expense / supplier payment\n• Unrecorded cash withdrawal or change given\n• Calculation / counting error'
                          : '• Unrecorded cash sale or customer payment\n• Cash received from customer credit (udhaar)',
                      style: const TextStyle(fontSize: 12, height: 1.45, color: GallaColors.muted),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: GallaSpacing.md),

            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Reconciliation Note (Optional)',
                hintText: 'e.g. End of day till audit by Ramesh',
                prefixIcon: Icon(Icons.edit_note_rounded),
              ),
            ),
            const SizedBox(height: GallaSpacing.base),

            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: GallaColors.brand,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GallaRadius.button)),
              ),
              onPressed: _submitting
                  ? null
                  : () async {
                      HapticFeedback.mediumImpact();
                      setState(() => _submitting = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final repo = ref.read(repositoryProvider);
                      final branchId = ref.read(selectedBranchIdProvider);
                      final bankVal = int.tryParse(_bankController.text.trim());

                      await repo.performReconciliation(
                        countedCashMinor: countedCashMinor,
                        bankBalanceMinor: bankVal != null ? bankVal * 100 : null,
                        expectedCashMinor: expectedCashMinor,
                        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                        createAdjustmentEntry: discrepancyMinor != 0,
                        branchId: branchId,
                      );

                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              discrepancyMinor != 0
                                  ? 'Reconciliation completed & adjustment entry created.'
                                  : 'Reconciliation completed with 0 discrepancy.',
                            ),
                          ),
                        );
                        _cashController.clear();
                        _bankController.clear();
                        _noteController.clear();
                        await _loadSummary();
                        setState(() => _submitting = false);
                      }
                    },
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      discrepancyMinor == 0 ? 'Save Reconciliation Record' : s.acceptAdjustment,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
            const SizedBox(height: GallaSpacing.xl),
          ],

          // ── Past History Section ───────────────────────────────────────
          GallaSectionHeader(
            title: 'Past Reconciliation History',
            topPadding: GallaSpacing.base,
            bottomPadding: GallaSpacing.sm,
          ),

          historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
            data: (history) {
              if (history.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(GallaSpacing.xl),
                  decoration: BoxDecoration(
                    color: GallaColors.surface,
                    borderRadius: BorderRadius.circular(GallaRadius.card),
                    border: Border.all(color: GallaColors.line),
                  ),
                  child: const Center(
                    child: Text(
                      'No previous reconciliations recorded yet.',
                      style: TextStyle(color: GallaColors.muted, fontSize: 13),
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (_, _) => const SizedBox(height: GallaSpacing.sm),
                itemBuilder: (context, idx) {
                  final rec = history[idx];
                  final isZero = rec.discrepancyMinor == 0;
                  return Container(
                    padding: const EdgeInsets.all(GallaSpacing.cardPadding),
                    decoration: BoxDecoration(
                      color: GallaColors.surface,
                      borderRadius: BorderRadius.circular(GallaRadius.card),
                      border: Border.all(color: GallaColors.line),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: isZero ? GallaColors.moneyInSoft : GallaColors.moneyOutSoft,
                            borderRadius: BorderRadius.circular(GallaRadius.md),
                          ),
                          child: Icon(
                            isZero ? Icons.check_circle_outline_rounded : Icons.tune_rounded,
                            color: isZero ? GallaColors.moneyIn : GallaColors.moneyOut,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: GallaSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat.yMMMd().add_jm().format(rec.occurredAt),
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: GallaColors.ink),
                              ),
                              if (rec.note != null && rec.note!.isNotEmpty)
                                Text(rec.note!, style: const TextStyle(fontSize: 12, color: GallaColors.muted)),
                              const SizedBox(height: 2),
                              Text(
                                'Counted: ${Money(rec.countedCashMinor, currency: currency).format()} (Expected: ${Money(rec.expectedCashMinor, currency: currency).format()})',
                                style: const TextStyle(fontSize: 11, color: GallaColors.muted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          isZero
                              ? '0 Diff'
                              : Money(rec.discrepancyMinor, currency: currency).format(),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: isZero ? GallaColors.moneyIn : GallaColors.moneyOut,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
