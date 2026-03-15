import 'dart:math' as math;

import 'package:expense_tracker_app/models/expense_filter.dart';
import 'package:expense_tracker_app/models/transaction_record.dart';
import 'package:expense_tracker_app/services/repository_registry.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const double _tabletBreakpoint = 760;
  static const double _desktopBreakpoint = 1100;

  bool _isLoading = true;
  String? _loadError;
  List<TransactionRecord> _allTransactions = const [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      await RepositoryRegistry.seedDemoDataIfNeeded();
      final transactions = await RepositoryRegistry.expenseRepository
          .getTransactions();

      if (!mounted) {
        return;
      }

      setState(() {
        _allTransactions = transactions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthlyTransactions = _transactionsInMonth(now, _allTransactions);
    final monthlyIncome = _sumByType(
      monthlyTransactions,
      TransactionType.income,
    );
    final monthlyExpense = _sumByType(
      monthlyTransactions,
      TransactionType.expense,
    );
    final monthlyBalance = monthlyIncome - monthlyExpense;
    final recentTransactions = _latestTransactions(_allTransactions);
    final availableCategories = _availableCategories(_allTransactions);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isTablet = width >= _tabletBreakpoint;
          final isDesktop = width >= _desktopBreakpoint;
          final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);
          final maxContentWidth = isDesktop ? 1180.0 : 900.0;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  24,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxContentWidth),
                      child: Column(
                        children: [
                          _Header(
                            monthLabel: _monthLabel(now),
                            onOpenSearch: () =>
                                _openSearchPage(availableCategories),
                            compact: !isTablet,
                          ),
                          const SizedBox(height: 16),
                          if (_isLoading) ...[
                            const _LoadingCard(),
                            const SizedBox(height: 16),
                          ] else if (_loadError != null) ...[
                            _ErrorCard(
                              error: _loadError!,
                              onRetry: _loadTransactions,
                            ),
                            const SizedBox(height: 16),
                          ],
                          isDesktop
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: _SummaryPanel(
                                        monthlyBalance: monthlyBalance,
                                        monthlyExpense: monthlyExpense,
                                        monthlyIncome: monthlyIncome,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    Expanded(
                                      flex: 4,
                                      child: _MonthlyReportCard(
                                        monthlyTransactions:
                                            monthlyTransactions,
                                        monthlyExpense: monthlyExpense,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _SummaryPanel(
                                      monthlyBalance: monthlyBalance,
                                      monthlyExpense: monthlyExpense,
                                      monthlyIncome: monthlyIncome,
                                    ),
                                    const SizedBox(height: 12),
                                    _MonthlyReportCard(
                                      monthlyTransactions: monthlyTransactions,
                                      monthlyExpense: monthlyExpense,
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 18),
                          _RecentTransactionsCard(
                            transactions: recentTransactions,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<TransactionRecord> _transactionsInMonth(
    DateTime now,
    List<TransactionRecord> source,
  ) {
    return source
        .where((tx) => tx.date.year == now.year && tx.date.month == now.month)
        .toList(growable: false);
  }

  List<TransactionRecord> _latestTransactions(List<TransactionRecord> source) {
    final sorted = [...source]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(5).toList(growable: false);
  }

  List<String> _availableCategories(List<TransactionRecord> source) {
    final categories = source.map((tx) => tx.category).toSet().toList()..sort();
    return [ExpenseFilter.allCategories, ...categories];
  }

  Future<void> _openSearchPage(List<String> categories) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _DashboardSearchPage(
          initialFilter: const ExpenseFilter(),
          categories: categories,
          allCategoriesLabel: ExpenseFilter.allCategories,
          sourceTransactions: _allTransactions,
        ),
      ),
    );
  }

  double _sumByType(
    List<TransactionRecord> transactions,
    TransactionType type,
  ) {
    return transactions
        .where((tx) => tx.type == type)
        .fold(0, (value, tx) => value + tx.amount);
  }

  String _monthLabel(DateTime date) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${monthNames[date.month - 1]} ${date.year}';
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.monthLabel,
    required this.onOpenSearch,
    required this.compact,
  });

  final String monthLabel;
  final VoidCallback onOpenSearch;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TH5 - Nhom 12',
                style:
                    (compact ? textTheme.titleLarge : textTheme.headlineSmall)
                        ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                monthLabel,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onOpenSearch,
          tooltip: 'Search and filter',
          icon: const Icon(Icons.search_rounded),
        ),
        CircleAvatar(
          radius: 21,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.person_outline,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

class _DashboardSearchPage extends StatefulWidget {
  const _DashboardSearchPage({
    required this.initialFilter,
    required this.categories,
    required this.allCategoriesLabel,
    required this.sourceTransactions,
  });

  final ExpenseFilter initialFilter;
  final List<String> categories;
  final String allCategoriesLabel;
  final List<TransactionRecord> sourceTransactions;

  @override
  State<_DashboardSearchPage> createState() => _DashboardSearchPageState();
}

class _DashboardSearchPageState extends State<_DashboardSearchPage> {
  late final TextEditingController _controller;
  late TimeFilter _timeFilter;
  late AmountFilter _amountFilter;
  late String _category;
  String _query = '';
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialFilter.keyword);
    _query = widget.initialFilter.keyword;
    _timeFilter = widget.initialFilter.timeFilter;
    _amountFilter = widget.initialFilter.amountFilter;
    _category = widget.initialFilter.category;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = _applyFilter(
      widget.sourceTransactions,
      ExpenseFilter(
        keyword: _query,
        timeFilter: _timeFilter,
        amountFilter: _amountFilter,
        category: _category,
      ),
      DateTime.now(),
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _closePage();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: _closePage,
            icon: const Icon(Icons.arrow_back_rounded),
            tooltip: 'Back',
          ),
          title: SizedBox(
            height: 44,
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (value) => setState(() => _query = value.trim()),
              decoration: InputDecoration(
                hintText: 'Search by content, note, category...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: _openFilterSheet,
              tooltip: 'Open filters',
              icon: const Icon(Icons.tune_rounded),
            ),
            IconButton(
              onPressed: _reset,
              tooltip: 'Reset filters',
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterInfoChip(
                        label: _amountLabel(_amountFilter).$1,
                        value: _amountLabel(_amountFilter).$2,
                      ),
                      _FilterInfoChip(
                        label: 'Time',
                        value: _timeLabel(_timeFilter),
                      ),
                      _FilterInfoChip(label: 'Category', value: _category),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Matched transactions: ${preview.length}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (preview.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No transactions found with current filters.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                        child: Column(
                          children: preview
                              .map((tx) => _TransactionTile(tx: tx))
                              .toList(growable: false),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _reset() {
    _controller.clear();
    setState(() {
      _query = '';
      _timeFilter = TimeFilter.all;
      _amountFilter = AmountFilter.all;
      _category = widget.allCategoriesLabel;
    });
  }

  void _closePage() {
    if (_isClosing) {
      return;
    }
    _isClosing = true;
    Navigator.of(context).pop();
  }

  Future<void> _openFilterSheet() async {
    var localTimeFilter = _timeFilter;
    var localAmountFilter = _amountFilter;
    var localCategory = _category;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                16 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter criteria',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AmountFilter>(
                    initialValue: localAmountFilter,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setSheetState(() => localAmountFilter = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: AmountFilter.all,
                        child: Text('All amounts'),
                      ),
                      DropdownMenuItem(
                        value: AmountFilter.under200k,
                        child: Text('Under 200K VND'),
                      ),
                      DropdownMenuItem(
                        value: AmountFilter.from200kTo1m,
                        child: Text('200K - 1M VND'),
                      ),
                      DropdownMenuItem(
                        value: AmountFilter.over1m,
                        child: Text('Over 1M VND'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TimeFilter>(
                    initialValue: localTimeFilter,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setSheetState(() => localTimeFilter = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Time',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TimeFilter.all,
                        child: Text('All time'),
                      ),
                      DropdownMenuItem(
                        value: TimeFilter.last7Days,
                        child: Text('Last 7 days'),
                      ),
                      DropdownMenuItem(
                        value: TimeFilter.last30Days,
                        child: Text('Last 30 days'),
                      ),
                      DropdownMenuItem(
                        value: TimeFilter.thisMonth,
                        child: Text('This month'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: localCategory,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setSheetState(() => localCategory = value);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: widget.categories
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheetState(() {
                              localTimeFilter = TimeFilter.all;
                              localAmountFilter = AmountFilter.all;
                              localCategory = widget.allCategoriesLabel;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              _timeFilter = localTimeFilter;
                              _amountFilter = localAmountFilter;
                              _category = localCategory;
                            });
                            Navigator.of(context).pop();
                          },
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _timeLabel(TimeFilter filter) {
    return switch (filter) {
      TimeFilter.all => 'All time',
      TimeFilter.last7Days => 'Last 7 days',
      TimeFilter.last30Days => 'Last 30 days',
      TimeFilter.thisMonth => 'This month',
      TimeFilter.custom => 'Custom range',
    };
  }

  (String, String) _amountLabel(AmountFilter filter) {
    return switch (filter) {
      AmountFilter.all => ('Amount', 'All amounts'),
      AmountFilter.under200k => ('Amount', 'Under 200K'),
      AmountFilter.from200kTo1m => ('Amount', '200K - 1M'),
      AmountFilter.over1m => ('Amount', 'Over 1M'),
    };
  }
}

List<TransactionRecord> _applyFilter(
  List<TransactionRecord> source,
  ExpenseFilter filter,
  DateTime now,
) {
  final sorted = [...source]..sort((a, b) => b.date.compareTo(a.date));
  return sorted.where((tx) => filter.matches(tx, now)).toList(growable: false);
}

class _FilterInfoChip extends StatelessWidget {
  const _FilterInfoChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading transactions from Firestore...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cannot load Firestore data.',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({
    required this.monthlyBalance,
    required this.monthlyExpense,
    required this.monthlyIncome,
  });

  final double monthlyBalance;
  final double monthlyExpense;
  final double monthlyIncome;

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 360;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF6FA593), Color(0xFF85B9A4)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Balance',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _currency(monthlyBalance),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            if (isCompact) ...[
              _smallMetric(
                'Total Income',
                _currency(monthlyIncome),
                const Color(0xFFDCFCE7),
                const Color(0xFF14532D),
              ),
              const SizedBox(height: 10),
              _smallMetric(
                'Total Expense',
                _currency(monthlyExpense),
                const Color(0xFFFFE4E6),
                const Color(0xFF881337),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: _smallMetric(
                      'Total Income',
                      _currency(monthlyIncome),
                      const Color(0xFFDCFCE7),
                      const Color(0xFF14532D),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _smallMetric(
                      'Total Expense',
                      _currency(monthlyExpense),
                      const Color(0xFFFFE4E6),
                      const Color(0xFF881337),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _smallMetric(String label, String value, Color bg, Color fg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyReportCard extends StatelessWidget {
  const _MonthlyReportCard({
    required this.monthlyTransactions,
    required this.monthlyExpense,
  });

  final List<TransactionRecord> monthlyTransactions;
  final double monthlyExpense;

  @override
  Widget build(BuildContext context) {
    final expenseByCategory = <String, double>{};
    for (final tx in monthlyTransactions) {
      if (tx.type == TransactionType.expense) {
        expenseByCategory.update(
          tx.category,
          (value) => value + tx.amount,
          ifAbsent: () => tx.amount,
        );
      }
    }

    final entries = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEntries = entries.take(4).toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This month report',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Expense distribution by category',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            if (topEntries.isEmpty)
              Text(
                'No expenses this month yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              ...topEntries.map((entry) {
                final ratio = monthlyExpense > 0
                    ? entry.value / monthlyExpense
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              entry.key,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '${(ratio * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: math.min(ratio, 1),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard({required this.transactions});

  final List<TransactionRecord> transactions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Transactions',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              'Showing latest 5 records',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            if (transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 18, 0, 22),
                child: Center(
                  child: Text(
                    'No transaction data available.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...transactions.map((tx) => _TransactionTile(tx: tx)),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});

  final TransactionRecord tx;

  @override
  Widget build(BuildContext context) {
    final isIncome = tx.type == TransactionType.income;
    final amountColor = isIncome
        ? const Color(0xFF047857)
        : const Color(0xFFB91C1C);

    return ListTile(
      contentPadding: EdgeInsets.zero,
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
        '${tx.category} · ${_dateLabel(tx.date)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 108),
        child: Text(
          '${isIncome ? '+' : '-'} ${_currency(tx.amount)}',
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
}

String _currency(double amount) {
  final value = amount.abs();
  if (value >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(2)}M VND';
  }
  if (value >= 1000) {
    return '${(amount / 1000).toStringAsFixed(0)}K VND';
  }
  return '${amount.toStringAsFixed(0)} VND';
}

String _dateLabel(DateTime date) {
  final now = DateTime.now();
  final onlyDate = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  final delta = today.difference(onlyDate).inDays;

  if (delta == 0) {
    return 'Today';
  }
  if (delta == 1) {
    return 'Yesterday';
  }
  return '${date.day}/${date.month}/${date.year}';
}
