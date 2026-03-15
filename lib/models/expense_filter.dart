import 'package:expense_tracker_app/models/transaction_record.dart';

enum TimeFilter { all, last7Days, last30Days, thisMonth, custom }

enum AmountFilter { all, under200k, from200kTo1m, over1m }

class ExpenseFilter {
  const ExpenseFilter({
    this.keyword = '',
    this.timeFilter = TimeFilter.all,
    this.amountFilter = AmountFilter.all,
    this.category = allCategories,
    this.fromDate,
    this.toDate,
  });

  static const String allCategories = 'All categories';

  final String keyword;
  final TimeFilter timeFilter;
  final AmountFilter amountFilter;
  final String category;
  final DateTime? fromDate;
  final DateTime? toDate;

  ExpenseFilter copyWith({
    String? keyword,
    TimeFilter? timeFilter,
    AmountFilter? amountFilter,
    String? category,
    DateTime? fromDate,
    DateTime? toDate,
    bool clearCustomRange = false,
  }) {
    return ExpenseFilter(
      keyword: keyword ?? this.keyword,
      timeFilter: timeFilter ?? this.timeFilter,
      amountFilter: amountFilter ?? this.amountFilter,
      category: category ?? this.category,
      fromDate: clearCustomRange ? null : fromDate ?? this.fromDate,
      toDate: clearCustomRange ? null : toDate ?? this.toDate,
    );
  }

  bool matches(TransactionRecord tx, DateTime now) {
    final keywordLower = keyword.trim().toLowerCase();
    final haystack = '${tx.title} ${tx.category} ${tx.note ?? ''}'
        .toLowerCase();

    final matchKeyword =
        keywordLower.isEmpty || haystack.contains(keywordLower);
    final matchCategory = category == allCategories || tx.category == category;
    final matchAmount = _matchAmount(tx.amount.abs());
    final matchTime = _matchTime(tx.date, now);

    return matchKeyword && matchCategory && matchAmount && matchTime;
  }

  bool _matchAmount(double amount) {
    return switch (amountFilter) {
      AmountFilter.all => true,
      AmountFilter.under200k => amount < 200000,
      AmountFilter.from200kTo1m => amount >= 200000 && amount <= 1000000,
      AmountFilter.over1m => amount > 1000000,
    };
  }

  bool _matchTime(DateTime date, DateTime now) {
    return switch (timeFilter) {
      TimeFilter.all => true,
      TimeFilter.last7Days => date.isAfter(
        now.subtract(const Duration(days: 7)),
      ),
      TimeFilter.last30Days => date.isAfter(
        now.subtract(const Duration(days: 30)),
      ),
      TimeFilter.thisMonth => date.year == now.year && date.month == now.month,
      TimeFilter.custom => _matchCustomRange(date),
    };
  }

  bool _matchCustomRange(DateTime date) {
    if (fromDate == null && toDate == null) {
      return true;
    }

    if (fromDate != null && date.isBefore(_startOfDay(fromDate!))) {
      return false;
    }

    if (toDate != null && date.isAfter(_endOfDay(toDate!))) {
      return false;
    }

    return true;
  }

  DateTime _startOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  DateTime _endOfDay(DateTime value) {
    return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
  }
}
