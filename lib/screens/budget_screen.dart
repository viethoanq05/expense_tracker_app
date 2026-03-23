import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/transaction_record.dart';
import 'package:fl_chart/fl_chart.dart';
import '../localization/app_strings.dart';
import '../widgets/app_preferences_scope.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<ExpenseProvider>().transactions;

    final Map<String, double> categoryTotals = {};
    final Map<int, double> dayExpense = {};
    final Map<int, double> weekIncome = {};
    final Map<int, double> weekExpense = {};
    final now = DateTime.now();
    const categoriesToTrack = ['Food', 'Housing', 'Shopping', 'Transport'];

    for (var tx in transactions) {
      final week = tx.date.weekOfYear;

      if (tx.type == TransactionType.income) {
        weekIncome[week] = (weekIncome[week] ?? 0) + tx.amount;
      } else {
        weekExpense[week] = (weekExpense[week] ?? 0) + tx.amount;

        // Daily spending trend for current month (only for the 4 tracked categories)
        if (tx.date.month == now.month &&
            tx.date.year == now.year &&
            categoriesToTrack.contains(tx.category)) {
          dayExpense[tx.date.day] = (dayExpense[tx.date.day] ?? 0) + tx.amount;
        }

        // Only add to categoryTotals if it's one of the 4 specified categories
        if (categoriesToTrack.contains(tx.category)) {
          categoryTotals[tx.category] =
              (categoryTotals[tx.category] ?? 0) + tx.amount;
        }
      }
    }

    final preferences = AppPreferencesScope.of(context);
    final double totalBudget = categoriesToTrack.fold(0.0, (sum, category) {
      return sum + (preferences.budgetFor(category) ?? 0.0);
    });

    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    double cumulativeSum = 0;
    final List<FlSpot> cumulativeSpots = List.generate(daysInMonth, (index) {
      final day = index + 1;
      cumulativeSum += dayExpense[day] ?? 0;
      return FlSpot(day.toDouble(), cumulativeSum);
    });

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
    ];

    final categoryList = categoryTotals.entries.toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth > 800 ? 64.0 : 16.0;
    const contentMaxWidth = 1200.0;

    final strings = AppStrings.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: contentMaxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    strings.monthlySpendingStats,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.categoryDistribution,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 32),
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
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: categoryList.asMap().entries.map((entry) {
                      int i = entry.key;
                      var e = entry.value;

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors[i % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${_translateCategory(e.key, context)}: ${_currency(e.value)}",
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (categoryList.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          strings.noDataForCategories,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 48),
                  Text(
                    strings.weeklyComparison,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        barGroups: (() {
                          final weeks =
                              {...weekIncome.keys, ...weekExpense.keys}
                                  .toList();
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
                  Text(
                    strings.dailySpendingTrend,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: LineChart(
                      LineChartData(
                        minX: 1,
                        maxX: daysInMonth.toDouble(),
                        minY: 0,
                        maxY: (totalBudget > cumulativeSum
                                ? totalBudget
                                : cumulativeSum)
                            .clamp(1.0, double.infinity) *
                            1.1,
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(
                          rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: cumulativeSpots,
                            isCurved: true,
                            color: Theme.of(context).colorScheme.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.1),
                            ),
                          ),
                          if (totalBudget > 0)
                            LineChartBarData(
                              spots: [
                                FlSpot(1, totalBudget),
                                FlSpot(daysInMonth.toDouble(), totalBudget),
                              ],
                              isCurved: false,
                              color: Colors.red.withOpacity(0.5),
                              barWidth: 2,
                              dashArray: [5, 5],
                              dotData: const FlDotData(show: false),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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

  String _currency(double amount, {bool skipSuffix = false}) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}${skipSuffix ? '' : 'M'}';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}${skipSuffix ? '' : 'K'}';
    }
    return '${amount.toStringAsFixed(0)}';
  }
}

extension DateTimeWeek on DateTime {
  int get weekOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    return ((difference(firstDayOfYear).inDays + firstDayOfYear.weekday) / 7)
        .ceil();
  }
}
