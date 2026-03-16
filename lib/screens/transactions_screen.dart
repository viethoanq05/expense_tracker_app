import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/transaction_record.dart';
import 'package:fl_chart/fl_chart.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<ExpenseProvider>().transactions;
    final expenseTransactions = transactions.where((tx) => tx.type == TransactionType.expense).toList();
    final incomeTransactions = transactions.where((tx) => tx.type == TransactionType.income).toList();

    // Biểu đồ cột: tổng thu và tổng chi theo ngày
    final Map<String, double> dailyIncome = {};
    final Map<String, double> dailyExpense = {};
    for (var tx in transactions) {
      final day = '${tx.date.year}-${tx.date.month}-${tx.date.day}';
      if (tx.type == TransactionType.income) {
        dailyIncome[day] = (dailyIncome[day] ?? 0) + tx.amount;
      } else {
        dailyExpense[day] = (dailyExpense[day] ?? 0) + tx.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final tx = transactions[index];
          return ListTile(
            leading: Icon(
              tx.type == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
              color: tx.type == TransactionType.income ? Colors.green : Colors.red,
            ),
            title: Text(tx.title),
            subtitle: Text('${tx.category} · ${tx.date.day}/${tx.date.month}/${tx.date.year}'),
            trailing: Text(
              (tx.type == TransactionType.income ? '+' : '-') + tx.amount.toStringAsFixed(0),
              style: TextStyle(
                color: tx.type == TransactionType.income ? Colors.green : Colors.red,
              ),
            ),
          );
        },
      ),
    );
  }
}
