import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlct/features/budget/data/models/budget_model.dart';
import 'package:qlct/features/budget/data/repositories/budget_repository.dart';
import 'package:qlct/features/transactions/data/models/transaction_model.dart';
import 'package:qlct/features/transactions/data/repositories/transaction_repository.dart';

final selectedBudgetMonthProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final budgetsProvider = StreamProvider<List<BudgetModel>>((ref) {
  final selected = ref.watch(selectedBudgetMonthProvider);
  return watchBudgets(selected.month, selected.year);
});

final budgetMonthTransactionsProvider = StreamProvider<List<TransactionModel>>((
  ref,
) {
  final selected = ref.watch(selectedBudgetMonthProvider);
  final start = DateTime(selected.year, selected.month, 1);
  final end = DateTime(selected.year, selected.month + 1, 0, 23, 59, 59);
  return watchTransactionsByDateRange(start, end);
});

final budgetProgressProvider = Provider<Map<String, Map<String, double>>>((
  ref,
) {
  final budgets = ref.watch(budgetsProvider).valueOrNull ?? [];
  final txns = ref.watch(budgetMonthTransactionsProvider).valueOrNull ?? [];

  final result = <String, Map<String, double>>{};

  for (final budget in budgets) {
    double spent = 0;
    for (final txn in txns) {
      if (txn.isExpense && txn.categoryId == budget.categoryId) {
        spent += txn.amount;
      }
    }
    result[budget.categoryId] = {
      'limit': budget.limit,
      'spent': spent,
      'remaining': budget.limit - spent,
      'percentage': budget.limit > 0
          ? (spent / budget.limit).clamp(0.0, 1.5)
          : 0,
    };
  }

  return result;
});
