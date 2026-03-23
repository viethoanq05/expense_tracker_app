import 'package:expense_tracker_app/models/transaction_record.dart';
import 'package:expense_tracker_app/services/repository_registry.dart';
import 'package:flutter/material.dart';
import '../localization/app_strings.dart';

import 'edit_transaction_screen.dart';

class TransactionDetailSheet extends StatefulWidget {
  const TransactionDetailSheet({
    super.key,
    required this.transactionId,
    required this.onDataChanged,
  });

  final String transactionId;
  final VoidCallback onDataChanged;

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
  bool _isLoading = true;
  TransactionRecord? _transaction;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final transactions = await RepositoryRegistry.expenseRepository
          .getTransactions();
      final target = transactions.firstWhere(
        (tx) => tx.id == widget.transactionId,
      );

      if (!mounted) return;
      setState(() {
        _transaction = target;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final strings = AppStrings.of(context);
      setState(() {
        _error = '${strings.couldNotLoadDetails}: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _delete() async {
    final strings = AppStrings.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.deleteTransactionQuestion),
        content: Text(strings.deleteUndoneWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(strings.pinCancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(strings.deleteLabel),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await RepositoryRegistry.expenseRepository.deleteTransaction(
        widget.transactionId,
      );
      widget.onDataChanged();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final strings = AppStrings.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${strings.failedToDelete}: $e')));
    }
  }

  Future<void> _edit() async {
    if (_transaction == null) return;

    final didUpdate = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditTransactionScreen(transaction: _transaction!),
      ),
    );

    if (didUpdate == true) {
      widget.onDataChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    if (_isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _transaction == null) {
      return SizedBox(
        height: 200,
        child: Center(child: Text(_error ?? strings.transactionNotFound)),
      );
    }

    final tx = _transaction!;
    final isIncome = tx.type == TransactionType.income;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildHeader(tx, isIncome, strings),
          const Divider(height: 32),
          _buildDetailRow(
            context,
            strings.categoryLabel,
            _translateCategory(tx.category, context),
            Icons.category_rounded,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            strings.exportColumnDate,
            _formatDate(tx.date),
            Icons.calendar_today_rounded,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            context,
            'Time',
            _formatTime(tx.date),
            Icons.access_time_rounded,
          ),
          if (tx.note != null && tx.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow(context, strings.exportColumnNote, tx.note!, Icons.notes_rounded),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(strings.deleteLabel),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _edit,
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(strings.editLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    TransactionRecord tx,
    bool isIncome,
    AppStrings strings,
  ) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: isIncome
              ? const Color(0xFFD1FAE5)
              : const Color(0xFFFFE4E6),
          child: Icon(
            isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
            size: 32,
            color: isIncome ? const Color(0xFF047857) : const Color(0xFFB91C1C),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          tx.title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${isIncome ? '+' : '-'} ${_currency(tx.amount, strings)}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: isIncome ? const Color(0xFF047857) : const Color(0xFFB91C1C),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _translateCategory(String category, BuildContext context) {
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

  bool _isVi(BuildContext context) =>
      AppStrings.of(context).language == AppLanguage.vi;
}
