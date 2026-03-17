import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlct/features/transactions/data/models/transaction_model.dart';
import 'package:qlct/features/transactions/data/models/category_model.dart';
import 'package:qlct/features/transactions/data/repositories/transaction_repository.dart';
import 'package:qlct/features/transactions/data/repositories/category_repository.dart';

final transactionsStreamProvider = StreamProvider<List<TransactionModel>>((
  ref,
) {
  return watchTransactions();
});

final categoriesStreamProvider = StreamProvider<List<CategoryModel>>((ref) {
  return watchCategories();
});

final expenseCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return watchCategoriesByType('expense');
});

final incomeCategoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return watchCategoriesByType('income');
});

final monthlyTransactionsProvider = StreamProvider<List<TransactionModel>>((
  ref,
) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, 1);
  final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  return watchTransactionsByDateRange(start, end);
});

final monthlySummaryProvider = Provider<Map<String, double>>((ref) {
  final txns = ref.watch(monthlyTransactionsProvider).valueOrNull ?? [];
  double totalIncome = 0;
  double totalExpense = 0;
  for (final txn in txns) {
    if (txn.isIncome) {
      totalIncome += txn.amount;
    } else {
      totalExpense += txn.amount;
    }
  }
  return {
    'income': totalIncome,
    'expense': totalExpense,
    'balance': totalIncome - totalExpense,
  };
});
