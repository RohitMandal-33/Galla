import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/l10n/strings.dart';
import '../../../core/money/money.dart';
import '../../../core/providers.dart';
import '../../../core/theme/galla_theme.dart';
import '../../../domain/models.dart';
import '../../../shared/widgets/transaction_tile.dart';
import '../../entry/view/entry_sheet.dart';

class CalendarLedgerScreen extends ConsumerStatefulWidget {
  const CalendarLedgerScreen({super.key});

  @override
  ConsumerState<CalendarLedgerScreen> createState() =>
      _CalendarLedgerScreenState();
}

class _CalendarLedgerScreenState extends ConsumerState<CalendarLedgerScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? const AppSettings();
    final s = S(settings.locale);
    final currency = settings.currency;
    final allTxns =
        ref.watch(transactionsProvider).valueOrNull ?? const <Txn>[];

    // Filter txns for selected day
    final dayTxns = allTxns.where((t) {
      return t.occurredAt.year == _selectedDate.year &&
          t.occurredAt.month == _selectedDate.month &&
          t.occurredAt.day == _selectedDate.day;
    }).toList();

    var dayIncomeMinor = 0;
    var dayExpenseMinor = 0;
    for (final t in dayTxns) {
      if (t.direction == Direction.moneyIn && !t.isCredit) {
        dayIncomeMinor += t.amountMinor;
      } else if (t.direction == Direction.moneyOut && !t.isCredit) {
        dayExpenseMinor += t.amountMinor;
      }
    }
    final dayNetMinor = dayIncomeMinor - dayExpenseMinor;

    return Scaffold(
      backgroundColor: GallaColors.canvas,
      body: CustomScrollView(
        slivers: [
          // Month Header & Days Carousel
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              color: GallaColors.surface,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded),
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime(
                              _selectedDate.year,
                              _selectedDate.month - 1,
                              1,
                            );
                          });
                        },
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedDate),
                        style: GallaType.cardTitle,
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded),
                        onPressed: () {
                          setState(() {
                            _selectedDate = DateTime(
                              _selectedDate.year,
                              _selectedDate.month + 1,
                              1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Horizontal Week/Day Selector
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 14,
                      itemBuilder: (context, index) {
                        final date = DateTime.now().subtract(
                          Duration(days: 7 - index),
                        );
                        final isSelected = DateUtils.isSameDay(
                          date,
                          _selectedDate,
                        );
                        final isToday = DateUtils.isSameDay(
                          date,
                          DateTime.now(),
                        );

                        return GestureDetector(
                          onTap: () => setState(() => _selectedDate = date),
                          child: Container(
                            width: 48,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? GallaColors.brand
                                  : (isToday
                                        ? GallaColors.brandSoft
                                        : Colors.transparent),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? GallaColors.brand
                                    : GallaColors.line,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat(
                                    'E',
                                  ).format(date).substring(0, 3).toUpperCase(),
                                  style: GallaType.labelSm.copyWith(
                                    fontSize: 10,
                                    color: isSelected
                                        ? Colors.white70
                                        : GallaColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date.day.toString(),
                                  style: GallaType.number.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : GallaColors.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Day Summary Cards
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GallaColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: GallaColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate),
                    style: GallaType.subtitle,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatMini(
                          label: 'Income',
                          value: Money(
                            dayIncomeMinor,
                            currency: currency,
                          ).format(),
                          color: GallaColors.moneyIn,
                        ),
                      ),
                      Expanded(
                        child: _StatMini(
                          label: 'Expense',
                          value: Money(
                            dayExpenseMinor,
                            currency: currency,
                          ).format(),
                          color: GallaColors.moneyOut,
                        ),
                      ),
                      Expanded(
                        child: _StatMini(
                          label: 'Net',
                          value: Money(
                            dayNetMinor,
                            currency: currency,
                          ).format(),
                          color: dayNetMinor >= 0
                              ? GallaColors.brand
                              : GallaColors.moneyOut,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Timeline Transactions
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: dayTxns.isEmpty
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'No transactions on this day.',
                          style: TextStyle(color: GallaColors.muted),
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final txn = dayTxns[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TransactionTile(
                          txn: txn,
                          currency: currency,
                          s: s,
                        ),
                      );
                    }, childCount: dayTxns.length),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: GallaColors.brand,
        foregroundColor: Colors.white,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const EntrySheet(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Entry'),
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GallaType.captionSm),
        const SizedBox(height: 2),
        Text(value, style: GallaType.subtitleSm.copyWith(color: color)),
      ],
    );
  }
}
