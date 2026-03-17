import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlct/features/auth/providers/auth_providers.dart';
import 'package:qlct/features/savings/data/models/savings_goal_model.dart';
import 'package:qlct/features/savings/data/repositories/savings_repository.dart';

final savingsGoalsProvider = StreamProvider<List<SavingsGoalModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return Stream.value([]);
  return watchSavingsGoals();
});
