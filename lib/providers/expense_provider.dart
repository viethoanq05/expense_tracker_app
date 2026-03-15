import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_record.dart';

class ExpenseProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore;
  List<TransactionRecord> _transactions = [];

  ExpenseProvider({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  List<TransactionRecord> get transactions => _transactions;

  Future<void> fetchTransactions() async {
    final snapshot = await _firestore.collection('transactions').get();
    _transactions = snapshot.docs.map((doc) {
      final data = doc.data();
      return TransactionRecord(
        id: doc.id,
        title: data['title'] ?? '',
        amount: (data['amount'] ?? 0).toDouble(),
        date: DateTime.parse(data['date']),
        category: data['category'] ?? '',
        type: data['type'] == 'income' ? TransactionType.income : TransactionType.expense,
        note: data['note'],
      );
    }).toList();
    notifyListeners();
  }

  Future<void> addTransaction(TransactionRecord tx) async {
    await _firestore.collection('transactions').add({
      'title': tx.title,
      'amount': tx.amount,
      'date': tx.date.toIso8601String(),
      'category': tx.category,
      'type': tx.type == TransactionType.income ? 'income' : 'expense',
      'note': tx.note,
    });
    await fetchTransactions();
  }
}
