import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlct/features/auth/providers/auth_providers.dart';
import 'package:qlct/features/debts/data/models/debt_model.dart';
import 'package:qlct/features/debts/data/repositories/debt_repository.dart';

final debtsProvider = StreamProvider<List<DebtModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return Stream.value([]);
  return watchDebts();
});

final totalOwedToMeProvider = Provider<double>((ref) {
  final debts = ref.watch(debtsProvider).valueOrNull ?? [];
  return debts
      .where((d) => d.isOwedToMe && !d.isPaid)
      .fold(0.0, (sum, d) => sum + d.amount);
});

final totalIBorrowedProvider = Provider<double>((ref) {
  final debts = ref.watch(debtsProvider).valueOrNull ?? [];
  return debts
      .where((d) => !d.isOwedToMe && !d.isPaid)
      .fold(0.0, (sum, d) => sum + d.amount);
});
