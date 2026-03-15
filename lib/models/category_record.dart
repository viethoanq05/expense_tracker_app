import 'package:expense_tracker_app/models/transaction_record.dart';

class CategoryRecord {
  const CategoryRecord({
    required this.id,
    required this.name,
    required this.type,
    required this.icon,
    this.colorHex,
  });

  final String id;
  final String name;
  final TransactionType type;
  final String icon;
  final String? colorHex;
}
