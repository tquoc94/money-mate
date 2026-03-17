import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qlct/features/auth/providers/auth_providers.dart';
import 'package:qlct/features/reminders/data/models/reminder_model.dart';
import 'package:qlct/features/reminders/data/repositories/reminder_repository.dart';

final remindersProvider = StreamProvider<List<ReminderModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  if (authState.valueOrNull == null) return Stream.value([]);
  return watchReminders();
});

final upcomingRemindersProvider = Provider<List<ReminderModel>>((ref) {
  final reminders = ref.watch(remindersProvider).valueOrNull ?? [];
  return reminders
      .where((r) => r.isActive && (r.isDueSoon || r.isOverdue))
      .toList();
});
