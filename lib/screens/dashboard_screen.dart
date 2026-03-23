import 'dart:math' as math;

import 'package:expense_tracker_app/controllers/app_preferences_controller.dart';
import 'package:expense_tracker_app/localization/app_strings.dart';
import 'package:expense_tracker_app/models/expense_filter.dart';
import 'package:expense_tracker_app/models/transaction_record.dart';
import 'package:expense_tracker_app/screens/transaction_detail_sheet.dart';
import 'package:expense_tracker_app/services/repository_registry.dart';
import 'package:flutter/foundation.dart';
import 'package:expense_tracker_app/widgets/app_preferences_scope.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.refreshNotifier});

  final ValueNotifier<int>? refreshNotifier;

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
    widget.refreshNotifier?.addListener(_loadTransactions);
    _loadTransactions();
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_loadTransactions);
    super.dispose();
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
    final preferences = AppPreferencesScope.of(context);
    final strings = AppStrings.of(context);
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
    final availableCategories = _availableCategories(_allTransactions, strings);
    final exceededBudgets = _exceededBudgets(
      transactions: monthlyTransactions,
      preferences: preferences,
    );

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
                            monthLabel: _monthLabel(now, strings),
                            onOpenSearch: () =>
                                _openSearchPage(availableCategories, strings),
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
                          if (exceededBudgets.isNotEmpty) ...[
                            _BudgetAlertCard(
                              exceededBudgets: exceededBudgets,
                              strings: strings,
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
                            onDataChanged: () {
                              _loadTransactions();
                              widget.refreshNotifier?.value++;
                            },
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

  List<String> _availableCategories(List<TransactionRecord> source, AppStrings strings) {
    final categories = source.map((tx) => tx.category).toSet().toList()..sort();
    return [strings.allCategories, ...categories];
  }

  Future<void> _openSearchPage(List<String> categories, AppStrings strings) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _DashboardSearchPage(
          initialFilter: ExpenseFilter(category: strings.allCategories),
          categories: categories,
          allCategoriesLabel: strings.allCategories,
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

  String _monthLabel(DateTime date, AppStrings strings) {
    return '${strings.getMonthName(date.month)} ${date.year}';
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
    final strings = AppStrings.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.appTitle,
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
          tooltip: strings.searchAndFilterTooltip,
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
    final strings = AppStrings.of(context);
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
                hintText: strings.searchHint,
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
              tooltip: strings.openFiltersTooltip,
              icon: const Icon(Icons.tune_rounded),
            ),
            IconButton(
              onPressed: _reset,
              tooltip: strings.resetFiltersTooltip,
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
                        label: strings.amountLabel,
                        value: strings.getAmountFilterLabel(_amountFilter),
                      ),
                      _FilterInfoChip(
                        label: strings.timeLabel,
                        value: strings.getTimeFilterLabel(_timeFilter),
                      ),
                      _FilterInfoChip(label: strings.categoryLabel, value: _category),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    strings.matchedTransactions(preview.length),
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
                          strings.noTransactionsForFilter,
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
                              .map((tx) => _TransactionTile(
                                    tx: tx,
                                    onDataChanged: () {
                                      // Optional: Could trigger search refresh + global refresh
                                    },
                                  ))
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
    final strings = AppStrings.of(context);
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
                    strings.filterCriteria,
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
                    items: [
                      DropdownMenuItem(
                        value: AmountFilter.all,
                        child: Text(strings.getAmountFilterLabel(AmountFilter.all)),
                      ),
                      DropdownMenuItem(
                        value: AmountFilter.under200k,
                        child: Text(strings.getAmountFilterLabel(AmountFilter.under200k)),
                      ),
                      DropdownMenuItem(
                        value: AmountFilter.from200kTo1m,
                        child: Text(strings.getAmountFilterLabel(AmountFilter.from200kTo1m)),
                      ),
                      DropdownMenuItem(
                        value: AmountFilter.over1m,
                        child: Text(strings.getAmountFilterLabel(AmountFilter.over1m)),
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
                    items: [
                      DropdownMenuItem(
                        value: TimeFilter.all,
                        child: Text(strings.getTimeFilterLabel(TimeFilter.all)),
                      ),
                      DropdownMenuItem(
                        value: TimeFilter.last7Days,
                        child: Text(strings.getTimeFilterLabel(TimeFilter.last7Days)),
                      ),
                      DropdownMenuItem(
                        value: TimeFilter.last30Days,
                        child: Text(strings.getTimeFilterLabel(TimeFilter.last30Days)),
                      ),
                      DropdownMenuItem(
                        value: TimeFilter.thisMonth,
                        child: Text(strings.getTimeFilterLabel(TimeFilter.thisMonth)),
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
                          child: Text(strings.resetLabel),
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
                          child: Text(strings.doneLabel),
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

  String _timeLabel(TimeFilter filter, AppStrings strings) {
    return strings.getTimeFilterLabel(filter);
  }

  String _amountLabel(AmountFilter filter, AppStrings strings) {
    return strings.getAmountFilterLabel(filter);
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
    final strings = AppStrings.of(context);

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
                strings.loadingTransactions,
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
    final strings = AppStrings.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.cannotLoadTransactions,
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
              label: Text(strings.retryLabel),
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
    final strings = AppStrings.of(context);
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
              strings.monthlyBalance,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _currency(monthlyBalance, strings),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            if (isCompact) ...[
              _smallMetric(
                strings.totalIncome,
                _currency(monthlyIncome, strings),
                const Color(0xFFDCFCE7),
                const Color(0xFF14532D),
              ),
              const SizedBox(height: 10),
              _smallMetric(
                strings.totalExpense,
                _currency(monthlyExpense, strings),
                const Color(0xFFFFE4E6),
                const Color(0xFF881337),
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: _smallMetric(
                      strings.totalIncome,
                      _currency(monthlyIncome, strings),
                      const Color(0xFFDCFCE7),
                      const Color(0xFF14532D),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _smallMetric(
                      strings.totalExpense,
                      _currency(monthlyExpense, strings),
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
    final strings = AppStrings.of(context);
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
              strings.thisMonthReport,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              strings.expenseDistributionByCategory,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            if (topEntries.isEmpty)
              Text(
                strings.noExpensesThisMonth,
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
                              _translateCategory(entry.key, strings),
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
  const _RecentTransactionsCard({required this.transactions, this.onDataChanged});

  final List<TransactionRecord> transactions;
  final VoidCallback? onDataChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.recentTransactions,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              strings.showingLatestRecords,
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
                    strings.noTransactionData,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              )
            else
              ...transactions.map((tx) => _TransactionTile(
                    tx: tx,
                    onDataChanged: onDataChanged,
                  )),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx, this.onDataChanged});

  final TransactionRecord tx;
  final VoidCallback? onDataChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final isIncome = tx.type == TransactionType.income;
    final amountColor = isIncome
        ? const Color(0xFF047857)
        : const Color(0xFFB91C1C);

    return ListTile(
      onTap: () {
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => TransactionDetailSheet(
            transactionId: tx.id,
            onDataChanged: () {
              if (onDataChanged != null) {
                onDataChanged!();
              }
            },
          ),
        );
      },
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
        '${_translateCategory(tx.category, strings)} · ${_dateLabel(tx.date, strings)}',
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

  if (delta == 0) {
    return strings.today;
  }
  if (delta == 1) {
    return strings.yesterday;
  }
  return '${date.day}/${date.month}/${date.year}';
}

String _translateCategory(String category, AppStrings strings) {
  if (strings.language == AppLanguage.vi) {
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

Map<String, double> _categoryExpenses(List<TransactionRecord> transactions) {
  final values = <String, double>{};

  for (final transaction in transactions) {
    if (transaction.type != TransactionType.expense) {
      continue;
    }

    values.update(
      transaction.category,
      (value) => value + transaction.amount,
      ifAbsent: () => transaction.amount,
    );
  }

  return values;
}

List<_ExceededBudget> _exceededBudgets({
  required List<TransactionRecord> transactions,
  required AppPreferencesController preferences,
}) {
  final expenses = _categoryExpenses(transactions);
  final exceeded = <_ExceededBudget>[];

  for (final entry in expenses.entries) {
    final limit = preferences.budgetFor(entry.key);
    if (limit == null || limit <= 0 || entry.value <= limit) {
      continue;
    }

    exceeded.add(
      _ExceededBudget(category: entry.key, spent: entry.value, limit: limit),
    );
  }

  exceeded.sort((a, b) => (b.spent - b.limit).compareTo(a.spent - a.limit));
  return exceeded;
}

class _ExceededBudget {
  const _ExceededBudget({
    required this.category,
    required this.spent,
    required this.limit,
  });

  final String category;
  final double spent;
  final double limit;
}

class _BudgetAlertCard extends StatelessWidget {
  const _BudgetAlertCard({
    required this.exceededBudgets,
    required this.strings,
  });

  final List<_ExceededBudget> exceededBudgets;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFE5E5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.overBudgetTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF8B1E1E),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              strings.overBudgetDescription(exceededBudgets.length),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF8B1E1E)),
            ),
            const SizedBox(height: 12),
            ...exceededBudgets
                .take(3)
                .map(
                  (budget) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${_translateCategory(budget.category, strings)}: ${_currency(budget.spent, strings)} / ${_currency(budget.limit, strings)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF8B1E1E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
