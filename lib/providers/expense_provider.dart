import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_record.dart';

import '../models/local_demo_data.dart';

class ExpenseProvider extends ChangeNotifier {
  static Future<void> seedDemoData(ExpenseProvider provider) async {
    final snapshot = await provider._firestore
        .collection('transactions')
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      // Seed local data vào Firestore nếu Firestore trống
      for (final tx in localDemoTransactions) {
        await provider._firestore.collection('transactions').doc(tx.id).set({
          'title': tx.title,
          'amount': tx.amount,
          'date': Timestamp.fromDate(tx.date),
          'category': tx.category,
          'type': tx.type == TransactionType.income ? 'income' : 'expense',
          'note': tx.note,
        });
      }
    }
    await provider.fetchTransactions();
  }

  final FirebaseFirestore _firestore;
  List<TransactionRecord> _transactions = [];

  ExpenseProvider({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance {
    Future.microtask(() => ExpenseProvider.seedDemoData(this));
  }

  List<TransactionRecord> get transactions => [
    ...localDemoTransactions,
    ..._transactions,
  ];

  Future<void> fetchTransactions() async {
    final snapshot = await _firestore.collection('transactions').get();
    _transactions = snapshot.docs.map((doc) {
      final data = doc.data();
      return TransactionRecord(
        id: doc.id,
        title: data['title'] ?? '',
        amount: (data['amount'] ?? 0).toDouble(),
        date: _parseFirestoreDate(data['date']),
        category: data['category'] ?? '',
        type: data['type'] == 'income'
            ? TransactionType.income
            : TransactionType.expense,
        note: data['note'],
      );
    }).toList();
    notifyListeners();
  }

  Future<void> addTransaction(TransactionRecord tx) async {
    await _firestore.collection('transactions').add({
      'title': tx.title,
      'amount': tx.amount,
      'date': Timestamp.fromDate(tx.date),
      'category': tx.category,
      'type': tx.type == TransactionType.income ? 'income' : 'expense',
      'note': tx.note,
    });
    await fetchTransactions();
  }

  DateTime _parseFirestoreDate(dynamic rawDate) {
    if (rawDate is Timestamp) {
      return rawDate.toDate();
    }
    if (rawDate is String) {
      return DateTime.tryParse(rawDate) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
