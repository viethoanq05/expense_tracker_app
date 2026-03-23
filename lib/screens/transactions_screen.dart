import 'package:expense_tracker_app/models/transaction_record.dart';
import 'package:expense_tracker_app/services/repository_registry.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../localization/app_strings.dart';
import '../widgets/app_preferences_scope.dart';
import 'transaction_detail_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key, this.refreshNotifier});

  final ValueNotifier<int>? refreshNotifier;

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _selectedMonth;

  bool _isLoading = true;
  String? _loadError;
  List<TransactionRecord> _allTransactions = const [];

  // Generate a list of months (e.g., past 12 months)
  late List<DateTime> _availableMonths;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);

    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);

    _availableMonths = List.generate(12, (index) {
      return DateTime(now.year, now.month - index, 1);
    });

    widget.refreshNotifier?.addListener(_refresh);
    _loadTransactions();
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_refresh);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final transactions = await RepositoryRegistry.expenseRepository
          .getTransactions();

      if (!mounted) return;

      setState(() {
        _allTransactions = transactions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  void _refresh() {
    _loadTransactions();
  }

  List<TransactionRecord> get _filteredTransactions {
    final activeTabIsIncome = _tabController.index == 0;
    return _allTransactions.where((tx) {
      final isSameMonth =
          tx.date.year == _selectedMonth.year &&
          tx.date.month == _selectedMonth.month;
      final typeMatches =
          (activeTabIsIncome && tx.type == TransactionType.income) ||
          (!activeTabIsIncome && tx.type == TransactionType.expense);
      return isSameMonth && typeMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.transactionsLabel),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: strings.transactionsTabIncome),
            Tab(text: strings.transactionsTabExpense),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _loadError != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          strings.cannotLoadTransactions,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(_loadError!),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _refresh,
                          icon: const Icon(Icons.refresh),
                          label: Text(strings.retryLabel),
                        ),
                      ],
                    ),
                  )
                : _buildTransactionList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse:
            true, // Show most recent on the right/left depending on preference. Wait, let's keep normal order, recent on left
        itemCount: _availableMonths.length,
        itemBuilder: (context, index) {
          final month = _availableMonths[index];
          final isSelected = month == _selectedMonth;

          final strings = AppStrings.of(context);
          final monthLabel =
              '${strings.getMonthName(month.month)} ${month.year}';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: ChoiceChip(
              label: Text(monthLabel),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedMonth = month);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionList() {
    final items = _filteredTransactions;

    if (items.isEmpty) {
      final strings = AppStrings.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              strings.noTransactionsFound,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 88,
      ), // Extra bottom padding for FAB
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        return TransactionListTile(
          tx: items[index],
          onTap: () {
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => TransactionDetailSheet(
                transactionId: items[index].id,
                onDataChanged: () {
                  _refresh();
                  widget.refreshNotifier?.value++;
                },
              ),
            );
          },
        );
      },
    );
  }

  static String _translateCategory(String category, BuildContext context) {
    if (AppStrings.of(context).language == AppLanguage.vi) {
      return switch (category) {
        'Food' => 'Ăn uống',
        'Housing' => 'Nhà cửa',
        'Shopping' => 'Mua sắm',
        'Transport' => 'Di chuyển',
        _ => category,
      };
    }
    return category;
  }
}

class TransactionListTile extends StatelessWidget {
  const TransactionListTile({super.key, required this.tx, this.onTap});

  final TransactionRecord tx;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    final amountColor = isIncome
        ? const Color(0xFF047857)
        : const Color(0xFFB91C1C);

    final strings = AppStrings.of(context);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isIncome
            ? const Color(0xFFD1FAE5)
            : const Color(0xFFFFE4E6),
        child: Icon(
          isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          color: amountColor,
        ),
      ),
      title: Text(tx.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${_TransactionsScreenState._translateCategory(tx.category, context)} · ${_dateLabel(tx.date, strings)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 108),
        child: Text(
          '${isIncome ? '+' : '-'} ${_currency(tx.amount, strings)}',
          textAlign: TextAlign.end,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: amountColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _currency(double amount, AppStrings strings) {
    final value = amount.abs();
    if (value >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M${strings.currencySuffix}';
    }
    if (value >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K${strings.currencySuffix}';
    }
    return '${amount.toStringAsFixed(0)}${strings.currencySuffix}';
  }

  String _dateLabel(DateTime date, AppStrings strings) {
    final now = DateTime.now();
    final onlyDate = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final delta = today.difference(onlyDate).inDays;

    if (delta == 0) return strings.today;
    if (delta == 1) return strings.yesterday;
    return '${date.day}/${date.month}/${date.year}';
  }
}
