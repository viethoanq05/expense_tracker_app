import 'package:expense_tracker_app/services/expense_repository.dart';
import 'package:expense_tracker_app/services/firebase_bootstrap.dart';
import 'package:expense_tracker_app/services/firestore_expense_repository.dart';
import 'package:expense_tracker_app/services/mock_expense_repository.dart';

class RepositoryRegistry {
  RepositoryRegistry._();

  static final ExpenseRepository _mockRepository = MockExpenseRepository();
  static final FirestoreExpenseRepository _firestoreRepository =
      FirestoreExpenseRepository();

  static ExpenseRepository get expenseRepository {
    return FirebaseBootstrap.isInitialized
        ? _firestoreRepository
        : _mockRepository;
  }

  static Future<void> seedDemoDataIfNeeded() async {
    if (!FirebaseBootstrap.isInitialized) {
      return;
    }

    await _firestoreRepository.seedDemoDataIfEmpty();
  }
}
