import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/transaction_record.dart';
import 'package:fl_chart/fl_chart.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  static List<FlSpot> buildLineSpots(
      List<TransactionRecord> transactions, TransactionType type) {
    final Map<int, double> dailyTotals = {};
    final List<int> days = [];
    for (var tx in transactions) {
      if (tx.type == type) {
        final day = tx.date.day;
        dailyTotals[day] = (dailyTotals[day] ?? 0) + tx.amount;
        if (!days.contains(day)) days.add(day);
      }
    }
    days.sort();
    return days.map((day) => FlSpot(day.toDouble(), dailyTotals[day] ?? 0)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<ExpenseProvider>().transactions;

    final Map<String, double> categoryTotals = {};
    final Map<int, double> weekIncome = {};
    final Map<int, double> weekExpense = {};

    for (var tx in transactions) {
      categoryTotals[tx.category] =
          (categoryTotals[tx.category] ?? 0) + tx.amount;

      final week = tx.date.weekOfYear;

      if (tx.type == TransactionType.income) {
        weekIncome[week] = (weekIncome[week] ?? 0) + tx.amount;
      } else {
        weekExpense[week] = (weekExpense[week] ?? 0) + tx.amount;
      }
    }

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.amber,
      Colors.pink
    ];

    final categoryList = categoryTotals.entries.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            Text(
              'Thống kê chi tiêu',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 8),

            Text(
              'Phân bổ chi tiêu theo danh mục',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: categoryList.asMap().entries.map((entry) {
                    int i = entry.key;
                    var e = entry.value;

                    return PieChartSectionData(
                      value: e.value,
                      title: '',
                      radius: 80,
                      color: colors[i % colors.length],
                    );
                  }).toList(),
                  centerSpaceRadius: 50,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: categoryList.asMap().entries.map((entry) {
                int i = entry.key;
                var e = entry.value;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: colors[i % colors.length],
                    ),
                    const SizedBox(width: 6),
                    Text("${e.key} (${e.value.toStringAsFixed(0)})"),
                  ],
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            Text(
              'Xu hướng chi tiêu theo ngày',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minX: transactions.isEmpty ? 0 : transactions.map((tx) => tx.date.day.toDouble()).reduce((a, b) => a < b ? a : b) - 1,
                  maxX: transactions.isEmpty ? 31 : transactions.map((tx) => tx.date.day.toDouble()).reduce((a, b) => a > b ? a : b) + 2,
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString());
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: BudgetScreen.buildLineSpots(
                          transactions, TransactionType.expense),
                      isCurved: true,
                      color: Colors.red,
                      dotData: FlDotData(show: false),
                      barWidth: 3,
                    ),
                    LineChartBarData(
                      spots: BudgetScreen.buildLineSpots(
                          transactions, TransactionType.income),
                      isCurved: true,
                      color: Colors.green,
                      dotData: FlDotData(show: false),
                      barWidth: 3,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            Text(
              'So sánh thu chi theo tuần',
              style: Theme.of(context).textTheme.titleMedium,
            ),

            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: (() {
                    final weeks = {...weekIncome.keys, ...weekExpense.keys}.toList();
                    weeks.sort();
                    return weeks.map((week) {
                      return BarChartGroupData(
                        x: week,
                        barRods: [
                          BarChartRodData(
                            toY: weekIncome[week] ?? 0,
                            color: Colors.green,
                          ),
                          BarChartRodData(
                            toY: weekExpense[week] ?? 0,
                            color: Colors.red,
                          ),
                        ],
                      );
                    }).toList();
                  })(),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

extension DateTimeWeek on DateTime {
  int get weekOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    return ((difference(firstDayOfYear).inDays + firstDayOfYear.weekday) / 7)
        .ceil();
  }
}