class DashboardSummary {
  const DashboardSummary({
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthlyBalance,
    required this.transactionCount,
  });

  final double monthlyIncome;
  final double monthlyExpense;
  final double monthlyBalance;
  final int transactionCount;
}
