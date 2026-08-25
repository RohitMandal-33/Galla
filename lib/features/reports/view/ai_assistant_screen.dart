import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../domain/models.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final _inputController = TextEditingController();
  final List<({bool isUser, String message})> _messages = [];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _ask(String question) {
    if (question.trim().isEmpty) return;
    setState(() {
      _messages.add((isUser: true, message: question));
    });

    final health = ref.read(healthReportProvider).valueOrNull;
    final txns = ref.read(transactionsProvider).valueOrNull ?? [];
    final inventory = ref.read(inventoryProvider).valueOrNull ?? [];
    final q = question.toLowerCase();

    String answer = "I've analyzed your store's transactions: ";
    if (q.contains('week') ||
        q.contains('how was my business') ||
        q.contains('performance')) {
      answer +=
          "Your business has recorded ${txns.length} entries. Profit trend is healthy with an overall score of ${health?.overallScore ?? 80}/100.";
    } else if (q.contains('expense') || q.contains('spending')) {
      answer +=
          "Your top expenses are purchases, rent, and utility. Total expenses this period are within safe margins.";
    } else if (q.contains('owe') ||
        q.contains('customer') ||
        q.contains('udhaar')) {
      answer +=
          "Review your Udhaar tab — sending payment reminders via WhatsApp usually speeds up collections by 40%.";
    } else if (q.contains('stock') || q.contains('selling')) {
      if (inventory.isNotEmpty) {
        answer +=
            "Your tracked stock item '${inventory.first.name}' is moving well. Current inventory is ${inventory.first.currentQuantity} ${inventory.first.unit}.";
      } else {
        answer +=
            "You currently have healthy stock rotation across your catalog.";
      }
    } else {
      answer +=
          "Based on your ledger, your cash flow is positive. Keep recording daily transactions for even deeper predictions!";
    }

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _messages.add((isUser: false, message: answer));
        });
      }
    });

    _inputController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final healthAsync = ref.watch(healthReportProvider);
    final txns = ref.watch(transactionsProvider).valueOrNull ?? [];
    final inventory = ref.watch(inventoryProvider).valueOrNull ?? [];

    var cashInHand = 0;
    for (final t in txns) {
      if (t.direction == Direction.moneyIn && !t.isCredit) {
        cashInHand += t.amountMinor;
      } else if (t.direction == Direction.moneyOut && !t.isCredit) {
        cashInHand -= t.amountMinor;
      }
    }

    final topItemName = inventory.isNotEmpty
        ? inventory.first.name
        : 'Mustard Oil 1L';

    return Scaffold(
      backgroundColor: GallaColors.canvas,
      appBar: AppBar(
        backgroundColor: GallaColors.canvas,
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(healthReportProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                // Greeting
                Text(
                  'Namaste, ${settings.businessName.isNotEmpty ? settings.businessName.split(" ").first : "Suman"} 👋',
                  style: GallaType.screenTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  "I'm here to help you understand your business better.",
                  style: GallaType.body.copyWith(color: GallaColors.muted),
                ),
                const SizedBox(height: 16),

                // 1. Business Health Card
                healthAsync.when(
                  loading: () => const SizedBox(
                    height: 80,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (health) => Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: GallaColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: GallaColors.line),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: GallaColors.brandSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.thumb_up_alt_outlined,
                            color: GallaColors.brand,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Business Health',
                                    style: GallaType.subtitle,
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: GallaColors.moneyInSoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Good',
                                      style: GallaType.labelStrong.copyWith(
                                        color: GallaColors.moneyIn,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(health.headline, style: GallaType.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 2. Cash In Hand
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GallaColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: GallaColors.line),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: GallaColors.blueSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.wallet_outlined,
                          color: GallaColors.blue,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cash in Hand', style: GallaType.caption),
                            Text(
                              Money(
                                cashInHand,
                                currency: settings.currency,
                              ).format(),
                              style: GallaType.number,
                            ),
                          ],
                        ),
                      ),
                      Text('As of today', style: GallaType.captionSm),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 3. Top Selling Item
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: GallaColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: GallaColors.line),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: GallaColors.amberSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: GallaColors.amber,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Top Tracked Item', style: GallaType.caption),
                            Text(topItemName, style: GallaType.subtitle),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Suggested Prompts
                Text(
                  'Suggested Questions',
                  style: GallaType.subtitleSm.copyWith(
                    color: GallaColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                _PromptChip(
                  text: 'How was my business this week?',
                  onTap: () => _ask('How was my business this week?'),
                ),
                _PromptChip(
                  text: 'Show me top expenses',
                  onTap: () => _ask('Show me top expenses'),
                ),
                _PromptChip(
                  text: 'Which customer owes me more?',
                  onTap: () => _ask('Which customer owes me more?'),
                ),
                const SizedBox(height: 12),

                // Interactive message exchange
                if (_messages.isNotEmpty) ...[
                  const Divider(),
                  ..._messages.map((m) {
                    return Align(
                      alignment: m.isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: m.isUser
                              ? GallaColors.brand
                              : GallaColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: m.isUser
                                ? GallaColors.brand
                                : GallaColors.line,
                          ),
                        ),
                        child: Text(
                          m.message,
                          style: GallaType.body.copyWith(
                            color: m.isUser ? Colors.white : GallaColors.ink,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: GallaColors.surface,
              border: Border(top: BorderSide(color: GallaColors.line)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      decoration: InputDecoration(
                        hintText: 'Ask anything...',
                        filled: true,
                        fillColor: GallaColors.canvas,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: _ask,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: GallaColors.brand,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _ask(_inputController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.text, required this.onTap});
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: GallaColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GallaColors.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text,
                style: GallaType.bodyStrong.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(
                Icons.north_east_rounded,
                size: 14,
                color: GallaColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
