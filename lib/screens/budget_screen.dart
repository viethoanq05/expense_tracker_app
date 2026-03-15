import 'package:expense_tracker_app/localization/app_strings.dart';
import 'package:expense_tracker_app/models/transaction_record.dart';
import 'package:expense_tracker_app/services/repository_registry.dart';
import 'package:expense_tracker_app/widgets/app_preferences_scope.dart';
import 'package:flutter/material.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key, this.onSaved});

  final ValueChanged<int>? onSaved;

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  bool _isLoading = true;
  String? _error;
  List<TransactionRecord> _transactions = const [];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await RepositoryRegistry.seedDemoDataIfNeeded();
      final transactions = await RepositoryRegistry.expenseRepository
          .getTransactions();

      if (!mounted) {
        return;
      }

      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final preferences = AppPreferencesScope.of(context);
    final expenses = _monthlyExpenses(_transactions);
    final categories = expenses.keys.toList()..sort();

    for (final category in categories) {
      _controllers.putIfAbsent(
        category,
        () => TextEditingController(
          text: _initialBudgetText(preferences.budgetFor(category)),
        ),
      );
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            strings.budgetScreenTitle,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            strings.budgetScreenDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_error != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_error!),
              ),
            )
          else if (categories.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(strings.noExpenseCategories),
              ),
            )
          else ...[
            ...categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BudgetCategoryCard(
                  category: category,
                  spent: expenses[category] ?? 0,
                  limit: preferences.budgetFor(category),
                  controller: _controllers[category]!,
                  strings: strings,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => _saveBudgets(categories),
              icon: const Icon(Icons.save_rounded),
              label: Text(strings.saveBudgets),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _saveBudgets(List<String> categories) async {
    final preferences = AppPreferencesScope.of(context);
    final budgets = <String, double?>{};
    final expenses = _monthlyExpenses(_transactions);

    for (final category in categories) {
      final value = _controllers[category]!.text.trim();
      if (value.isEmpty) {
        budgets[category] = null;
        continue;
      }

      budgets[category] = double.tryParse(value.replaceAll(',', ''));
    }

    await preferences.setBudgets(budgets);
    if (!mounted) {
      return;
    }

    var exceededCount = 0;
    for (final category in categories) {
      final limit = budgets[category];
      if (limit == null || limit <= 0) {
        continue;
      }
      final spent = expenses[category] ?? 0;
      if (spent > limit) {
        exceededCount++;
      }
    }

    widget.onSaved?.call(exceededCount);
  }

  Map<String, double> _monthlyExpenses(List<TransactionRecord> transactions) {
    final now = DateTime.now();
    final values = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type != TransactionType.expense) {
        continue;
      }
      if (transaction.date.year != now.year ||
          transaction.date.month != now.month) {
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

  String _initialBudgetText(double? value) {
    if (value == null || value <= 0) {
      return '';
    }
    return value.toStringAsFixed(0);
  }
}

class _BudgetCategoryCard extends StatelessWidget {
  const _BudgetCategoryCard({
    required this.category,
    required this.spent,
    required this.limit,
    required this.controller,
    required this.strings,
  });

  final String category;
  final double spent;
  final double? limit;
  final TextEditingController controller;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final isOverLimit = limit != null && limit! > 0 && spent > limit!;
    final ratio = limit == null || limit == 0
        ? 0.0
        : (spent / limit!).clamp(0.0, 1.0).toDouble();
    final color = isOverLimit
        ? const Color(0xFFB91C1C)
        : Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    category,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    isOverLimit
                        ? strings.overBudgetChip
                        : strings.withinBudgetChip,
                  ),
                  backgroundColor: isOverLimit
                      ? const Color(0xFFFFE4E6)
                      : Theme.of(context).colorScheme.primaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${strings.spentThisMonth}: ${_currency(spent)}'),
            const SizedBox(height: 4),
            Text(
              '${strings.limitAmount}: ${limit == null ? strings.noLimitLabel : _currency(limit!)}',
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: ratio,
                color: color,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: strings.limitAmount,
                hintText: '2000000',
                prefixIcon: const Icon(Icons.flag_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _currency(double amount) {
  if (amount >= 1000000) {
    return '${(amount / 1000000).toStringAsFixed(2)}M VND';
  }
  if (amount >= 1000) {
    return '${(amount / 1000).toStringAsFixed(0)}K VND';
  }
  return '${amount.toStringAsFixed(0)} VND';
}
