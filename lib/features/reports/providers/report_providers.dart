import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlct/features/transactions/data/models/transaction_model.dart';
import 'package:qlct/features/transactions/data/repositories/transaction_repository.dart';

enum ReportPeriod { week, month, year }

final reportPeriodProvider = StateProvider<ReportPeriod>(
  (ref) => ReportPeriod.month,
);

final selectedReportMonthProvider = StateProvider<DateTime>(
  (ref) => DateTime.now(),
);

final reportTransactionsProvider = StreamProvider<List<TransactionModel>>((
  ref,
) {
  final period = ref.watch(reportPeriodProvider);
  final selected = ref.watch(selectedReportMonthProvider);

  late DateTime start;
  late DateTime end;

  switch (period) {
    case ReportPeriod.week:
      final weekday = selected.weekday;
      start = DateTime(
        selected.year,
        selected.month,
        selected.day - weekday + 1,
      );
      end = start.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );
      break;
    case ReportPeriod.month:
      start = DateTime(selected.year, selected.month, 1);
      end = DateTime(selected.year, selected.month + 1, 0, 23, 59, 59);
      break;
    case ReportPeriod.year:
      start = DateTime(selected.year, 1, 1);
      end = DateTime(selected.year, 12, 31, 23, 59, 59);
      break;
  }

  return watchTransactionsByDateRange(start, end);
});

final reportSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final txns = ref.watch(reportTransactionsProvider).valueOrNull ?? [];

  double totalIncome = 0;
  double totalExpense = 0;
  double largestExpense = 0;
  final categoryExpenses = <String, double>{};
  final categoryColors = <String, String>{};
  final dailyData = <String, Map<String, double>>{};

  for (final txn in txns) {
    if (txn.isIncome) {
      totalIncome += txn.amount;
    } else {
      totalExpense += txn.amount;
      if (txn.amount > largestExpense) largestExpense = txn.amount;
      categoryExpenses[txn.categoryName] =
          (categoryExpenses[txn.categoryName] ?? 0) + txn.amount;
    }

    final dayKey = '${txn.date.month}/${txn.date.day}';
    dailyData.putIfAbsent(dayKey, () => {'income': 0, 'expense': 0});
    if (txn.isIncome) {
      dailyData[dayKey]!['income'] =
          (dailyData[dayKey]!['income'] ?? 0) + txn.amount;
    } else {
      dailyData[dayKey]!['expense'] =
          (dailyData[dayKey]!['expense'] ?? 0) + txn.amount;
    }
  }

  final days = txns.isEmpty
      ? 1
      : txns.last.date.difference(txns.first.date).inDays.abs() + 1;
  final avgPerDay = txns.isEmpty ? 0.0 : totalExpense / days;

  return {
    'totalIncome': totalIncome,
    'totalExpense': totalExpense,
    'balance': totalIncome - totalExpense,
    'largestExpense': largestExpense,
    'avgPerDay': avgPerDay,
    'categoryExpenses': categoryExpenses,
    'categoryColors': categoryColors,
    'dailyData': dailyData,
    'transactionCount': txns.length,
  };
});
