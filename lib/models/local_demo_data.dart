import '../models/transaction_record.dart';

final List<TransactionRecord> localDemoTransactions = [
  TransactionRecord(
    id: 'local_001',
    title: 'Lương tháng',
    amount: 20000000,
    date: DateTime.now().subtract(const Duration(days: 2)),
    category: 'Salary',
    type: TransactionType.income,
    note: 'Công ty ABC',
  ),
  TransactionRecord(
    id: 'local_002',
    title: 'Ăn trưa',
    amount: 50000,
    date: DateTime.now().subtract(const Duration(days: 1)),
    category: 'Food',
    type: TransactionType.expense,
  ),
  TransactionRecord(
    id: 'local_003',
    title: 'Mua sách',
    amount: 120000,
    date: DateTime.now().subtract(const Duration(days: 3)),
    category: 'Shopping',
    type: TransactionType.expense,
  ),
  TransactionRecord(
    id: 'local_004',
    title: 'Freelance',
    amount: 3000000,
    date: DateTime.now().subtract(const Duration(days: 5)),
    category: 'Freelance',
    type: TransactionType.income,
  ),
  TransactionRecord(
    id: 'local_005',
    title: 'Tiền nhà',
    amount: 3500000,
    date: DateTime.now().subtract(const Duration(days: 7)),
    category: 'Housing',
    type: TransactionType.expense,
  ),
];
