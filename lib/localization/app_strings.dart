import 'package:expense_tracker_app/widgets/app_preferences_scope.dart';
import 'package:flutter/material.dart';

enum AppLanguage {
  en('en'),
  vi('vi');

  const AppLanguage(this.code);

  final String code;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (language) => language.code == code,
      orElse: () => AppLanguage.en,
    );
  }
}

class AppStrings {
  const AppStrings(this.language);

  final AppLanguage language;

  static AppStrings of(BuildContext context) {
    final controller = AppPreferencesScope.of(context);
    return AppStrings(controller.language);
  }

  bool get _isVi => language == AppLanguage.vi;

  String get appTitle => _isVi ? 'Quản lý chi tiêu' : 'Expense Tracker';
  String get dashboardLabel => _isVi ? 'Tổng quan' : 'Dashboard';
  String get transactionsLabel => _isVi ? 'Giao dịch' : 'Transactions';
  String get budgetLabel => _isVi ? 'Ngân sách' : 'Budget';
  String get settingsLabel => _isVi ? 'Cài đặt' : 'Settings';
  String get addLabel => _isVi ? 'Thêm' : 'Add';
  String get addTransactionTooltip =>
      _isVi ? 'Thêm giao dịch' : 'Add transaction';
  String get comingSoonPrefix => _isVi ? 'Sắp có màn' : 'Coming soon:';
  String get searchAndFilterTooltip =>
      _isVi ? 'Tìm kiếm và lọc' : 'Search and filter';
  String get searchHint => _isVi
      ? 'Tìm theo nội dung, ghi chú, danh mục...'
      : 'Search by content, note, category...';
  String get openFiltersTooltip => _isVi ? 'Mở bộ lọc' : 'Open filters';
  String get resetFiltersTooltip => _isVi ? 'Đặt lại bộ lọc' : 'Reset filters';
  String matchedTransactions(int count) =>
      _isVi ? 'Giao dịch phù hợp: $count' : 'Matched transactions: $count';
  String get noTransactionsForFilter => _isVi
      ? 'Không có giao dịch phù hợp với bộ lọc hiện tại.'
      : 'No transactions found with current filters.';
  String get filterCriteria => _isVi ? 'Tiêu chí lọc' : 'Filter criteria';
  String get resetLabel => _isVi ? 'Đặt lại' : 'Reset';
  String get doneLabel => _isVi ? 'Xong' : 'Done';
  String get loadingTransactions => _isVi
      ? 'Đang tải giao dịch từ Firestore...'
      : 'Loading transactions from Firestore...';
  String get cannotLoadTransactions => _isVi
      ? 'Không thể tải dữ liệu giao dịch.'
      : 'Cannot load Firestore data.';
  String get retryLabel => _isVi ? 'Thử lại' : 'Retry';
  String get monthlyBalance => _isVi ? 'Số dư tháng này' : 'Monthly Balance';
  String get totalIncome => _isVi ? 'Tổng thu' : 'Total Income';
  String get totalExpense => _isVi ? 'Tổng chi' : 'Total Expense';
  String get thisMonthReport =>
      _isVi ? 'Báo cáo tháng này' : 'This month report';
  String get expenseDistributionByCategory => _isVi
      ? 'Phân bổ chi tiêu theo danh mục'
      : 'Expense distribution by category';
  String get noExpensesThisMonth => _isVi
      ? 'Chưa có chi tiêu trong tháng này.'
      : 'No expenses this month yet.';
  String get recentTransactions =>
      _isVi ? 'Giao dịch gần đây' : 'Recent Transactions';
  String get showingLatestRecords =>
      _isVi ? 'Hiện 5 giao dịch mới nhất' : 'Showing latest 5 records';
  String get noTransactionData =>
      _isVi ? 'Chưa có dữ liệu giao dịch.' : 'No transaction data available.';
  String get overBudgetTitle =>
      _isVi ? 'Cảnh báo vượt ngân sách' : 'Over budget warning';
  String overBudgetDescription(int count) => _isVi
      ? 'Bạn đã vượt hạn mức ở $count danh mục trong tháng này.'
      : 'You have exceeded the limit in $count categories this month.';
  String get budgetScreenTitle => _isVi ? 'Hạn mức chi tiêu' : 'Budget Limits';
  String get budgetScreenDescription => _isVi
      ? 'Đặt hạn mức theo danh mục. Nếu vượt hạn mức, app sẽ hiện cảnh báo đỏ.'
      : 'Set spending limits by category. Exceeded limits are highlighted in red.';
  String get spentThisMonth => _isVi ? 'Đã chi tháng này' : 'Spent this month';
  String get limitAmount => _isVi ? 'Hạn mức' : 'Limit';
  String get saveBudgets => _isVi ? 'Lưu hạn mức' : 'Save budgets';
  String get budgetsSaved => _isVi ? 'Đã lưu hạn mức.' : 'Budgets saved.';
  String get noExpenseCategories => _isVi
      ? 'Chưa có danh mục chi tiêu để thiết lập hạn mức.'
      : 'No expense categories available for budgeting.';
  String get overBudgetChip => _isVi ? 'Vượt mức' : 'Over limit';
  String get withinBudgetChip => _isVi ? 'Trong mức' : 'Within limit';
  String get noLimitLabel => _isVi ? 'Chưa đặt' : 'Not set';
  String get settingsScreenTitle => _isVi ? 'Cài đặt' : 'Settings';
  String get languageLabel => _isVi ? 'Ngôn ngữ' : 'Language';
  String get darkModeLabel => _isVi ? 'Dark Mode' : 'Dark Mode';
  String get exportSectionTitle => _isVi ? 'Xuất dữ liệu' : 'Export data';
  String get exportCsvLabel => _isVi ? 'Xuất CSV' : 'Export CSV';
  String get exportExcelLabel =>
      _isVi ? 'Xuất CSV mở bằng Excel' : 'Export Excel-compatible CSV';
  String get exportingLabel => _isVi ? 'Đang xuất...' : 'Exporting...';
  String exportSuccess(String path) =>
      _isVi ? 'Đã xuất file tại: $path' : 'File exported to: $path';
  String exportFailure(String error) =>
      _isVi ? 'Xuất file thất bại: $error' : 'Export failed: $error';
  String get englishLabel => 'English';
  String get vietnameseLabel => 'Tiếng Việt';
}
