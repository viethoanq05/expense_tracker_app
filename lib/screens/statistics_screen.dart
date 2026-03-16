import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/transaction_record.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<ExpenseProvider>().transactions;
    final Map<String, double> categoryTotals = {};
    final Map<int, double> weekIncome = {};
    final Map<int, double> weekExpense = {};

    for (var tx in transactions) {
      // Pie chart: accumulate by category
      categoryTotals[tx.category] = (categoryTotals[tx.category] ?? 0) + tx.amount;
      // Bar chart: accumulate by week
      final week = tx.date.weekOfYear;
      if (tx.type == TransactionType.income) {
        weekIncome[week] = (weekIncome[week] ?? 0) + tx.amount;
      } else {
        weekExpense[week] = (weekExpense[week] ?? 0) + tx.amount;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê chi tiêu')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text('Phân bổ chi tiêu theo danh mục', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: categoryTotals.entries.map((e) => PieChartSectionData(
                    value: e.value,
                    title: e.key,
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text('So sánh thu chi theo tuần', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: weekIncome.keys.map((week) => BarChartGroupData(
                    x: week,
                    barRods: [
                       BarChartRodData(toY: weekIncome[week] ?? 0, color: Colors.green),
                       BarChartRodData(toY: weekExpense[week] ?? 0, color: Colors.red),
                    ],
                  )).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension DateTimeWeek on DateTime {
  int get weekOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    return ((difference(firstDayOfYear).inDays + firstDayOfYear.weekday) / 7).ceil();
  }
}
