import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_tracker_app/models/category_record.dart';
import 'package:expense_tracker_app/models/dashboard_summary.dart';
import 'package:expense_tracker_app/models/expense_filter.dart';
import 'package:expense_tracker_app/models/transaction_record.dart';
import 'package:expense_tracker_app/services/expense_repository.dart';

class FirestoreExpenseRepository implements ExpenseRepository {
  FirestoreExpenseRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _firestore.collection('transactions');

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _firestore.collection('categories');

  Future<void> seedDemoDataIfEmpty() async {
    final existing = await _transactionsRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return;
    }

    final batch = _firestore.batch();
    final now = DateTime.now();

    for (final tx in _demoTransactions(now)) {
      batch.set(_transactionsRef.doc(tx.id), _toFirestore(tx));
    }

    for (final category in _demoCategories) {
      batch.set(_categoriesRef.doc(category.id), {
        'name': category.name,
        'type': category.type.name,
        'icon': category.icon,
        'colorHex': category.colorHex,
      });
    }

    await batch.commit();
  }

  @override
  Future<void> addTransaction(TransactionRecord transaction) async {
    await _transactionsRef.doc(transaction.id).set(_toFirestore(transaction));
  }

  @override
  Future<void> deleteTransaction(String transactionId) async {
    await _transactionsRef.doc(transactionId).delete();
  }

  @override
  Future<List<CategoryRecord>> getCategories() async {
    final snapshot = await _categoriesRef.get();
    if (snapshot.docs.isEmpty) {
      return _categoriesFromTransactions();
    }

    return snapshot.docs.map(_categoryFromDoc).toList(growable: false);
  }

  @override
  Future<DashboardSummary> getMonthlySummary(DateTime month) async {
    final start = DateTime(month.year, month.month, 1);
    final nextMonth = DateTime(month.year, month.month + 1, 1);

    final snapshot = await _transactionsRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(nextMonth))
        .get();

    double income = 0;
    double expense = 0;
    for (final doc in snapshot.docs) {
      final tx = _txFromDoc(doc);
      if (tx.type == TransactionType.income) {
        income += tx.amount;
      } else {
        expense += tx.amount;
      }
    }

    return DashboardSummary(
      monthlyIncome: income,
      monthlyExpense: expense,
      monthlyBalance: income - expense,
      transactionCount: snapshot.docs.length,
    );
  }

  @override
  Future<List<TransactionRecord>> getTransactions({
    ExpenseFilter filter = const ExpenseFilter(),
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _transactionsRef.orderBy(
      'date',
      descending: true,
    );

    if (limit != null) {
      query = query.limit(limit * 4);
    }

    final snapshot = await query.get();
    final now = DateTime.now();

    final filtered =
        snapshot.docs
            .map(_txFromDoc)
            .where((tx) => filter.matches(tx, now))
            .toList(growable: false)
          ..sort((a, b) => b.date.compareTo(a.date));

    if (limit == null || filtered.length <= limit) {
      return filtered;
    }
    return filtered.take(limit).toList(growable: false);
  }

  @override
  Future<void> updateTransaction(TransactionRecord transaction) async {
    await _transactionsRef
        .doc(transaction.id)
        .update(_toFirestore(transaction));
  }

  CategoryRecord _categoryFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final typeName = (data['type'] as String? ?? 'expense').toLowerCase();

    return CategoryRecord(
      id: doc.id,
      name: data['name'] as String? ?? 'Unknown',
      type: typeName == TransactionType.income.name
          ? TransactionType.income
          : TransactionType.expense,
      icon: data['icon'] as String? ?? 'category',
      colorHex: data['colorHex'] as String?,
    );
  }

  Future<List<CategoryRecord>> _categoriesFromTransactions() async {
    final transactions = await getTransactions();
    final names = transactions.map((tx) => tx.category).toSet().toList()
      ..sort();

    return names
        .map(
          (name) => CategoryRecord(
            id: name.toLowerCase().replaceAll(' ', '_'),
            name: name,
            type: TransactionType.expense,
            icon: 'category',
          ),
        )
        .toList(growable: false);
  }

  TransactionRecord _txFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final typeName = (data['type'] as String? ?? 'expense').toLowerCase();
    final rawDate = data['date'];

    DateTime date;
    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    return TransactionRecord(
      id: doc.id,
      title: data['title'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: date,
      category: data['category'] as String? ?? 'Uncategorized',
      type: typeName == TransactionType.income.name
          ? TransactionType.income
          : TransactionType.expense,
      note: data['note'] as String?,
    );
  }

  Map<String, dynamic> _toFirestore(TransactionRecord tx) {
    return {
      'title': tx.title,
      'amount': tx.amount,
      'date': Timestamp.fromDate(tx.date),
      'category': tx.category,
      'type': tx.type.name,
      'note': tx.note,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  List<TransactionRecord> _demoTransactions(DateTime now) {
    return [
      TransactionRecord(
        id: 'tx_demo_001',
        title: 'Lương tháng này',
        amount: 18500000,
        date: DateTime(now.year, now.month, 1),
        category: 'Salary',
        type: TransactionType.income,
        note: 'Công ty ABC',
      ),
      TransactionRecord(
        id: 'tx_demo_002',
        title: 'Ăn trưa văn phòng',
        amount: 85000,
        date: now.subtract(const Duration(days: 1)),
        category: 'Food',
        type: TransactionType.expense,
      ),
      TransactionRecord(
        id: 'tx_demo_003',
        title: 'Cafe họp nhóm',
        amount: 58000,
        date: now.subtract(const Duration(days: 2)),
        category: 'Food',
        type: TransactionType.expense,
      ),
      TransactionRecord(
        id: 'tx_demo_004',
        title: 'Di chuyển',
        amount: 124000,
        date: now.subtract(const Duration(days: 3)),
        category: 'Transport',
        type: TransactionType.expense,
      ),
      TransactionRecord(
        id: 'tx_demo_005',
        title: 'Mua đồ gia dụng',
        amount: 332000,
        date: now.subtract(const Duration(days: 4)),
        category: 'Shopping',
        type: TransactionType.expense,
      ),
      TransactionRecord(
        id: 'tx_demo_006',
        title: 'Freelance sprint UI',
        amount: 2100000,
        date: now.subtract(const Duration(days: 6)),
        category: 'Freelance',
        type: TransactionType.income,
      ),
      TransactionRecord(
        id: 'tx_demo_007',
        title: 'Tiền nhà',
        amount: 3500000,
        date: now.subtract(const Duration(days: 10)),
        category: 'Housing',
        type: TransactionType.expense,
      ),
      TransactionRecord(
        id: 'tx_demo_008',
        title: 'Netflix',
        amount: 260000,
        date: now.subtract(const Duration(days: 11)),
        category: 'Subscription',
        type: TransactionType.expense,
      ),
    ];
  }

  static const List<CategoryRecord> _demoCategories = [
    CategoryRecord(
      id: 'cat_salary',
      name: 'Salary',
      type: TransactionType.income,
      icon: 'payments',
      colorHex: '#1D9A6C',
    ),
    CategoryRecord(
      id: 'cat_freelance',
      name: 'Freelance',
      type: TransactionType.income,
      icon: 'laptop_mac',
      colorHex: '#00796B',
    ),
    CategoryRecord(
      id: 'cat_food',
      name: 'Food',
      type: TransactionType.expense,
      icon: 'restaurant',
      colorHex: '#C65A1E',
    ),
    CategoryRecord(
      id: 'cat_transport',
      name: 'Transport',
      type: TransactionType.expense,
      icon: 'directions_car',
      colorHex: '#2E5AAC',
    ),
    CategoryRecord(
      id: 'cat_housing',
      name: 'Housing',
      type: TransactionType.expense,
      icon: 'home',
      colorHex: '#A24566',
    ),
    CategoryRecord(
      id: 'cat_shopping',
      name: 'Shopping',
      type: TransactionType.expense,
      icon: 'shopping_bag',
      colorHex: '#7158A8',
    ),
  ];
}
