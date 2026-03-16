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
  String get budgetCheckResultTitle =>
      _isVi ? 'Kết quả kiểm tra hạn mức' : 'Budget status';
  String get noBudgetExceededMessage => _isVi
      ? 'Chưa có danh mục nào vượt hạn mức trong tháng này.'
      : 'No category exceeds the budget this month.';
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
  String get exportToRealDeviceLabel =>
      _isVi ? 'Xuất ra máy thật' : 'Export to real device';
  String get uploadingToRealDeviceLabel =>
      _isVi ? 'Đang upload lên link...' : 'Uploading for real device...';
  String get exportHistoryTitle =>
      _isVi ? 'Lịch sử link export' : 'Export link history';
  String get exportHistoryEmpty =>
      _isVi ? 'Chưa có link export nào.' : 'No exported links yet.';
  String get exportHistoryLoadFailed =>
      _isVi ? 'Không tải được lịch sử export.' : 'Cannot load export history.';
  String exportHistoryDate(DateTime date) => _isVi
      ? 'Tạo lúc ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
      : 'Created at ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  String get exportPreviewLabel => _isVi ? 'Xem preview' : 'Preview in app';
  String get exportPreviewTitle =>
      _isVi ? 'Preview dữ liệu xuất' : 'Export preview';
  String get downloadLabel => _isVi ? 'Tải về' : 'Download';
  String get copyPullCommandLabel =>
      _isVi ? 'Copy lệnh pull' : 'Copy pull command';
  String get pullCommandCopiedSuccess =>
      _isVi ? 'Đã copy lệnh kéo file về máy tính.' : 'Pull command copied.';
  String downloadSaved(String path) =>
      _isVi ? 'Đã tải file về: $path' : 'File downloaded to: $path';
  String downloadFailed(String error) =>
      _isVi ? 'Không tải được file: $error' : 'Cannot download file: $error';
  String exportPreviewSubtitle(int count) =>
      _isVi ? 'Tổng số dòng dữ liệu: $count' : 'Total exported rows: $count';
  String get exportPreviewEmpty =>
      _isVi ? 'Chưa có dữ liệu để preview.' : 'There is no data to preview.';
  String get exportColumnId => 'ID';
  String get exportColumnTitle => _isVi ? 'Tiêu đề' : 'Title';
  String get exportColumnAmount => _isVi ? 'Số tiền' : 'Amount';
  String get exportColumnDate => _isVi ? 'Ngày' : 'Date';
  String get exportColumnCategory => _isVi ? 'Danh mục' : 'Category';
  String get exportColumnType => _isVi ? 'Loại' : 'Type';
  String get exportColumnNote => _isVi ? 'Ghi chú' : 'Note';
  String get openFolderLabel => _isVi ? 'Mở thư mục' : 'Open folder';
  String get openFileLabel => _isVi ? 'Mở file' : 'Open file';
  String get shareFileLabel => _isVi ? 'Chia sẻ file' : 'Share file';
  String get noExportYetLabel =>
      _isVi ? 'Chưa có file export gần nhất.' : 'No recent exported file yet.';
  String get latestExportLabel => _isVi ? 'File gần nhất:' : 'Latest file:';
  String get openFolderFailed =>
      _isVi ? 'Không mở được thư mục.' : 'Unable to open folder.';
  String get openFileFailed =>
      _isVi ? 'Không mở được file.' : 'Unable to open file.';
  String get shareFileFailed =>
      _isVi ? 'Không thể chia sẻ file.' : 'Unable to share file.';
  String get exportLinkReadyTitle =>
      _isVi ? 'Link tải file đã sẵn sàng' : 'Download link is ready';
  String get exportLinkReadyDescription => _isVi
      ? 'Mở hoặc sao chép link này trên máy thật để tải file export.'
      : 'Open or copy this link on your real computer to download the export file.';
  String get copyLinkLabel => _isVi ? 'Sao chép link' : 'Copy link';
  String get openLinkLabel => _isVi ? 'Mở link' : 'Open link';
  String get linkCopiedSuccess =>
      _isVi ? 'Đã sao chép link tải file.' : 'Download link copied.';
  String get copyFileNameLabel =>
      _isVi ? 'Sao chép tên file' : 'Copy file name';
  String get exportingLabel => _isVi ? 'Đang xuất...' : 'Exporting...';
  String exportSuccess(String path) =>
      _isVi ? 'Đã xuất file tại: $path' : 'File exported to: $path';
  String exportFailure(String error) =>
      _isVi ? 'Xuất file thất bại: $error' : 'Export failed: $error';
  String get englishLabel => 'English';
  String get vietnameseLabel => 'Tiếng Việt';

  String get securitySectionTitle => _isVi ? 'Bảo mật' : 'Security';
  String get pinLockLabel =>
      _isVi ? 'Khoá ứng dụng bằng mã PIN' : 'Lock app with PIN';
  String get pinLockDescription => _isVi
      ? 'Thiết lập mã PIN 4 số để mở app sau khi mở lại từ nền.'
      : 'Set a 4-digit PIN to unlock the app when reopening it.';
  String get pinSetUpLabel => _isVi ? 'Thiết lập mã PIN' : 'Set PIN';
  String get pinChangeLabel => _isVi ? 'Đổi mã PIN' : 'Change PIN';
  String get pinRemoveLabel => _isVi ? 'Xoá mã PIN' : 'Remove PIN';
  String get pinEnableLabel => _isVi ? 'Bật khoá bằng PIN' : 'Enable PIN lock';
  String get pinEnabledDescription => _isVi
      ? 'App sẽ yêu cầu mã PIN khi mở lại.'
      : 'The app will require your PIN when reopened.';
  String get pinDisabledDescription => _isVi
      ? 'Đã lưu mã PIN nhưng đang tắt khóa ứng dụng.'
      : 'PIN is saved but app lock is currently disabled.';
  String get pinDialogTitle => _isVi ? 'Thiết lập mã PIN' : 'Set PIN';
  String get pinDialogChangeTitle => _isVi ? 'Đổi mã PIN' : 'Change PIN';
  String get pinFieldLabel => _isVi ? 'Mã PIN 4 số' : '4-digit PIN';
  String get pinConfirmFieldLabel => _isVi ? 'Nhập lại mã PIN' : 'Confirm PIN';
  String get pinCurrentFieldLabel => _isVi ? 'Mã PIN hiện tại' : 'Current PIN';
  String get pinSaveLabel => _isVi ? 'Lưu mã PIN' : 'Save PIN';
  String get pinUnlockLabel => _isVi ? 'Mở khoá' : 'Unlock';
  String get pinPrompt => _isVi
      ? 'Nhập mã PIN để mở khóa ứng dụng'
      : 'Enter your PIN to unlock the app';
  String get pinIncorrect => _isVi
      ? 'Mã PIN không đúng. Vui lòng thử lại.'
      : 'Incorrect PIN. Please try again.';
  String get pinValidationLength => _isVi
      ? 'Mã PIN phải gồm đúng 4 chữ số.'
      : 'PIN must be exactly 4 digits.';
  String get pinValidationMismatch => _isVi
      ? 'Mã PIN xác nhận không khớp.'
      : 'PIN confirmation does not match.';
  String get pinValidationCurrentIncorrect =>
      _isVi ? 'Mã PIN hiện tại không đúng.' : 'Current PIN is incorrect.';
  String get pinSavedSuccess => _isVi ? 'Đã lưu mã PIN.' : 'PIN saved.';
  String get pinRemovedSuccess => _isVi ? 'Đã xoá mã PIN.' : 'PIN removed.';
  String get pinCancelLabel => _isVi ? 'Huỷ' : 'Cancel';
}
